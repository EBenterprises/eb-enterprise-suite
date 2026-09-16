#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Payment Status & Partial Tracking Upgrade
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Updating server.js to support payment status (paid, unpaid, partial) and paid amounts..."
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

    // Initialize Schema with payment status and paid amount
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        customer TEXT,
        payment_status TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        created_at TEXT NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
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

    app.get('/api/analytics', (req, res) => {
        try {
            const revStmt = db.prepare("SELECT SUM(amount) as total_revenue, SUM(paid_amount) as total_collected FROM sales");
            revStmt.step();
            const revData = revStmt.getAsObject();
            const totalRev = revData.total_revenue || 0;
            const totalCollected = revData.total_collected || 0;
            revStmt.free();

            const custStmt = db.prepare("SELECT customer, SUM(amount) as total_spent, SUM(paid_amount) as total_paid, COUNT(*) as transaction_count FROM sales WHERE customer IS NOT NULL AND customer != '' GROUP BY customer");
            const perCustomer = [];
            while (custStmt.step()) {
                perCustomer.push(custStmt.getAsObject());
            }
            custStmt.free();

            const dayStmt = db.prepare("SELECT SUBSTR(created_at, 1, 10) as sale_date, SUM(amount) as daily_total, SUM(paid_amount) as daily_collected, COUNT(*) as daily_count FROM sales GROUP BY SUBSTR(created_at, 1, 10) ORDER BY sale_date DESC");
            const dayByDay = [];
            while (dayStmt.step()) {
                dayByDay.push(dayStmt.getAsObject());
            }
            dayStmt.free();

            res.json({
                total_revenue: totalRev,
                total_collected: totalCollected,
                per_customer: perCustomer,
                day_by_day: dayByDay
            });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        const { item, amount, customer, payment_status, paid_amount, timestamp } = req.body;
        const saleTime = timestamp || new Date().toLocaleString();
        const pStatus = payment_status || 'paid';
        const pAmount = pStatus === 'paid' ? amount : (pStatus === 'unpaid' ? 0 : parseFloat(paid_amount || 0));

        try {
            db.run(`INSERT INTO sales (item, amount, customer, payment_status, paid_amount, created_at) VALUES (?, ?, ?, ?, ?, ?)`, 
                [item, parseFloat(amount), customer || '', pStatus, pAmount, saleTime]);
            saveDatabase();
            res.json({ success: true });
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
            db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, parseFloat(quantity), parseFloat(price)]);
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

    app.listen(PORT, () => {
        console.log(`[+] EB Sales Tracker running live on port ${PORT}.`);
    });
});
EJS

echo "[+] Updating index.html with payment status dropdown and conditional partial amount field..."
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
            <button class="tab-btn" onclick="switchTab('analytics')">Analytics</button>
        </nav>

        <!-- Sales Tab -->
        <div id="tab-sales" class="tab-content active">
            <section class="form-section">
                <h2>Record Transaction</h2>
                <div class="preset-buttons">
                    <button class="preset-btn" onclick="applyPreset('0.87g', 20)">0.87g - $20</button>
                    <button class="preset-btn" onclick="applyPreset('1.75g', 40)">1.75g - $40</button>
                    <button class="preset-btn" onclick="applyPreset('3.5g', 80)">3.5g - $80</button>
                    <button class="preset-btn" onclick="applyPreset('7g', 160)">7g - $160</button>
                    <button class="preset-btn" onclick="applyPreset('14g', 320)">14g - $320</button>
                    <button class="preset-btn" onclick="applyPreset('28g', 640)">28g - $640</button>
                </div>
                <form id="sale-form">
                    <div class="input-group">
                        <input type="text" id="item" placeholder="Item / Strain / Description" required>
                    </div>
                    <div class="input-group">
                        <input type="number" id="amount" step="0.01" placeholder="Amount ($ CAD)" required>
                    </div>
                    <div class="input-group">
                        <input type="text" id="customer" placeholder="Customer Name / Notes">
                    </div>
                    <div class="input-group">
                        <select id="payment-status" onchange="togglePartialInput()">
                            <option value="paid">Paid (In Full)</option>
                            <option value="unpaid">Unpaid</option>
                            <option value="partial">Partial Payment</option>
                        </select>
                    </div>
                    <div class="input-group" id="partial-group" style="display: none;">
                        <input type="number" id="paid-amount" step="0.01" placeholder="Amount Paid So Far ($)">
                    </div>
                    <button type="submit" class="btn-submit">Record Sale</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Recent Transactions & Timestamps</h2>
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
                        <input type="number" id="inv-qty" step="0.01" placeholder="Quantity (supports decimals e.g. 0.01)" required>
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

        <!-- Analytics Tab -->
        <div id="tab-analytics" class="tab-content">
            <section class="form-section summary-card">
                <h2>Revenue & Collected</h2>
                <div style="display: flex; justify-content: space-around; text-align: center;">
                    <div>
                        <small style="color: var(--text-muted);">Total Value</small>
                        <div id="total-revenue-display" class="revenue-big" style="font-size: 1.5rem;">$0.00</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Collected</small>
                        <div id="total-collected-display" class="revenue-big" style="font-size: 1.5rem; color: var(--gold-highlight);">$0.00</div>
                    </div>
                </div>
            </section>

            <section class="list-section">
                <h2>Totals Per Person</h2>
                <div id="per-customer-list"><p class="loading">Loading customer totals...</p></div>
            </section>

            <section class="list-section">
                <h2>Day-by-Day Sales History</h2>
                <div id="day-history-list"><p class="loading">Loading daily history...</p></div>
            </section>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
