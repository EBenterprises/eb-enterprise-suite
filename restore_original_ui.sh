#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Revert UI to Original Layout
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Restoring original index.html, styles.css, and app.js..."

cat << 'EHTML' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Sales Tracker</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="app-container">
        <header>
            <h1>EB Sales Tracker</h1>
        </header>

        <section class="form-section">
            <form id="sale-form">
                <div class="input-group">
                    <input type="text" id="item" placeholder="Item / Strain" required>
                </div>
                <div class="input-group">
                    <input type="number" id="amount" step="0.01" placeholder="Amount ($)" required>
                </div>
                <div class="input-group">
                    <input type="text" id="customer" placeholder="Customer Notes">
                </div>
                <button type="submit" class="btn-submit">Add Sale</button>
            </form>
        </section>

        <section class="list-section">
            <h2>Transactions</h2>
            <div id="sales-list"></div>
        </section>
    </div>

    <script src="app.js"></script>
</body>
</html>
EHTML

cat << 'ECSS' > public/styles.css
body {
    background-color: #0b0f12;
    color: #e2e8f0;
    font-family: sans-serif;
    margin: 0;
    padding: 1rem;
}

.app-container {
    max-width: 500px;
    margin: 0 auto;
}

header h1 {
    color: #00d2c4;
    text-align: center;
    font-size: 1.5rem;
}

.form-section, .list-section {
    background: #131b22;
    padding: 1rem;
    border-radius: 6px;
    margin-bottom: 1rem;
    border: 1px solid #1e293b;
}

.input-group {
    margin-bottom: 0.8rem;
}

input {
    width: 100%;
    padding: 0.6rem;
    background: #0b0f12;
    border: 1px solid #1e293b;
    color: #e2e8f0;
    border-radius: 4px;
    box-sizing: border-box;
}

input:focus {
    border-color: #00d2c4;
    outline: none;
}

.btn-submit {
    background: #00d2c4;
    color: #0b0f12;
    border: none;
    width: 100%;
    padding: 0.7rem;
    font-weight: bold;
    border-radius: 4px;
    cursor: pointer;
}

.sale-item {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px solid #1e293b;
}

.sale-item:last-child {
    border-bottom: none;
}
ECSS

cat << 'EJS' > public/app.js
async function fetchSales() {
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        const listEl = document.getElementById('sales-list');
        
        if (sales.length === 0) {
            listEl.innerHTML = '<p style="color: #94a3b8; text-align: center;">No sales recorded.</p>';
            return;
        }

        listEl.innerHTML = sales.map(sale => `
            <div class="sale-item">
                <div>
                    <strong>${escapeHtml(sale.item)}</strong>
                    ${sale.customer ? `<br><small style="color: #d4af37;">${escapeHtml(sale.customer)}</small>` : ''}
                </div>
                <div style="color: #00d2c4; font-family: monospace;">$${parseFloat(sale.amount).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching sales:', err);
    }
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const item = document.getElementById('item').value;
    const amount = parseFloat(document.getElementById('amount').value);
    const customer = document.getElementById('customer').value;

    try {
        const res = await fetch('/api/sales', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ item, amount, customer })
        });

        if (res.ok) {
            document.getElementById('sale-form').reset();
            fetchSales();
        }
    } catch (err) {
        console.error('Error saving sale:', err);
    }
});

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

fetchSales();
EJS

echo "[+] Original UI layout restored successfully. Restarting server..."
node server.js
