#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Full-Stack Rebuild & Live Launch
# ==============================================================================
set -e

PROJECT_DIR="eb-sales-tracker"
PORT=8080

echo "[+] Initializing clean directory build sequence: $PROJECT_DIR"
rm -rf "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/public"
mkdir -p "$PROJECT_DIR/data"
cd "$PROJECT_DIR"

echo "[+] Writing server environment configuration..."
cat << 'ENV_EOF' > .env
PORT=8080
API_KEY=proprietary_key_placeholder
ENV_EOF

echo "[+] Writing zero-dependency server logic (server.js)..."
cat << 'JS_EOF' > server.js
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const DATA_FILE = path.join(__dirname, 'data', 'sales.json');

if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([]));
}

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.url === '/api/sales') {
        if (req.method === 'GET') {
            fs.readFile(DATA_FILE, (err, data) => {
                if (err) {
                    res.writeHead(500);
                    return res.end(JSON.stringify({ error: 'Database error' }));
                }
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(data);
            });
            return;
        }

        if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => body += chunk.toString());
            req.on('end', () => {
                const newSale = JSON.parse(body);
                const sales = JSON.parse(fs.readFileSync(DATA_FILE));
                newSale.id = Date.now();
                sales.push(newSale);
                fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(newSale));
            });
            return;
        }
    }

    if (req.method === 'DELETE' && req.url.startsWith('/api/sales/')) {
        const id = parseInt(req.url.split('/').pop());
        let sales = JSON.parse(fs.readFileSync(DATA_FILE));
        sales = sales.filter(s => s.id !== id);
        fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
        res.writeHead(200);
        res.end(JSON.stringify({ success: true }));
        return;
    }

    let filePath = path.join(__dirname, 'public', req.url === '/' ? 'index.html' : req.url);
    const extname = path.extname(filePath);
    let contentType = 'text/html';

    switch (extname) {
        case '.js': contentType = 'text/javascript'; break;
        case '.css': contentType = 'text/css'; break;
        case '.json': contentType = 'application/json'; break;
    }

    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404);
            res.end('Asset not found.');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, () => {
    console.log(`\n[EB ENTERPRISES] Proprietary Node Server Active`);
    console.log(`[STATUS] Listening on http://localhost:${PORT}`);
});
JS_EOF

echo "[+] Writing Executive Spectrum user interface (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises | Sales Logistics</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">EB</div>
            <h1>Sales Logistics Terminal</h1>
            <p>Proprietary weight, customer, and revenue tracking system</p>
        </header>

        <section class="dashboard">
            <div class="card">
                <h3>Total Revenue</h3>
                <p id="totalRevenue" class="gold-text">$0.00</p>
            </div>
            <div class="card">
                <h3>Total Mass (g)</h3>
                <p id="totalWeight" class="teal-text">0.00 g</p>
            </div>
            <div class="card">
                <h3>Transaction Count</h3>
                <p id="totalSales">0</p>
            </div>
        </section>

        <section class="form-section">
            <h2>Process Transaction</h2>
            <form id="salesForm">
                <div class="form-grid">
                    <div class="form-group">
                        <label>Customer Name</label>
                        <input type="text" id="customerName" required autocomplete="off" placeholder="e.g. John Doe">
                    </div>
                    <div class="form-group">
                        <label>Asset Description</label>
                        <input type="text" id="itemName" required autocomplete="off" placeholder="e.g. Product A">
                    </div>
                    <div class="form-group">
                        <label>Unit Value ($)</label>
                        <input type="number" id="unitPrice" step="0.01" min="0" required placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label>Quantity</label>
                        <input type="number" id="quantity" min="1" value="1" required>
                    </div>
                    <div class="form-group">
                        <label>Mass Per Unit (Grams)</label>
                        <input type="number" id="weightGrams" step="0.01" min="0" required placeholder="0.00">
                    </div>
                </div>
                <button type="submit" class="btn-submit">EXECUTE LOG</button>
            </form>
        </section>

        <section class="table-section">
            <h2>Ledger</h2>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Timestamp</th>
                            <th>Customer</th>
                            <th>Asset</th>
                            <th>Unit $</th>
                            <th>Qty</th>
                            <th>Mass (g)</th>
                            <th>Total Mass</th>
                            <th>Total Val</th>
                            <th>Terminate</th>
                        </tr>
                    </thead>
                    <tbody id="salesTableBody"></tbody>
                </table>
            </div>
        </section>
    </div>
    <script src="app.js"></script>
</body>
</html>
HTML_EOF

echo "[+] Writing Executive Spectrum styling (public/styles.css)..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #0b0c10;
    --dark-grey: #1f2833;
    --deep-teal: #005f73;
    --teal-glow: #0a9396;
    --champagne-gold: #e5c158;
    --gold-dim: #c5a343;
    --text-main: #e2e8f0;
    --danger: #9e2a2b;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Courier New', Courier, monospace; }

body {
    background-color: var(--obsidian);
    color: var(--text-main);
    padding: 20px;
}

