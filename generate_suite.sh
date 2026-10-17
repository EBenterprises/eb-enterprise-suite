#!/usr/bin/env bash
set -e

echo "=== Initializing EB Enterprise Suite Workspace ==="

# Create directory structure
mkdir -p eb-enterprise-suite/{gateway,auth-service,sales-service,dashboard/public}
cd eb-enterprise-suite

# 1. ROOT DOCKER COMPOSE
cat << 'EOF_DOCKER' > docker-compose.yml
version: '3.8'

services:
  gateway:
    build: ./gateway
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - AUTH_URL=http://auth-service:4001
      - SALES_URL=http://sales-service:4002
    depends_on:
      - auth-service
      - sales-service

  auth-service:
    build: ./auth-service
    ports:
      - "4001:4001"
    environment:
      - PORT=4001
      - JWT_SECRET=eb_secure_enterprise_secret_2026

  sales-service:
    build: ./sales-service
    ports:
      - "4002:4002"
    environment:
      - PORT=4002

  dashboard:
    build: ./dashboard
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - GATEWAY_URL=http://localhost:8080
EOF_DOCKER

# 2. AUTH SERVICE (Node.js / Express / JWT)
cat << 'EOF_AUTH_PKG' > auth-service/package.json
{
  "name": "eb-auth-service",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5"
  }
}
EOF_AUTH_PKG

cat << 'EOF_AUTH_SRV' > auth-service/server.js
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 4001;
const JWT_SECRET = process.env.JWT_SECRET || 'eb_secure_enterprise_secret_2026';

app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;
    // Enterprise mock validation
    if (username === 'admin' && password === 'admin') {
        const token = jwt.sign({ username, role: 'administrator' }, JWT_SECRET, { expiresIn: '12h' });
        return res.json({ success: true, token, user: { username, role: 'administrator' } });
    }
    res.status(401).json({ success: false, error: 'Invalid enterprise credentials' });
});

app.post('/api/auth/verify', (req, res) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ valid: false, error: 'No token provided' });

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) return res.status(403).json({ valid: false, error: 'Token invalid or expired' });
        res.json({ valid: true, decoded });
    });
});

app.listen(PORT, () => console.log(`[Auth Service] Running on port ${PORT}`));
EOF_AUTH_SRV

cat << 'EOF_AUTH_DOCKER' > auth-service/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4001
CMD ["npm", "start"]
EOF_AUTH_DOCKER

# 3. SALES SERVICE (Node.js / SQLite / Express)
cat << 'EOF_SALES_PKG' > sales-service/package.json
{
  "name": "eb-sales-service",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "sqlite3": "^5.1.7",
    "cors": "^2.8.5"
  }
}
EOF_SALES_PKG

cat << 'EOF_SALES_SRV' > sales-service/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 4002;
const db = new sqlite3.Database('./sales.db', (err) => {
    if (err) console.error('Database opening error: ', err.message);
    else console.log('[Sales Service] Connected to SQLite database.');
});

db.run(`CREATE TABLE IF NOT EXISTS sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item TEXT NOT NULL,
    amount REAL NOT NULL,
    buyer TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`);

app.get('/api/sales', (req, res) => {
    db.all("SELECT * FROM sales ORDER BY created_at DESC", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true, data: rows });
    });
});

app.post('/api/sales', (req, res) => {
    const { item, amount, buyer } = req.body;
    if (!item || !amount || !buyer) {
        return res.status(400).json({ error: 'Missing required fields: item, amount, buyer' });
    }
    db.run("INSERT INTO sales (item, amount, buyer) VALUES (?, ?, ?)", [item, amount, buyer], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true, id: this.lastID, item, amount, buyer });
    });
});

app.listen(PORT, () => console.log(`[Sales Service] Running on port ${PORT}`));
EOF_SALES_SRV

cat << 'EOF_SALES_DOCKER' > sales-service/Dockerfile
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4002
CMD ["npm", "start"]
EOF_SALES_DOCKER

# 4. API GATEWAY (Node.js / Express Proxy Router)
cat << 'EOF_GW_PKG' > gateway/package.json
{
  "name": "eb-api-gateway",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5"
  }
}
EOF_GW_PKG

