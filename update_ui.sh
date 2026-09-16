#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - UI Verification & Patch
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Verifying index.html form fields..."
grep -n "customerName" public/index.html || {
    echo "[!] Customer name input missing from index.html. Re-injecting..."
    cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises | Sales Logistics</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">EB</div>
            <h1>Sales Logistics Terminal</h1>
            <p>Proprietary weight, customer, and revenue tracking system</p>
        </header>

        <section class="dashboard">
            <div class="card">
                <h3>Total Revenue</h3>
                <p id="totalRevenue" class="gold-text">$0.00</p>
            </div>
            <div class="card">
                <h3>Total Mass (g)</h3>
                <p id="totalWeight" class="teal-text">0.00 g</p>
            </div>
            <div class="card">
                <h3>Transaction Count</h3>
                <p id="totalSales">0</p>
            </div>
        </section>

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
                </div>
                <button type="submit" class="btn-submit">EXECUTE LOG</button>
            </form>
        </section>

        <section class="table-section">
            <h2>Ledger</h2>
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
}

echo "[+] Restarting server..."
node server.js
