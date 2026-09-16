let currentFilter = 'all';

function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    
    document.getElementById(`tab-${tabName}`).classList.add('active');
    event.currentTarget.classList.add('active');

    if (tabName === 'sales') fetchSales();
    if (tabName === 'payments') fetchPayments();
    if (tabName === 'inventory') fetchInventory();
    if (tabName === 'customers') fetchCustomers();
    if (tabName === 'analytics') fetchAnalytics();
    refreshGlobalTotals();
}

async function refreshGlobalTotals() {
    try {
        const res = await fetch('/api/analytics?filter=all');
        const data = await res.json();
        document.getElementById('global-rev').innerText = `$${parseFloat(data.total_revenue).toFixed(2)}`;
        document.getElementById('global-collected').innerText = `$${parseFloat(data.total_collected).toFixed(2)}`;
        document.getElementById('global-grams').innerText = `${parseFloat(data.total_grams).toFixed(2)}g`;
    } catch (err) { console.error(err); }
}

function applyPreset(weightVal, costVal) {
    document.getElementById('weight').value = weightVal;
    document.getElementById('cost').value = costVal;
}

function togglePartialInput() {
    const status = document.getElementById('payment-status').value;
    document.getElementById('partial-group').style.display = status === 'partial' ? 'block' : 'none';
}

async function fetchSales() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        const tbodyEl = document.getElementById('sales-table-body');
        
        if (sales.length === 0) {
            tbodyEl.innerHTML = '<tr><td colspan="7" class="loading">No transactions recorded.</td></tr>';
            return;
        }

        tbodyEl.innerHTML = sales.map(sale => {
            const dateStr = new Date(sale.timestamp).toLocaleString();
            let statusBadge = '';
            if (sale.payment_status === 'paid') {
                statusBadge = `<span style="color: var(--teal-accent); font-weight: bold;">PAID ($${parseFloat(sale.paid_amount).toFixed(2)})</span>`;
            } else if (sale.payment_status === 'unpaid') {
                statusBadge = `<span style="color: #ef4444; font-weight: bold;">UNPAID ($0.00 / $${parseFloat(sale.cost).toFixed(2)})</span>`;
            } else {
                statusBadge = `<span style="color: var(--gold-highlight); font-weight: bold;">PARTIAL ($${parseFloat(sale.paid_amount).toFixed(2)} / $${parseFloat(sale.cost).toFixed(2)})</span>`;
            }

            const paymentsJson = encodeURIComponent(JSON.stringify(sale.payments || []));

            return `
                <tr>
                    <td class="timestamp">${dateStr}</td>
                    <td><strong>${escapeHtml(sale.name)}</strong></td>
                    <td style="font-family: monospace; color: var(--gold-highlight);">${escapeHtml(sale.weight)}</td>
                    <td>${escapeHtml(sale.item)}</td>
                    <td style="font-family: monospace; font-weight: bold;">$${parseFloat(sale.cost).toFixed(2)}</td>
                    <td>
                        ${statusBadge}
                        <br><button class="action-link" onclick="openPaymentModal(${sale.id}, '${escapeHtml(sale.name)}', ${sale.cost}, ${sale.paid_amount}, '${paymentsJson}')">Manage Payments</button>
                    </td>
                    <td><button class="btn-delete" onclick="deleteSale(${sale.id})">Delete</button></td>
                </tr>
            `;
        }).join('');
    } catch (err) { console.error(err); }
}

