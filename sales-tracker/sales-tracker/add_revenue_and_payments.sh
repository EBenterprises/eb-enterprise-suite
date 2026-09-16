#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Total Revenues & Dedicated Payments Dashboard
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Updating server.js across all instances to include revenue metrics and PATCH /api/sales/:id endpoint..."

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    cat << ERS > "$DIR/server.js"
const express = require('express');
const fs = require('fs');
const path = require('path');
const initSqlJs = require('sql.js');

const app = express();
const PORT = $P;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db = null;
const dbPath = path.join(__dirname, 'data', 'sales.db');

async function initDatabase() {
    const dataDir = path.dirname(dbPath);
    if (!fs.existsSync(dataDir)){
        fs.mkdirSync(dataDir, { recursive: true });
    }
    const SQL = await initSqlJs();
    if (fs.existsSync(dbPath)) {
        const filebuffer = fs.readFileSync(dbPath);
        db = new SQL.Database(filebuffer);
    } else {
        db = new SQL.Database();
        db.run(\`
            CREATE TABLE IF NOT EXISTS sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                name TEXT,
                quantity TEXT,
                weight TEXT,
                item TEXT,
                cost REAL,
                payment_status TEXT
            );
        \`);
        saveDatabase();
    }
}

function saveDatabase() {
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(dbPath, buffer);
}

app.get('/api/sales', (req, res) => {
    try {
        const stmt = db.prepare("SELECT * FROM sales ORDER BY timestamp DESC;");
        const results = [];
        while (stmt.step()) {
            results.push(stmt.getAsObject());
        }
        stmt.free();
        res.json(results);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/sales', (req, res) => {
    try {
        const { name, quantity, weight, item, cost, payment_status } = req.body;
        const stmt = db.prepare("INSERT INTO sales (name, quantity, weight, item, cost, payment_status) VALUES (?, ?, ?, ?, ?, ?);");
        stmt.run([name || '', quantity || '', weight || '', item || '', cost || 0, payment_status || 'Paid']);
        stmt.free();
        saveDatabase();
        res.json({ success: true, message: "Transaction logged successfully." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.patch('/api/sales/:id', (req, res) => {
    try {
        const { id } = req.params;
        const { payment_status } = req.body;
        const stmt = db.prepare("UPDATE sales SET payment_status = ? WHERE id = ?;");
        stmt.run([payment_status, id]);
        stmt.free();
        saveDatabase();
        res.json({ success: true, message: "Payment status updated successfully." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

initDatabase().then(() => {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(\`[+] EB Sales Tracker [$V] running on http://localhost:\${PORT}\`);
    });
});
ERS

    # Update frontend index.html with Revenue Metrics Cards and Payments Tab/View
    PUBLIC_DIR="$DIR/public"
    mkdir -p "$PUBLIC_DIR"
    
    cat << 'HTML' > "$PUBLIC_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales Tracker & Revenue Platform</title>
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: #111827;
            --text-color: #f3f4f6;
            --accent-teal: #0d9488;
            --accent-gold: #fbbf24;
            --border-color: #1f2937;
            --danger-color: #ef4444;
            --success-color: #10b981;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1100px;
            margin: 0 auto;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid var(--accent-teal);
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        h1 {
            color: var(--accent-gold);
            margin: 0;
            font-size: 1.6rem;
        }
        .nav-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .tab-btn {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            color: var(--text-color);
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
        }
        .tab-btn.active {
            background-color: var(--accent-teal);
            border-color: var(--accent-teal);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 15px;
            margin-bottom: 25px;
        }
        .metric-card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 15px 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        .metric-card h4 {
            margin: 0 0 8px 0;
            font-size: 0.85rem;
            color: #9ca3af;
            text-transform: uppercase;
        }
        .metric-value {
            font-size: 1.5rem;
            font-weight: bold;
            color: var(--accent-gold);
            margin: 0;
        }
        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        .card h3 {
            margin-top: 0;
            color: var(--accent-gold);
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 10px;
        }
        form {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        .form-group {
            display: flex;
            flex-direction: column;
        }
        .form-group.full {
            grid-column: span 2;
        }
        label {
            font-size: 0.85rem;
            color: #9ca3af;
            margin-bottom: 5px;
            font-weight: 500;
        }
        input, select {
            background-color: #1f2937;
            border: 1px solid #374151;
            color: var(--text-color);
            padding: 10px;
            border-radius: 6px;
            font-size: 1rem;
        }
        input:focus, select:focus {
            outline: none;
            border-color: var(--accent-teal);
        }
        .cta-row {
            grid-column: span 2;
            display: flex;
            gap: 10px;
            margin-top: 5px;
        }
        button.cta-btn {
            flex: 1;
            background: linear-gradient(135deg, var(--accent-teal), #0f766e);
            color: white;
            border: none;
            padding: 12px;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        button.cta-btn:hover {
            opacity: 0.9;
        }
        button.secondary-btn {
            background-color: #374151;
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 6px;
            font-size: 1rem;
            cursor: pointer;
        }
        button.secondary-btn:hover {
            background-color: #4b5563;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.9rem;
        }
        th {
            color: var(--accent-gold);
            background-color: rgba(17, 24, 39, 0.5);
        }
        .status-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: bold;
        }
        .status-paid { background-color: rgba(16, 185, 129, 0.2); color: var(--success-color); }
        .status-pending { background-color: rgba(251, 191, 36, 0.2); color: var(--accent-gold); }
        .status-credit { background-color: rgba(239, 68, 68, 0.2); color: var(--danger-color); }
        .action-btn {
            background-color: #1f2937;
            border: 1px solid #374151;
            color: var(--text-color);
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.8rem;
        }
        .action-btn:hover {
            border-color: var(--accent-teal);
        }
        .view-section {
            display: none;
        }
        .view-section.active {
            display: block;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>EB Sales & Payments Tracker</h1>
            <span style="color: var(--accent-teal); font-weight: bold;">Executive Spectrum • Revenue Engine</span>
        </header>

        <div class="nav-tabs">
            <button class="tab-btn active" onclick="switchView('tracker')">Sales & Ledger</button>
            <button class="tab-btn" onclick="switchView('payments')">Payments Hub</button>
        </div>

        <div class="metrics-grid">
            <div class="metric-card">
                <h4>Total Revenue (Paid)</h4>
                <p class="metric-value" id="metricTotalRevenue">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Pending Payments</h4>
                <p class="metric-value" id="metricPendingAmount" style="color: var(--accent-gold);">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Credit / Outstanding</h4>
                <p class="metric-value" id="metricCreditAmount" style="color: var(--danger-color);">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Total Transactions</h4>
                <p class="metric-value" id="metricTotalCount" style="color: var(--text-color);">0</p>
            </div>
        </div>

        <!-- TRACKER VIEW -->
        <div id="view-tracker" class="view-section active">
            <div class="card">
                <h3>Log Transaction & Payment</h3>
                <form id="saleForm">
                    <div class="form-group">
                        <label for="name">Client Name</label>
                        <input type="text" id="name" required placeholder="Enter client name">
                    </div>
                    <div class="form-group">
                        <label for="item">Item / Product</label>
                        <input type="text" id="item" required placeholder="Product description">
                    </div>
                    <div class="form-group">
                        <label for="quantity">Quantity</label>
                        <input type="text" id="quantity" required value="1">
                    </div>
                    <div class="form-group">
                        <label for="weight">Weight / Tier</label>
                        <input type="text" id="weight" required placeholder="e.g., 7g / 14g / Unit">
                    </div>
                    <div class="form-group">
                        <label for="cost">Cost ($)</label>
                        <input type="number" step="0.01" id="cost" required placeholder="0.00">
                    </div>
                    <div class="form-group">
                        <label for="payment_status">Payment Status</label>
                        <select id="payment_status">
                            <option value="Paid">Paid</option>
                            <option value="Pending">Pending</option>
                            <option value="Credit">Credit</option>
                        </select>
                    </div>
                    <div class="cta-row">
                        <button type="submit" class="cta-btn" id="submitBtn">Add Transaction & Process Payment</button>
                        <button type="button" class="secondary-btn" onclick="document.getElementById('saleForm').reset(); document.getElementById('quantity').value='1';">Reset</button>
                    </div>
                </form>
            </div>

            <div class="card">
                <h3>Complete Transaction History</h3>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Timestamp</th>
                            <th>Name</th>
                            <th>Item</th>
                            <th>Qty</th>
                            <th>Weight</th>
                            <th>Cost</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="salesTableBody">
                        <tr><td colspan="9" style="text-align: center; color: #9ca3af;">Loading transactions...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- PAYMENTS VIEW -->
        <div id="view-payments" class="view-section">
            <div class="card">
                <h3>Payments & Receivables Ledger</h3>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Timestamp</th>
                            <th>Client</th>
                            <th>Item</th>
                            <th>Amount Due</th>
                            <th>Status</th>
                            <th>Action / Settlement</th>
                        </tr>
                    </thead>
                    <tbody id="paymentsTableBody">
                        <tr><td colspan="7" style="text-align: center; color: #9ca3af;">Loading payments...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        let cachedSales = [];

        function switchView(viewName) {
            document.querySelectorAll('.view-section').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
            if (viewName === 'tracker') {
                document.getElementById('view-tracker').classList.add('active');
                document.querySelectorAll('.tab-btn')[0].classList.add('active');
            } else {
                document.getElementById('view-payments').classList.add('active');
                document.querySelectorAll('.tab-btn')[1].classList.add('active');
            }
        }

        async function fetchSales() {
            try {
                const res = await fetch('/api/sales');
                cachedSales = await res.json();
                renderAll();
            } catch (err) {
                console.error('Failed to fetch sales:', err);
            }
        }

        function renderAll() {
            const tbody = document.getElementById('salesTableBody');
            const pbody = document.getElementById('paymentsTableBody');
            tbody.innerHTML = '';
            pbody.innerHTML = '';

            if (!cachedSales || cachedSales.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align: center; color: #9ca3af;">No transaction records found.</td></tr>';
                pbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: #9ca3af;">No payment records found.</td></tr>';
                updateMetrics(0, 0, 0, 0);
                return;
            }

            let totalPaid = 0;
            let totalPending = 0;
            let totalCredit = 0;

            cachedSales.forEach(row => {
                const cost = parseFloat(row.cost || 0);
                const status = row.payment_status || 'Paid';
                if (status === 'Paid') totalPaid += cost;
                else if (status === 'Pending') totalPending += cost;
                else if (status === 'Credit') totalCredit += cost;

                const statusClass = status === 'Paid' ? 'status-paid' : (status === 'Pending' ? 'status-pending' : 'status-credit');

                // Render Sales Table Row
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>#${row.id || ''}</td>
                    <td>${row.timestamp || ''}</td>
                    <td>${row.name || ''}</td>
                    <td>${row.item || ''}</td>
                    <td>${row.quantity || ''}</td>
                    <td>${row.weight || ''}</td>
                    <td style="color: var(--accent-gold); font-weight: bold;">$\${cost.toFixed(2)}</td>
                    <td><span class="status-badge \${statusClass}">\${status}</span></td>
                    <td>
                        <button class="action-btn" onclick="togglePaymentStatus(\${row.id}, '\${status}')">Toggle Status</button>
                    </td>
                `;
                tbody.appendChild(tr);

                // Render Payments Table Row
                const ptr = document.createElement('tr');
                ptr.innerHTML = `
                    <td>#${row.id || ''}</td>
                    <td>${row.timestamp || ''}</td>
                    <td>${row.name || ''}</td>
                    <td>${row.item || ''}</td>
                    <td style="color: var(--accent-gold); font-weight: bold;">$\${cost.toFixed(2)}</td>
                    <td><span class="status-badge \${statusClass}">\${status}</span></td>
                    <td>
                        <button class="action-btn" style="background-color: #0d9488; color: white;" onclick="setPaymentStatus(\${row.id}, 'Paid')">Mark Paid</button>
                        <button class="action-btn" onclick="setPaymentStatus(\${row.id}, 'Pending')">Pending</button>
                        <button class="action-btn" style="background-color: #ef4444; color: white;" onclick="setPaymentStatus(\${row.id}, 'Credit')">Credit</button>
                    </td>
                `;
                pbody.appendChild(ptr);
            });

            updateMetrics(totalPaid, totalPending, totalCredit, cachedSales.length);
        }

        function updateMetrics(paid, pending, credit, count) {
            document.getElementById('metricTotalRevenue').textContent = '$' + paid.toFixed(2);
            document.getElementById('metricPendingAmount').textContent = '$' + pending.toFixed(2);
            document.getElementById('metricCreditAmount').textContent = '$' + credit.toFixed(2);
            document.getElementById('metricTotalCount').textContent = count;
        }

        async function togglePaymentStatus(id, currentStatus) {
            const nextStatus = currentStatus === 'Paid' ? 'Pending' : (currentStatus === 'Pending' ? 'Credit' : 'Paid');
            await setPaymentStatus(id, nextStatus);
        }

        async function setPaymentStatus(id, newStatus) {
            try {
                const res = await fetch('/api/sales/' + id, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ payment_status: newStatus })
                });
                if (res.ok) {
                    await fetchSales();
                } else {
                    alert('Failed to update payment status.');
                }
            } catch (err) {
                console.error('Error updating status:', err);
            }
        }

        document.getElementById('saleForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('submitBtn');
            btn.disabled = true;
            btn.textContent = 'Processing Payment...';

            const payload = {
                name: document.getElementById('name').value,
                item: document.getElementById('item').value,
                quantity: document.getElementById('quantity').value,
                weight: document.getElementById('weight').value,
                cost: parseFloat(document.getElementById('cost').value),
                payment_status: document.getElementById('payment_status').value
            };

            try {
                const res = await fetch('/api/sales', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const result = await res.json();
                if (res.ok) {
                    document.getElementById('saleForm').reset();
                    document.getElementById('quantity').value = '1';
                    await fetchSales();
                } else {
                    alert('Error: ' + (result.error || 'Failed to save transaction'));
                }
            } catch (err) {
                alert('Network error while saving transaction.');
                console.error(err);
            } finally {
                btn.disabled = false;
                btn.textContent = 'Add Transaction & Process Payment';
            }
        });

        // Initial load
        fetchSales();
    </script>
</body>
</html>
HTML
    echo "    -> Updated instance $V with total revenues metrics and dedicated payments hub."
done

echo "[+] Restarting all server instances..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Restarted $V on port $P"
    fi
done

echo "[+] Total revenue analytics and dedicated Payments Hub successfully restored across all instances."
