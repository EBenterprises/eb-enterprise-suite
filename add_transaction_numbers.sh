#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Transaction History Numbering Patch
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Updating index.html to include transaction row number column..."
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
            <p>Track revenue, item weights, and individual customer bills with numbered transaction history</p>
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
                    <div class="form-group" id="amountPaidGroup" style="display: none;">
                        <label>Amount Paid ($)</label>
                        <input type="number" id="amountPaid" step="0.01" min="0" placeholder="0.00">
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
                            <th>Total Tx</th>
                            <th>Total Mass</th>
                            <th>Total Bill</th>
                            <th>Total Paid</th>
                            <th>Remaining Balance</th>
                            <th>Tab Status</th>
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
                            <th>#</th>
                            <th>Timestamp</th>
                            <th>Customer</th>
                            <th>Asset</th>
                            <th>Unit $</th>
                            <th>Qty</th>
                            <th>Mass (g)</th>
                            <th>Total Mass</th>
                            <th>Total Val</th>
                            <th>Status / Paid</th>
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

echo "[+] Updating app.js to display sequential transaction numbers..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const paymentStatusInput = document.getElementById('paymentStatus');
const amountPaidGroup = document.getElementById('amountPaidGroup');
const amountPaidInput = document.getElementById('amountPaid');

const salesTableBody = document.getElementById('salesTableBody');
const customerTabsTableBody = document.getElementById('customerTabsTableBody');

const totalRevenueEl = document.getElementById('totalRevenue');
const totalWeightEl = document.getElementById('totalWeight');
const totalSalesEl = document.getElementById('totalSales');

document.addEventListener('DOMContentLoaded', fetchAndRender);

paymentStatusInput.addEventListener('change', (e) => {
    if (e.target.value === 'partial' || e.target.value === 'paid') {
        amountPaidGroup.style.display = 'flex';
        if (e.target.value === 'paid') {
            const unitPrice = parseFloat(unitPriceInput.value) || 0;
            const qty = parseInt(quantityInput.value) || 1;
            amountPaidInput.value = (unitPrice * qty).toFixed(2);
        }
    } else {
        amountPaidGroup.style.display = 'none';
        amountPaidInput.value = '';
    }
});

[unitPriceInput, quantityInput].forEach(el => {
    el.addEventListener('input', () => {
        if (paymentStatusInput.value === 'paid') {
            const unitPrice = parseFloat(unitPriceInput.value) || 0;
            const qty = parseInt(quantityInput.value) || 1;
            amountPaidInput.value = (unitPrice * qty).toFixed(2);
        }
    });
});

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
    const status = paymentStatusInput.value;
    let amountPaid = 0;
    if (status === 'paid') {
        amountPaid = parseFloat(unitPriceInput.value) * parseInt(quantityInput.value, 10);
    } else if (status === 'partial') {
        amountPaid = parseFloat(amountPaidInput.value) || 0;
    }

    const payload = {
        date: new Date().toISOString().replace('T', ' ').substring(0, 19),
        customer: customerNameInput.value.trim(),
        name: itemNameInput.value.trim(),
        price: parseFloat(unitPriceInput.value),
        quantity: parseInt(quantityInput.value, 10),
        weightGrams: parseFloat(weightGramsInput.value),
        status: status,
        amountPaid: amountPaid
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    salesForm.reset();
    quantityInput.value = '1';
    paymentStatusInput.value = 'unpaid';
    amountPaidGroup.style.display = 'none';
    amountPaidInput.value = '';
    fetchAndRender();
});

