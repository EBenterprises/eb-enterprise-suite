#!/bin/bash
set -e

echo "[+] Updating index.html so quantity has a dedicated numeric input field separate from unit/description..."

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
            <div id="live-totals-bar" style="display: flex; justify-content: center; gap: 2.5rem; margin-top: 1.5rem; padding: 1rem 1.5rem; background: rgba(0, 255, 204, 0.03); border: 1px solid var(--teal-accent); border-radius: 8px; font-family: monospace; font-size: 0.95rem;">
                <div><span style="color: var(--text-muted);">Total Revenue:</span> <strong id="global-rev" style="color: var(--teal-accent);">$0.00</strong></div>
                <div><span style="color: var(--text-muted);">Total Collected:</span> <strong id="global-collected" style="color: var(--gold-highlight);">$0.00</strong></div>
                <div><span style="color: var(--text-muted);">Total Volume:</span> <strong id="global-grams" style="color: #fff;">0.00g</strong></div>
            </div>
        </header>

        <nav class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('sales')">Sales & Ledger</button>
            <button class="tab-btn" onclick="switchTab('payments')">Payments</button>
            <button class="tab-btn" onclick="switchTab('inventory')">Inventory</button>
            <button class="tab-btn" onclick="switchTab('customers')">Customers</button>
            <button class="tab-btn" onclick="switchTab('analytics')">Analytics & Filters</button>
        </nav>

        <!-- Sales Tab -->
        <div id="tab-sales" class="tab-content active">
            <section class="form-section">
                <h2>Record Transaction</h2>
                <div class="preset-buttons">
                    <button class="preset-btn" onclick="applyPreset(0.87, 'g', 20)">0.87g - $20</button>
                    <button class="preset-btn" onclick="applyPreset(1.75, 'g', 40)">1.75g - $40</button>
                    <button class="preset-btn" onclick="applyPreset(3.5, 'g', 80)">3.5g - $80</button>
                    <button class="preset-btn" onclick="applyPreset(7, 'g', 160)">7g - $160</button>
                    <button class="preset-btn" onclick="applyPreset(14, 'g', 320)">14g - $320</button>
                    <button class="preset-btn" onclick="applyPreset(28, 'g', 640)">28g - $640</button>
                </div>
                <form id="sale-form">
                    <div class="input-group">
                        <label style="display: block; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.3rem;">Timestamp (Leave blank for current time)</label>
                        <input type="datetime-local" id="sale-timestamp">
                    </div>
                    <div class="input-group"><input type="text" id="name" placeholder="Customer Name" required></div>
                    
                    <!-- Dedicated Quantity Number Input & Unit Selector -->
                    <div class="input-group" style="display: flex; gap: 0.5rem;">
                        <input type="number" id="qty-number" step="0.01" placeholder="Quantity (e.g. 3.5, 1, 10)" style="flex: 2;" required>
                        <select id="qty-unit" style="flex: 1; background: var(--bg-card); color: var(--text-main); border: 1px solid var(--border-color); border-radius: 4px; padding: 0.5rem;">
                            <option value="g">grams (g)</option>
                            <option value="units">Units / Pcs</option>
                            <option value="oz">Ounces (oz)</option>
                            <option value="ml">Milliliters (ml)</option>
                            <option value="other">Other</option>
                        </select>
                    </div>

                    <div class="input-group"><input type="text" id="item" placeholder="Description / Strain / Item Name" required></div>
                    <div class="input-group"><input type="number" id="cost" step="0.01" placeholder="Item Cost ($ CAD)" required></div>
                    <div class="input-group">
                        <select id="payment-status" onchange="togglePartialInput()">
                            <option value="paid">Paid (In Full)</option>
                            <option value="unpaid">Unpaid</option>
                            <option value="partial">Partial Payment</option>
                        </select>
                    </div>
                    <div class="input-group" id="partial-group" style="display: none;">
                        <input type="number" id="paid-amount" step="0.01" placeholder="Initial Amount Paid ($)">
                    </div>
                    <button type="submit" class="btn-submit">Record Transaction</button>
                </form>
            </section>

            <section class="list-section">
                <h2>Transaction Ledger</h2>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Timestamp</th>
                                <th>Name</th>
                                <th>Quantity</th>
                                <th>Description</th>
                                <th>Cost</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="sales-table-body">
                            <tr><td colspan="7" class="loading">Loading ledger...</td></tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </div>

        <!-- Standalone Payments Tab -->
        <div id="tab-payments" class="tab-content">
            <section class="form-section">
                <h2>Record Direct Payment (Standalone)</h2>
                <form id="direct-payment-form">
                    <div class="input-group">
                        <label style="display: block; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.3rem;">Timestamp (Leave blank for current time)</label>
                        <input type="datetime-local" id="pay-timestamp">
                    </div>
                    <div class="input-group"><input type="text" id="pay-customer" placeholder="Customer Name" required></div>
                    <div class="input-group"><input type="number" id="pay-amount" step="0.01" placeholder="Payment Amount ($)" required></div>
                    <div class="input-group"><input type="text" id="pay-notes" placeholder="Notes / Reference (e.g. E-Transfer, Cash)"></div>
                    <button type="submit" class="btn-submit">Record Payment</button>
                </form>
            </section>

            <section class="list-section">
                <h2>All Payment Records</h2>
                <div class="table-responsive">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Timestamp</th>
                                <th>Customer</th>
                                <th>Amount</th>
                                <th>Reference / Notes</th>
                                <th>Linked To</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="payments-table-body">
                            <tr><td colspan="6" class="loading">Loading payments...</td></tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </div>

        <!-- Inventory Tab -->
        <div id="tab-inventory" class="tab-content">
            <section class="form-section">
                <h2>Add Inventory Stock</h2>
                <form id="inventory-form">
                    <div class="input-group"><input type="text" id="inv-name" placeholder="Item / Strain Name" required></div>
                    <div class="input-group"><input type="number" id="inv-qty" step="0.01" placeholder="Quantity" required></div>
                    <div class="input-group"><input type="number" id="inv-price" step="0.01" placeholder="Target Price ($)" required></div>
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
                    <div class="input-group"><input type="text" id="cust-name" placeholder="Customer Name" required></div>
                    <div class="input-group"><input type="text" id="cust-phone" placeholder="Phone Number"></div>
                    <div class="input-group"><input type="text" id="cust-notes" placeholder="Preferences / Notes"></div>
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
            <section class="form-section">
                <h2>Filter Transaction History</h2>
                <div class="filter-buttons">
                    <button class="filter-btn active" onclick="setFilter('all', event)">All Time</button>
                    <button class="filter-btn" onclick="setFilter('day', event)">Today</button>
                    <button class="filter-btn" onclick="setFilter('week', event)">This Week</button>
                    <button class="filter-btn" onclick="setFilter('month', event)">This Month</button>
                    <button class="filter-btn" onclick="setFilter('year', event)">This Year</button>
                </div>
            </section>

            <section class="form-section summary-card">
                <h2>Summary (<span id="filter-label">All Time</span>)</h2>
                <div style="display: flex; justify-content: space-around; text-align: center; margin-top: 1rem; flex-wrap: wrap; gap: 1rem;">
                    <div>
                        <small style="color: var(--text-muted);">Total Revenue</small>
                        <div id="analytics-revenue" class="revenue-big" style="font-size: 1.4rem;">$0.00</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Total Collected</small>
                        <div id="analytics-collected" class="revenue-big" style="font-size: 1.4rem; color: var(--gold-highlight);">$0.00</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Total Volume</small>
                        <div id="analytics-grams" class="revenue-big" style="font-size: 1.4rem; color: #fff;">0.00g</div>
                    </div>
                    <div>
                        <small style="color: var(--text-muted);">Transactions</small>
                        <div id="analytics-count" class="revenue-big" style="font-size: 1.4rem; color: var(--teal-accent);">0</div>
                    </div>
                </div>
            </section>

            <section class="list-section">
                <h2>Revenue By Customer</h2>
                <div id="analytics-customers"><p class="loading">Loading analytics...</p></div>
            </section>
        </div>
        
        <footer style="text-align: center; margin-top: 3rem; padding: 1.5rem 0; border-top: 1px solid var(--border-color); color: var(--text-muted); font-size: 0.85rem; font-family: monospace;">
            &copy; 2026 EB Enterprises / Easton Bodeux Inc. All rights reserved.
        </footer>
    </div>

    <!-- Payment Modal -->
    <div id="payment-modal" class="modal" style="display: none;">
        <div class="modal-content" style="width: 420px; max-width: 90%;">
            <h3>Payment Ledger & Installments</h3>
            <p id="modal-sale-info" style="color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem;"></p>
            <div id="modal-payments-history" style="max-height: 150px; overflow-y: auto; margin-bottom: 1rem; border: 1px solid var(--border-color); padding: 0.5rem; border-radius: 4px;"></div>
            <form id="payment-form">
                <input type="hidden" id="modal-sale-id">
                <div class="input-group"><input type="number" id="payment-amount" step="0.01" placeholder="Payment Amount ($)" required></div>
                <div class="input-group"><input type="text" id="payment-notes" placeholder="Note / Reference"></div>
                <div style="display: flex; gap: 0.5rem;">
                    <button type="submit" class="btn-submit">Add Payment</button>
                    <button type="button" class="btn-submit" style="background: var(--text-muted);" onclick="closePaymentModal()">Close</button>
                </div>
            </form>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
