#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Cyber-Executive "Dope AF" Overhaul
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Updating server.js to support full database backup/restore endpoints..."
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
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
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
                newSale.status = newSale.status || 'unpaid';
                
                const totalVal = newSale.price * newSale.quantity;
                if (newSale.status === 'paid') {
                    newSale.amountPaid = totalVal;
                } else if (newSale.status === 'unpaid') {
                    newSale.amountPaid = 0;
                } else {
                    newSale.amountPaid = parseFloat(newSale.amountPaid) || 0;
                }

                sales.push(newSale);
                fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(newSale));
            });
            return;
        }
    }

    // Database backup import endpoint
    if (req.url === '/api/backup' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                if (Array.isArray(data)) {
                    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: true }));
                } else {
                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Invalid backup format' }));
                }
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Malformed JSON' }));
            }
        });
        return;
    }

    // Settle entire customer tab endpoint
    if (req.url.startsWith('/api/settle-customer/') && req.method === 'PUT') {
        const customerName = decodeURIComponent(req.url.split('/').pop());
        let sales = JSON.parse(fs.readFileSync(DATA_FILE));
        sales = sales.map(s => {
            if ((s.customer || 'N/A').toLowerCase() === customerName.toLowerCase()) {
                const totalVal = s.price * s.quantity;
                return { ...s, status: 'paid', amountPaid: totalVal };
            }
            return s;
        });
        fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
        return;
    }

    if (req.method === 'PUT' && req.url.startsWith('/api/sales/')) {
        const id = parseInt(req.url.split('/').pop());
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            const updates = JSON.parse(body);
            let sales = JSON.parse(fs.readFileSync(DATA_FILE));
            sales = sales.map(s => {
                if (s.id === id) {
                    const updated = { ...s, ...updates };
                    const totalVal = updated.price * updated.quantity;
                    if (updated.status === 'paid') {
                        updated.amountPaid = totalVal;
                    } else if (updated.status === 'unpaid') {
                        updated.amountPaid = 0;
                    } else if (updates.amountPaid !== undefined) {
                        updated.amountPaid = parseFloat(updates.amountPaid) || 0;
                    }
                    return updated;
                }
                return s;
            });
            fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true }));
        });
        return;
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
    console.log(`\n[EB ENTERPRISES] Dope AF Server Active on Port ${PORT}`);
});
JS_EOF

echo "[+] Updating index.html with search bars, audio toggle, and export/import tools..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises | Sales Logistics Terminal</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">EB</div>
            <h1>Sales Logistics Terminal</h1>
            <p>Cyber-Executive Asset, Tab & Revenue Command Center</p>
            <div class="header-actions">
                <button class="btn-action" id="toggleAudioBtn" title="Toggle Sound FX">🔊 Audio: ON</button>
                <button class="btn-action" id="exportCsvBtn" title="Export CSV">📥 Export CSV</button>
                <button class="btn-action" id="exportJsonBtn" title="Backup JSON">💾 Backup JSON</button>
                <button class="btn-action" id="importJsonBtn" title="Restore JSON">📂 Restore JSON</button>
                <input type="file" id="importFile" accept=".json" style="display: none;">
            </div>
        </header>

        <!-- Summary Cards -->
        <section class="dashboard">
            <div class="card">
                <h3>Total Revenue</h3>
                <p id="totalRevenue" class="gold-text">$0.00</p>
            </div>
            <div class="card">
                <h3>Total Mass</h3>
                <p id="totalWeight" class="teal-text">0.00 g</p>
            </div>
            <div class="card">
                <h3>Transaction Count</h3>
                <p id="totalSales">0</p>
            </div>
        </section>

        <!-- Form Section -->
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
                    <div class="form-group">
                        <label>Payment Status</label>
                        <select id="paymentStatus">
                            <option value="unpaid">Unpaid</option>
                            <option value="partial">Partial</option>
                            <option value="paid">Paid</option>
                        </select>
                    </div>
                    <div class="form-group" id="amountPaidGroup" style="display: none;">
                        <label>Amount Paid ($)</label>
                        <input type="number" id="amountPaid" step="0.01" min="0" placeholder="0.00">
                    </div>
                </div>
                <button type="submit" class="btn-submit">EXECUTE LOG</button>
            </form>
        </section>

        <!-- Customer-by-Customer Tabs Ledger -->
        <section class="table-section">
            <div class="section-header-flex">
                <h2>Customer Tabs & Balances</h2>
                <input type="text" id="customerSearch" class="search-input" placeholder="Search customer tabs...">
            </div>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Customer Name</th>
                            <th>Total Tx</th>
                            <th>Total Mass</th>
                            <th>Total Bill</th>
                            <th>Total Paid</th>
                            <th>Remaining Balance</th>
                            <th>Tab Status / Action</th>
                        </tr>
                    </thead>
                    <tbody id="customerTabsTableBody"></tbody>
                </table>
            </div>
        </section>

        <!-- Complete Transaction History -->
        <section class="table-section">
            <div class="section-header-flex">
                <h2>Complete Transaction History</h2>
                <input type="text" id="transactionSearch" class="search-input" placeholder="Search transactions...">
            </div>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Timestamp</th>
                            <th>Customer</th>
                            <th>Asset</th>
                            <th>Unit $</th>
                            <th>Qty</th>
                            <th>Mass (g)</th>
                            <th>Total Mass</th>
                            <th>Total Val</th>
                            <th>Status / Paid</th>
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

