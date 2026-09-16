#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Sales Tracker Refinement
# ==============================================================================
set -e

echo "[+] Terminating existing Node processes..."
pkill -f "node server.js" || true
sleep 1

echo "[+] Updating server.js with dedicated weight, description, payment tracking, and date-filtered analytics..."
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
        try {
            const data = db.export();
            const buffer = Buffer.from(data);
            fs.writeFileSync(DB_FILE, buffer);
        } catch (e) {
            console.error('[!] Error saving database to disk:', e.message);
        }
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

    // Initialize Schema: timestamp, name (customer), weight, item, cost (amount), status, payments ledger
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        name TEXT,
        weight TEXT NOT NULL,
        item TEXT NOT NULL,
        cost REAL NOT NULL,
        payment_status TEXT NOT NULL,
        paid_amount REAL NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id)
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
                const row = stmt.getAsObject();
                // Fetch associated payments for this sale
                const pStmt = db.prepare("SELECT * FROM payments WHERE sale_id = ? ORDER BY id ASC");
                pStmt.bind([row.id]);
                const payments = [];
                while (pStmt.step()) {
                    payments.push(pStmt.getAsObject());
                }
                pStmt.free();
                row.payments = payments;
                rows.push(row);
            }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        const { timestamp, name, weight, item, cost, payment_status, paid_amount } = req.body;
        const saleTime = timestamp || new Date().toISOString();
        const pStatus = payment_status || 'paid';
        const initialPaid = pStatus === 'paid' ? parseFloat(cost) : (pStatus === 'unpaid' ? 0 : parseFloat(paid_amount || 0));

        try {
            db.run(`INSERT INTO sales (timestamp, name, weight, item, cost, payment_status, paid_amount) VALUES (?, ?, ?, ?, ?, ?, ?)`, 
                [saleTime, name || '', weight || 'N/A', item || '', parseFloat(cost), pStatus, initialPaid]);
            
            // Get last inserted sale ID
            const idStmt = db.prepare("SELECT last_insert_rowid() as id");
            idStmt.step();
            const saleId = idStmt.getAsObject().id;
            idStmt.free();

            // If any payment was made initially, record it in payments table
            if (initialPaid > 0) {
                db.run(`INSERT INTO payments (sale_id, amount, timestamp) VALUES (?, ?, ?)`, [saleId, initialPaid, saleTime]);
            }

            saveDatabase();
            res.json({ success: true, id: saleId });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Add payment transaction to an existing sale
    app.post('/api/sales/:id/payment', (req, res) => {
        const saleId = req.params.id;
        const { amount } = req.body;
        const paymentTime = new Date().toISOString();
        const payAmount = parseFloat(amount);

        try {
            // Insert payment
            db.run(`INSERT INTO payments (sale_id, amount, timestamp) VALUES (?, ?, ?)`, [saleId, payAmount, paymentTime]);

            // Update total paid and status on sale
            const sStmt = db.prepare("SELECT cost, paid_amount FROM sales WHERE id = ?");
            sStmt.bind([saleId]);
            if (sStmt.step()) {
                const sale = sStmt.getAsObject();
                sStmt.free();

                const newPaid = sale.paid_amount + payAmount;
                let newStatus = 'partial';
                if (newPaid >= sale.cost) {
                    newStatus = 'paid';
                } else if (newPaid <= 0) {
                    newStatus = 'unpaid';
                }

                db.run(`UPDATE sales SET paid_amount = ?, payment_status = ? WHERE id = ?`, [newPaid, newStatus, saleId]);
                saveDatabase();
                res.json({ success: true, new_paid: newPaid, payment_status: newStatus });
            } else {
                sStmt.free();
                res.status(404).json({ error: 'Sale not found' });
            }
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Delete sale
    app.delete('/api/sales/:id', (req, res) => {
        const saleId = req.params.id;
        try {
            db.run(`DELETE FROM payments WHERE sale_id = ?`, [saleId]);
            db.run(`DELETE FROM sales WHERE id = ?`, [saleId]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Analytics with Day, Week, Month, Year Filtering
    app.get('/api/analytics', (req, res) => {
        const filter = req.query.filter || 'all'; // day, week, month, year, all
        let dateCondition = "";
        const now = new Date();

        if (filter === 'day') {
            const todayStr = now.toISOString().split('T')[0];
            dateCondition = `WHERE SUBSTR(timestamp, 1, 10) = '${todayStr}'`;
        } else if (filter === 'week') {
            const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
            dateCondition = `WHERE timestamp >= '${weekAgo}'`;
        } else if (filter === 'month') {
            const monthPrefix = now.toISOString().substring(0, 7); // YYYY-MM
            dateCondition = `WHERE SUBSTR(timestamp, 1, 7) = '${monthPrefix}'`;
        } else if (filter === 'year') {
            const yearPrefix = now.toISOString().substring(0, 4); // YYYY
            dateCondition = `WHERE SUBSTR(timestamp, 1, 4) = '${yearPrefix}'`;
        }

        try {
            const revStmt = db.prepare(`SELECT SUM(cost) as total_revenue, SUM(paid_amount) as total_collected, COUNT(*) as total_count FROM sales ${dateCondition}`);
            revStmt.step();
            const revData = revStmt.getAsObject();
            revStmt.free();

            const custStmt = db.prepare(`SELECT name, SUM(cost) as total_spent, SUM(paid_amount) as total_paid, COUNT(*) as transaction_count FROM sales ${dateCondition} AND name IS NOT NULL AND name != '' GROUP BY name`);
            const perCustomer = [];
            while (custStmt.step()) {
                perCustomer.push(custStmt.getAsObject());
            }
            custStmt.free();

            res.json({
                filter: filter,
                total_revenue: revData.total_revenue || 0,
                total_collected: revData.total_collected || 0,
                total_count: revData.total_count || 0,
                per_customer: perCustomer
            });
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

mkdir -p public

echo "[+] Updating index.html with exact column ordering and payment tracking controls..."
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
            <button class="tab-btn active" onclick="switchTab('sales')">Sales & Ledger</button>
            <button class="tab-btn" onclick="switchTab('inventory')">Inventory</button>
            <button class="tab-btn" onclick="switchTab('customers')">Customers</button>
            <button class="tab-btn" onclick="switchTab('analytics')">Analytics & Filters</button>
        </nav>

        <!-- Sales Tab -->
        <div id="tab-sales" class="tab-content active">
            <section class="form-section">
                <h2>Record Transaction</h2>
                <div class="preset-buttons">
                    <button class="preset-btn" onclick="applyPreset('0.87g', '0.87g - Eighth', 20)">0.87g - $20</button>
                    <button class="preset-btn" onclick="applyPreset('1.75g', '1.75g - Quarter', 40)">1.75g - $40</button>
                    <button class="preset-btn" onclick="applyPreset('3.5g', '3.5g - Half', 80)">3.5g - $80</button>
                    <button class="preset-btn" onclick="applyPreset('7g', '7g - Quarter', 160)">7g - $160</button>
                    <button class="preset-btn" onclick="applyPreset('14g', '14g - Half Oz', 320)">14g - $320</button>
                    <button class="preset-btn" onclick="applyPreset('28g', '28g - Full Oz', 640)">28g - $640</button>
                </div>
                <form id="sale-form">
                    <div class="input-group">
                        <input type="text" id="name" placeholder="Customer Name" required>
                    </div>
                    <div class="input-group">
                        <input type="text" id="weight" placeholder="Weight (e.g. 7g, 3.5g)" required>
                    </div>
                    <div class="input-group">
                        <input type="text" id="item" placeholder="Description / Strain / Item" required>
                    </div>
                    <div class="input-group">
                        <input type="number" id="cost" step="0.01" placeholder="Item Cost ($ CAD)" required>
                    </div>
                    <div class="input-group">
                        <select id="payment-status" onchange="togglePartialInput()">
                            <option value="paid">Paid (In Full)</option>
                            <option value="unpaid">Unpaid</option>
                            <option value="partial">Partial Payment</option>
                        </select>
                    </div>
                    <div class="input-group" id="partial-group" style="display: none;">
                        <input type="number" id="paid-amount" step="0.01" placeholder="Initial Amount Paid ($)">
                    </div>
                    <button type="submit" class="btn-submit">Record Transaction</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Transaction Ledger</h2>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Timestamp</th>
                                <th>Name</th>
                                <th>Weight</th>
                                <th>Description</th>
                                <th>Cost</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="sales-table-body">
                            <tr><td colspan="7" class="loading">Loading ledger...</td></tr>
                        </tbody>
                    </table>
                </div>
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
                        <input type="number" id="inv-qty" step="0.01" placeholder="Quantity" required>
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
            <section class="form-section">
                <h2>Filter Transaction History</h2>
                <div class="filter-buttons">
                    <button class="filter-btn active" onclick="setFilter('all', event)">All Time</button>
                    <button class="filter-btn" onclick="setFilter('day', event)">Today</button>
                    <button class="filter-btn" onclick="setFilter('week', event)">This Week</button>
                    <button class="filter-btn" onclick="setFilter('month', event)">This Month</button>
                    <button class="filter-btn" onclick="setFilter('year', event)">This Year</button>
                </div>
            </section>

            <section class="form-section summary-card">
                <h2>Summary (<span id="filter-label">All Time</span>)</h2>
                <div style="display: flex; justify-content: space-around; text-align: center; margin-top: 1rem;">
                    <div>
                        <small style="color: var(--text-muted);">Total Revenue</small>
                        <div id="analytics-revenue" class="revenue-big" style="font-size: 1.4rem;">$0.00</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Total Collected</small>
                        <div id="analytics-collected" class="revenue-big" style="font-size: 1.4rem; color: var(--gold-highlight);">$0.00</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Transactions</small>
                        <div id="analytics-count" class="revenue-big" style="font-size: 1.4rem; color: var(--teal-accent);">0</div>
                    </div>
                </div>
            </section>

            <section class="list-section">
                <h2>Revenue By Customer</h2>
                <div id="analytics-customers"><p class="loading">Loading analytics...</p></div>
            </section>
        </div>
    </div>

    <!-- Payment Modal -->
    <div id="payment-modal" class="modal" style="display: none;">
        <div class="modal-content">
            <h3>Record Payment</h3>
            <p id="modal-sale-info" style="color: var(--text-muted); font-size: 0.85rem;"></p>
            <form id="payment-form">
                <input type="hidden" id="modal-sale-id">
                <div class="input-group">
                    <input type="number" id="payment-amount" step="0.01" placeholder="Payment Amount ($)" required>
                </div>
                <div style="display: flex; gap: 0.5rem;">
                    <button type="submit" class="btn-submit">Add Payment</button>
                    <button type="button" class="btn-submit" style="background: var(--text-muted);" onclick="closePaymentModal()">Cancel</button>
                </div>
            </form>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
EHTML

echo "[+] Updating app.js frontend controller..."
cat << 'EJS' > public/app.js
let currentFilter = 'all';

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

function applyPreset(weightVal, itemVal, costVal) {
    document.getElementById('weight').value = weightVal;
    document.getElementById('item').value = itemVal;
    document.getElementById('cost').value = costVal;
}

function togglePartialInput() {
    const status = document.getElementById('payment-status').value;
    document.getElementById('partial-group').style.display = status === 'partial' ? 'block' : 'none';
}

async function fetchSales() {
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        const tbodyEl = document.getElementById('sales-table-body');
        
        if (sales.length === 0) {
            tbodyEl.innerHTML = '<tr><td colspan="7" class="loading">No transactions recorded.</td></tr>';
            return;
        }

        tbodyEl.innerHTML = sales.map(sale => {
            const dateStr = new Date(sale.timestamp).toLocaleString();
            let statusBadge = '';
            if (sale.payment_status === 'paid') {
                statusBadge = `<span style="color: var(--teal-accent); font-weight: bold;">PAID ($${parseFloat(sale.paid_amount).toFixed(2)})</span>`;
            } else if (sale.payment_status === 'unpaid') {
                statusBadge = `<span style="color: #ef4444; font-weight: bold;">UNPAID ($0.00 / $${parseFloat(sale.cost).toFixed(2)})</span>`;
            } else {
                statusBadge = `<span style="color: var(--gold-highlight); font-weight: bold;">PARTIAL ($${parseFloat(sale.paid_amount).toFixed(2)} / $${parseFloat(sale.cost).toFixed(2)})</span>`;
            }

            return `
                <tr>
                    <td class="timestamp">${dateStr}</td>
                    <td><strong>${escapeHtml(sale.name)}</strong></td>
                    <td style="font-family: monospace; color: var(--gold-highlight);">${escapeHtml(sale.weight)}</td>
                    <td>${escapeHtml(sale.item)}</td>
                    <td style="font-family: monospace; font-weight: bold;">$${parseFloat(sale.cost).toFixed(2)}</td>
                    <td>
                        ${statusBadge}
                        <br><button class="action-link" onclick="openPaymentModal(${sale.id}, '${escapeHtml(sale.name)}', ${sale.cost}, ${sale.paid_amount})">+ Add Payment</button>
                    </td>
                    <td>
                        <button class="btn-delete" onclick="deleteSale(${sale.id})">Delete</button>
                    </td>
                </tr>
            `;
        }).join('');
    } catch (err) {
        console.error('Error fetching sales:', err);
    }
}

async function deleteSale(id) {
    if (!confirm('Are you sure you want to delete this transaction?')) return;
    const res = await fetch(`/api/sales/${id}`, { method: 'DELETE' });
    if (res.ok) fetchSales();
}

function openPaymentModal(id, name, cost, paid) {
    document.getElementById('modal-sale-id').value = id;
    document.getElementById('modal-sale-info').innerText = `${name} | Total: $${cost.toFixed(2)} | Paid So Far: $${paid.toFixed(2)}`;
    document.getElementById('payment-amount').value = (cost - paid).toFixed(2);
    document.getElementById('payment-modal').style.display = 'flex';
}

function closePaymentModal() {
    document.getElementById('payment-modal').style.display = 'none';
}

document.getElementById('payment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('modal-sale-id').value;
    const amount = document.getElementById('payment-amount').value;

    const res = await fetch(`/api/sales/${id}/payment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount })
    });

    if (res.ok) {
        closePaymentModal();
        fetchSales();
    }
});

function setFilter(filterType, event) {
    currentFilter = filterType;
    document.querySelectorAll('.filter-btn').forEach(el => el.classList.remove('active'));
    event.currentTarget.classList.add('active');

    const labels = { all: 'All Time', day: 'Today', week: 'This Week', month: 'This Month', year: 'This Year' };
    document.getElementById('filter-label').innerText = labels[filterType];
    fetchAnalytics();
}

async function fetchAnalytics() {
    try {
        const res = await fetch(`/api/analytics?filter=${currentFilter}`);
        const data = await res.json();

        document.getElementById('analytics-revenue').innerText = `$${parseFloat(data.total_revenue).toFixed(2)}`;
        document.getElementById('analytics-collected').innerText = `$${parseFloat(data.total_collected).toFixed(2)}`;
        document.getElementById('analytics-count').innerText = data.total_count;

        const custEl = document.getElementById('analytics-customers');
        if (data.per_customer.length === 0) {
            custEl.innerHTML = '<p class="loading">No customer activity for this period.</p>';
        } else {
            custEl.innerHTML = data.per_customer.map(c => `
                <div class="analytics-row" style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
                    <div>
                        <strong>${escapeHtml(c.name)}</strong>
                        <br><small class="timestamp">${c.transaction_count} transaction(s) | Collected: $${parseFloat(c.total_paid).toFixed(2)}</small>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace; font-weight: bold;">$${parseFloat(c.total_spent).toFixed(2)}</div>
                </div>
            `).join('');
        }
    } catch (err) {
        console.error('Error fetching analytics:', err);
    }
}

async function fetchInventory() {
    try {
        const res = await fetch('/api/inventory');
        const items = await res.json();
        const listEl = document.getElementById('inventory-list');
        listEl.innerHTML = items.length === 0 ? '<p class="loading">No inventory stock added.</p>' : items.map(item => `
            <div class="inventory-item" style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
                <div>
                    <strong>${escapeHtml(item.name)}</strong>
                    <br><small style="color: var(--text-muted);">Qty: ${parseFloat(item.quantity).toFixed(2)}</small>
                </div>
                <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(item.price).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) { console.error(err); }
}

async function fetchCustomers() {
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        const listEl = document.getElementById('customers-list');
        listEl.innerHTML = customers.length === 0 ? '<p class="loading">No customer profiles.</p>' : customers.map(cust => `
            <div class="customer-item" style="padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
                <strong>${escapeHtml(cust.name)}</strong>
                ${cust.notes ? `<br><small style="color: var(--text-muted);">${escapeHtml(cust.notes)}</small>` : ''}
            </div>
        `).join('');
    } catch (err) { console.error(err); }
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('name').value;
    const weight = document.getElementById('weight').value;
    const item = document.getElementById('item').value;
    const cost = parseFloat(document.getElementById('cost').value);
    const payment_status = document.getElementById('payment-status').value;
    const paid_amount = document.getElementById('paid-amount').value;
    const timestamp = new Date().toISOString();

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timestamp, name, weight, item, cost, payment_status, paid_amount })
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

echo "[+] Updating styles.css..."
cat << 'ECSS' > public/styles.css
:root {
    --bg-obsidian: #0d1117;
    --card-bg: #161b22;
    --teal-accent: #1a8f91;
    --gold-highlight: #d4af37;
    --text-main: #c9d1d9;
    --text-muted: #8b949e;
    --border-color: #30363d;
}
body { background: var(--bg-obsidian); color: var(--text-main); font-family: sans-serif; margin: 0; padding: 1rem; }
.app-container { max-width: 900px; margin: auto; background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--border-color); }
.tab-nav { display: flex; gap: 0.5rem; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.5rem; flex-wrap: wrap; }
.tab-btn { background: transparent; border: none; color: var(--text-muted); padding: 0.5rem 1rem; cursor: pointer; font-weight: 600; border-radius: 4px; }
.tab-btn.active { background: var(--teal-accent); color: white; }
.tab-content { display: none; }
.tab-content.active { display: block; }
.form-section, .list-section { margin-bottom: 1.5rem; background: rgba(255,255,255,0.02); padding: 1rem; border-radius: 6px; border: 1px solid var(--border-color); }
.input-group { margin-bottom: 0.8rem; }
input, select { width: 100%; padding: 0.7rem; background: var(--bg-obsidian); border: 1px solid var(--border-color); color: var(--text-main); border-radius: 4px; box-sizing: border-box; }
input:focus, select:focus { border-color: var(--teal-accent); outline: none; }
.btn-submit { background: var(--teal-accent); color: white; border: none; padding: 0.7rem 1.2rem; border-radius: 4px; cursor: pointer; font-weight: bold; width: 100%; }
.preset-buttons, .filter-buttons { display: flex; gap: 0.4rem; flex-wrap: wrap; margin-bottom: 0.8rem; }
.preset-btn, .filter-btn { background: var(--bg-obsidian); border: 1px solid var(--border-color); color: var(--gold-highlight); padding: 0.4rem 0.8rem; border-radius: 4px; cursor: pointer; font-size: 0.85rem; }
.filter-btn.active { background: var(--gold-highlight); color: var(--bg-obsidian); font-weight: bold; }
.timestamp { color: var(--text-muted); font-size: 0.8rem; }
.table-responsive { width: 100%; overflow-x: auto; }
.data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 0.9rem; }
.data-table th, .data-table td { padding: 0.7rem; border-bottom: 1px solid var(--border-color); }
.data-table th { color: var(--teal-accent); font-weight: 600; text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.05em; }
.data-table tr:hover { background: rgba(26, 143, 145, 0.05); }
.btn-delete { background: #ef4444; color: white; border: none; padding: 0.3rem 0.6rem; border-radius: 4px; cursor: pointer; font-size: 0.8rem; }
.action-link { background: none; border: none; color: var(--teal-accent); cursor: pointer; padding: 0; font-size: 0.8rem; text-decoration: underline; margin-top: 0.2rem; display: inline-block; }
.modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); display: flex; justify-content: center; align-items: center; z-index: 1000; }
.modal-content { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--border-color); width: 320px; }
ECSS

echo "[+] Starting server..."
node server.js