EHTML

cat << 'EJS' > public/app.js
let currentFilter = 'all';
let cachedSales = [];

document.addEventListener('DOMContentLoaded', () => {
    fetchSales();
    fetchInventory();
    fetchCustomers();
    fetchPayments();
    refreshGlobalTotals();
});

function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    document.getElementById('tab-' + tabName).classList.add('active');
    event.currentTarget.classList.add('active');
    if (tabName === 'analytics') {
        renderAnalytics(cachedSales);
    }
}

function applyPreset(qtyVal, unitVal, costVal) {
    document.getElementById('qty-number').value = qtyVal;
    document.getElementById('qty-unit').value = unitVal;
    document.getElementById('cost').value = costVal.toFixed(2);
}

function togglePartialInput() {
    const status = document.getElementById('payment-status').value;
    const partialGroup = document.getElementById('partial-group');
    partialGroup.style.display = status === 'partial' ? 'block' : 'none';
}

async function refreshGlobalTotals() {
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        let totalRev = 0;
        let totalColl = 0;
        let totalGrams = 0;

        sales.forEach(sale => {
            totalRev += sale.cost;
            totalColl += sale.totalPaid || 0;
            const match = String(sale.weight || '').match(/^([\d.]+)/);
            if (match && String(sale.weight).includes('g')) {
                totalGrams += parseFloat(match[1]);
            }
        });

        document.getElementById('global-rev').innerText = '$' + totalRev.toFixed(2);
        document.getElementById('global-collected').innerText = '$' + totalColl.toFixed(2);
        document.getElementById('global-grams').innerText = totalGrams.toFixed(2) + 'g';
    } catch (err) {
        console.error('Error refreshing totals:', err);
    }
}

