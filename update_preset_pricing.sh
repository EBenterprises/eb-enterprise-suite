#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Updated Preset Pricing Matrix
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Updating preset buttons in index.html with new pricing scale..."
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
                <h2>Total Revenue</h2>
                <div id="total-revenue-display" class="revenue-big">$0.00</div>
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

echo "[+] Pricing matrix updated successfully. Restarting server..."
fuser -k 3000/tcp || true
node server.js