echo "[+] Updating styles.css for next-gen cyber styling..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #05070b;
    --dark-grey: #0f172a;
    --card-bg: rgba(15, 23, 42, 0.75);
    --border-color: #1e293b;
    --deep-teal: #0284c7;
    --teal-glow: #38bdf8;
    --champagne-gold: #fbbf24;
    --gold-glow: rgba(251, 191, 36, 0.3);
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --danger: #ef4444;
    --danger-hover: #dc2626;
    --success: #10b981;
    --warning: #f59e0b;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'JetBrains Mono', monospace, -apple-system, sans-serif; }

body {
    background-color: var(--obsidian);
    background-image: 
        radial-gradient(circle at 15% 10%, rgba(2, 132, 199, 0.1) 0%, transparent 45%),
        radial-gradient(circle at 85% 90%, rgba(251, 191, 36, 0.07) 0%, transparent 45%);
    color: var(--text-main);
    padding: 30px;
    line-height: 1.6;
    min-height: 100vh;
}

.container { max-width: 1400px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 35px; border-bottom: 1px solid var(--border-color); padding-bottom: 25px;
    position: relative;
}

.logo {
    display: inline-block; width: 65px; height: 65px; line-height: 65px;
    background: linear-gradient(135deg, var(--deep-teal), #0369a1); color: var(--text-main);
    font-weight: 900; font-size: 2rem; border-radius: 14px; margin-bottom: 12px;
    box-shadow: 0 0 25px rgba(56, 189, 248, 0.4);
    border: 1px solid var(--teal-glow);
}

h1 { color: var(--teal-glow); font-size: 2.6rem; letter-spacing: 2px; text-transform: uppercase; text-shadow: 0 0 20px rgba(56, 189, 248, 0.3); }
header p { color: var(--text-muted); font-size: 1.05rem; margin-bottom: 15px; }

.header-actions { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; margin-top: 15px; }
.btn-action {
    background: rgba(30, 41, 59, 0.8); border: 1px solid var(--border-color); color: var(--text-muted);
    padding: 8px 14px; border-radius: 6px; font-size: 0.8rem; font-weight: 700; cursor: pointer;
    transition: all 0.2s ease; text-transform: uppercase;
}
.btn-action:hover { border-color: var(--teal-glow); color: var(--teal-glow); box-shadow: 0 0 10px rgba(56, 189, 248, 0.2); }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 25px; margin-bottom: 35px; }
.card { 
    background: var(--card-bg); backdrop-filter: blur(16px);
    padding: 25px; border: 1px solid var(--border-color); border-radius: 12px; 
    border-left: 6px solid var(--deep-teal);
    box-shadow: 0 10px 30px rgba(0,0,0,0.6);
    transition: transform 0.2s ease, border-color 0.2s ease;
}
.card:hover { transform: translateY(-3px); border-color: var(--teal-glow); }
.card h3 { color: var(--text-muted); font-size: 0.8rem; text-transform: uppercase; margin-bottom: 10px; letter-spacing: 1px; font-weight: 700; }
.card p { font-size: 2.3rem; font-weight: 800; color: var(--text-main); }