.container { max-width: 1100px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 30px; border-bottom: 1px solid var(--deep-teal); padding-bottom: 20px;
}

.logo {
    display: inline-block; width: 50px; height: 50px; line-height: 50px;
    background: var(--deep-teal); color: var(--champagne-gold);
    font-weight: bold; font-size: 1.5rem; border-radius: 4px; margin-bottom: 10px;
}

h1 { color: var(--champagne-gold); font-size: 1.8rem; letter-spacing: 2px; text-transform: uppercase; }
header p { color: var(--teal-glow); font-size: 0.9rem; }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
.card { background: var(--dark-grey); padding: 20px; border: 1px solid var(--deep-teal); border-radius: 4px; border-left: 4px solid var(--champagne-gold); }
.card h3 { color: #8b949e; font-size: 0.8rem; text-transform: uppercase; margin-bottom: 10px; }
.card p { font-size: 1.6rem; font-weight: bold; }

.gold-text { color: var(--champagne-gold); }
.teal-text { color: var(--teal-glow); }

.form-section, .table-section { background: var(--dark-grey); padding: 25px; border: 1px solid var(--deep-teal); margin-bottom: 30px; border-radius: 4px; }
h2 { color: var(--champagne-gold); margin-bottom: 20px; font-size: 1.2rem; text-transform: uppercase; }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.8rem; margin-bottom: 5px; color: var(--teal-glow); text-transform: uppercase; }
.form-group input { padding: 10px; background: var(--obsidian); border: 1px solid var(--deep-teal); color: var(--champagne-gold); font-size: 1rem; }
.form-group input:focus { outline: none; border-color: var(--champagne-gold); box-shadow: 0 0 5px var(--champagne-gold); }

.btn-submit { width: 100%; padding: 15px; background: var(--deep-teal); color: var(--champagne-gold); border: 1px solid var(--champagne-gold); font-weight: bold; font-size: 1rem; cursor: pointer; text-transform: uppercase; transition: 0.3s; }
.btn-submit:hover { background: var(--champagne-gold); color: var(--obsidian); }

.table-wrapper { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 12px; border-bottom: 1px solid var(--deep-teal); }
th { color: var(--teal-glow); text-transform: uppercase; font-size: 0.85rem; }
td { font-size: 0.95rem; }

.btn-delete { background: none; border: 1px solid var(--danger); color: var(--danger); padding: 5px 10px; cursor: pointer; transition: 0.2s; }
.btn-delete:hover { background: var(--danger); color: var(--text-main); }
CSS_EOF

echo "[+] Writing bridging logic (public/app.js)..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const salesTableBody = document.getElementById('salesTableBody');

const totalRevenueEl = document.getElementById('totalRevenue');
const totalWeightEl = document.getElementById('totalWeight');
const totalSalesEl = document.getElementById('totalSales');

document.addEventListener('DOMContentLoaded', fetchAndRender);

async function fetchAndRender() {
    try {
        const res = await fetch(API_URL);
        const sales = await res.json();
        render(sales);
    } catch (err) {
        console.error("API Failure:", err);
    }
}

salesForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = {
        date: new Date().toISOString().replace('T', ' ').substring(0, 19),
        customer: customerNameInput.value.trim(),
        name: itemNameInput.value.trim(),
        price: parseFloat(unitPriceInput.value),
        quantity: parseInt(quantityInput.value, 10),
        weightGrams: parseFloat(weightGramsInput.value)
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    salesForm.reset();
    quantityInput.value = '1';
    fetchAndRender();
});

async function deleteEntry(id) {
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRender();
}

function render(sales) {
    salesTableBody.innerHTML = '';
    let grandRevenue = 0, grandWeight = 0;

    if (sales.length === 0) {
        salesTableBody.innerHTML = `
            <tr>
                <td colspan="9" style="text-align: center; color: #8b949e; padding: 20px;">
                    No transactions recorded.
                </td>
            </tr>
        `;
    } else {
        sales.forEach(sale => {
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;
            grandRevenue += rowTotalPrice;
            grandWeight += rowTotalWeight;

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${sale.date}</td>
                <td><strong class="gold-text">${escapeHtml(sale.customer || 'N/A')}</strong></td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td>$${sale.price.toFixed(2)}</td>
                <td>${sale.quantity}</td>
                <td>${sale.weightGrams.toFixed(2)}</td>
                <td class="teal-text">${rowTotalWeight.toFixed(2)} g</td>
                <td class="gold-text">$${rowTotalPrice.toFixed(2)}</td>
                <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
            `;
            salesTableBody.appendChild(tr);
        });
    }

    totalRevenueEl.textContent = `$${grandRevenue.toFixed(2)}`;
    totalWeightEl.textContent = `${grandWeight.toFixed(2)} g`;
    totalSalesEl.textContent = sales.length;
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
JS_EOF

echo "[+] Rebuild complete. Launching EB Enterprises Server..."
node server.js
