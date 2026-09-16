#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Customer Field Integration
# ==============================================================================
set -e

PROJECT_DIR="eb-sales-tracker"
cd "$PROJECT_DIR"

echo "[+] Updating frontend index.html to include Customer Name..."
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
            <p>Proprietary weight and revenue tracking system</p>
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
                        <input type="text" id="itemName" required autocomplete="off">
                    </div>
                    <div class="form-group">
                        <label>Unit Value ($)</label>
                        <input type="number" id="unitPrice" step="0.01" min="0" required>
                    </div>
                    <div class="form-group">
                        <label>Quantity</label>
                        <input type="number" id="quantity" min="1" value="1" required>
                    </div>
                    <div class="form-group">
                        <label>Mass Per Unit (Grams)</label>
                        <input type="number" id="weightGrams" step="0.01" min="0" required>
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

echo "[+] Updating bridging logic (app.js) to handle customer field..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const salesTableBody = document.getElementById('salesTableBody');

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
        weightGrams: parseFloat(weightGramsInput.value)
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    
    salesForm.reset();
    quantityInput.value = '1';
    fetchAndRender();
});

async function deleteEntry(id) {
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRender();
}

function render(sales) {
    salesTableBody.innerHTML = '';
    let grandRevenue = 0, grandWeight = 0;

    sales.forEach(sale => {
        const rowTotalWeight = sale.weightGrams * sale.quantity;
        const rowTotalPrice = sale.price * sale.quantity;
        grandRevenue += rowTotalPrice;
        grandWeight += rowTotalWeight;

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${sale.date}</td>
            <td><strong class="gold-text">${sale.customer || 'N/A'}</strong></td>
            <td><strong>${sale.name}</strong></td>
            <td>$${sale.price.toFixed(2)}</td>
            <td>${sale.quantity}</td>
            <td>${sale.weightGrams.toFixed(2)}</td>
            <td class="teal-text">${rowTotalWeight.toFixed(2)}</td>
            <td class="gold-text">$${rowTotalPrice.toFixed(2)}</td>
            <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
        `;
        salesTableBody.appendChild(tr);
    });

    totalRevenueEl.textContent = `$${grandRevenue.toFixed(2)}`;
    totalWeightEl.textContent = `${grandWeight.toFixed(2)} g`;
    totalSalesEl.textContent = sales.length;
}
JS_EOF

echo "[+] Customer field integration complete. Restarting service..."
node server.js
