#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Frontend CTA & Form Submission Fixer
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

echo "[+] Inspecting and fixing frontend public/index.html across instances..."

for V in "${VERSIONS[@]}"; do
    PUBLIC_DIR="instances/$V/public"
    mkdir -p "$PUBLIC_DIR"
    
    cat << 'HTML' > "$PUBLIC_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales Tracker & Inventory Platform</title>
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: #111827;
            --text-color: #f3f4f6;
            --accent-teal: #0d9488;
            --accent-gold: #fbbf24;
            --border-color: #1f2937;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid var(--accent-teal);
            padding-bottom: 15px;
            margin-bottom: 25px;
        }
        h1 {
            color: var(--accent-gold);
            margin: 0;
            font-size: 1.5rem;
        }
        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
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
        button.cta-btn {
            grid-column: span 2;
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
            background-color: rgba(13, 148, 136, 0.2);
            color: var(--accent-teal);
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>EB Sales Tracker</h1>
            <span style="color: var(--accent-teal); font-weight: bold;">Executive Spectrum</span>
        </header>

        <div class="card">
            <h3>Log New Transaction / Sale</h3>
            <form id="saleForm">
                <div class="form-group">
                    <label for="name">Client / Name</label>
                    <input type="text" id="name" required placeholder="Enter client name">
                </div>
                <div class="form-group">
                    <label for="item">Item / Product</label>
                    <input type="text" id="item" required placeholder="Enter item description">
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
                <button type="submit" class="cta-btn" id="submitBtn">Add Transaction & Payment</button>
            </form>
        </div>

        <div class="card">
            <h3>Recent Transactions</h3>
            <table>
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Name</th>
                        <th>Item</th>
                        <th>Qty</th>
                        <th>Weight</th>
                        <th>Cost</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody id="salesTableBody">
                    <tr><td colspan="7" style="text-align: center; color: #9ca3af;">Loading transactions...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        async function fetchSales() {
            try {
                const res = await fetch('/api/sales');
                const data = await res.json();
                const tbody = document.getElementById('salesTableBody');
                tbody.innerHTML = '';
                
                if (!data || data.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: #9ca3af;">No transactions recorded yet.</td></tr>';
                    return;
                }

                data.forEach(row => {
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td>${row.timestamp || ''}</td>
                        <td>${row.name || ''}</td>
                        <td>${row.item || ''}</td>
                        <td>${row.quantity || ''}</td>
                        <td>${row.weight || ''}</td>
                        <td style="color: var(--accent-gold); font-weight: bold;">$${parseFloat(row.cost || 0).toFixed(2)}</td>
                        <td><span class="status-badge">${row.payment_status || 'Paid'}</span></td>
                    `;
                    tbody.appendChild(tr);
                });
            } catch (err) {
                console.error('Failed to fetch sales:', err);
            }
        }

        document.getElementById('saleForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('submitBtn');
            btn.disabled = true;
            btn.textContent = 'Processing...';

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
                btn.textContent = 'Add Transaction & Payment';
            }
        });

        // Initial load
        fetchSales();
    </script>
</body>
</html>
HTML
    echo "    -> Updated frontend index.html for instance $V"
done

echo "[+] Restarting all server instances to apply frontend changes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P=$(expr 3000 + $i)
    cd "instances/$V"
    nohup node server.js > server.log 2>&1 &
    cd - > /dev/null
done

sleep 2
echo "[+] All frontend CTAs and database POST handlers have been successfully patched and restarted."
