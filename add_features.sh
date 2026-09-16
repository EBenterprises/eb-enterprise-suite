#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Advanced Features & UI Polish
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Enhancing server.js with customer profile notes and financial adjustments..."
cat << 'SERVER_EOF' > server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const dbFile = path.join(__dirname, 'sales.db');
const db = new sqlite3.Database(dbFile, (err) => {
    if (err) console.error('Database opening error: ' + err.message);
    else console.log('Connected to SQLite database.');
});

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        customer TEXT,
        name TEXT,
        price REAL,
        quantity INTEGER,
        weightGrams REAL,
        status TEXT DEFAULT 'unpaid',
        amountPaid REAL DEFAULT 0
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS customer_notes (
        customer TEXT PRIMARY KEY,
        notes TEXT,
        discountPercent REAL DEFAULT 0
    )`);
});

// Get all sales
app.get('/api/sales', (req, res) => {
    db.all("SELECT * FROM sales ORDER BY id DESC", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Get customer notes and discounts
app.get('/api/customers/:name', (req, res) => {
    const cust = req.params.name;
    db.get("SELECT * FROM customer_notes WHERE customer = ?", [cust], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(row || { customer: cust, notes: '', discountPercent: 0 });
    });
});

// Save customer notes and discounts
app.post('/api/customers/:name', (req, res) => {
    const cust = req.params.name;
    const { notes, discountPercent } = req.body;
    db.run(
        `INSERT INTO customer_notes (customer, notes, discountPercent) VALUES (?, ?, ?)
         ON CONFLICT(customer) DO UPDATE SET notes = excluded.notes, discountPercent = excluded.discountPercent`,
        [cust, notes || '', discountPercent || 0],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ success: true });
        }
    );
});

// Add sale
app.post('/api/sales', (req, res) => {
    const { date, customer, name, price, quantity, weightGrams, status, amountPaid } = req.body;
    db.run(
        `INSERT INTO sales (date, customer, name, price, quantity, weightGrams, status, amountPaid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [date, customer, name, price, quantity, weightGrams, status, amountPaid],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: this.lastID });
        }
    );
});

// Update sale
app.put('/api/sales/:id', (req, res) => {
    const { status, amountPaid } = req.body;
    db.run(
        `UPDATE sales SET status = ?, amountPaid = ? WHERE id = ?`,
        [status, amountPaid, req.params.id],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ updated: this.changes });
        }
    );
});

// Delete sale
app.delete('/api/sales/:id', (req, res) => {
    db.run(`DELETE FROM sales WHERE id = ?`, [req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ deleted: this.changes });
    });
});

// Settle customer tab
app.put('/api/settle-customer/:name', (req, res) => {
    const custName = req.params.name;
    db.run(
        `UPDATE sales SET status = 'paid', amountPaid = (price * quantity) WHERE customer = ? AND status != 'paid'`,
        [custName],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ settled: this.changes });
        }
    );
});

// Restore backup
app.post('/api/backup', (req, res) => {
    const items = req.body;
    if (!Array.isArray(items)) return res.status(400).json({ error: 'Invalid backup format' });
    db.serialize(() => {
        db.run("DELETE FROM sales", () => {
            const stmt = db.prepare(`INSERT INTO sales (id, date, customer, name, price, quantity, weightGrams, status, amountPaid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`);
            items.forEach(s => {
                stmt.run(s.id, s.date, s.customer, s.name, s.price, s.quantity, s.weightGrams, s.status, s.amountPaid);
            });
            stmt.finalize(() => {
                res.json({ restored: items.length });
            });
        });
    });
});

app.listen(PORT, () => {
    console.log(`EB Sales Tracker running on port ${PORT}`);
});
SERVER_EOF

