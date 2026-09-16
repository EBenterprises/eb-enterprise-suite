#!/bin/bash
set -e

echo "[+] Updating server.js database schema for customer phone numbers..."
python3 -c '
with open("server.js", "r") as f:
    code = f.read()

old_table = """        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            notes TEXT
        );"""

new_table = """        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            notes TEXT
        );"""

if "phone TEXT" not in code:
    code = code.replace(old_table, new_table)
    with open("server.js", "w") as f:
        f.write(code)
    print("[+] Updated server.js schema.")
else:
    print("[+] Phone column already in server.js.")
'

python3 -c '
with open("server.js", "r") as f:
    code = f.read()

old_post = """app.post(\x27/api/customers\x27, (req, res) => {
    try {
        const { name, notes } = req.body;
        const stmt = db.prepare(\x27INSERT INTO customers (name, notes) VALUES (?, ?)\x27);
        stmt.run([name, notes || \x27\x27]);"""

new_post = """app.post(\x27/api/customers\x27, (req, res) => {
    try {
        const { name, phone, notes } = req.body;
        const stmt = db.prepare(\x27INSERT INTO customers (name, phone, notes) VALUES (?, ?, ?)\x27);
        stmt.run([name, phone || \x27\x27, notes || \x27\x27]);"""

if "phone" not in code.split("app.post('/api/customers'")[1]:
    code = code.replace(old_post, new_post)
    with open("server.js", "w") as f:
        f.write(code)
    print("[+] Updated POST /api/customers handler.")
else:
    print("[+] POST handler already updated.")
'

echo "[+] Updating index.html customer form..."
python3 -c '
with open("public/index.html", "r") as f:
    html = f.read()

old_form = """            <section class=\"form-section\">
                <h2>Add Customer Profile</h2>
                <form id=\"customer-form\">
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-name\" placeholder=\"Customer Name\" required></div>
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-notes\" placeholder=\"Preferences / Notes\"></div>
                    <button type=\"submit\" class=\"btn-submit\">Save Profile</button>
                </form>
            </section>"""

new_form = """            <section class=\"form-section\">
                <h2>Add Customer Profile</h2>
                <form id=\"customer-form\">
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-name\" placeholder=\"Customer Name\" required></div>
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-phone\" placeholder=\"Phone Number\"></div>
                    <div class=\"input-group\"><input type=\"text\" id=\"cust-notes\" placeholder=\"Preferences / Notes\"></div>
                    <button type=\"submit\" class=\"btn-submit\">Save Profile</button>
                </form>
            </section>"""

if "cust-phone" not in html:
    html = html.replace(old_form, new_form)
    with open("public/index.html", "w") as f:
        f.write(html)
    print("[+] Added phone input field to index.html.")
else:
    print("[+] Phone input already present in index.html.")
'

echo "[+] Updating app.js customer rendering and submission..."
python3 -c '
with open("public/app.js", "r") as f:
    js = f.read()

old_fetch = """async function fetchCustomers() {
    refreshGlobalTotals();
    try {
        const res = await fetch(\x27/api/customers\x27);
        const customers = await res.json();
        document.getElementById(\x27customers-list\x27).innerHTML = customers.length === 0 ? \x27<p class=\"loading\">No customer profiles.</p>\x27 : customers.map(cust => `
            <div style=\"padding: 0.5rem 0; border-bottom: 1px solid var(--border-color);\">
                <strong>${escapeHtml(cust.name)}</strong>${cust.notes ? `<br><small style=\"color: var(--text-muted);\">${escapeHtml(cust.notes)}</small>` : \x27\x27}
            </div>
        `).join(\x27\x27);
    } catch (err) { console.error(err); }
}"""

new_fetch = """async function fetchCustomers() {
    refreshGlobalTotals();
    try {
        const res = await fetch(\x27/api/customers\x27);
        const customers = await res.json();
        document.getElementById(\x27customers-list\x27).innerHTML = customers.length === 0 ? \x27<p class=\"loading\">No customer profiles.</p>\x27 : customers.map(cust => `
            <div style=\"padding: 0.5rem 0; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;\">
                <div>
                    <strong>${escapeHtml(cust.name)}</strong>
                    ${cust.phone ? `<br><small style=\"color: var(--teal-accent); font-family: monospace;\">&#9743; ${escapeHtml(cust.phone)}</small>` : \x27\x27}
                    ${cust.notes ? `<br><small style=\"color: var(--text-muted);\">${escapeHtml(cust.notes)}</small>` : \x27\x27}
                </div>
            </div>
        `).join(\x27\x27);
    } catch (err) { console.error(err); }
}"""

old_submit = """document.getElementById(\x27customer-form\x27).addEventListener(\x27submit\x27, async (e) => {
    e.preventDefault();
    const name = document.getElementById(\x27cust-name\x27).value;
    const notes = document.getElementById(\x27cust-notes\x27).value;

    const res = await fetch(\x27/api/customers\x27, {
        method: \x27POST\x27,
        headers: { \x27Content-Type\x27: \x27application/json\x27 },
        body: JSON.stringify({ name, notes })
    });

    if (res.ok) {
        document.getElementById(\x27customer-form\x27).reset();
        fetchCustomers();
    }
});"""

new_submit = """document.getElementById(\x27customer-form\x27).addEventListener(\x27submit\x27, async (e) => {
    e.preventDefault();
    const name = document.getElementById(\x27cust-name\x27).value;
    const phone = document.getElementById(\x27cust-phone\x27).value;
    const notes = document.getElementById(\x27cust-notes\x27).value;

    const res = await fetch(\x27/api/customers\x27, {
        method: \x27POST\x27,
        headers: { \x27Content-Type\x27: \x27application/json\x27 },
        body: JSON.stringify({ name, phone, notes })
    });

    if (res.ok) {
        document.getElementById(\x27customer-form\x27).reset();
        fetchCustomers();
    }
});"""

if "cust-phone" not in js:
    js = js.replace(old_fetch, new_fetch)
    js = js.replace(old_submit, new_submit)
    with open("public/app.js", "w") as f:
        f.write(js)
    print("[+] Updated app.js for customer phone handling.")
else:
    print("[+] app.js already updated.")
'

echo "[+] Restarting server..."
./run.sh
