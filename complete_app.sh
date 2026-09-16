#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Complete Feature Integration Script
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Enhancing server.js with complete API endpoints (Inventory, Customers, Analytics)..."
cat << 'EJS' > server.js
const express = require('express');
const initSqlJs = require('sql.js');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'sales.sqlite');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db = null;

function saveDatabase() {
    if (db) {
        const data = db.export();
        const buffer = Buffer.from(data);
        fs.writeFileSync(DB_FILE, buffer);
    }
}

initSqlJs().then(SQL => {
    try {
        if (fs.existsSync(DB_FILE)) {
            const filebuffer = fs.readFileSync(DB_FILE);
            db = new SQL.Database(filebuffer);
            console.log('[+] Loaded existing SQLite database from disk.');
        } else {
            db = new SQL.Database();
            console.log('[+] Created new in-memory SQLite database.');
        }
    } catch (e) {
        console.log('[!] Error loading database file, initializing fresh:', e.message);
        db = new SQL.Database();
    }

    // Initialize Schema
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        customer TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        notes TEXT
    )`);
    
    saveDatabase();

    // Sales Routes
    app.get('/api/sales', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM sales ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) {
                rows.push(stmt.getAsObject());
            }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        const { item, amount, customer } = req.body;
        try {
            db.run(`INSERT INTO sales (item, amount, customer) VALUES (?, ?, ?)`, [item, amount, customer || '']);
            saveDatabase();
            
            const resStmt = db.prepare("SELECT last_insert_rowid() as id");
            resStmt.step();
            const lastId = resStmt.getAsObject().id;
            resStmt.free();

            res.json({ id: lastId, item, amount, customer });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Inventory Routes
    app.get('/api/inventory', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM inventory ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/inventory', (req, res) => {
        const { name, quantity, price } = req.body;
        try {
            db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, quantity, price]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Customer Routes
    app.get('/api/customers', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM customers ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/customers', (req, res) => {
        const { name, notes } = req.body;
        try {
            db.run(`INSERT INTO customers (name, notes) VALUES (?, ?)`, [name, notes]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Start Server
    app.listen(PORT, () => {
        console.log(`[+] EB Sales Tracker running live on port ${PORT}.`);
    });
});
EJS

echo "[+] Updating public/index.html with full dashboard tabs & features..."
cat << 'EHTML' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales Tracker | Executive Spectrum</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="app-container">
        <header>
            <h1>EB Sales Tracker</h1>
            <p class="subtitle">Executive Spectrum Edition</p>
        </header>

        <nav class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('sales')">Sales</button>
            <button class="tab-btn" onclick="switchTab('inventory')">Inventory</button>
            <button class="tab-btn" onclick="switchTab('customers')">Customers</button>
        </nav>

        <!-- Sales Tab -->
        <div id="tab-sales" class="tab-content active">
            <section class="form-section">
                <h2>Record Transaction</h2>
                <div class="preset-buttons">
                    <button class="preset-btn" onclick="applyPreset('Quarter (7g)', 100)">Quarter (7g) - $100</button>
                    <button class="preset-btn" onclick="applyPreset('Half (14g)', 180)">Half (14g) - $180</button>
                    <button class="preset-btn" onclick="applyPreset('Full (28g)', 320)">Full (28g) - $320</button>
                </div>
                <form id="sale-form">
                    <div class="input-group">
                        <input type="text" id="item" placeholder="Item / Strain / Description" required>
                    </div>
                    <div class="input-group">
                        <input type="number" id="amount" step="0.01" placeholder="Amount ($ CAD)" required>
                    </div>
                    <div class="input-group">
                        <input type="text" id="customer" placeholder="Customer Notes / Profile">
                    </div>
                    <button type="submit" class="btn-submit">Record Sale</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Recent Transactions</h2>
                <div id="sales-list"><p class="loading">Loading ledger...</p></div>
            </section>
        </div>

        <!-- Inventory Tab -->
        <div id="tab-inventory" class="tab-content">
            <section class="form-section">
                <h2>Add Inventory Stock</h2>
                <form id="inventory-form">
                    <div class="input-group">
                        <input type="text" id="inv-name" placeholder="Item / Strain Name" required>
                    </div>
                    <div class="input-group">
                        <input type="number" id="inv-qty" placeholder="Quantity (grams/units)" required>
                    </div>
                    <div class="input-group">
                        <input type="number" id="inv-price" step="0.01" placeholder="Target Price ($)" required>
                    </div>
                    <button type="submit" class="btn-submit">Add Stock</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Current Inventory</h2>
                <div id="inventory-list"><p class="loading">Loading inventory...</p></div>
            </section>
        </div>

        <!-- Customers Tab -->
        <div id="tab-customers" class="tab-content">
            <section class="form-section">
                <h2>Add Customer Profile</h2>
                <form id="customer-form">
                    <div class="input-group">
                        <input type="text" id="cust-name" placeholder="Customer Name" required>
                    </div>
                    <div class="input-group">
                        <input type="text" id="cust-notes" placeholder="Preferences / Notes">
                    </div>
                    <button type="submit" class="btn-submit">Save Profile</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Customer Directory</h2>
                <div id="customers-list"><p class="loading">Loading directory...</p></div>
            </section>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
EHTML

echo "[+] Updating public/styles.css..."
cat << 'ECSS' > public/styles.css
:root {
    --bg-obsidian: #0b0f12;
    --card-bg: #131b22;
    --teal-accent: #00d2c4;
    --gold-highlight: #d4af37;
    --text-main: #e2e8f0;
    --text-muted: #94a3b8;
    --border-color: #1e293b;
}

body {
    background-color: var(--bg-obsidian);
    color: var(--text-main);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    margin: 0;
    padding: 1rem;
}

.app-container {
    max-width: 550px;
    margin: 0 auto;
}

header {
    text-align: center;
    margin-bottom: 1rem;
}

header h1 {
    color: var(--teal-accent);
    margin: 0;
    font-size: 1.6rem;
}

.subtitle {
    color: var(--gold-highlight);
    font-size: 0.8rem;
    margin: 0.2rem 0 0;
    text-transform: uppercase;
    letter-spacing: 1.5px;
}

.tab-nav {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
}

.tab-btn {
    flex: 1;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    color: var(--text-muted);
    padding: 0.6rem;
    border-radius: 4px;
    cursor: pointer;
    font-weight: bold;
    transition: all 0.2s;
}

.tab-btn.active {
    background: var(--teal-accent);
    color: var(--bg-obsidian);
    border-color: var(--teal-accent);
}

.tab-content {
    display: none;
}

.tab-content.active {
    display: block;
}

.form-section, .list-section {
    background: var(--card-bg);
    padding: 1.2rem;
    border-radius: 6px;
    margin-bottom: 1rem;
    border: 1px solid var(--border-color);
}

.form-section h2, .list-section h2 {
    color: var(--teal-accent);
    font-size: 1.1rem;
    margin-top: 0;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 0.4rem;
}

.preset-buttons {
    display: flex;
    gap: 0.4rem;
    margin-bottom: 0.8rem;
    flex-wrap: wrap;
}

.preset-btn {
    background: transparent;
    border: 1px solid var(--gold-highlight);
    color: var(--gold-highlight);
    padding: 0.4rem 0.6rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
}

.preset-btn:hover {
    background: var(--gold-highlight);
    color: var(--bg-obsidian);
}

.input-group {
    margin-bottom: 0.8rem;
}

input {
    width: 100%;
    padding: 0.7rem;
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    border-radius: 4px;
    box-sizing: border-box;
}

input:focus {
    border-color: var(--teal-accent);
    outline: none;
}

.btn-submit {
    background: var(--teal-accent);
    color: var(--bg-obsidian);
    border: none;
    width: 100%;
    padding: 0.75rem;
    font-weight: bold;
    border-radius: 4px;
    cursor: pointer;
}

.sale-item, .inventory-item, .customer-item {
    display: flex;
    justify-content: space-between;
    padding: 0.6rem 0;
    border-bottom: 1px solid var(--border-color);
}

.sale-item:last-child, .inventory-item:last-child, .customer-item:last-child {
    border-bottom: none;
}

.loading {
    color: var(--text-muted);
    text-align: center;
    font-size: 0.9rem;
}
ECSS

echo "[+] Updating public/app.js with full functionality..."
cat << 'EJS' > public/app.js
function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    
    document.getElementById(`tab-${tabName}`).classList.add('active');
    event.currentTarget.classList.add('active');

    if (tabName === 'sales') fetchSales();
    if (tabName === 'inventory') fetchInventory();
    if (tabName === 'customers') fetchCustomers();
}

function applyPreset(itemName, price) {
    document.getElementById('item').value = itemName;
    document.getElementById('amount').value = price;
}

async function fetchSales() {
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        const listEl = document.getElementById('sales-list');
        
        if (sales.length === 0) {
            listEl.innerHTML = '<p class="loading">No sales recorded.</p>';
            return;
        }

        listEl.innerHTML = sales.map(sale => `
            <div class="sale-item">
                <div>
                    <strong>${escapeHtml(sale.item)}</strong>
                    ${sale.customer ? `<br><small style="color: var(--gold-highlight);">${escapeHtml(sale.customer)}</small>` : ''}
                </div>
                <div style="color: var(--teal-accent); font-family: monospace; font-size: 1.1rem;">$${parseFloat(sale.amount).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching sales:', err);
    }
}