echo "[+] Updating index.html to add Customer Profile & Quick Inventory Presets..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales & Inventory Tracker</title>
    <link rel="stylesheet" href="styles.css">
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&display=swap" rel="stylesheet">
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">EB</div>
            <h1>Sales & Inventory Tracker</h1>
            <p>Executive Spectrum Command Console • EB Enterprises</p>
            <div class="header-actions">
                <button class="btn-action" id="toggleAudioBtn">🔊 Audio: ON</button>
                <button class="btn-action" id="exportCsvBtn">📥 Export CSV</button>
                <button class="btn-action" id="exportJsonBtn">💾 Backup JSON</button>
                <button class="btn-action" id="importJsonBtn">📂 Restore JSON</button>
                <input type="file" id="importFile" style="display: none;" accept=".json">
            </div>
        </header>

        <!-- KPI DASHBOARD -->
        <div class="dashboard">
            <div class="card">
                <h3>Total Revenue</h3>
                <p id="totalRevenue" class="gold-text">$0.00</p>
            </div>
            <div class="card">
                <h3>Total Volume</h3>
                <p id="totalWeight" class="teal-text">0.00 g</p>
            </div>
            <div class="card">
                <h3>Total Transactions</h3>
                <p id="totalSales" style="color: var(--text-main);">0</p>
            </div>
        </div>

        <!-- QUICK PRESETS -->
        <div class="form-section" style="margin-bottom: 20px; padding: 20px;">
            <div class="section-header-flex" style="margin-bottom: 10px;">
                <h3 style="color: var(--champagne-gold); font-size: 0.9rem; text-transform: uppercase; letter-spacing: 1px;">⚡ Quick Item Presets</h3>
            </div>
            <div style="display: flex; gap: 10px; flex-wrap: wrap;" id="presetContainer">
                <button type="button" class="btn-preset" data-name="Quarter (7g)" data-price="100" data-weight="7.00">Quarter (7g)</button>
                <button type="button" class="btn-preset" data-name="Half Ounce (14g)" data-price="180" data-weight="14.00">Half Oz (14g)</button>
                <button type="button" class="btn-preset" data-name="Full Ounce (28g)" data-price="320" data-weight="28.00">Full Oz (28g)</button>
                <button type="button" class="btn-preset" data-name="Concentrate (1g)" data-price="50" data-weight="1.00">Concentrate (1g)</button>
            </div>
        </div>

        <!-- TRANSACTION ENTRY FORM -->
        <div class="form-section">
            <div class="section-header-flex">
                <h2>New Transaction</h2>
            </div>
            <form id="salesForm">
                <div class="form-grid">
                    <div class="form-group">
                        <label for="customerName">Customer Name</label>
                        <input type="text" id="customerName" required placeholder="e.g. John Doe">
                    </div>
                    <div class="form-group">
                        <label for="itemName">Item / Strain</label>
                        <input type="text" id="itemName" required placeholder="e.g. Blue Dream">
                    </div>
                    <div class="form-group">
                        <label for="unitPrice">Unit Price ($)</label>
                        <input type="number" id="unitPrice" step="0.01" min="0" required placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label for="quantity">Quantity</label>
                        <input type="number" id="quantity" min="1" value="1" required>
                    </div>
                    <div class="form-group">
                        <label for="weightGrams">Unit Weight (g)</label>
                        <input type="number" id="weightGrams" step="0.01" min="0" required placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label for="paymentStatus">Payment Status</label>
                        <select id="paymentStatus">
                            <option value="unpaid">Unpaid</option>
                            <option value="partial">Partial</option>
                            <option value="paid" selected>Paid</option>
                        </select>
                    </div>
                    <div class="form-group" id="amountPaidGroup" style="display: flex;">
                        <label for="amountPaid">Amount Paid ($)</label>
                        <input type="number" id="amountPaid" step="0.01" min="0" placeholder="0.00">
                    </div>
                </div>
                <button type="submit" class="btn-submit">Record Transaction</button>
            </form>
        </div>

        <!-- CUSTOMER TABS & PROFILES -->
        <div class="table-section">
            <div class="section-header-flex">
                <h2>Customer Tabs & Profiles</h2>
                <input type="text" class="search-input" id="customerSearch" placeholder="Search customer...">
            </div>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Customer</th>
                            <th>Transactions</th>
                            <th>Total Mass</th>
                            <th>Total Bill</th>
                            <th>Total Paid</th>
                            <th>Balance Due</th>
                            <th>Actions / Status</th>
                        </tr>
                    </thead>
                    <tbody id="customerTabsTableBody">
                        <!-- Populated by JS -->
                    </tbody>
                </table>
            </div>
        </div>

        <!-- TRANSACTION LEDGER -->
        <div class="table-section">
            <div class="section-header-flex">
                <h2>Transaction Ledger</h2>
                <input type="text" class="search-input" id="transactionSearch" placeholder="Search transactions...">
            </div>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Date & Time</th>
                            <th>Customer</th>
                            <th>Item</th>
                            <th>Unit Price</th>
                            <th>Qty</th>
                            <th>Unit Wt</th>
                            <th>Total Mass</th>
                            <th>Total Value</th>
                            <th>Status & Paid</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="salesTableBody">
                        <!-- Populated by JS -->
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- CUSTOMER PROFILE MODAL -->
    <div id="customerModal" class="modal-overlay" style="display: none;">
        <div class="modal-content">
            <div class="section-header-flex">
                <h2 id="modalCustomerTitle">Customer Profile</h2>
                <button type="button" class="btn-action" id="closeModalBtn">Close</button>
            </div>
            <div class="form-group" style="margin-bottom: 15px;">
                <label for="customerNotesInput">Customer Notes / Preferences</label>
                <textarea id="customerNotesInput" rows="4" class="search-input" style="width: 100%; resize: vertical;" placeholder="Add private customer notes here..."></textarea>
            </div>
            <div class="form-group" style="margin-bottom: 20px;">
                <label for="customerDiscountInput">Custom Discount (%)</label>
                <input type="number" id="customerDiscountInput" min="0" max="100" step="1" value="0" style="width: 150px;">
            </div>
            <button type="button" class="btn-submit" id="saveCustomerProfileBtn">Save Profile</button>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