.gold-text { color: var(--champagne-gold) !important; text-shadow: 0 0 12px var(--gold-glow); }
.teal-text { color: var(--teal-glow) !important; text-shadow: 0 0 12px rgba(56, 189, 248, 0.3); }

.form-section, .table-section { 
    background: var(--card-bg); backdrop-filter: blur(16px);
    padding: 30px; border: 1px solid var(--border-color); margin-bottom: 35px; border-radius: 12px; 
    box-shadow: 0 15px 35px rgba(0,0,0,0.7);
}

.section-header-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; margin-bottom: 25px; }
h2 { color: var(--teal-glow); font-size: 1.4rem; text-transform: uppercase; letter-spacing: 1px; border-left: 4px solid var(--champagne-gold); padding-left: 12px; }

.search-input {
    background: var(--obsidian); border: 1px solid var(--border-color); color: var(--text-main);
    padding: 10px 14px; border-radius: 8px; font-size: 0.9rem; width: 260px;
    transition: all 0.2s ease;
}
.search-input:focus { outline: none; border-color: var(--teal-glow); box-shadow: 0 0 12px rgba(56, 189, 248, 0.25); }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 20px; margin-bottom: 25px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.8rem; margin-bottom: 8px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; }
.form-group input, .form-group select { 
    padding: 14px; background: var(--obsidian); border: 1px solid var(--border-color); 
    color: var(--text-main); font-size: 1rem; border-radius: 8px; 
    transition: all 0.2s ease;
}
.form-group input::placeholder { color: #475569; }
.form-group input:focus, .form-group select:focus { 
    outline: none; border-color: var(--teal-glow); 
    box-shadow: 0 0 15px rgba(56, 189, 248, 0.25); 
    background: #0f172a;
}

.btn-submit { 
    width: 100%; padding: 16px; 
    background: linear-gradient(135deg, var(--deep-teal), #0369a1); 
    color: var(--text-main); border: 1px solid var(--teal-glow); 
    font-weight: 800; font-size: 1.1rem; cursor: pointer; border-radius: 8px; 
    text-transform: uppercase; letter-spacing: 1.5px;
    box-shadow: 0 4px 20px rgba(2, 132, 199, 0.4);
    transition: all 0.2s ease; 
}
.btn-submit:hover { 
    background: linear-gradient(135deg, #0369a1, var(--deep-teal));
    box-shadow: 0 6px 25px rgba(56, 189, 248, 0.6);
    transform: translateY(-2px);
}

.table-wrapper { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border-color); }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 16px 14px; border-bottom: 1px solid var(--border-color); }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 1px; background: #0f172a; font-weight: 800; }
td { font-size: 0.95rem; color: var(--text-main); }
tbody tr { transition: background 0.15s ease; }
tbody tr:hover { background: rgba(30, 41, 59, 0.5); }

.badge { padding: 6px 12px; border-radius: 6px; font-size: 0.75rem; font-weight: 800; text-transform: uppercase; display: inline-block; box-shadow: 0 2px 10px rgba(0,0,0,0.3); }
.badge-paid { background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981; }
.badge-unpaid { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid #ef4444; }
.badge-partial { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }

.status-controls { display: flex; flex-direction: column; gap: 8px; }
select.status-select { 
    padding: 6px 10px; background: var(--obsidian); color: var(--text-main); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; font-weight: 600;
    cursor: pointer;
}
input.paid-input { 
    padding: 6px 10px; background: var(--obsidian); color: var(--champagne-gold); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; width: 110px; font-weight: bold;
}

.btn-settle {
    background: rgba(16, 185, 129, 0.15); border: 1px solid var(--success); color: #34d399;
    padding: 6px 12px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.75rem;
    text-transform: uppercase; transition: all 0.2s ease; margin-left: 8px;
}
.btn-settle:hover { background: var(--success); color: white; box-shadow: 0 0 12px rgba(16, 185, 129, 0.4); }

.btn-delete { 
    background: rgba(239, 68, 68, 0.15); border: 1px solid var(--danger); color: #f87171; 
    padding: 8px 14px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.8rem;
    text-transform: uppercase; transition: all 0.2s ease; 
}
.btn-delete:hover { background: var(--danger); color: white; box-shadow: 0 0 15px rgba(239, 68, 68, 0.4); }
CSS_EOF

echo "[+] Updating app.js with Web Audio SFX, search filtering, CSV export, and backup/restore..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const paymentStatusInput = document.getElementById('paymentStatus');
const amountPaidGroup = document.getElementById('amountPaidGroup');
const amountPaidInput = document.getElementById('amountPaid');

const salesTableBody = document.getElementById('salesTableBody');
const customerTabsTableBody = document.getElementById('customerTabsTableBody');

const totalRevenueEl = document.getElementById('totalRevenue');
const totalWeightEl = document.getElementById('totalWeight');
const totalSalesEl = document.getElementById('totalSales');

const customerSearch = document.getElementById('customerSearch');
const transactionSearch = document.getElementById('transactionSearch');

const toggleAudioBtn = document.getElementById('toggleAudioBtn');
const exportCsvBtn = document.getElementById('exportCsvBtn');
const exportJsonBtn = document.getElementById('exportJsonBtn');
const importJsonBtn = document.getElementById('importJsonBtn');
const importFile = document.getElementById('importFile');

let audioEnabled = true;
let currentSalesData = [];

// Web Audio API Synthesizer
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
function playSynthSound(type) {
    if (!audioEnabled) return;
    if (audioCtx.state === 'suspended') audioCtx.resume();
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);

    if (type === 'click') {
        osc.frequency.setValueAtTime(440, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(220, audioCtx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.05, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.05);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.05);
    } else if (type === 'success') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(523.25, audioCtx.currentTime); // C5
        osc.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.08); // E5
        osc.frequency.setValueAtTime(783.99, audioCtx.currentTime + 0.16); // G5
        gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.3);
    }
}

