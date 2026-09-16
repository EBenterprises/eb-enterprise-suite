#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Customer Tab & Payment Status System
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Updating server.js to support customer balance tracking & payment status..."
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
                newSale.status = newSale.status || 'unpaid'; // 'paid', 'unpaid', 'partial'
                sales.push(newSale);
                fs.writeFileSync(DATA_FILE, JSON.stringify(sales, null, 2));
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(newSale));
            });
            return;
        }
    }

    // Update payment status route
    if (req.method === 'PUT' && req.url.startsWith('/api/sales/')) {
        const id = parseInt(req.url.split('/').pop());
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            const updates = JSON.parse(body);
            let sales = JSON.parse(fs.readFileSync(DATA_FILE));
            sales = sales.map(s => {
                if (s.id === id) {
                    return { ...s, ...updates };
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
    console.log(`\n[EB ENTERPRISES] Server active with Customer Tabs & Status`);
    console.log(`[STATUS] Listening on http://localhost:${PORT}`);
});
JS_EOF

echo "[+] Updating index.html to add Customer Tabs section..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises | Sales & Customer Tabs</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">EB</div>
            <h1>Sales Logistics & Customer Tabs</h1>
            <p>Track revenue, item weights, and individual customer bills/tabs</p>
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
                <h3>Total Sales Count</h3>
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
                </div>
                <button type="submit" class="btn-submit">EXECUTE LOG</button>
            </form>
        </section>

        <!-- Customer-by-Customer Tabs Ledger -->
        <section class="table-section">
            <h2>Customer Tabs & Balances</h2>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Customer Name</th>
                            <th>Total Transactions</th>
                            <th>Total Mass</th>
                            <th>Total Bill</th>
                            <th>Payment Status / Actions</th>
                        </tr>
                    </thead>
                    <tbody id="customerTabsTableBody"></tbody>
                </table>
            </div>
        </section>

        <!-- Complete Transaction History -->
        <section class="table-section">
            <h2>Complete Transaction History</h2>
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
                            <th>Status</th>
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

echo "[+] Updating styles.css for payment badges and selects..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #0d1117;
    --dark-grey: #161b22;
    --border-color: #30363d;
    --deep-teal: #1f6feb;
    --teal-glow: #58a6ff;
    --champagne-gold: #f0b72c;
    --text-main: #ffffff;
    --text-muted: #8b949e;
    --danger: #f85149;
    --danger-hover: #da3633;
    --success: #238636;
    --warning: #9e6a03;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }

body {
    background-color: var(--obsidian);
    color: var(--text-main);
    padding: 20px;
    line-height: 1.5;
}

.container { max-width: 1200px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 30px; border-bottom: 2px solid var(--border-color); padding-bottom: 20px;
}

.logo {
    display: inline-block; width: 50px; height: 50px; line-height: 50px;
    background: var(--deep-teal); color: var(--text-main);
    font-weight: bold; font-size: 1.5rem; border-radius: 6px; margin-bottom: 10px;
}

h1 { color: var(--teal-glow); font-size: 2.2rem; letter-spacing: 1px; }
header p { color: var(--text-muted); font-size: 1rem; }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }
.card { background: var(--dark-grey); padding: 20px; border: 1px solid var(--border-color); border-radius: 8px; border-left: 5px solid var(--deep-teal); }
.card h3 { color: var(--text-muted); font-size: 0.85rem; text-transform: uppercase; margin-bottom: 8px; font-weight: 600; }
.card p { font-size: 1.8rem; font-weight: bold; color: var(--text-main); }

.gold-text { color: var(--champagne-gold) !important; }
.teal-text { color: var(--teal-glow) !important; }

.form-section, .table-section { background: var(--dark-grey); padding: 25px; border: 1px solid var(--border-color); margin-bottom: 30px; border-radius: 8px; }
h2 { color: var(--teal-glow); margin-bottom: 20px; font-size: 1.3rem; }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin-bottom: 20px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.85rem; margin-bottom: 6px; color: var(--text-main); font-weight: 600; }
.form-group input, .form-group select { padding: 12px; background: var(--obsidian); border: 1px solid var(--border-color); color: var(--text-main); font-size: 1rem; border-radius: 6px; }
.form-group input::placeholder { color: #484f58; }
.form-group input:focus, .form-group select:focus { outline: none; border-color: var(--teal-glow); box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.3); }