HTML_EOF

echo "[+] Updating styles.css with preset buttons and modal styling..."
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
    --success: #10b981;
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
}
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
.form-group input, .form-group select, .form-group textarea { 
    padding: 14px; background: var(--obsidian); border: 1px solid var(--border-color); 
    color: var(--text-main); font-size: 1rem; border-radius: 8px; 
    transition: all 0.2s ease;
}
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { 
    outline: none; border-color: var(--teal-glow); 
    box-shadow: 0 0 15px rgba(56, 189, 248, 0.25); 
    background: #0f172a;
}

.btn-preset {
    background: rgba(2, 132, 199, 0.15); border: 1px solid var(--deep-teal); color: var(--teal-glow);
    padding: 8px 14px; border-radius: 6px; font-weight: 700; font-size: 0.8rem; cursor: pointer;
    transition: all 0.2s ease; text-transform: uppercase;
}
.btn-preset:hover { background: var(--deep-teal); color: white; box-shadow: 0 0 12px rgba(56, 189, 248, 0.4); }

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
th, td { padding: 20px 16px; border-bottom: 1px solid var(--border-color); vertical-align: middle; }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 1px; background: #0f172a; font-weight: 800; }
td { font-size: 0.95rem; color: var(--text-main); }
tbody tr:hover { background: rgba(30, 41, 59, 0.5); }

.badge { padding: 8px 14px; border-radius: 6px; font-size: 0.75rem; font-weight: 800; text-transform: uppercase; display: inline-block; }
.badge-paid { background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981; }
.badge-unpaid { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid #ef4444; }
.badge-partial { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }

.status-controls { display: flex; flex-direction: column; gap: 10px; min-width: 150px; }
select.status-select { 
    padding: 8px 12px; background: var(--obsidian); color: var(--text-main); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; font-weight: 600; cursor: pointer; width: 100%;
}
input.paid-input { 
    padding: 8px 12px; background: var(--obsidian); color: var(--champagne-gold); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; width: 100%; font-weight: bold;
}

.tab-action-container { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-top: 6px; }

.btn-settle {
    background: rgba(16, 185, 129, 0.2); border: 1px solid var(--success); color: #34d399;
    padding: 8px 14px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.75rem;
    text-transform: uppercase; transition: all 0.2s ease;
}
.btn-settle:hover { background: var(--success); color: white; }

.btn-profile {
    background: rgba(251, 191, 36, 0.15); border: 1px solid var(--champagne-gold); color: var(--champagne-gold);
    padding: 8px 14px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.75rem;
    text-transform: uppercase; transition: all 0.2s ease;
}
.btn-profile:hover { background: var(--champagne-gold); color: var(--obsidian); }

.btn-delete { 
    background: rgba(239, 68, 68, 0.15); border: 1px solid var(--danger); color: #f87171; 
    padding: 10px 16px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.8rem;
    text-transform: uppercase; transition: all 0.2s ease;
}
.btn-delete:hover { background: var(--danger); color: white; }

.modal-overlay {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(5, 7, 11, 0.85); backdrop-filter: blur(8px);
    display: flex; justify-content: center; align-items: center; z-index: 1000;
}
.modal-content {
    background: var(--dark-grey); border: 1px solid var(--teal-glow);
    padding: 35px; border-radius: 14px; width: 550px; max-width: 90%;
    box-shadow: 0 25px 50px rgba(0,0,0,0.8);
}
CSS_EOF

echo "[+] Updating app.js with Quick Presets and Customer Profile Modal..."
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
const presetContainer = document.getElementById('presetContainer');

const customerModal = document.getElementById('customerModal');
const modalCustomerTitle = document.getElementById('modalCustomerTitle');
const customerNotesInput = document.getElementById('customerNotesInput');
const customerDiscountInput = document.getElementById('customerDiscountInput');
const saveCustomerProfileBtn = document.getElementById('saveCustomerProfileBtn');
const closeModalBtn = document.getElementById('closeModalBtn');

let audioEnabled = true;
let currentSalesData = [];
let activeCustomerForModal = '';

// Web Audio Synthesizer
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
        osc.frequency.setValueAtTime(523.25, audioCtx.currentTime);
        osc.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.08);
        osc.frequency.setValueAtTime(783.99, audioCtx.currentTime + 0.16);
        gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.3);
    }
}