cat << 'EOF_GW_SRV' > gateway/server.js
const express = require('express');
const cors = require('cors');
const http = require('http');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 8080;
const AUTH_URL = process.env.AUTH_URL || 'http://localhost:4001';
const SALES_URL = process.env.SALES_URL || 'http://localhost:4002';

function proxyRequest(req, res, targetBaseUrl) {
    const targetUrl = new URL(req.url, targetBaseUrl);
    const options = {
        hostname: targetUrl.hostname,
        port: targetUrl.port,
        path: targetUrl.pathname + targetUrl.search,
        method: req.method,
        headers: req.headers
    };

    const proxyReq = http.request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res, { end: true });
    });

    proxyReq.on('error', (err) => {
        res.status(502).json({ error: 'Gateway Proxy Error', details: err.message });
    });

    if (req.body && Object.keys(req.body).length > 0) {
        proxyReq.write(JSON.stringify(req.body));
    }
    proxyReq.end();
}

app.use('/api/auth', (req, res) => proxyRequest(req, res, AUTH_URL));
app.use('/api/sales', (req, res) => proxyRequest(req, res, SALES_URL));

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', gateway: 'operational', timestamp: new Date() });
});

app.listen(PORT, () => console.log(`[API Gateway] Running and routing on port ${PORT}`));
EOF_GW_SRV

cat << 'EOF_GW_DOCKER' > gateway/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
EOF_GW_DOCKER

# 5. DASHBOARD UI (Tailwind CSS Cyberpunk Frontend)
cat << 'EOF_DASH_PKG' > dashboard/package.json
{
  "name": "eb-enterprise-dashboard",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5"
  }
}
EOF_DASH_PKG

cat << 'EOF_DASH_SRV' > dashboard/server.js
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[Dashboard] Operational at http://localhost:${PORT}`));
EOF_DASH_SRV

cat << 'EOF_DASH_HTML' > dashboard/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprise Suite | Command Center</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'JetBrains Mono', monospace; background-color: #0b0f19; color: #f3f4f6; }
        .neon-glow { text-shadow: 0 0 12px rgba(59, 130, 246, 0.6); }
        .border-neon { border-color: rgba(59, 130, 246, 0.4); }
    </style>
