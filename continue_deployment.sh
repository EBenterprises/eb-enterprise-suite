#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Full-Stack Deployment & Verification
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Verifying directory structure & required assets..."
mkdir -p public

echo "[+] Generating complete frontend interface (public/index.html)..."
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
    <header class="app-header">
        <h1>EB Sales Tracker</h1>
        <p class="subtitle">Executive Spectrum Edition</p>
    </header>

    <main class="container">
        <section class="card">
            <h2>Record Sale / Quick Preset</h2>
            <div class="preset-buttons">
                <button class="preset-btn" onclick="applyPreset('Quarter (7g)', 100)">Quarter (7g) - $100</button>
                <button class="preset-btn" onclick="applyPreset('Half (14g)', 180)">Half (14g) - $180</button>
                <button class="preset-btn" onclick="applyPreset('Full (28g)', 320)">Full (28g) - $320</button>
            </div>
            <form id="sale-form">
                <div class="form-group">
                    <label for="item">Item / Strain / Description</label>
                    <input type="text" id="item" required placeholder="e.g. Premium Reserve">
                </div>
                <div class="form-group">
                    <label for="amount">Amount ($ CAD)</label>
                    <input type="number" id="amount" step="0.01" required placeholder="0.00">
                </div>
                <div class="form-group">
                    <label for="customer">Customer Profile Notes</label>
                    <input type="text" id="customer" placeholder="Customer name or preferences">
                </div>
                <button type="submit" class="primary-btn">Record Transaction</button>
            </form>
        </section>

        <section class="card">
            <h2>Recent Transactions</h2>
            <div id="sales-list" class="list-container">
                <p class="loading">Loading sales ledger...</p>
            </div>
        </section>
    </main>

    <script src="app.js"></script>
</body>
</html>
EHTML

echo "[+] Generating stylesheet (public/styles.css)..."
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
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    margin: 0;
    padding: 0;
}

.app-header {
    background: linear-gradient(135deg, #0f172a, var(--card-bg));
    border-bottom: 2px solid var(--teal-accent);
    padding: 1.5rem;
    text-align: center;
}

.app-header h1 {
    color: var(--teal-accent);
    margin: 0;
    font-size: 1.8rem;
    letter-spacing: 1px;
}

.subtitle {
    color: var(--gold-highlight);
    font-size: 0.9rem;
    margin: 0.3rem 0 0;
    text-transform: uppercase;
    letter-spacing: 2px;
}

.container {
    max-width: 600px;
    margin: 1.5rem auto;
    padding: 0 1rem;
}

.card {
    background-color: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
}

.card h2 {
    color: var(--teal-accent);
    font-size: 1.2rem;
    margin-top: 0;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 0.5rem;
}

.preset-buttons {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.2rem;
    flex-wrap: wrap;
}

.preset-btn {
    background-color: transparent;
    border: 1px solid var(--gold-highlight);
    color: var(--gold-highlight);
    padding: 0.5rem 0.8rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85rem;
    transition: all 0.2s;
}

.preset-btn:hover {
    background-color: var(--gold-highlight);
    color: var(--bg-obsidian);
}

.form-group {
    margin-bottom: 1rem;
}

.form-group label {
    display: block;
    color: var(--text-muted);
    font-size: 0.85rem;
    margin-bottom: 0.3rem;
}

.form-group input {
    width: 100%;
    padding: 0.75rem;
    background-color: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    color: var(--text-main);
    box-sizing: border-box;
}

.form-group input:focus {
    border-color: var(--teal-accent);
    outline: none;
}

.primary-btn {
    background-color: var(--teal-accent);
    color: var(--bg-obsidian);
    border: none;
    width: 100%;
    padding: 0.8rem;
    font-weight: bold;
    border-radius: 4px;
    cursor: pointer;
    transition: opacity 0.2s;
}

.primary-btn:hover {
    opacity: 0.9;
}

.sale-item {
    background-color: var(--bg-obsidian);
    border-left: 3px solid var(--teal-accent);
    padding: 0.8rem;
    margin-bottom: 0.6rem;
    border-radius: 0 4px 4px 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.sale-info .item-name {
    font-weight: bold;
    color: var(--text-main);
}

.sale-info .customer-note {
    font-size: 0.8rem;
    color: var(--gold-highlight);
}

.sale-amount {
    font-family: monospace;
    font-size: 1.1rem;
    color: var(--teal-accent);
}
ECSS

echo "[+] Generating frontend logic (public/app.js)..."
cat << 'EJS' > public/app.js
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
            listEl.innerHTML = '<p class="loading">No transactions recorded yet.</p>';
            return;
        }

        listEl.innerHTML = sales.reverse().map(sale => `
            <div class="sale-item">
                <div class="sale-info">
                    <div class="item-name">${escapeHtml(sale.item)}</div>
                    ${sale.customer ? `<div class="customer-note">Client: ${escapeHtml(sale.customer)}</div>` : ''}
                </div>
                <div class="sale-amount">$${parseFloat(sale.amount).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Failed to load sales:', err);
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
        console.error('Failed to save transaction:', err);
    }
});

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

fetchSales();
EJS

echo "[+] Full-stack assets deployed successfully. Starting live server..."
node server.js