async function fetchPayments() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/payments');
        const payments = await res.json();
        const tbodyEl = document.getElementById('payments-table-body');

        if (payments.length === 0) {
            tbodyEl.innerHTML = '<tr><td colspan="6" class="loading">No payments recorded.</td></tr>';
            return;
        }

        tbodyEl.innerHTML = payments.map(p => {
            const dateStr = new Date(p.timestamp).toLocaleString();
            const linked = p.sale_id ? `<span style="color: var(--teal-accent);">Transaction #${p.sale_id}</span>` : `<span style="color: var(--gold-highlight);">Standalone Direct Payment</span>`;
            return `
                <tr>
                    <td class="timestamp">${dateStr}</td>
                    <td><strong>${escapeHtml(p.customer_name || 'General')}</strong></td>
                    <td style="font-family: monospace; color: var(--gold-highlight); font-weight: bold;">$${parseFloat(p.amount).toFixed(2)}</td>
                    <td>${escapeHtml(p.notes || '')}</td>
                    <td>${linked}</td>
                    <td><button class="btn-delete" onclick="deletePayment(${p.id})">Delete</button></td>
                </tr>
            `;
        }).join('');
    } catch (err) { console.error(err); }
}

async function deleteSale(id) {
    if (!confirm('Are you sure you want to delete this transaction?')) return;
    const res = await fetch(`/api/sales/${id}`, { method: 'DELETE' });
    if (res.ok) fetchSales();
}

async function deletePayment(id) {
    if (!confirm('Are you sure you want to delete this payment record?')) return;
    const res = await fetch(`/api/payments/${id}`, { method: 'DELETE' });
    if (res.ok) {
        fetchPayments();
        if (document.getElementById('tab-sales').classList.contains('active')) fetchSales();
    }
}

function openPaymentModal(id, name, cost, paid, paymentsEncoded) {
    const payments = JSON.parse(decodeURIComponent(paymentsEncoded));
    document.getElementById('modal-sale-id').value = id;
    document.getElementById('modal-sale-info').innerText = `${name} | Total Cost: $${cost.toFixed(2)} | Paid: $${paid.toFixed(2)}`;
    document.getElementById('payment-amount').value = Math.max(0, cost - paid).toFixed(2);
    document.getElementById('payment-notes').value = '';

    const historyEl = document.getElementById('modal-payments-history');
    if (payments.length === 0) {
        historyEl.innerHTML = '<small style="color: var(--text-muted);">No installments recorded.</small>';
    } else {
        historyEl.innerHTML = payments.map(p => `
            <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.3rem 0; border-bottom: 1px solid var(--border-color); font-size: 0.85rem;">
                <div>
                    <span style="color: var(--gold-highlight); font-family: monospace; font-weight: bold;">+$${parseFloat(p.amount).toFixed(2)}</span>
                    <br><small style="color: var(--text-muted);">${new Date(p.timestamp).toLocaleString()} — ${escapeHtml(p.notes || '')}</small>
                </div>
                <button class="btn-delete" style="padding: 0.1rem 0.4rem; font-size: 0.7rem;" onclick="deletePayment(${p.id}); closePaymentModal();">Remove</button>
            </div>
        `).join('');
    }
    document.getElementById('payment-modal').style.display = 'flex';
}

function closePaymentModal() {
    document.getElementById('payment-modal').style.display = 'none';
}

