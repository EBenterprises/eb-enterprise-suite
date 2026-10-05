node "$REPO_DIR/v4/pin_picker_server.js" &
V4_PID=$!

echo "[*] Starting v5 Standalone Server (Port $V5_PORT)..."
node "$REPO_DIR/v5_server.js" &
V5_PID=$!

echo ""
echo "Cluster Status:"
echo "----------------------------------------"
echo "  v4 Pin Picker UI : http://localhost:$V4_PORT"
echo "  v5 Core API      : http://localhost:$V5_PORT"
echo "----------------------------------------"
echo "Press Ctrl+C to terminate cluster processes."

wait $V4_PID$V5_PID
EOF

chmod +x ~/sales-tracker/start_pin_picker_cluster.sh
~/sales-tracker/start_pin_picker_cluster.sh
cat << 'EOF' > ~/sales-tracker/run_cluster.sh
#!/bin/bash
# Sales Tracker - Automated Cluster Fix & Unified Launcher

REPO_DIR="$HOME/sales-tracker"
V4_PORT=51204
V5_PORT=51205

echo "[*] Terminating existing Node processes on ports $V4_PORT and$V5_PORT..."
fuser -k ${V4_PORT}/tcp${V5_PORT}/tcp 2>/dev/null || pkill -f "node.*sales-tracker" 2>/dev/null
sleep 1

mkdir -p "$REPO_DIR/v4" "$REPO_DIR/v5"
cd "$REPO_DIR" || exit 1

# Ensure unified v5 dataset is active
if [ -f "$REPO_DIR/transactions.json" ] && [ ! -f "$REPO_DIR/v5/transactions.json" ]; then
    cp "$REPO_DIR/transactions.json" "$REPO_DIR/v5/transactions.json"
fi