async function fetchSales() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/sales');
        cachedSales = await res.json();
        filterAndRenderSales();
    } catch (err) {
        console.error('Error fetching sales:', err);
    }
}

function setFilter(filterType, e) {
    currentFilter = filterType;
    document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
    if (e && e.target) e.target.classList.add('active');
    
    const labels = { all: 'All Time', day: 'Today', week: 'This Week', month: 'This Month', year: 'This Year' };
    document.getElementById('filter-label').innerText = labels[filterType] || 'Filtered';
    
    filterAndRenderSales();
    renderAnalytics(cachedSales);
}

function filterAndRenderSales() {
    const now = new Date();
    const filtered = cachedSales.filter(sale => {
        if (!sale.timestamp) return true;
        const saleDate = new Date(sale.timestamp);
        if (isNaN(saleDate)) return true;

        if (currentFilter === 'day') {
            return saleDate.toDateString() === now.toDateString();
        } else if (currentFilter === 'week') {
            const startOfWeek = new Date(now);
            startOfWeek.setDate(now.getDate() - now.getDay());
            startOfWeek.setHours(0,0,0,0);
            return saleDate >= startOfWeek;
        } else if (currentFilter === 'month') {
            return saleDate.getMonth() === now.getMonth() && saleDate.getFullYear() === now.getFullYear();
        } else if (currentFilter === 'year') {
            return saleDate.getFullYear() === now.getFullYear();
        }
        return true;
    });

    const tbody = document.getElementById('sales-table-body');
    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="loading">No transactions found.</td></tr>';
        return;
    }

    tbody.innerHTML = filtered.map(sale => {
        const cost = typeof sale.cost === 'number' ? sale.cost : parseFloat(sale.cost || 0);
        const totalPaid = typeof sale.totalPaid === 'number' ? sale.totalPaid : parseFloat(sale.totalPaid || 0);
        const balanceDue = cost - totalPaid;
        
        let statusBadge = '';
        if (sale.payment_status === 'paid' || balanceDue <= 0.001) {
            statusBadge = '<span class="status-badge status-paid">Paid</span>';
        } else if (sale.payment_status === 'partial' || totalPaid > 0) {
            statusBadge = `<span class="status-badge status-partial" title="Paid: $${totalPaid.toFixed(2)}">Partial ($${balanceDue.toFixed(2)} due)</span>`;
        } else {
            statusBadge = '<span class="status-badge status-unpaid">Unpaid</span>';
        }

        const dateStr = sale.timestamp ? new Date(sale.timestamp).toLocaleString() : 'N/A';

        return `
            <tr>
                <td>${escapeHtml(dateStr)}</td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td><span style="color: var(--teal-accent); font-family: monospace;">${escapeHtml(sale.weight || '-')}</span></td>
                <td>${escapeHtml(sale.item || '-')}</td>
                <td>$${cost.toFixed(2)}</td>
                <td>${statusBadge}</td>
                <td>
                    <button class="action-btn" onclick="openPaymentModal(${sale.id}, '${escapeHtml(sale.name)}', ${cost}, ${totalPaid})">Pay / History</button>
                    <button class="action-btn delete-btn" onclick="deleteSale(${sale.id})">Delete</button>
                </td>
            </tr>
        `;
    }).join('');
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const timestamp = document.getElementById('sale-timestamp').value;
    const name = document.getElementById('name').value;
    const qtyNum = document.getElementById('qty-number').value;
    const qtyUnit = document.getElementById('qty-unit').value;
    const weight = `${qtyNum}${qtyUnit}`;
    const item = document.getElementById('item').value;
    const cost = parseFloat(document.getElementById('cost').value);
    const payment_status = document.getElementById('payment-status').value;
    let paidAmount = 0;

    if (payment_status === 'partial') {
        paidAmount = parseFloat(document.getElementById('paid-amount').value || 0);
    } else if (payment_status === 'paid') {
        paidAmount = cost;
    }

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timestamp: timestamp || new Date().toISOString(), name, weight, item, cost, payment_status, paidAmount })
    });

    if (res.ok) {
        document.getElementById('sale-form').reset();
        document.getElementById('partial-group').style.display = 'none';
        fetchSales();
        fetchPayments();
    }
});