async function updateTransaction(id, newStatus, currentTotalVal, currentAmountPaidInputEl) {
    const statusVal = newStatus;
    let paidVal = parseFloat(currentAmountPaidInputEl.value) || 0;

    if (statusVal === 'paid') {
        paidVal = currentTotalVal;
    } else if (statusVal === 'unpaid') {
        paidVal = 0;
    }

    await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: statusVal, amountPaid: paidVal })
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

    if (sales.length === 0) {
        salesTableBody.innerHTML = `<tr><td colspan="11" style="text-align: center; color: var(--text-muted); padding: 20px;">No transactions recorded.</td></tr>`;
        customerTabsTableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 20px;">No active customer tabs.</td></tr>`;
    } else {
        sales.forEach((sale, index) => {
            const rowNumber = index + 1;
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;
            const salePaid = typeof sale.amountPaid === 'number' ? sale.amountPaid : (sale.status === 'paid' ? rowTotalPrice : 0);
            
            grandRevenue += rowTotalPrice;
            grandWeight += rowTotalWeight;

            // Aggregate by customer tab
            const custName = sale.customer || 'N/A';
            if (!customerMap[custName]) {
                customerMap[custName] = {
                    name: custName,
                    txCount: 0,
                    totalMass: 0,
                    totalBill: 0,
                    totalPaid: 0,
                    items: []
                };
            }
            customerMap[custName].txCount += 1;
            customerMap[custName].totalMass += rowTotalWeight;
            customerMap[custName].totalBill += rowTotalPrice;
            customerMap[custName].totalPaid += salePaid;
            customerMap[custName].items.push(sale);

            // Render transaction row with numbering column
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong style="color: var(--teal-glow);">#${rowNumber}</strong></td>
                <td>${sale.date}</td>
                <td><strong class="gold-text">${escapeHtml(sale.customer || 'N/A')}</strong></td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td>$${sale.price.toFixed(2)}</td>
                <td>${sale.quantity}</td>
                <td>${sale.weightGrams.toFixed(2)}</td>
                <td class="teal-text">${rowTotalWeight.toFixed(2)} g</td>
                <td class="gold-text">$${rowTotalPrice.toFixed(2)}</td>
                <td>
                    <div class="status-controls">
                        <select class="status-select" id="status-${sale.id}" onchange="handleStatusChange(${sale.id}, ${rowTotalPrice})">
                            <option value="unpaid" ${sale.status === 'unpaid' ? 'selected' : ''}>Unpaid</option>
                            <option value="partial" ${sale.status === 'partial' ? 'selected' : ''}>Partial</option>
                            <option value="paid" ${sale.status === 'paid' ? 'selected' : ''}>Paid</option>
                        </select>
                        <input type="number" class="paid-input" id="paid-input-${sale.id}" step="0.01" min="0" max="${rowTotalPrice}" value="${salePaid.toFixed(2)}" ${sale.status === 'unpaid' ? 'style="display:none;"' : ''} placeholder="Paid $" onchange="updateTransaction(${sale.id}, document.getElementById('status-${sale.id}').value, ${rowTotalPrice}, this)">
                    </div>
                </td>
                <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
            `;
            salesTableBody.appendChild(tr);
        });

        // Render customer tabs summary
        Object.values(customerMap).forEach(cust => {
            const remainingBalance = Math.max(0, cust.totalBill - cust.totalPaid);
            const tr = document.createElement('tr');
            let badgeHtml = '';
            if (remainingBalance <= 0.01) {
                badgeHtml = '<span class="badge badge-paid">Fully Settled</span>';
            } else if (cust.totalPaid > 0) {
                badgeHtml = '<span class="badge badge-partial">Partial Balance</span>';
            } else {
                badgeHtml = '<span class="badge badge-unpaid">Unpaid Tab</span>';
            }

            tr.innerHTML = `
                <td><strong class="gold-text">${escapeHtml(cust.name)}</strong></td>
                <td>${cust.txCount} tx</td>
                <td class="teal-text">${cust.totalMass.toFixed(2)} g</td>
                <td class="gold-text">$${cust.totalBill.toFixed(2)}</td>
                <td style="color: var(--success);">$${cust.totalPaid.toFixed(2)}</td>
                <td style="color: ${remainingBalance > 0 ? 'var(--danger)' : 'var(--success)'}; font-weight: bold;">$${remainingBalance.toFixed(2)}</td>
                <td>${badgeHtml}</td>
            `;
            customerTabsTableBody.appendChild(tr);
        });
    }

    totalRevenueEl.textContent = `$${grandRevenue.toFixed(2)}`;
    totalWeightEl.textContent = `${grandWeight.toFixed(2)} g`;
    totalSalesEl.textContent = sales.length;
}

function handleStatusChange(id, totalVal) {
    const statusSelect = document.getElementById(`status-${id}`);
    const paidInput = document.getElementById(`paid-input-${id}`);
    
    if (statusSelect.value === 'paid') {
        paidInput.value = totalVal.toFixed(2);
        paidInput.style.display = 'block';
    } else if (statusSelect.value === 'partial') {
        paidInput.style.display = 'block';
        if (parseFloat(paidInput.value) >= totalVal || parseFloat(paidInput.value) === 0) {
            paidInput.value = (totalVal / 2).toFixed(2);
        }
    } else {
        paidInput.value = '0.00';
        paidInput.style.display = 'none';
    }

    updateTransaction(id, statusSelect.value, totalVal, paidInput);
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
JS_EOF

echo "[+] Transaction history updated with sequential numbering. Restarting server..."
node server.js