</head>
<body class="min-h-screen p-6">
    <header class="max-w-7xl mx-auto flex justify-between items-center pb-6 border-b border-gray-800">
        <div>
            <h1 class="text-2xl font-extrabold text-blue-400 neon-glow">EB ENTERPRISE SUITE</h1>
            <p class="text-xs text-gray-400">Microservice Architecture & Gateway Dashboard</p>
        </div>
        <div id="auth-status" class="px-4 py-1.5 bg-red-950 border border-red-800 text-red-400 text-xs rounded-full font-semibold">
            UNAUTHENTICATED
        </div>
    </header>

    <main class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
        <!-- Auth Card -->
        <div class="bg-gray-900 border border-neon rounded-xl p-6 shadow-xl">
            <h2 class="text-lg font-bold text-blue-300 mb-4">🔐 Auth Terminal</h2>
            <div id="login-form" class="space-y-4">
                <input id="username" type="text" placeholder="Username (admin)" value="admin" class="w-full bg-gray-950 border border-gray-700 rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500">
                <input id="password" type="password" placeholder="Password (admin)" value="admin" class="w-full bg-gray-950 border border-gray-700 rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500">
                <button onclick="login()" class="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-2 rounded text-sm transition">Authenticate</button>
            </div>
            <div id="user-info" class="hidden space-y-3">
                <p class="text-xs text-green-400 font-semibold">Session Active: <span id="logged-user" class="text-white"></span></p>
                <button onclick="logout()" class="w-full bg-red-700 hover:bg-red-600 text-white font-bold py-2 rounded text-sm transition">Destroy Session</button>
            </div>
        </div>

        <!-- Sales Management -->
        <div class="lg:col-span-2 bg-gray-900 border border-neon rounded-xl p-6 shadow-xl flex flex-col justify-between">
            <div>
                <h2 class="text-lg font-bold text-blue-300 mb-4">📊 Sales Microservice (SQLite)</h2>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-4">
                    <input id="sale-item" type="text" placeholder="Item Name" class="bg-gray-950 border border-gray-700 rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500">
                    <input id="sale-amount" type="number" placeholder="Amount ($)" class="bg-gray-950 border border-gray-700 rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500">
                    <input id="sale-buyer" type="text" placeholder="Buyer Name" class="bg-gray-950 border border-gray-700 rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500">
                </div>
                <button onclick="addSale()" class="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-2 rounded text-sm transition mb-6">Record New Sale</button>
                
                <div class="overflow-x-auto max-h-64 overflow-y-auto border border-gray-800 rounded">
                    <table class="w-full text-left text-xs">
                        <thead class="bg-gray-950 text-gray-400 uppercase">
                            <tr>
                                <th class="p-3">ID</th>
                                <th class="p-3">Item</th>
                                <th class="p-3">Amount</th>
                                <th class="p-3">Buyer</th>
                                <th class="p-3">Timestamp</th>
                            </tr>
                        </thead>
                        <tbody id="sales-table" class="divide-y divide-gray-800 text-gray-300">
                            <!-- Populated dynamically -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <script>
        let token = localStorage.getItem('eb_token') || null;

        function updateAuthUI() {
            const badge = document.getElementById('auth-status');
            const form = document.getElementById('login-form');
            const info = document.getElementById('user-info');
            if (token) {
                badge.className = 'px-4 py-1.5 bg-emerald-950 border border-emerald-800 text-emerald-400 text-xs rounded-full font-semibold';
                badge.innerText = 'AUTHENTICATED (JWT)';
                form.classList.add('hidden');
                info.classList.remove('hidden');
                fetchSales();
            } else {
                badge.className = 'px-4 py-1.5 bg-red-950 border border-red-800 text-red-400 text-xs rounded-full font-semibold';
                badge.innerText = 'UNAUTHENTICATED';
                form.classList.remove('hidden');
                info.classList.add('hidden');
            }
        }

        async function login() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            try {
                const res = await fetch('http://localhost:8080/api/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                const data = await res.json();
                if (data.success) {
                    token = data.token;
                    localStorage.setItem('eb_token', token);
                    document.getElementById('logged-user').innerText = data.user.username;
                    updateAuthUI();
                } else {
                    alert('Authentication failed: ' + data.error);
                }
            } catch (err) {
                alert('Gateway connection error: Ensure services are running on port 8080');
            }
        }

        function logout() {
            token = null;
            localStorage.removeItem('eb_token');
            updateAuthUI();
        }

        async function fetchSales() {
            try {
                const res = await fetch('http://localhost:8080/api/sales');
                const data = await res.json();
                if (data.success) {
                    const tbody = document.getElementById('sales-table');
                    tbody.innerHTML = data.data.map(s => \`
                        <tr class="hover:bg-gray-800/50">
                            <td class="p-3">\${s.id}</td>
                            <td class="p-3 font-semibold text-white">\${s.item}</td>
                            <td class="p-3 text-emerald-400">$\${s.amount.toFixed(2)}</td>
                            <td class="p-3">\${s.buyer}</td>
                            <td class="p-3 text-gray-500">\${new Date(s.created_at).toLocaleString()}</td>
                        </tr>
                    \`).join('');
                }
            } catch (err) {
                console.error('Failed to load sales', err);
            }
        }

        async function addSale() {
            const item = document.getElementById('sale-item').value;
            const amount = parseFloat(document.getElementById('sale-amount').value);
            const buyer = document.getElementById('sale-buyer').value;
            if (!item || isNaN(amount) || !buyer) return alert('Please fill in all sale details.');

            try {
                const res = await fetch('http://localhost:8080/api/sales', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ item, amount, buyer })
                });
                const data = await res.json();
                if (data.success) {
                    document.getElementById('sale-item').value = '';
                    document.getElementById('sale-amount').value = '';
                    document.getElementById('sale-buyer').value = '';
                    fetchSales();
                }
            } catch (err) {
                alert('Failed to record sale via Gateway.');
            }
        }

        updateAuthUI();
        if(token) fetchSales();
    </script>
</body>
</html>
EOF_DASH_HTML

cat << 'EOF_DASH_DOCKER' > dashboard/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF_DASH_DOCKER

echo "=== Workspace generation complete! ==="
echo "To boot the entire stack with Docker Compose:"
echo "  cd eb-enterprise-suite && docker-compose up --build"