# Build Pin Picker v4 Server (Port 51204)
cat << 'NODE_EOF' > "$REPO_DIR/v4/pin_picker_server.js"
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51204;
const DATA_FILE = path.join(__dirname, '..', 'v5', 'transactions.json');

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sales Tracker v4 - Pin Picker</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { margin: 0; font-family: monospace; background: #0d1117; color: #c9d1d9; display: flex; flex-direction: column; height: 100vh; }
        header { padding: 10px 15px; background: #161b22; border-bottom: 1px solid #30363d; display: flex; justify-content: space-between; align-items: center; }
        #main { display: flex; flex: 1; overflow: hidden; }
        #map { flex: 2; height: 100%; background: #222; }
        #panel { flex: 1; min-width: 320px; max-width: 420px; background: #161b22; border-left: 1px solid #30363d; padding: 15px; overflow-y: auto; }
        .card { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: 10px; margin-bottom: 10px; }
        .card h4 { margin: 0 0 5px 0; color: #58a6ff; }
        .balance { color: #f85149; font-weight: bold; }
        .paid { color: #3fb950; font-weight: bold; }
        input, button { width: 100%; padding: 8px; margin: 4px 0; background: #21262d; border: 1px solid #30363d; color: #fff; border-radius: 4px; box-sizing: border-box; }
        button { background: #238636; font-weight: bold; cursor: pointer; border: none; margin-top: 8px; }
        button:hover { background: #2ea043; }
    </style>
</head>
<body>
    <header>
        <div><strong>SALES TRACKER v4</strong> [GPS Pin Picker]</div>
        <div>Port: 51204</div>
    </header>
    <div id="main">
        <div id="map"></div>
        <div id="panel">
            <h3>New Transaction with Pin</h3>
            <div class="card">
                <input type="text" id="customer" placeholder="Customer Name">
                <input type="text" id="item" placeholder="Item (e.g. 3.5g Unit)">
                <input type="number" id="total" placeholder="Total Amount ($)">
                <input type="number" id="paid" placeholder="Cash Paid ($)">
                <input type="text" id="location" placeholder="Location Name / Landmark">
                <input type="text" id="coords" placeholder="Lat, Lng (Click map to set)" readonly>
                <button onclick="saveTransaction()">Save Transaction</button>
            </div>
            <h3>Active Ledger</h3>
            <div id="ledger">Loading...</div>
        </div>
    </div>
    <script>
        const map = L.map('map').setView([49.8353, -119.6050], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        let selectedMarker = null;

        map.on('click', function(e) {
            const lat = e.latlng.lat.toFixed(6);
            const lng = e.latlng.lng.toFixed(6);
            document.getElementById('coords').value = `${lat},${lng}`;
            if (selectedMarker) map.removeLayer(selectedMarker);
            selectedMarker = L.marker([lat, lng]).addTo(map).bindPopup("Selected Location").openPopup();
        });

        async function loadTransactions() {
            try {
                const res = await fetch('/api/transactions');
                const data = await res.json();
                const container = document.getElementById('ledger');
                container.innerHTML = '';

                data.forEach(tx => {
                    const el = document.createElement('div');
                    el.className = 'card';
                    const total = tx.total !== undefined ? tx.total : (tx.amount || 0);
                    const paid = tx.paid !== undefined ? tx.paid : (tx.cashCollected || 0);
                    const bal = tx.balance !== undefined ? tx.balance : (total - paid);
                    const loc = tx.location || tx.landmark || 'N/A';

                    el.innerHTML = `
                        <h4>${tx.customer \vert{}\vert{} 'Unknown'} -${tx.item || 'Item'}</h4>
                        <div><strong>Loc:</strong> ${loc}</div>
                        <div><strong>Total:</strong> $${total} \vert{} <strong>Paid:</strong>$${paid}</div>
                        <div><strong>Balance:</strong> <span class="${bal > 0 ? 'balance' : 'paid'}">$${bal}</span></div>
                    `;
                    container.appendChild(el);

                    let lat = tx.lat, lng = tx.lng;
                    if (!lat && tx.gps) {
                        const parts = tx.gps.split(',');
                        if (parts.length === 2) {
                            lat = parseFloat(parts[0].trim());
                            lng = parseFloat(parts[1].trim());
                        }
                    }

                    if (lat && lng) {
                        L.marker([lat, lng]).addTo(map)
                            .bindPopup(`<b>${tx.customer}</b><br>${loc}<br>Balance:$${bal}`);
                    }
                });
            } catch (e) {
                console.error("Failed to load transactions", e);
            }
        }

        async function saveTransaction() {
            const customer = document.getElementById('customer').value;
            const item = document.getElementById('item').value;
            const total = parseFloat(document.getElementById('total').value) || 0;
            const paid = parseFloat(document.getElementById('paid').value) || 0;
            const location = document.getElementById('location').value;
            const coords = document.getElementById('coords').value.split(',');

            if (!customer || !location) return alert("Customer and Location required");

            const payload = {
                timestamp: Date.now(),
                date: new Date().toISOString().replace('T', ' ').substring(0, 16),
                customer, item, total, paid, amount: total, cashCollected: paid, balance: total - paid,
                location, landmark: location,
                lat: coords[0] ? parseFloat(coords[0]) : null,
                lng: coords[1] ? parseFloat(coords[1]) : null,
                gps: coords[0] && coords[1] ? `${coords[0].trim()},${coords[1].trim()}` : null
            };

            await fetch('/api/transactions', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            loadTransactions();
        }

        loadTransactions();
    </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.url === '/' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(htmlContent);
    } else if (req.url === '/api/transactions' && req.method === 'GET') {
        fs.readFile(DATA_FILE, 'utf8', (err, data) => {
            if (err) return res.end('[]');
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(data);
        });
    } else if (req.url === '/api/transactions' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const tx = JSON.parse(body);
                fs.readFile(DATA_FILE, 'utf8', (err, data) => {
                    let txs = err ? [] : JSON.parse(data);
                    tx.id = txs.length ? (txs[txs.length - 1].id || 0) + 1 : 1;
                    txs.push(tx);
                    fs.writeFile(DATA_FILE, JSON.stringify(txs, null, 2), () => {
                        res.writeHead(201, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify(tx));
                    });
                });
            } catch (e) {
                res.writeHead(400);
                res.end('Bad Request');
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    console.log(`[+] v4 Pin Picker UI active on http://localhost:${PORT}`);
});
NODE_EOF

# Launch Node instances
node "$REPO_DIR/v4/pin_picker_server.js" &
V4_PID=$!

node "$REPO_DIR/v5_server.js" &
V5_PID=$!

echo "=========================================="
echo "   SALES TRACKER CLUSTER ONLINE          "
echo "=========================================="
echo "  v4 Pin Picker UI : http://localhost:$V4_PORT"
echo "  v5 Core API      : http://localhost:$V5_PORT"
echo "=========================================="

trap "kill $V4_PID$V5_PID 2>/dev/null; exit" INT TERM
wait $V4_PID$V5_PID
EOF

chmod +x ~/sales-tracker/run_cluster.sh
~/sales-tracker/run_cluster.sh
cat << 'EOF' > ~/sales-tracker/run_cluster.sh
#!/bin/bash
# Sales Tracker - Automated Cluster Fix & Unified Launcher

REPO_DIR="$HOME/sales-tracker"
V4_PORT=51204
V5_PORT=51205

echo "[*] Cleaning up orphaned processes on ports $V4_PORT and$V5_PORT..."
fuser -k ${V4_PORT}/tcp${V5_PORT}/tcp 2>/dev/null || pkill -f "node.*sales-tracker" 2>/dev/null
sleep 1

mkdir -p "$REPO_DIR/v4" "$REPO_DIR/v5"
cd "$REPO_DIR" || exit 1

# Ensure unified v5 dataset exists
if [ ! -f "$REPO_DIR/v5/transactions.json" ]; then
    if [ -f "$REPO_DIR/transactions.json" ]; then
        cp "$REPO_DIR/transactions.json" "$REPO_DIR/v5/transactions.json"
    else
        echo "[]" > "$REPO_DIR/v5/transactions.json"
    fi
fi

# Build Pin Picker v4 Server (Port 51204)
cat << 'NODE_EOF' > "$REPO_DIR/v4/pin_picker_server.js"
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51204;
const DATA_FILE = path.join(__dirname, '..', 'v5', 'transactions.json');

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sales Tracker v4 - Pin Picker</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        body { margin: 0; font-family: monospace; background: #0d1117; color: #c9d1d9; display: flex; flex-direction: column; height: 100vh; }
        header { padding: 10px 15px; background: #161b22; border-bottom: 1px solid #30363d; display: flex; justify-content: space-between; align-items: center; }
        #main { display: flex; flex: 1; overflow: hidden; }
        #map { flex: 2; height: 100%; background: #222; }
        #panel { flex: 1; min-width: 320px; max-width: 420px; background: #161b22; border-left: 1px solid #30363d; padding: 15px; overflow-y: auto; }
        .card { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: 10px; margin-bottom: 10px; }
        .card h4 { margin: 0 0 5px 0; color: #58a6ff; }
        .balance { color: #f85149; font-weight: bold; }
        .paid { color: #3fb950; font-weight: bold; }
        input, button { width: 100%; padding: 8px; margin: 4px 0; background: #21262d; border: 1px solid #30363d; color: #fff; border-radius: 4px; box-sizing: border-box; }
        button { background: #238636; font-weight: bold; cursor: pointer; border: none; margin-top: 8px; }
        button:hover { background: #2ea043; }
    </style>
</head>
<body>
    <header>
        <div><strong>SALES TRACKER v4</strong> [GPS Pin Picker]</div>
        <div>Port: 51204</div>
    </header>
    <div id="main">
        <div id="map"></div>
        <div id="panel">
            <h3>New Transaction with Pin</h3>
            <div class="card">
                <input type="text" id="customer" placeholder="Customer Name">
                <input type="text" id="item" placeholder="Item (e.g. 3.5g Unit)">
                <input type="number" id="total" placeholder="Total Amount ($)">
                <input type="number" id="paid" placeholder="Cash Paid ($)">
                <input type="text" id="location" placeholder="Location Name / Landmark">
                <input type="text" id="coords" placeholder="Lat, Lng (Click map to set)" readonly>
                <button onclick="saveTransaction()">Save Transaction</button>
            </div>
            <h3>Active Ledger</h3>
            <div id="ledger">Loading...</div>
        </div>
    </div>
    <script>
        const map = L.map('map').setView([49.8353, -119.6050], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        let selectedMarker = null;

        map.on('click', function(e) {
            const lat = e.latlng.lat.toFixed(6);
            const lng = e.latlng.lng.toFixed(6);
            document.getElementById('coords').value = lat + ', ' + lng;
            if (selectedMarker) map.removeLayer(selectedMarker);
            selectedMarker = L.marker([lat, lng]).addTo(map).bindPopup("Selected Location").openPopup();
        });

        async function loadTransactions() {
            try {
                const res = await fetch('/api/transactions');
                const data = await res.json();
                const container = document.getElementById('ledger');
                container.innerHTML = '';

                data.forEach(tx => {
                    const el = document.createElement('div');
                    el.className = 'card';
                    const total = tx.total !== undefined ? tx.total : (tx.amount || 0);
                    const paid = tx.paid !== undefined ? tx.paid : (tx.cashCollected || 0);
                    const bal = tx.balance !== undefined ? tx.balance : (total - paid);
                    const loc = tx.location || tx.landmark || 'N/A';

                    el.innerHTML = \`
                        <h4>\${tx.customer || 'Unknown'} - \${tx.item || 'Item'}</h4>
                        <div><strong>Loc:</strong> \${loc}</div>
                        <div><strong>Total:</strong> $\${total} \vert{} <strong>Paid:</strong>$\${paid}</div>
                        <div><strong>Balance:</strong> <span class="\${bal > 0 ? 'balance' : 'paid'}">$\${bal}</span></div>
                    \`;
                    container.appendChild(el);

                    let lat = tx.lat, lng = tx.lng;
                    if (!lat && tx.gps) {
                        const parts = tx.gps.split(',');
                        if (parts.length === 2) {
                            lat = parseFloat(parts[0].trim());
                            lng = parseFloat(parts[1].trim());
                        }
                    }

                    if (lat && lng) {
                        L.marker([lat, lng]).addTo(map)
                            .bindPopup(\`<b>\${tx.customer}</b><br>\${loc}<br>Balance: $\${bal}\`);
                    }
                });
            } catch (e) {
                console.error("Failed to load transactions", e);
            }
        }

        async function saveTransaction() {
            const customer = document.getElementById('customer').value;
            const item = document.getElementById('item').value;
            const total = parseFloat(document.getElementById('total').value) || 0;
            const paid = parseFloat(document.getElementById('paid').value) || 0;
            const location = document.getElementById('location').value;
            const coords = document.getElementById('coords').value.split(',');

            if (!customer || !location) return alert("Customer and Location required");

            const payload = {
                timestamp: Date.now(),
                date: new Date().toISOString().replace('T', ' ').substring(0, 16),
                customer, item, total, paid, amount: total, cashCollected: paid, balance: total - paid,
                location, landmark: location,
                lat: coords[0] ? parseFloat(coords[0]) : null,
                lng: coords[1] ? parseFloat(coords[1]) : null,
                gps: coords[0] && coords[1] ? coords[0].trim() + ', ' + coords[1].trim() : null
            };

            await fetch('/api/transactions', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            loadTransactions();
        }

        loadTransactions();
    </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.url === '/' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(htmlContent);
    } else if (req.url === '/api/transactions' && req.method === 'GET') {
        fs.readFile(DATA_FILE, 'utf8', (err, data) => {
            if (err) return res.end('[]');
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(data);
        });
    } else if (req.url === '/api/transactions' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const tx = JSON.parse(body);
                fs.readFile(DATA_FILE, 'utf8', (err, data) => {
                    let txs = err ? [] : JSON.parse(data);
                    tx.id = txs.length ? (txs[txs.length - 1].id || 0) + 1 : 1;
                    txs.push(tx);
                    fs.writeFile(DATA_FILE, JSON.stringify(txs, null, 2), () => {
                        res.writeHead(201, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify(tx));
                    });
                });
            } catch (e) {
                res.writeHead(400);
                res.end('Bad Request');
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    console.log(`[+] v4 Pin Picker UI active on http://localhost:${PORT}`);
});
NODE_EOF

# Launch Node instances
node "$REPO_DIR/v4/pin_picker_server.js" &
V4_PID=$!

if [ -f "$REPO_DIR/v5_server.js" ]; then
    node "$REPO_DIR/v5_server.js" &
    V5_PID=$!
fi

echo "=========================================="
echo "   SALES TRACKER CLUSTER ONLINE          "
echo "=========================================="
echo "  v4 Pin Picker UI : http://localhost:$V4_PORT"
echo "  v5 Core API      : http://localhost:$V5_PORT"
echo "=========================================="

trap "kill $V4_PID$V5_PID 2>/dev/null; exit" INT TERM
wait $V4_PID$V5_PID
EOF

chmod +x ~/sales-tracker/run_cluster.sh
~/sales-tracker/run_cluster.sh
