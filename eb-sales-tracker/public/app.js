function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    
    document.getElementById(`tab-${tabName}`).classList.add('active');
    event.currentTarget.classList.add('active');

    if (tabName === 'sales') fetchSales();
    if (tabName === 'inventory') fetchInventory();
    if (tabName === 'customers') fetchCustomers();
    if (tabName === 'analytics') fetchAnalytics();
}

function applyPreset(itemName, price) {
    document.getElementById('item').value = itemName;
    document.getElementById('amount').value = price;
}

function togglePartialInput() {
    const status = document.getElementById('payment-status').value;
    const partialGroup = document.getElementById('partial-group');
    partialGroup.style.display = status === 'partial' ? 'block' : 'none';
}

async function fetchSales() {
    try {
        const res = await fetch('/api/sales');
        const sales = await res.json();
        const listEl = document.getElementById('sales-list');
        
        if (sales.length === 0) {
            listEl.innerHTML = '<p class="loading">No sales recorded.</p>';
            return;
        }

        listEl.innerHTML = sales.map(sale => {
            let statusBadge = '';
            if (sale.payment_status === 'paid') {
                statusBadge = '<span style="color: var(--teal-accent); font-size: 0.8rem;">[PAID]</span>';
            } else if (sale.payment_status === 'unpaid') {
                statusBadge = '<span style="color: #ef4444; font-size: 0.8rem;">[UNPAID]</span>';
            } else {
                statusBadge = `<span style="color: var(--gold-highlight); font-size: 0.8rem;">[PARTIAL: $${parseFloat(sale.paid_amount).toFixed(2)}]</span>`;
            }

            return `
                <div class="sale-item">
                    <div>
                        <strong>${escapeHtml(sale.item)}</strong> ${statusBadge}
                        ${sale.customer ? `<br><small style="color: var(--gold-highlight);">${escapeHtml(sale.customer)}</small>` : ''}
                        <br><span class="timestamp">${sale.created_at || 'Just now'}</span>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace; font-size: 1.1rem;">$${parseFloat(sale.amount).toFixed(2)}</div>
                </div>
            `;
        }).join('');
    } catch (err) {
        console.error('Error fetching sales:', err);
    }
}

async function fetchInventory() {
    try {
        const res = await fetch('/api/inventory');
        const items = await res.json();
        const listEl = document.getElementById('inventory-list');
        
        if (items.length === 0) {
            listEl.innerHTML = '<p class="loading">No inventory stock added.</p>';
            return;
        }

        listEl.innerHTML = items.map(item => `
            <div class="inventory-item">
                <div>
                    <strong>${escapeHtml(item.name)}</strong>
                    <br><small style="color: var(--text-muted);">Qty: ${parseFloat(item.quantity).toFixed(2)}</small>
                </div>
                <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(item.price).toFixed(2)}</div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching inventory:', err);
    }
}

async function fetchCustomers() {
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        const listEl = document.getElementById('customers-list');
        
        if (customers.length === 0) {
            listEl.innerHTML = '<p class="loading">No customer profiles.</p>';
            return;
        }

        listEl.innerHTML = customers.map(cust => `
            <div class="customer-item">
                <div>
                    <strong>${escapeHtml(cust.name)}</strong>
                    ${cust.notes ? `<br><small style="color: var(--text-muted);">${escapeHtml(cust.notes)}</small>` : ''}
                </div>
            </div>
        `).join('');
    } catch (err) {
        console.error('Error fetching customers:', err);
    }
}

async function fetchAnalytics() {
    try {
        const res = await fetch('/api/analytics');
        const data = await res.json();

        document.getElementById('total-revenue-display').innerText = `$${parseFloat(data.total_revenue).toFixed(2)}`;
        document.getElementById('total-collected-display').innerText = `$${parseFloat(data.total_collected).toFixed(2)}`;

        const custEl = document.getElementById('per-customer-list');
        if (data.per_customer.length === 0) {
            custEl.innerHTML = '<p class="loading">No customer sales recorded.</p>';
        } else {
            custEl.innerHTML = data.per_customer.map(c => `
                <div class="analytics-row">
                    <div>
                        <strong>${escapeHtml(c.customer)}</strong>
                        <br><small class="timestamp">${c.transaction_count} transaction(s) | Paid: $${parseFloat(c.total_paid).toFixed(2)}</small>
                    </div>
                    <div style="color: var(--teal-accent); font-family: monospace;">$${parseFloat(c.total_spent).toFixed(2)}</div>
                </div>
            `).join('');
        }

        const dayEl = document.getElementById('day-history-list');
        if (data.day_by_day.length === 0) {
            dayEl.innerHTML = '<p class="loading">No daily history available.</p>';
        } else {
            dayEl.innerHTML = data.day_by_day.map(d => `
                <div class="analytics-row">
                    <div>
                        <strong>${d.sale_date}</strong>
                        <br><small class="timestamp">${d.daily_count} sale(s) | Collected: $${parseFloat(d.daily_collected).toFixed(2)}</small>
                    </div>
                    <div style="color: var(--gold-highlight); font-family: monospace;">$${parseFloat(d.daily_total).toFixed(2)}</div>
                </div>
            `).join('');
        }
    } catch (err) {
        console.error('Error fetching analytics:', err);
    }
}

document.getElementById('sale-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const item = document.getElementById('item').value;
    const amount = parseFloat(document.getElementById('amount').value);
    const customer = document.getElementById('customer').value;
    const payment_status = document.getElementById('payment-status').value;
    const paid_amount = document.getElementById('paid-amount').value;
    const timestamp = new Date().toLocaleString();

    const res = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ item, amount, customer, payment_status, paid_amount, timestamp })
    });

    if (res.ok) {
        document.getElementById('sale-form').reset();
        document.getElementById('partial-group').style.display = 'none';
        fetchSales();
    }
});

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
    const notes = document.getElementById('cust-notes').value;

    const res = await fetch('/api/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, notes })
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
