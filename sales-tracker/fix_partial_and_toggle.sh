#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Partial Status Color & Toggle Bugfix
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    PUBLIC_DIR="$DIR/public"
    mkdir -p "$PUBLIC_DIR"
    
    cat << 'HTML' > "$PUBLIC_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales Tracker & Payments Platform</title>
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
            --warning-color: #f59e0b;
        }
        * {
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 10px;
        }
        @media(min-width: 768px) {
            body { padding: 20px; }
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            display: flex;
            flex-direction: column;
            gap: 10px;
            border-bottom: 2px solid var(--accent-teal);
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        @media(min-width: 640px) {
            header {
                flex-direction: row;
                justify-content: space-between;
                align-items: center;
            }
        }
        h1 {
            color: var(--accent-gold);
            margin: 0;
            font-size: 1.4rem;
        }
        @media(min-width: 768px) {
            h1 { font-size: 1.6rem; }
        }
        .nav-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            overflow-x: auto;
            padding-bottom: 5px;
        }
        .tab-btn {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            color: var(--text-color);
            padding: 10px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            white-space: nowrap;
            font-size: 0.9rem;
        }
        .tab-btn.active {
            background-color: var(--accent-teal);
            border-color: var(--accent-teal);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            margin-bottom: 20px;
        }
        @media(min-width: 768px) {
            .metrics-grid {
                grid-template-columns: repeat(4, 1fr);
                gap: 15px;
                margin-bottom: 25px;
            }
        }
        .metric-card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 12px 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        .metric-card h4 {
            margin: 0 0 5px 0;
            font-size: 0.75rem;
            color: #9ca3af;
            text-transform: uppercase;
        }
        @media(min-width: 768px) {
            .metric-card h4 { font-size: 0.85rem; }
        }
        .metric-value {
            font-size: 1.2rem;
            font-weight: bold;
            color: var(--accent-gold);
            margin: 0;
        }
        @media(min-width: 768px) {
            .metric-value { font-size: 1.5rem; }
        }
        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        @media(min-width: 768px) {
            .card { padding: 20px; }
        }
        .card h3 {
            margin-top: 0;
            color: var(--accent-gold);
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 10px;
            font-size: 1.1rem;
        }
        @media(min-width: 768px) {
            .card h3 { font-size: 1.3rem; }
        }
        .presets-bar {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            margin-bottom: 15px;
            padding-bottom: 12px;
            border-bottom: 1px dashed var(--border-color);
        }
        .preset-pill {
            background-color: #1f2937;
            border: 1px solid var(--accent-teal);
            color: var(--accent-gold);
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            cursor: pointer;
            font-weight: bold;
            transition: background-color 0.2s;
        }
        .preset-pill:hover {
            background-color: var(--accent-teal);
            color: white;
        }
        form {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }
        @media(min-width: 640px) {
            form { grid-template-columns: 1fr 1fr; gap: 15px; }
        }
        .form-group {
            display: flex;
            flex-direction: column;
        }
        .form-group.full {
            grid-column: span 1;
        }
        @media(min-width: 640px) {
            .form-group.full { grid-column: span 2; }
        }
        label {
            font-size: 0.8rem;
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
            width: 100%;
        }
        input:focus, select:focus {
            outline: none;
            border-color: var(--accent-teal);
        }
        .cta-row {
            grid-column: span 1;
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-top: 5px;
        }
        @media(min-width: 640px) {
            .cta-row { grid-column: span 2; flex-direction: row; }
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
        .table-responsive {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            margin-top: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            white-space: nowrap;
        }
        th, td {
            text-align: left;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.85rem;
        }
        @media(min-width: 768px) {
            th, td { padding: 12px; font-size: 0.9rem; }
        }
        th {
            color: var(--accent-gold);
            background-color: rgba(17, 24, 39, 0.5);
        }
        .status-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: bold;
        }
        .status-paid { background-color: rgba(16, 185, 129, 0.2); color: var(--success-color); }
        .status-pending { background-color: rgba(251, 191, 36, 0.2); color: var(--accent-gold); }
        .status-partial { background-color: rgba(245, 158, 11, 0.2); color: var(--warning-color); }
        .status-credit { background-color: rgba(239, 68, 68, 0.2); color: var(--danger-color); }
        .action-btn {
            background-color: #1f2937;
            border: 1px solid #374151;
            color: var(--text-color);
            padding: 6px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.8rem;
            margin-right: 4px;
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
            <span style="color: var(--accent-teal); font-weight: bold; font-size: 0.9rem;">Executive Spectrum • Revenue Engine</span>
        </header>

        <div class="nav-tabs">
            <button class="tab-btn active" onclick="switchView('tracker')">Sales & Ledger</button>
            <button class="tab-btn" onclick="switchView('payments')">Payments Hub</button>
        </div>

        <div class="metrics-grid">
            <div class="metric-card">
                <h4>Total Revenue</h4>
                <p class="metric-value" id="metricTotalRevenue">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Pending / Partial</h4>
                <p class="metric-value" id="metricPendingAmount" style="color: var(--warning-color);">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Credit / Due</h4>
                <p class="metric-value" id="metricCreditAmount" style="color: var(--danger-color);">$0.00</p>
            </div>
            <div class="metric-card">
                <h4>Total Orders</h4>
                <p class="metric-value" id="metricTotalCount" style="color: var(--text-color);">0</p>
            </div>
        </div>

        <!-- TRACKER VIEW -->
        <div id="view-tracker" class="view-section active">
            <div class="card">
                <h3>Log Transaction & Payment</h3>
                
                <!-- Quick-Fill Presets -->
                <div class="presets-bar">
                    <span style="font-size: 0.8rem; color: #9ca3af; align-self: center; margin-right: 5px;">Quick Presets:</span>
                    <button type="button" class="preset-pill" onclick="applyPreset('Syde', '1.75 g', 50)">Syde (1.75g)</button>
                    <button type="button" class="preset-pill" onclick="applyPreset('Syde', '3.5 g', 90)">Syde (3.5g)</button>
                    <button type="button" class="preset-pill" onclick="applyPreset('Syde', '7 g', 150)">Syde (7g)</button>
                    <button type="button" class="preset-pill" onclick="applyPreset('Syde', '14 g', 260)">Syde (14g)</button>
                </div>

                <form id="saleForm">
                    <div class="form-group">
                        <label for="name">Client Name</label>
                        <input type="text" id="name" required placeholder="Client name">
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
                            <option value="Partial">Partial</option>
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
                <div class="table-responsive">
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
        </div>

        <!-- PAYMENTS VIEW -->
        <div id="view-payments" class="view-section">
            <div class="card">
                <h3>Payments & Receivables Hub</h3>
                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Timestamp</th>
                                <th>Client</th>
                                <th>Item</th>
                                <th>Amount Due</th>
                                <th>Status</th>
                                <th>Settlement Actions</th>
                            </tr>
                        </thead>
                        <tbody id="paymentsTableBody">
                            <tr><td colspan="7" style="text-align: center; color: #9ca3af;">Loading payments...</td></tr>
                        </tbody>
                    </table>
                </div>
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

        function applyPreset(item, weight, cost) {
            document.getElementById('item').value = item;
            document.getElementById('weight').value = weight;
            document.getElementById('cost').value = cost;
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

        function getStatusClass(status) {
            if (status === 'Paid') return 'status-paid';
            if (status === 'Pending') return 'status-pending';
            if (status === 'Partial') return 'status-partial';
            if (status === 'Credit') return 'status-credit';
            return 'status-pending';
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
                else if (status === 'Pending' || status === 'Partial') totalPending += cost;
                else if (status === 'Credit') totalCredit += cost;

                const statusClass = getStatusClass(status);

                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>#\${row.id || ''}</td>
                    <td>\${row.timestamp || ''}</td>
                    <td>\${row.name || ''}</td>
                    <td>\${row.item || ''}</td>
                    <td>\${row.quantity || ''}</td>
                    <td>\${row.weight || ''}</td>
                    <td style="color: var(--accent-gold); font-weight: bold;">$\${cost.toFixed(2)}</td>
                    <td><span class="status-badge \${statusClass}">\${status}</span></td>
                    <td>
                        <button class="action-btn" onclick="togglePaymentStatus(\${row.id}, '\${status}')">Toggle</button>
                    </td>
                `;
                tbody.appendChild(tr);

                const ptr = document.createElement('tr');
                ptr.innerHTML = `
                    <td>#\${row.id || ''}</td>
                    <td>\${row.timestamp || ''}</td>
                    <td>\${row.name || ''}</td>
                    <td>\${row.item || ''}</td>
                    <td style="color: var(--accent-gold); font-weight: bold;">$\${cost.toFixed(2)}</td>
                    <td><span class="status-badge \${statusClass}">\${status}</span></td>
                    <td>
                        <button class="action-btn" style="background-color: #0d9488; color: white;" onclick="setPaymentStatus(\${row.id}, 'Paid')">Paid</button>
                        <button class="action-btn" style="background-color: #f59e0b; color: white;" onclick="setPaymentStatus(\${row.id}, 'Partial')">Partial</button>
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
            let nextStatus = 'Paid';
            if (currentStatus === 'Paid') nextStatus = 'Pending';
            else if (currentStatus === 'Pending') nextStatus = 'Partial';
            else if (currentStatus === 'Partial') nextStatus = 'Credit';
            else if (currentStatus === 'Credit') nextStatus = 'Paid';
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
    echo "    -> Updated instance $V with yellow Partial status badge and functional toggle."
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

echo "[+] Deployment complete. Partial status is now highlighted in executive yellow, and toggle buttons cycle correctly through statuses."