EHTML

echo "[+] Updating app.js frontend controller for payment status..."
cat << 'EJS' > public/app.js
function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    
    document.getElementById(`tab-${tabName}`).classList.add('active');
    event.currentTarget.classList.add('active');

    if (tabName === 'sales') fetchSales();
    if (tabName === 'inventory') fetchInventory();
    if (tabName === 'customers') fetchCustomers();
    if (tabName === 'analytics') fetchAnalytics();
}

function applyPreset(itemName, price) {
    document.getElementById('item').value = itemName;
    document.getElementById('amount').value = price;
}

function togglePartialInput() {
    const status = document.getElementById('payment-status').value;
    const partialGroup = document.getElementById('partial-group');
    partialGroup.style.display = status === 'partial' ? 'block' : 'none';
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

        listEl.innerHTML = sales.map(sale => {
            let statusBadge = '';
            if (sale.payment_status === 'paid') {
                statusBadge = '<span style="color: var(--teal-accent); font-size: 0.8rem;">[PAID]</span>';
            } else if (sale.payment_status === 'unpaid') {
                statusBadge = '<span style="color: #ef4444; font-size: 0.8rem;">[UNPAID]</span>';
            } else {
                statusBadge = `<span style="color: var(--gold-highlight); font-size: 0.8rem;">[PARTIAL: $${parseFloat(sale.paid_amount).toFixed(2)}]</span>`;
            }

            return `
                <div class="sale-item">
                    <div>
                        <strong>${escapeHtml(sale.item)}</strong> ${statusBadge}
                        ${sale.customer ? `<br><small style="color: var(--gold-highlight);">${escapeHtml(sale.customer)}</small>` : ''}
                        <br><span class="timestamp">${sale.created_at || 'Just now'}</span>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace; font-size: 1.1rem;">$${parseFloat(sale.amount).toFixed(2)}</div>
                </div>
            `;
        }).join('');
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
                    <br><small style="color: var(--text-muted);">Qty: ${parseFloat(item.quantity).toFixed(2)}</small>
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

async function fetchAnalytics() {
    try {
        const res = await fetch('/api/analytics');
        const data = await res.json();

        document.getElementById('total-revenue-display').innerText = `$${parseFloat(data.total_revenue).toFixed(2)}`;
        document.getElementById('total-collected-display').innerText = `$${parseFloat(data.total_collected).toFixed(2)}`;

        const custEl = document.getElementById('per-customer-list');
        if (data.per_customer.length === 0) {
            custEl.innerHTML = '<p class="loading">No customer sales recorded.</p>';
        } else {
            custEl.innerHTML = data.per_customer.map(c => `
                <div class="analytics-row">
                    <div>
                        <strong>${escapeHtml(c.customer)}</strong>
                        <br><small class="timestamp">${c.transaction_count} transaction(s) | Paid: $${parseFloat(c.total_paid).toFixed(2)}</small>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace;">$${parseFloat(c.total_spent).toFixed(2)}</div>
                </div>
            `).join('');
        }

        const dayEl = document.getElementById('day-history-list');
        if (data.day_by_day.length === 0) {
            dayEl.innerHTML = '<p class="loading">No daily history available.</p>';
        } else {
            dayEl.innerHTML = data.day_by_day.map(d => `
                <div class="analytics-row">
                    <div>
                        <strong>${d.sale_date}</strong>
                        <br><small class="timestamp">${d.daily_count} sale(s) | Collected: $${parseFloat(d.daily_collected).toFixed(2)}</small>
                    </div>
                    <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(d.daily_total).toFixed(2)}</div>
                </div>
            `).join('');
        }
    } catch (err) {
        console.error('Error fetching analytics:', err);
    }
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const item = document.getElementById('item').value;
    const amount = parseFloat(document.getElementById('amount').value);
    const customer = document.getElementById('customer').value;
    const payment_status = document.getElementById('payment-status').value;
    const paid_amount = document.getElementById('paid-amount').value;
    const timestamp = new Date().toLocaleString();

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ item, amount, customer, payment_status, paid_amount, timestamp })
    });

    if (res.ok) {
        document.getElementById('sale-form').reset();
        document.getElementById('partial-group').style.display = 'none';
        fetchSales();
    }
});

document.getElementById('inventory-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('inv-name').value;
    const quantity = parseFloat(document.getElementById('inv-qty').value);
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

echo "[+] Updating styles.css for select dropdowns..."
cat << 'ECSS' >> public/styles.css

select {
    width: 100%;
    padding: 0.7rem;
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    border-radius: 4px;
    box-sizing: border-box;
}

select:focus {
    border-color: var(--teal-accent);
    outline: none;
}
ECSS

echo "[+] Payment status update applied successfully. Restarting server..."
fuser -k 3000/tcp || true
node server.js
