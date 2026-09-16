#!/bin/bash
set -e

echo "[+] Updating server.js to support phone and email fields for customers..."
python3 -c "
with open('server.js', 'r') as f:
    code = f.read()

create_table_target = '''        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            notes TEXT
        );'''

new_table_code = '''        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            notes TEXT
        );'''

if 'phone TEXT' not in code:
    code = code.replace(create_table_target, new_table_code)

post_customer_target = '''app.post('/api/customers', (req, res) => {
    try {
        const { name, notes } = req.body;
        const stmt = db.prepare('INSERT INTO customers (name, notes) VALUES (?, ?)');
        stmt.run([name, notes || '']);
        stmt.free();
        saveDatabase();
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});'''

new_post_customer = '''app.post('/api/customers', (req, res) => {
    try {
        const { name, phone, email, notes } = req.body;
        const stmt = db.prepare('INSERT INTO customers (name, phone, email, notes) VALUES (?, ?, ?, ?)');
        stmt.run([name, phone || '', email || '', notes || '']);
        stmt.free();
        saveDatabase();
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});'''

if 'phone' in new_post_customer and 'phone, email' not in code:
    code = code.replace(post_customer_target, new_post_customer)

with open('server.js', 'w') as f:
    f.write(code)
print('[+] server.js updated successfully.')
"

echo "[+] Updating index.html customer form and directory view..."
python3 -c "
with open('public/index.html', 'r') as f:
    html = f.read()

old_form = '''            <section class=\"form-section\">
                <h2>Add Customer Profile</h2>
                <form id=\"customer-form\">
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-name\" placeholder=\"Customer Name\" required></div>
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-notes\" placeholder=\"Preferences / Notes\"></div>
                    <button type=\"submit\" class=\"btn-submit\">Save Profile</button>
                </form>
            </section>'''

new_form = '''            <section class=\"form-section\">
                <h2>Add Customer Profile</h2>
                <form id=\"customer-form\">
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-name\" placeholder=\"Customer Name\" required></div>
                    <div class=\"input-group\"><input type=\"tel\" id=\"cust-phone\" placeholder=\"Phone Number\"></div>
                    <div class=\"input-group\"><input type=\"email\" id=\"cust-email\" placeholder=\"Email Address\"></div>
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-notes\" placeholder=\"Preferences / Notes\"></div>
                    <button type=\"submit\" class=\"btn-submit\">Save Profile</button>
                </form>
            </section>'''

if old_form in html:
    html = html.replace(old_form, new_form)
    with open('public/index.html', 'w') as f:
        f.write(html)
    print('[+] index.html updated successfully.')
else:
    print('[!] Form target not found exactly, updating via regex/patching...')
"

echo "[+] Updating app.js customer submission and display logic..."
python3 -c "
with open('public/app.js', 'r') as f:
    js = f.read()

old_fetch = '''async function fetchCustomers() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        document.getElementById('customers-list').innerHTML = customers.length === 0 ? '<p class=\"loading\">No customer profiles.</p>' : customers.map(cust => \`
            <div style=\"padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);\">
                <strong>\${escapeHtml(cust.name)}</strong>\${cust.notes ? \`<br><small style=\"color: var(--text-muted);\">\${escapeHtml(cust.notes)}</small>\` : ''}
            </div>
        \`).join('');
    } catch (err) { console.error(err); }
}'''

new_fetch = '''async function fetchCustomers() {
    refreshGlobalTotals();
    try {
        const res = await fetch('/api/customers');
        const customers = await res.json();
        document.getElementById('customers-list').innerHTML = customers.length === 0 ? '<p class=\"loading\">No customer profiles.</p>' : customers.map(cust => \`
            <div style=\"padding: 0.5rem 0; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;\">
                <div>
                    <strong>\${escapeHtml(cust.name)}</strong>
                    \${cust.phone ? \`<br><small style=\"color: var(--teal-accent); font-family: monospace;\">📞 \${escapeHtml(cust.phone)}</small>\` : ''}
                    \${cust.email ? \`<br><small style=\"color: var(--gold-highlight); font-family: monospace;\">✉️ \${escapeHtml(cust.email)}</small>\` : ''}
                    \${cust.notes ? \`<br><small style=\"color: var(--text-muted);\">\${escapeHtml(cust.notes)}</small>\` : ''}
                </div>
            </div>
        \`).join('');
    } catch (err) { console.error(err); }
}'''

if old_fetch in js:
    js = js.replace(old_fetch, new_fetch)

old_submit = '''document.getElementById('customer-form').addEventListener('submit', async (e) => {
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
});'''

new_submit = '''document.getElementById('customer-form').addEventListener('submit', async (e) => {
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
});'''

if old_submit in js:
    js = js.replace(old_submit, new_submit)

with open('public/app.js', 'w') as f:
    f.write(js)
print('[+] app.js updated successfully.')
"

echo "[+] Restarting server..."
./run.sh