async function deleteSale(id) {
    if (confirm('Are you sure you want to delete this transaction?')) {
        await fetch(`/api/sales/${id}`, { method: 'DELETE' });
        fetchSales();
        fetchPayments();
    }
}

// Payment Modal handlers
async function openPaymentModal(saleId, customerName, totalCost, totalPaid) {
    document.getElementById('modal-sale-id').value = saleId;
    document.getElementById('modal-sale-info').innerText = `Customer: ${customerName} | Total: $${totalCost.toFixed(2)} | Paid: $${totalPaid.toFixed(2)} | Balance Due: $${(totalCost - totalPaid).toFixed(2)}`;
    document.getElementById('payment-amount').value = (totalCost - totalPaid).toFixed(2);
    document.getElementById('payment-notes').value = '';
    
    try {
        const res = await fetch(`/api/payments?sale_id=${saleId}`);
        const payments = await res.json();
        const historyDiv = document.getElementById('modal-payments-history');
        if (payments.length === 0) {
            historyDiv.innerHTML = '<small style="color: var(--text-muted);">No installment payments recorded.</small>';
        } else {
            historyDiv.innerHTML = payments.map(p => `
                <div style="display: flex; justify-content: space-between; align-items: center; font-size: 0.85rem; padding: 0.2rem 0; border-bottom: 1px dashed var(--border-color);">
                    <span><strong>$${p.amount.toFixed(2)}</strong> (${escapeHtml(p.notes || 'Payment')}) - <small>${new Date(p.timestamp).toLocaleDateString()}</small></span>
                    <button class="action-btn delete-btn" style="padding: 0.1rem 0.4rem; font-size: 0.75rem;" onclick="deletePayment(${p.id})">&times;</button>
                </div>
            `).join('');
        }
    } catch (err) {
        console.error(err);
    }

    document.getElementById('payment-modal').style.display = 'flex';
}