.btn-submit { width: 100%; padding: 14px; background: var(--deep-teal); color: var(--text-main); border: none; font-weight: bold; font-size: 1rem; cursor: pointer; border-radius: 6px; transition: background 0.2s; }
.btn-submit:hover { background: #388bfd; }

.table-wrapper { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 14px 12px; border-bottom: 1px solid var(--border-color); }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.85rem; background: #21262d; }
td { font-size: 1rem; color: var(--text-main); }

.badge { padding: 4px 8px; border-radius: 4px; font-size: 0.8rem; font-weight: bold; text-transform: uppercase; display: inline-block; }
.badge-paid { background: var(--success); color: white; }
.badge-unpaid { background: var(--danger); color: white; }
.badge-partial { background: var(--warning); color: white; }

select.status-select { padding: 4px 8px; background: var(--obsidian); color: var(--text-main); border: 1px solid var(--border-color); border-radius: 4px; font-size: 0.85rem; }

.btn-delete { background: var(--danger); border: none; color: var(--text-main); padding: 6px 12px; cursor: pointer; border-radius: 4px; font-weight: 600; transition: background 0.2s; }
.btn-delete:hover { background: var(--danger-hover); }
CSS_EOF

echo "[+] Updating app.js to aggregate customer tabs and handle status updates..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const paymentStatusInput = document.getElementById('paymentStatus');

const salesTableBody = document.getElementById('salesTableBody');
const customerTabsTableBody = document.getElementById('customerTabsTableBody');

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
        weightGrams: parseFloat(weightGramsInput.value),
        status: paymentStatusInput.value
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    salesForm.reset();
    quantityInput.value = '1';
    paymentStatusInput.value = 'unpaid';
    fetchAndRender();
});

async function updateStatus(id, newStatus) {
    await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
    });
    fetchAndRender();
}

async function deleteEntry(id) {
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRender();
}

function render(sales) {
    salesTableBody.innerHTML = '';
    customerTabsTableBody.innerHTML = '';
    
    let grandRevenue = 0, grandWeight = 0;
    const customerMap = {};

    // 1. Populate Transaction History & Aggregate Customer Tabs
    if (sales.length === 0) {
        salesTableBody.innerHTML = `<tr><td colspan="10" style="text-align: center; color: var(--text-muted); padding: 20px;">No transactions recorded.</td></tr>`;
        customerTabsTableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 20px;">No active customer tabs.</td></tr>`;
    } else {
        sales.forEach(sale => {
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;
            grandRevenue += rowTotalPrice;
            grandWeight += rowTotalWeight;

            // Aggregate by customer
            const custName = sale.customer || 'N/A';
            if (!customerMap[custName]) {
                customerMap[custName] = {
                    name: custName,
                    txCount: 0,
                    totalMass: 0,
                    totalBill: 0,
                    items: []
                };
            }
            customerMap[custName].txCount += 1;
            customerMap[custName].totalMass += rowTotalWeight;
            customerMap[custName].totalBill += rowTotalPrice;
            customerMap[custName].items.push(sale);

            // Render transaction row
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
                <td>
                    <select class="status-select" onchange="updateStatus(${sale.id}, this.value)">
                        <option value="unpaid" ${sale.status === 'unpaid' ? 'selected' : ''}>Unpaid</option>
                        <option value="partial" ${sale.status === 'partial' ? 'selected' : ''}>Partial</option>
                        <option value="paid" ${sale.status === 'paid' ? 'selected' : ''}>Paid</option>
                    </select>
                </td>
                <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
            `;
            salesTableBody.appendChild(tr);
        });

        // 2. Render Customer-by-Customer Tabs
        Object.values(customerMap).forEach(cust => {
            const tr = document.createElement('tr');
            const unpaidItems = cust.items.filter(i => i.status !== 'paid');
            const statusBadge = unpaidItems.length === 0 
                ? '<span class="badge badge-paid">Fully Paid</span>' 
                : `<span class="badge badge-unpaid">${unpaidItems.length} Unpaid / Partial</span>`;

            tr.innerHTML = `
                <td><strong class="gold-text">${escapeHtml(cust.name)}</strong></td>
                <td>${cust.txCount} transaction(s)</td>
                <td class="teal-text">${cust.totalMass.toFixed(2)} g</td>
                <td class="gold-text">$${cust.totalBill.toFixed(2)}</td>
                <td>${statusBadge}</td>
            `;
            customerTabsTableBody.appendChild(tr);
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

echo "[+] Restarting server..."
node server.js