toggleAudioBtn.addEventListener('click', () => {
    audioEnabled = !audioEnabled;
    toggleAudioBtn.textContent = audioEnabled ? '🔊 Audio: ON' : '🔇 Audio: OFF';
    playSynthSound('click');
});

presetContainer.addEventListener('click', (e) => {
    if (e.target.classList.contains('btn-preset')) {
        playSynthSound('click');
        itemNameInput.value = e.target.getAttribute('data-name');
        unitPriceInput.value = e.target.getAttribute('data-price');
        weightGramsInput.value = e.target.getAttribute('data-weight');
        quantityInput.value = '1';
        if (paymentStatusInput.value === 'paid') {
            amountPaidInput.value = e.target.getAttribute('data-price');
        }
    }
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

async function openCustomerProfile(customerName) {
    playSynthSound('click');
    activeCustomerForModal = customerName;
    modalCustomerTitle.textContent = `Profile: ${customerName}`;
    
    try {
        const res = await fetch(`/api/customers/${encodeURIComponent(customerName)}`);
        const data = await res.json();
        customerNotesInput.value = data.notes || '';
        customerDiscountInput.value = data.discountPercent || 0;
    } catch (err) {
        customerNotesInput.value = '';
        customerDiscountInput.value = 0;
    }

    customerModal.style.display = 'flex';
}

closeModalBtn.addEventListener('click', () => {
    playSynthSound('click');
    customerModal.style.display = 'none';
});

saveCustomerProfileBtn.addEventListener('click', async () => {
    playSynthSound('success');
    await fetch(`/api/customers/${encodeURIComponent(activeCustomerForModal)}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            notes: customerNotesInput.value,
            discountPercent: parseFloat(customerDiscountInput.value) || 0
        })
    });
    customerModal.style.display = 'none';
});

async function deleteEntry(id) {
    playSynthSound('click');
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRecord();
}

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
                totalPaid: 0
            };
        }
        customerMap[custName].txCount += 1;
        customerMap[custName].totalMass += rowTotalWeight;
        customerMap[custName].totalBill += rowTotalPrice;
        customerMap[custName].totalPaid += salePaid;
    });

    const filteredSales = sales.filter((sale, index) => {
        const textToSearch = `#${index + 1} ${sale.date} ${sale.customer} ${sale.name} ${sale.status}`.toLowerCase();
        return textToSearch.includes(txQuery);
    });

    if (filteredSales.length === 0) {
        salesTableBody.innerHTML = `<tr><td colspan="11" style="text-align: center; color: var(--text-muted); padding: 25px;">No matching transactions found.</td></tr>`;
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

    const filteredCustomers = Object.values(customerMap).filter(cust => 
        cust.name.toLowerCase().includes(custQuery)
    );

    if (filteredCustomers.length === 0) {
        customerTabsTableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 25px;">No matching customer tabs.</td></tr>`;
    } else {
        filteredCustomers.forEach(cust => {
            const remainingBalance = Math.max(0, cust.totalBill - cust.totalPaid);
            const tr = document.createElement('tr');
            let actionHtml = '';
            
            let settleBtn = remainingBalance > 0.01 ? `<button class="btn-settle" onclick="settleCustomerTab('${escapeQuote(cust.name)}')">Settle Tab</button>` : '';
            let profileBtn = `<button class="btn-profile" onclick="openCustomerProfile('${escapeQuote(cust.name)}')">Profile</button>`;

            if (remainingBalance <= 0.01) {
                actionHtml = `
                    <div class="tab-action-container">
                        <span class="badge badge-paid">Settled</span>
                        ${profileBtn}
                    </div>
                `;
            } else if (cust.totalPaid > 0) {
                actionHtml = `
                    <div class="tab-action-container">
                        <span class="badge badge-partial">Due: $${remainingBalance.toFixed(2)}</span>
                        ${settleBtn}
                        ${profileBtn}
                    </div>
                `;
            } else {
                actionHtml = `
                    <div class="tab-action-container">
                        <span class="badge badge-unpaid">Unpaid</span>
                        ${settleBtn}
                        ${profileBtn}
                    </div>
                `;
            }

            tr.innerHTML = `
                <td><strong class="gold-text">${escapeHtml(cust.name)}</strong></td>
                <td>${cust.txCount} tx</td>
                <td class="teal-text">${cust.totalMass.toFixed(2)} g</td>
                <td class="gold-text">$${cust.totalBill.toFixed(2)}</td>
                <td style="color: var(--success);">$${cust.totalPaid.toFixed(2)}</td>
                <td style="color: ${remainingBalance > 0 ? 'var(--danger)' : 'var(--success)'}; font-weight: bold;">$${remainingBalance.toFixed(2)}</td>
                <td>${actionHtml}</td>
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

echo "[+] Enhancements deployed. Restarting server..."
node server.js