toggleAudioBtn.addEventListener('click', () => {
    audioEnabled = !audioEnabled;
    toggleAudioBtn.textContent = audioEnabled ? '🔊 Audio: ON' : 'muted Audio: OFF';
    playSynthSound('click');
});

document.addEventListener('DOMContentLoaded', fetchAndRecord);

async function fetchAndRecord() {
    try {
        const res = await fetch(API_URL);
        currentSalesData = await res.json();
        render(currentSalesData);
    } catch (err) {
        console.error("API Failure:", err);
    }
}

paymentStatusInput.addEventListener('change', (e) => {
    playSynthSound('click');
    if (e.target.value === 'partial' || e.target.value === 'paid') {
        amountPaidGroup.style.display = 'flex';
        if (e.target.value === 'paid') {
            const unitPrice = parseFloat(unitPriceInput.value) || 0;
            const qty = parseInt(quantityInput.value) || 1;
            amountPaidInput.value = (unitPrice * qty).toFixed(2);
        }
    } else {
        amountPaidGroup.style.display = 'none';
        amountPaidInput.value = '';
    }
});

salesForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    playSynthSound('success');
    const status = paymentStatusInput.value;
    let amountPaid = 0;
    if (status === 'paid') {
        amountPaid = parseFloat(unitPriceInput.value) * parseInt(quantityInput.value, 10);
    } else if (status === 'partial') {
        amountPaid = parseFloat(amountPaidInput.value) || 0;
    }

    const payload = {
        date: new Date().toISOString().replace('T', ' ').substring(0, 19),
        customer: customerNameInput.value.trim(),
        name: itemNameInput.value.trim(),
        price: parseFloat(unitPriceInput.value),
        quantity: parseInt(quantityInput.value, 10),
        weightGrams: parseFloat(weightGramsInput.value),
        status: status,
        amountPaid: amountPaid
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    salesForm.reset();
    quantityInput.value = '1';
    paymentStatusInput.value = 'unpaid';
    amountPaidGroup.style.display = 'none';
    amountPaidInput.value = '';
    fetchAndRecord();
});

async function updateTransaction(id, newStatus, currentTotalVal, currentAmountPaidInputEl) {
    playSynthSound('click');
    const statusVal = newStatus;
    let paidVal = parseFloat(currentAmountPaidInputEl.value) || 0;

    if (statusVal === 'paid') {
        paidVal = currentTotalVal;
    } else if (statusVal === 'unpaid') {
        paidVal = 0;
    }

    await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: statusVal, amountPaid: paidVal })
    });
    fetchAndRecord();
}