document.getElementById('payment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('modal-sale-id').value;
    const amount = document.getElementById('payment-amount').value;
    const notes = document.getElementById('payment-notes').value;

    const res = await fetch(`/api/sales/${id}/payment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount, notes })
    });

    if (res.ok) {
        closePaymentModal();
        fetchSales();
    }
});

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const rawTime = document.getElementById('sale-timestamp').value;
    const timestamp = rawTime ? new Date(rawTime).toISOString() : new Date().toISOString();
    const name = document.getElementById('name').value;
    const weight = document.getElementById('weight').value;
    const item = document.getElementById('item').value;
    const cost = parseFloat(document.getElementById('cost').value);
    const payment_status = document.getElementById('payment-status').value;
    const paid_amount = document.getElementById('paid-amount').value;

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timestamp, name, weight, item, cost, payment_status, paid_amount })
    });

    if (res.ok) {
        document.getElementById('sale-form').reset();
        document.getElementById('partial-group').style.display = 'none';
        fetchSales();
    }
});

document.getElementById('direct-payment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const rawTime = document.getElementById('pay-timestamp').value;
    const timestamp = rawTime ? new Date(rawTime).toISOString() : new Date().toISOString();
    const customer_name = document.getElementById('pay-customer').value;
    const amount = document.getElementById('pay-amount').value;
    const notes = document.getElementById('pay-notes').value;

    const res = await fetch('/api/payments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ customer_name, amount, notes, timestamp })
    });

    if (res.ok) {
        document.getElementById('direct-payment-form').reset();
        fetchPayments();
    }
});

function setFilter(filterType, event) {
    currentFilter = filterType;
    document.querySelectorAll('.filter-btn').forEach(el => el.classList.remove('active'));
    event.currentTarget.classList.add('active');

    const labels = { all: 'All Time', day: 'Today', week: 'This Week', month: 'This Month', year: 'This Year' };
    document.getElementById('filter-label').innerText = labels[filterType];
    fetchAnalytics();
}

async function fetchAnalytics() {
    refreshGlobalTotals();
    try {
        const res = await fetch(`/api/analytics?filter=${currentFilter}`);
        const data = await res.json();

        document.getElementById('analytics-revenue').innerText = `$${parseFloat(data.total_revenue).toFixed(2)}`;
        document.getElementById('analytics-collected').innerText = `$${parseFloat(data.total_collected).toFixed(2)}`;
        document.getElementById('analytics-grams').innerText = `${parseFloat(data.total_grams).toFixed(2)}g`;
        document.getElementById('analytics-count').innerText = data.total_count;

        const custEl = document.getElementById('analytics-customers');
        if (data.per_customer.length === 0) {
            custEl.innerHTML = '<p class="loading">No customer activity for this period.</p>';
        } else {
            custEl.innerHTML = data.per_customer.map(c => `
                <div class="analytics-row" style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
                    <div>
                        <strong>${escapeHtml(c.name)}</strong>
                        <br><small class="timestamp">${c.transaction_count} transaction(s)</small>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace; font-weight: bold;">$${parseFloat(c.total_spent).toFixed(2)}</div>
                </div>
            `).join('');
        }
    } catch (err) { console.error(err); }
}

async function fetchInventory() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/inventory');
        const items = await res.json();
        document.getElementById('inventory-list').innerHTML = items.length === 0 ? '<p class="loading">No inventory stock added.</p>' : items.map(item => `
            <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);">
                <div><strong>${escapeHtml(item.name)}</strong><br><small style="color: var(--text-muted);">Qty: ${parseFloat(item.quantity).toFixed(2)}</small></div>
                <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(item.price).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) { console.error(err); }
}

async function fetchCustomers() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        document.getElementById('customers-list').innerHTML = customers.length === 0 ? '<p class="loading">No customer profiles.</p>' : customers.map(cust => `
            <div style="padding: 0.5rem 0; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong>${escapeHtml(cust.name)}</strong>
                    ${cust.phone ? `<br><small style="color: var(--teal-accent); font-family: monospace;">📞 ${escapeHtml(cust.phone)}</small>` : ''}
                    ${cust.email ? `<br><small style="color: var(--gold-highlight); font-family: monospace;">✉️ ${escapeHtml(cust.email)}</small>` : ''}
                    ${cust.notes ? `<br><small style="color: var(--text-muted);">${escapeHtml(cust.notes)}</small>` : ''}
                </div>
            </div>
        `).join('');
    } catch (err) { console.error(err); }
}

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

document.getElementById('customer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('cust-name').value;
    const phone = document.getElementById('cust-phone').value;
    const email = document.getElementById('cust-email').value;
    const notes = document.getElementById('cust-notes').value;

    const res = await fetch('/api/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, phone, email, notes })
    });

    if (res.ok) {
        document.getElementById('customer-form').reset();
        fetchCustomers();
    }
});

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

fetchSales();