function closePaymentModal() {
    document.getElementById('payment-modal').style.display = 'none';
}

document.getElementById('payment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const sale_id = document.getElementById('modal-sale-id').value;
    const amount = parseFloat(document.getElementById('payment-amount').value);
    const notes = document.getElementById('payment-notes').value;

    const res = await fetch('/api/payments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sale_id, customer: 'Payment', amount, notes, timestamp: new Date().toISOString() })
    });

    if (res.ok) {
        closePaymentModal();
        fetchSales();
        fetchPayments();
    }
});

async function deletePayment(id) {
    await fetch(`/api/payments/${id}`, { method: 'DELETE' });
    fetchSales();
    fetchPayments();
    closePaymentModal();
}

// Standalone Payments Tab
document.getElementById('direct-payment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const timestamp = document.getElementById('pay-timestamp').value;
    const customer = document.getElementById('pay-customer').value;
    const amount = parseFloat(document.getElementById('pay-amount').value);
    const notes = document.getElementById('pay-notes').value;

    const res = await fetch('/api/payments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sale_id: null, customer, amount, notes, timestamp: timestamp || new Date().toISOString() })
    });

    if (res.ok) {
        document.getElementById('direct-payment-form').reset();
        fetchPayments();
        fetchSales();
    }
});

async function fetchPayments() {
    try {
        const res = await fetch('/api/payments');
        const payments = await res.json();
        const tbody = document.getElementById('payments-table-body');
        if (payments.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="loading">No payment records found.</td></tr>';
            return;
        }

        tbody.innerHTML = payments.map(p => `
            <tr>
                <td>${escapeHtml(new Date(p.timestamp).toLocaleString())}</td>
                <td><strong>${escapeHtml(p.customer)}</strong></td>
                <td><span style="color: var(--gold-highlight); font-family: monospace;">$${p.amount.toFixed(2)}</span></td>
                <td>${escapeHtml(p.notes || '-')}</td>
                <td>${p.sale_id ? `<span style="color: var(--teal-accent);">Sale #${p.sale_id}</span>` : '<span style="color: var(--text-muted);">Direct Payment</span>'}</td>
                <td>
                    <button class="action-btn delete-btn" onclick="deleteDirectPayment(${p.id})">Delete</button>
                </td>
            </tr>
        `).join('');
    } catch (err) {
        console.error(err);
    }
}

async function deleteDirectPayment(id) {
    if (confirm('Delete this payment record?')) {
        await fetch(`/api/payments/${id}`, { method: 'DELETE' });
        fetchPayments();
        fetchSales();
    }
}

// Inventory
document.getElementById('inventory-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('inv-name').value;
    const quantity = parseFloat(document.getElementById('inv-qty').value);
    const price = parseFloat(document.getElementById('inv-price').value);

    const res = await fetch('/api/inventory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, quantity, price })
    });

    if (res.ok) {
        document.getElementById('inventory-form').reset();
        fetchInventory();
    }
});

async function fetchInventory() {
    try {
        const res = await fetch('/api/inventory');
        const items = await res.json();
        const listDiv = document.getElementById('inventory-list');
        if (items.length === 0) {
            listDiv.innerHTML = '<p class="loading">No inventory stock added.</p>';
            return;
        }

        listDiv.innerHTML = items.map(item => `
            <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.6rem 0; border-bottom: 1px solid var(--border-color);">
                <div>
                    <strong>${escapeHtml(item.name)}</strong>
                    <br><small style="color: var(--text-muted);">Stock: <span style="color: var(--teal-accent);">${item.quantity}</span> | Target Price: <span style="color: var(--gold-highlight);">$${item.price.toFixed(2)}</span></small>
                </div>
                <button class="action-btn delete-btn" onclick="deleteInventory(${item.id})">Remove</button>
            </div>
        `).join('');
    } catch (err) {
        console.error(err);
    }
}

async function deleteInventory(id) {
    await fetch(`/api/inventory/${id}`, { method: 'DELETE' });
    fetchInventory();
}

// Customers
document.getElementById('customer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('cust-name').value;
    const phone = document.getElementById('cust-phone').value;
    const notes = document.getElementById('cust-notes').value;

    const res = await fetch('/api/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, phone, notes })
    });

    if (res.ok) {
        document.getElementById('customer-form').reset();
        fetchCustomers();
    }
});

async function fetchCustomers() {
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        const listDiv = document.getElementById('customers-list');
        if (customers.length === 0) {
            listDiv.innerHTML = '<p class="loading">No customer profiles.</p>';
            return;
        }

        listDiv.innerHTML = customers.map(cust => `
            <div style="padding: 0.5rem 0; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong>${escapeHtml(cust.name)}</strong>
                    ${cust.phone ? `<br><small style="color: var(--teal-accent); font-family: monospace;">&#9743; ${escapeHtml(cust.phone)}</small>` : ''}
                    ${cust.notes ? `<br><small style="color: var(--text-muted);">${escapeHtml(cust.notes)}</small>` : ''}
                </div>
            </div>
        `).join('');
    } catch (err) {
        console.error(err);
    }
}

// Analytics
function renderAnalytics(sales) {
    const now = new Date();
    const filtered = sales.filter(sale => {
        if (!sale.timestamp) return true;
        const saleDate = new Date(sale.timestamp);
        if (isNaN(saleDate)) return true;

        if (currentFilter === 'day') {
            return saleDate.toDateString() === now.toDateString();
        } else if (currentFilter === 'week') {
            const startOfWeek = new Date(now);
            startOfWeek.setDate(now.getDate() - now.getDay());
            startOfWeek.setHours(0,0,0,0);
            return saleDate >= startOfWeek;
        } else if (currentFilter === 'month') {
            return saleDate.getMonth() === now.getMonth() && saleDate.getFullYear() === now.getFullYear();
        } else if (currentFilter === 'year') {
            return saleDate.getFullYear() === now.getFullYear();
        }
        return true;
    });

    let totalRev = 0;
    let totalColl = 0;
    let totalGrams = 0;
    const custMap = {};

    filtered.forEach(sale => {
        const cost = sale.cost || 0;
        const paid = sale.totalPaid || 0;
        totalRev += cost;
        totalColl += paid;

        const match = String(sale.weight || '').match(/^([\d.]+)/);
        if (match && String(sale.weight).includes('g')) {
            totalGrams += parseFloat(match[1]);
        }

        const cust = sale.name || 'Unknown';
        if (!custMap[cust]) custMap[cust] = { revenue: 0, count: 0 };
        custMap[cust].revenue += cost;
        custMap[cust].count += 1;
    });

    document.getElementById('analytics-revenue').innerText = '$' + totalRev.toFixed(2);
    document.getElementById('analytics-collected').innerText = '$' + totalColl.toFixed(2);
    document.getElementById('analytics-grams').innerText = totalGrams.toFixed(2) + 'g';
    document.getElementById('analytics-count').innerText = filtered.length;

    const custDiv = document.getElementById('analytics-customers');
    const sortedCusts = Object.entries(custMap).sort((a,b) => b[1].revenue - a.revenue);

    if (sortedCusts.length === 0) {
        custDiv.innerHTML = '<p class="loading">No customer analytics for this period.</p>';
        return;
    }

    custDiv.innerHTML = sortedCusts.map(([cust, data]) => `
        <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
            <div>
                <strong>${escapeHtml(cust)}</strong>
                <br><small style="color: var(--text-muted);">${data.count} transaction(s)</small>
            </div>
            <div style="text-align: right; font-family: monospace; color: var(--teal-accent);">
                $${data.revenue.toFixed(2)}
            </div>
        </div>
    `).join('');
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
EJS

echo "[+] Restarting server..."
./run.sh