async function settleCustomerTab(customerName) {
    playSynthSound('success');
    await fetch(`/api/settle-customer/${encodeURIComponent(customerName)}`, {
        method: 'PUT'
    });
    fetchAndRecord();
}

async function deleteEntry(id) {
    playSynthSound('click');
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRecord();
}

// Search filtering listeners
customerSearch.addEventListener('input', () => render(currentSalesData));
transactionSearch.addEventListener('input', () => render(currentSalesData));

function render(sales) {
    salesTableBody.innerHTML = '';
    customerTabsTableBody.innerHTML = '';
    
    let grandRevenue = 0, grandWeight = 0;
    const customerMap = {};

    const custQuery = customerSearch.value.toLowerCase();
    const txQuery = transactionSearch.value.toLowerCase();

    sales.forEach(sale => {
        const rowTotalWeight = sale.weightGrams * sale.quantity;
        const rowTotalPrice = sale.price * sale.quantity;
        const salePaid = typeof sale.amountPaid === 'number' ? sale.amountPaid : (sale.status === 'paid' ? rowTotalPrice : 0);
        
        grandRevenue += rowTotalPrice;
        grandWeight += rowTotalWeight;

        const custName = sale.customer || 'N/A';
        if (!customerMap[custName]) {
            customerMap[custName] = {
                name: custName,
                txCount: 0,
                totalMass: 0,
                totalBill: 0,
                totalPaid: 0,
                items: []
            };
        }
        customerMap[custName].txCount += 1;
        customerMap[custName].totalMass += rowTotalWeight;
        customerMap[custName].totalBill += rowTotalPrice;
        customerMap[custName].totalPaid += salePaid;
        customerMap[custName].items.push(sale);
    });

    // Render Filtered Transactions
    const filteredSales = sales.filter((sale, index) => {
        const textToSearch = `#${index + 1} ${sale.date} ${sale.customer} ${sale.name} ${sale.status}`.toLowerCase();
        return textToSearch.includes(txQuery);
    });

    if (filteredSales.length === 0) {
        salesTableBody.innerHTML = `<tr><td colspan="11" style="text-align: center; color: var(--text-muted); padding: 20px;">No matching transactions found.</td></tr>`;
    } else {
        filteredSales.forEach((sale) => {
            const originalIndex = sales.indexOf(sale);
            const rowNumber = originalIndex + 1;
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;
            const salePaid = typeof sale.amountPaid === 'number' ? sale.amountPaid : (sale.status === 'paid' ? rowTotalPrice : 0);

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong style="color: var(--teal-glow);">#${rowNumber}</strong></td>
                <td>${sale.date}</td>
                <td><strong class="gold-text">${escapeHtml(sale.customer || 'N/A')}</strong></td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td>$${sale.price.toFixed(2)}</td>
                <td>${sale.quantity}</td>
                <td>${sale.weightGrams.toFixed(2)}</td>
                <td class="teal-text">${rowTotalWeight.toFixed(2)} g</td>
                <td class="gold-text">$${rowTotalPrice.toFixed(2)}</td>
                <td>
                    <div class="status-controls">
                        <select class="status-select" id="status-${sale.id}" onchange="handleStatusChange(${sale.id}, ${rowTotalPrice})">
                            <option value="unpaid" ${sale.status === 'unpaid' ? 'selected' : ''}>Unpaid</option>
                            <option value="partial" ${sale.status === 'partial' ? 'selected' : ''}>Partial</option>
                            <option value="paid" ${sale.status === 'paid' ? 'selected' : ''}>Paid</option>
                        </select>
                        <input type="number" class="paid-input" id="paid-input-${sale.id}" step="0.01" min="0" max="${rowTotalPrice}" value="${salePaid.toFixed(2)}" ${sale.status === 'unpaid' ? 'style="display:none;"' : ''} placeholder="Paid $" onchange="updateTransaction(${sale.id}, document.getElementById('status-${sale.id}').value, ${rowTotalPrice}, this)">
                    </div>
                </td>
                <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
            `;
            salesTableBody.appendChild(tr);
        });
    }

    // Render Filtered Customer Tabs
    const filteredCustomers = Object.values(customerMap).filter(cust => 
        cust.name.toLowerCase().includes(custQuery)
    );

    if (filteredCustomers.length === 0) {
        customerTabsTableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 20px;">No matching customer tabs.</td></tr>`;
    } else {
        filteredCustomers.forEach(cust => {
            const remainingBalance = Math.max(0, cust.totalBill - cust.totalPaid);
            const tr = document.createElement('tr');
            let badgeHtml = '';
            if (remainingBalance <= 0.01) {
                badgeHtml = '<span class="badge badge-paid">Fully Settled</span>';
            } else if (cust.totalPaid > 0) {
                badgeHtml = `<span class="badge badge-partial">Partial ($${remainingBalance.toFixed(2)} Due)</span> <button class="btn-settle" onclick="settleCustomerTab('${escapeQuote(cust.name)}')">Settle Tab</button>`;
            } else {
                badgeHtml = `<span class="badge badge-unpaid">Unpaid Tab</span> <button class="btn-settle" onclick="settleCustomerTab('${escapeQuote(cust.name)}')">Settle Tab</button>`;
            }

            tr.innerHTML = `
                <td><strong class="gold-text">${escapeHtml(cust.name)}</strong></td>
                <td>${cust.txCount} tx</td>
                <td class="teal-text">${cust.totalMass.toFixed(2)} g</td>
                <td class="gold-text">$${cust.totalBill.toFixed(2)}</td>
                <td style="color: var(--success);">$${cust.totalPaid.toFixed(2)}</td>
                <td style="color: ${remainingBalance > 0 ? 'var(--danger)' : 'var(--success)'}; font-weight: bold;">$${remainingBalance.toFixed(2)}</td>
                <td>${badgeHtml}</td>
            `;
            customerTabsTableBody.appendChild(tr);
        });
    }

    totalRevenueEl.textContent = `$${grandRevenue.toFixed(2)}`;
    totalWeightEl.textContent = `${grandWeight.toFixed(2)} g`;
    totalSalesEl.textContent = sales.length;
}

function handleStatusChange(id, totalVal) {
    const statusSelect = document.getElementById(`status-${id}`);
    const paidInput = document.getElementById(`paid-input-${id}`);
    
    if (statusSelect.value === 'paid') {
        paidInput.value = totalVal.toFixed(2);
        paidInput.style.display = 'block';
    } else if (statusSelect.value === 'partial') {
        paidInput.style.display = 'block';
        if (parseFloat(paidInput.value) >= totalVal || parseFloat(paidInput.value) === 0) {
            paidInput.value = (totalVal / 2).toFixed(2);
        }
    } else {
        paidInput.value = '0.00';
        paidInput.style.display = 'none';
    }

    updateTransaction(id, statusSelect.value, totalVal, paidInput);
}

// Export & Import Handlers
exportCsvBtn.addEventListener('click', () => {
    playSynthSound('click');
    if (currentSalesData.length === 0) return alert('No data to export.');
    let csv = 'ID,Date,Customer,Asset,UnitPrice,Quantity,WeightPerUnit,TotalMass,TotalValue,Status,AmountPaid\n';
    currentSalesData.forEach(s => {
        csv += `${s.id},"${s.date}","${s.customer}","${s.name}",${s.price},${s.quantity},${s.weightGrams},${s.weightGrams * s.quantity},${s.price * s.quantity},${s.status},${s.amountPaid}\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `eb-sales-ledger-${new Date().toISOString().substring(0,10)}.csv`;
    a.click();
});

exportJsonBtn.addEventListener('click', () => {
    playSynthSound('click');
    const blob = new Blob([JSON.stringify(currentSalesData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `eb-database-backup-${new Date().toISOString().substring(0,10)}.json`;
    a.click();
});

importJsonBtn.addEventListener('click', () => {
    playSynthSound('click');
    importFile.click();
});

importFile.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async function(event) {
        try {
            const json = JSON.parse(event.target.result);
            await fetch('/api/backup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(json)
            });
            fetchAndRecord();
            alert('Database successfully restored!');
        } catch (err) {
            alert('Invalid backup file format.');
        }
    };
    reader.readAsText(file);
});

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}

function escapeQuote(str) {
    return str.replace(/'/g, "\\'");
}
JS_EOF

echo "[+] Dope AF feature set injected successfully. Restarting server..."
node server.js
