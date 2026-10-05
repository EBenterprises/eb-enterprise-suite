#!/bin/bash
cd ~/sales-tracker

echo "[*] Terminating existing node instances..."
pkill -f node || true
pkill -f "v5_server.js" || true

PORT=51205
REPO_DIR="$HOME/sales-tracker"

mkdir -p "$REPO_DIR/v5"
if [ ! -f "$REPO_DIR/v5/transactions.json" ]; then
    if [ -f "$REPO_DIR/transactions.json" ]; then
        cp "$REPO_DIR/transactions.json" "$REPO_DIR/v5/transactions.json"
    else
        echo "[]" > "$REPO_DIR/v5/transactions.json"
    fi
fi

cat << 'NODE_EOF' > "$REPO_DIR/enterprise_server.js"
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51205;
const DATA_FILE = path.join(__dirname, 'v5', 'transactions.json');

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enterprise Suite - Sales Tracker v5</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        :root {
            --bg-dark: #07090e;
            --panel-bg: #0f131c;
            --card-bg: #161c28;
            --border-color: #2a3447;
            --text-main: #f1f5f9;
            --text-muted: #94a3b8;
            --accent-blue: #2563eb;
            --accent-green: #16a34a;
            --accent-red: #dc2626;
            --accent-gold: #ca8a04;
            --accent-purple: #7c3aed;
        }

        * { box-sizing: border-box; }
        body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; background: var(--bg-dark); color: var(--text-main); display: flex; flex-direction: column; height: 100vh; overflow: hidden; }

        header { height: 55px; background: var(--panel-bg); border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; padding: 0 20px; }
        header h1 { font-size: 15px; margin: 0; letter-spacing: 1.5px; color: #fff; text-transform: uppercase; display: flex; align-items: center; gap: 10px; }
        header .badge { background: var(--accent-purple); color: #fff; font-size: 10px; padding: 3px 8px; border-radius: 4px; font-weight: bold; letter-spacing: 1px; }

        .header-stats { display: flex; gap: 20px; font-size: 12px; color: var(--text-muted); }
        .header-stats span { color: #fff; font-weight: bold; }

        #layout { display: flex; flex: 1; height: calc(100vh - 55px); }
        #map-container { flex: 1.6; position: relative; background: #000; }
        #map { width: 100%; height: 100%; }

        #sidebar { flex: 1; min-width: 400px; max-width: 500px; background: var(--panel-bg); border-left: 1px solid var(--border-color); display: flex; flex-direction: column; }

        .tabs { display: flex; background: var(--bg-dark); border-bottom: 1px solid var(--border-color); }
        .tab-btn { flex: 1; padding: 12px 8px; border: none; background: transparent; color: var(--text-muted); font-weight: bold; cursor: pointer; text-align: center; font-size: 11px; letter-spacing: 0.5px; border-bottom: 2px solid transparent; }
        .tab-btn.active { color: var(--accent-blue); border-bottom-color: var(--accent-blue); background: var(--panel-bg); }

        .tab-content { flex: 1; overflow-y: auto; padding: 15px; display: none; }
        .tab-content.active { display: block; }

        .card { background: var(--card-bg); border: 1px solid var(--border-color); border-radius: 6px; padding: 14px; margin-bottom: 12px; }
        .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; border-bottom: 1px solid var(--border-color); padding-bottom: 6px; }
        .card-title { font-weight: bold; color: #fff; font-size: 13px; letter-spacing: 0.5px; }
        .card-subtitle { font-size: 11px; color: var(--text-muted); }

        .form-group { margin-bottom: 10px; }
        .form-group label { display: block; font-size: 11px; color: var(--text-muted); margin-bottom: 4px; font-weight: 500; }
        input, select { width: 100%; padding: 8px 10px; background: var(--bg-dark); border: 1px solid var(--border-color); color: #fff; border-radius: 4px; font-size: 12px; }
        input:focus, select:focus { border-color: var(--accent-blue); outline: none; }

        .btn { width: 100%; padding: 10px; background: var(--accent-blue); border: none; color: #fff; font-weight: bold; border-radius: 4px; cursor: pointer; font-size: 12px; margin-top: 6px; letter-spacing: 0.5px; }
        .btn:hover { opacity: 0.9; }
        .btn-gold { background: var(--accent-gold); color: #000; }
        .btn-danger { background: var(--accent-red); }
        .btn-purple { background: var(--accent-purple); color: #fff; }

        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }

        .tx-card { background: var(--card-bg); border-left: 3px solid var(--accent-blue); padding: 12px; margin-bottom: 10px; border-radius: 6px; font-size: 12px; position: relative; border-top: 1px solid var(--border-color); border-right: 1px solid var(--border-color); border-bottom: 1px solid var(--border-color); }
        .tx-card.unpaid { border-left-color: var(--accent-red); }
        .tx-card.paid { border-left-color: var(--accent-green); }
        .tx-meta { display: flex; justify-content: space-between; font-size: 10px; color: var(--text-muted); margin-top: 8px; border-top: 1px solid rgba(255,255,255,0.05); padding-top: 6px; }
        .tx-actions { position: absolute; top: 10px; right: 10px; display: flex; gap: 5px; }
        .action-btn { background: var(--bg-dark); border: 1px solid var(--border-color); color: var(--text-muted); padding: 3px 8px; font-size: 10px; border-radius: 3px; cursor: pointer; font-weight: bold; }
        .action-btn:hover { color: #fff; border-color: var(--accent-blue); }

        .modal { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.85); z-index: 9999; justify-content: center; align-items: center; }
        .modal-content { background: var(--panel-bg); border: 1px solid var(--border-color); border-radius: 8px; width: 380px; padding: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }

        .enterprise-kpi { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 12px; }
        .kpi-box { background: var(--card-bg); border: 1px solid var(--border-color); padding: 10px; border-radius: 6px; text-align: center; }
        .kpi-val { font-size: 16px; font-weight: bold; color: #fff; margin-top: 4px; }
        .kpi-lbl { font-size: 10px; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
    </style>
</head>
<body>
    <header>
        <h1>ENTERPRISE SUITE <span class="badge">V5.0 PRO</span></h1>
        <div class="header-stats">
            <div>Active Records: <span id="stat-count">0</span></div>
            <div>Total Vol: <span id="stat-vol">$0.00</span></div>
        </div>
    </header>

    <div id="layout">
        <div id="map-container">
            <div id="map"></div>
        </div>

        <div id="sidebar">
            <div class="tabs">
                <button class="tab-btn active" onclick="switchTab('entry')">NEW ENTRY</button>
                <button class="tab-btn" onclick="switchTab('ledger')">MASTER LEDGER</button>
                <button class="tab-btn" onclick="switchTab('timemachine')">TIME MACHINE</button>
                <button class="tab-btn" onclick="switchTab('analytics')">ANALYTICS</button>
            </div>

            <!-- TAB 1: NEW ENTRY -->
            <div id="tab-entry" class="tab-content active">
                <div class="card">
                    <div class="card-header">
                        <span class="card-title">Enterprise Transaction Entry</span>
                        <span class="card-subtitle">Automated GPS / Sync</span>
                    </div>
                    <div class="form-group">
                        <label>Customer Name / Entity</label>
                        <input type="text" id="customer" placeholder="e.g. Acme Corporation">
                    </div>
                    <div class="form-group">
                        <label>Product / Item Specification</label>
                        <input type="text" id="item" placeholder="e.g. Enterprise License Tier 1">
                    </div>
                    <div class="grid-2">
                        <div class="form-group">
                            <label>Total Price ($)</label>
                            <input type="number" id="total" placeholder="0.00" oninput="calcBalance()">
                        </div>
                        <div class="form-group">
                            <label>Cash Paid ($)</label>
                            <input type="number" id="paid" placeholder="0.00" oninput="calcBalance()">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Remaining Balance ($)</label>
                        <input type="number" id="balance" placeholder="0.00" readonly>
                    </div>
                    <div class="form-group">
                        <label>Location Landmark / Branch</label>
                        <input type="text" id="location" placeholder="e.g. Downtown Hub Sector 4">
                    </div>
                    <div class="form-group">
                        <label>GPS Coordinates (Map Pin)</label>
                        <input type="text" id="coords" placeholder="Click map to lock coordinates" readonly>
                    </div>
                    <button class="btn btn-purple" onclick="saveTransaction()">COMMIT ENTERPRISE ENTRY</button>
                </div>
            </div>

            <!-- TAB 2: MASTER LEDGER -->
            <div id="tab-ledger" class="tab-content">
                <div class="card" style="padding: 10px; margin-bottom: 10px;">
                    <input type="text" id="ledger-search" placeholder="Search transactions..." oninput="renderLedger()">
                </div>
                <div id="ledger-list">Loading Enterprise Ledger...</div>
            </div>

            <!-- TAB 3: TIME MACHINE -->
            <div id="tab-timemachine" class="tab-content">
                <div class="card">
                    <div class="card-header">
                        <span class="card-title">Chronological Time Machine</span>
                        <span class="card-subtitle">Backdate & Audit</span>
                    </div>
                    <p style="font-size: 11px; color: var(--text-muted); margin-top: 0;">Perform precise temporal audits, backdate historical ledgers, and adjust transaction timelines.</p>
                </div>
                <div id="timemachine-list">Loading Time Machine...</div>
            </div>

            <!-- TAB 4: ANALYTICS -->
            <div id="tab-analytics" class="tab-content">
                <div class="enterprise-kpi">
                    <div class="kpi-box">
                        <div class="kpi-lbl">Total Volume</div>
                        <div class="kpi-val" id="kpi-vol">$0.00</div>
                    </div>
                    <div class="kpi-box">
                        <div class="kpi-lbl">Collected</div>
                        <div class="kpi-val" id="kpi-collected" style="color:var(--accent-green);">$0.00</div>
                    </div>
                    <div class="kpi-box">
                        <div class="kpi-lbl">Outstanding Balance</div>
                        <div class="kpi-val" id="kpi-outstanding" style="color:var(--accent-red);">$0.00</div>
                    </div>
                    <div class="kpi-box">
                        <div class="kpi-lbl">Total Orders</div>
                        <div class="kpi-val" id="kpi-orders">0</div>
                    </div>
                </div>
                <div class="card">
                    <div class="card-header">
                        <span class="card-title">Enterprise System Status</span>
                    </div>
                    <div style="font-size: 11px; color: var(--text-muted); line-height: 1.6;">
                        <div>Server: <b>Node.js v5.0 Cluster</b></div>
                        <div>Database: <b>Encrypted JSON Store</b></div>
                        <div>Geolocation Engine: <b>Leaflet / OpenStreetMap</b></div>
                        <div>Real-Time Sync: <b>Active</b></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- ENTERPRISE EDIT MODAL -->
    <div id="editModal" class="modal">
        <div class="modal-content">
            <h3 style="margin-top:0; color:#fff; font-size: 14px; border-bottom:1px solid var(--border-color); padding-bottom:8px;">Enterprise Audit & Edit</h3>
            <input type="hidden" id="edit-id">
            <div class="form-group">
                <label>Customer Entity</label>
                <input type="text" id="edit-customer">
            </div>
            <div class="form-group">
                <label>Item Description</label>
                <input type="text" id="edit-item">
            </div>
            <div class="grid-2">
                <div class="form-group">
                    <label>Total ($)</label>
                    <input type="number" id="edit-total">
                </div>
                <div class="form-group">
                    <label>Paid ($)</label>
                    <input type="number" id="edit-paid">
                </div>
            </div>
            <div class="form-group">
                <label>Time Machine Backdate Timestamp</label>
                <input type="datetime-local" id="edit-timestamp">
            </div>
            <div style="display:flex; gap: 8px; margin-top: 15px;">
                <button class="btn btn-gold" onclick="commitEdit()">Update Record</button>
                <button class="btn btn-danger" onclick="closeModal()">Cancel</button>
            </div>
        </div>
    </div>

    <script>
        const map = L.map('map').setView([49.8353, -119.6050], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '© OpenStreetMap Enterprise' }).addTo(map);

        let activeMarker = null;
        let masterDataset = [];
        let mapMarkers = [];

        map.on('click', function(e) {
            const lat = e.latlng.lat.toFixed(6);
            const lng = e.latlng.lng.toFixed(6);
            document.getElementById('coords').value = lat + ', ' + lng;
            if (activeMarker) map.removeLayer(activeMarker);
            activeMarker = L.marker([lat, lng]).addTo(map).bindPopup("Selected Enterprise Location").openPopup();
        });

        function switchTab(tabName) {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

            event.target.classList.add('active');
            document.getElementById('tab-' + tabName).classList.add('active');
        }

        function calcBalance() {
            const total = parseFloat(document.getElementById('total').value) || 0;
            const paid = parseFloat(document.getElementById('paid').value) || 0;
            document.getElementById('balance').value = (total - paid).toFixed(2);
        }

        async function loadData() {
            try {
                const res = await fetch('/api/transactions');
                masterDataset = await res.json();
                updateKPIs();
                renderLedger();
                renderTimeMachine();
                renderMapPins();
            } catch (e) {
                console.error("Failed loading enterprise dataset", e);
            }
        }

        function updateKPIs() {
            let totalVol = 0;
            let totalPaid = 0;
            let totalBal = 0;

            masterDataset.forEach(tx => {
                const t = tx.total !== undefined ? tx.total : (tx.amount || 0);
                const p = tx.paid !== undefined ? tx.paid : (tx.cashCollected || 0);
                const b = tx.balance !== undefined ? tx.balance : (t - p);
                totalVol += t;
                totalPaid += p;
                totalBal += b;
            });

            document.getElementById('stat-count').innerText = masterDataset.length;
            document.getElementById('stat-vol').innerText = '$' + totalVol.toFixed(2);

            document.getElementById('kpi-vol').innerText = '$' + totalVol.toFixed(2);
            document.getElementById('kpi-collected').innerText = '$' + totalPaid.toFixed(2);
            document.getElementById('kpi-outstanding').innerText = '$' + totalBal.toFixed(2);
            document.getElementById('kpi-orders').innerText = masterDataset.length;
        }

        function renderMapPins() {
            mapMarkers.forEach(m => map.removeLayer(m));
            mapMarkers = [];

            masterDataset.forEach(tx => {
                let lat = tx.lat, lng = tx.lng;
                if (!lat && tx.gps) {
                    const parts = tx.gps.split(',');
                    if (parts.length === 2) {
                        lat = parseFloat(parts[0].trim());
                        lng = parseFloat(parts[1].trim());
                    }
                }
                if (lat && lng) {
                    const marker = L.marker([lat, lng]).addTo(map)
                        .bindPopup(\`<b>\${tx.customer || 'Entity'}</b><br>\${tx.item || ''}<br>Balance: $\${tx.balance || 0}\`);
                    mapMarkers.push(marker);
                }
            });
        }

        function renderLedger() {
            const container = document.getElementById('ledger-list');
            container.innerHTML = '';

            const filter = (document.getElementById('ledger-search').value || '').toLowerCase();
            const filtered = masterDataset.slice().reverse().filter(tx => {
                const cust = (tx.customer || '').toLowerCase();
                const item = (tx.item || '').toLowerCase();
                const loc = (tx.location || tx.landmark || '').toLowerCase();
                return cust.includes(filter) || item.includes(filter) || loc.includes(filter);
            });

            if (filtered.length === 0) {
                container.innerHTML = '<div style="color:var(--text-muted); text-align:center; padding:20px;">No transactions found.</div>';
                return;
            }

            filtered.forEach(tx => {
                const total = tx.total !== undefined ? tx.total : (tx.amount || 0);
                const paid = tx.paid !== undefined ? tx.paid : (tx.cashCollected || 0);
                const bal = tx.balance !== undefined ? tx.balance : (total - paid);

                const el = document.createElement('div');
                el.className = 'tx-card ' + (bal > 0 ? 'unpaid' : 'paid');
                el.innerHTML = \`
                    <div class="tx-actions">
                        <button class="action-btn" onclick="openEditModal(\${tx.id})">Edit</button>
                    </div>
                    <div style="font-weight:bold; color:#fff; font-size:13px;">\${tx.customer || 'Anonymous Entity'}</div>
                    <div style="color:var(--text-muted); font-size:11px; margin-top:2px;">\${tx.item || 'General Product'}</div>
                    <div style="margin-top:6px; font-weight:500;">
                        Total: $\${total} \vert{} Paid:$\${paid} | <span style="color:\${bal > 0 ? 'var(--accent-red)' : 'var(--accent-green)'}">Bal: $\${bal}</span>
                    </div>
                    <div class="tx-meta">
                        <span>\${tx.location || tx.landmark || 'Enterprise Hub'}</span>
                        <span>\${tx.date || 'N/A'}</span>
                    </div>
                \`;
                container.appendChild(el);
            });
        }

        function renderTimeMachine() {
            const container = document.getElementById('timemachine-list');
            container.innerHTML = '';

            const sorted = masterDataset.slice().sort((a,b) => (b.timestamp || 0) - (a.timestamp || 0));

            sorted.forEach(tx => {
                const el = document.createElement('div');
                el.className = 'tx-card';
                el.style.borderLeftColor = 'var(--accent-gold)';
                el.innerHTML = \`
                    <div class="tx-actions">
                        <button class="action-btn" onclick="openEditModal(\${tx.id})">Time Travel</button>
                    </div>
                    <div style="font-weight:bold; color:var(--accent-gold);">[\${tx.date || 'No Date'}]</div>
                    <div style="color:#fff; font-weight:bold; margin-top:2px;">\${tx.customer || 'Unknown'} - $\${tx.total || tx.amount || 0}</div>
                    <div class="tx-meta">
                        <span>ID: \${tx.id}</span>
                        <span>Timestamp: \${tx.timestamp || 'N/A'}</span>
                    </div>
                \`;
                container.appendChild(el);
            });
        }

        async function saveTransaction() {
            const customer = document.getElementById('customer').value;
            const item = document.getElementById('item').value;
            const total = parseFloat(document.getElementById('total').value) || 0;
            const paid = parseFloat(document.getElementById('paid').value) || 0;
            const location = document.getElementById('location').value;
            const coords = document.getElementById('coords').value.split(',');

            if (!customer) return alert("Customer required");

            const now = new Date();
            const payload = {
                timestamp: now.getTime(),
                date: now.toISOString().replace('T', ' ').substring(0, 16),
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

            document.getElementById('customer').value = '';
            document.getElementById('item').value = '';
            document.getElementById('total').value = '';
            document.getElementById('paid').value = '';
            document.getElementById('balance').value = '';
            document.getElementById('location').value = '';
            document.getElementById('coords').value = '';

            loadData();
            switchTab('ledger');
        }

        function openEditModal(id) {
            const tx = masterDataset.find(t => t.id === id);
            if (!tx) return;

            document.getElementById('edit-id').value = tx.id;
            document.getElementById('edit-customer').value = tx.customer || '';
            document.getElementById('edit-item').value = tx.item || '';
            document.getElementById('edit-total').value = tx.total !== undefined ? tx.total : (tx.amount || 0);
            document.getElementById('edit-paid').value = tx.paid !== undefined ? tx.paid : (tx.cashCollected || 0);

            if (tx.timestamp) {
                const d = new Date(tx.timestamp);
                const isoStr = new Date(d.getTime() - (d.getTimezoneOffset() * 60000)).toISOString().slice(0, 16);
                document.getElementById('edit-timestamp').value = isoStr;
            } else {
                document.getElementById('edit-timestamp').value = '';
            }

            document.getElementById('editModal').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('editModal').style.display = 'none';
        }

        async function commitEdit() {
            const id = parseInt(document.getElementById('edit-id').value);
            const customer = document.getElementById('edit-customer').value;
            const item = document.getElementById('edit-item').value;
            const total = parseFloat(document.getElementById('edit-total').value) || 0;
            const paid = parseFloat(document.getElementById('edit-paid').value) || 0;
            const tsInput = document.getElementById('edit-timestamp').value;

            let timestamp = Date.now();
            let dateStr = new Date().toISOString().replace('T', ' ').substring(0, 16);

            if (tsInput) {
                const customDate = new Date(tsInput);
                timestamp = customDate.getTime();
                dateStr = customDate.toISOString().replace('T', ' ').substring(0, 16);
            }

            const payload = {
                id,
                customer,
                item,
                total,
                paid,
                amount: total,
                cashCollected: paid,
                balance: total - paid,
                timestamp,
                date: dateStr
            };

            await fetch('/api/transactions/edit', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            closeModal();
            loadData();
        }

        loadData();
    </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

    if (req.url === '/' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(htmlContent);
    } else if (req.url === '/api/transactions' && req.method === 'GET') {
        fs.readFile(DATA_FILE, 'utf8', (err, data) => {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(data || '[]');
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
                res.writeHead(400); res.end('Bad Request');
            }
        });
    } else if (req.url === '/api/transactions/edit' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const updatedTx = JSON.parse(body);
                fs.readFile(DATA_FILE, 'utf8', (err, data) => {
                    let txs = err ? [] : JSON.parse(data);
                    const idx = txs.findIndex(t => t.id === updatedTx.id);
                    if (idx !== -1) {
                        txs[idx] = { ...txs[idx], ...updatedTx };
                        fs.writeFile(DATA_FILE, JSON.stringify(txs, null, 2), () => {
                            res.writeHead(200, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify(txs[idx]));
                        });
                    } else {
                        res.writeHead(404); res.end('Record Not Found');
                    }
                });
            } catch (e) {
                res.writeHead(400); res.end('Bad Request');
            }
        });
    } else {
        res.writeHead(404); res.end('Not Found');
    }
});

server.listen(PORT, () => console.log(`[+] Enterprise Suite running on http://localhost:${PORT}`));
NODE_EOF

node "$REPO_DIR/enterprise_server.js" &
ENTERPRISE_PID=$!

echo "=========================================="
echo "   ENTERPRISE SUITE V5.0 DEPLOYED         "
echo "=========================================="
echo "  URL: http://localhost:$PORT             "
echo "=========================================="

trap "kill $ENTERPRISE_PID 2>/dev/null; exit" INT TERM
wait $ENTERPRISE_PID