async function fetchInventory() {
    try {
        const res = await fetch('/api/inventory');
        const items = await res.json();
        const listEl = document.getElementById('inventory-list');
        
        if (items.length === 0) {
            listEl.innerHTML = '<p class="loading">No inventory stock added.</p>';
            return;
        }

        listEl.innerHTML = items.map(item => `
            <div class="inventory-item">
                <div>
                    <strong>${escapeHtml(item.name)}</strong>
                    <br><small style="color: var(--text-muted);">Qty: ${item.quantity}</small>
                </div>
                <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(item.price).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching inventory:', err);
    }
}

async function fetchCustomers() {
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        const listEl = document.getElementById('customers-list');
        
        if (customers.length === 0) {
            listEl.innerHTML = '<p class="loading">No customer profiles.</p>';
            return;
        }

        listEl.innerHTML = customers.map(cust => `
            <div class="customer-item">
                <div>
                    <strong>${escapeHtml(cust.name)}</strong>
                    ${cust.notes ? `<br><small style="color: var(--text-muted);">${escapeHtml(cust.notes)}</small>` : ''}
                </div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching customers:', err);
    }
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const item = document.getElementById('item').value;
    const amount = parseFloat(document.getElementById('amount').value);
    const customer = document.getElementById('customer').value;

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ item, amount, customer })
    });

    if (res.ok) {
        document.getElementById('sale-form').reset();
        fetchSales();
    }
});

document.getElementById('inventory-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('inv-name').value;
    const quantity = parseInt(document.getElementById('inv-qty').value);
    const price = parseFloat(document.getElementById('inv-price').value);

    const res = await fetch('/api/inventory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, quantity, price })
    });

    if (res.ok) {
        document.getElementById('inventory-form').reset();
        fetchInventory();
    }
});

document.getElementById('customer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('cust-name').value;
    const notes = document.getElementById('cust-notes').value;

    const res = await fetch('/api/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, notes })
    });

    if (res.ok) {
        document.getElementById('customer-form').reset();
        fetchCustomers();
    }
});

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

fetchSales();
EJS

echo "[+] Application completed successfully."
