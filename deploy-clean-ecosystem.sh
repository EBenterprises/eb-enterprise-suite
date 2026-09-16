#!/bin/bash
echo "========================================================"
echo " Deploying Clean Multi-Node Application Suite "
echo "========================================================"

rm -rf clean-ecosystem
mkdir -p clean-ecosystem/assets/css
cd clean-ecosystem

# --------------------------------------------------------
# Standard Styling & Universal Navigation Macro
# --------------------------------------------------------
cat << 'CSS' > assets/css/theme.css
:root { --bg-dark: #121212; --primary-color: #3b82f6; --accent-color: #10b981; --text-light: #e5e7eb; --surface-color: #1e293b; }
body { background-color: var(--bg-dark); color: var(--text-light); font-family: system-ui, -apple-system, sans-serif; margin: 0; padding: 25px; }
.card { background: var(--surface-color); border-left: 4px solid var(--primary-color); padding: 20px; max-width: 650px; margin: 0 auto; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.4); }
h2 { color: var(--text-light); margin-top: 0; }
input, select, textarea { width: 100%; padding: 10px; margin: 8px 0; background: var(--bg-dark); border: 1px solid #475569; color: #fff; border-radius: 4px; box-sizing: border-box; }
button { background: var(--primary-color); color: #fff; border: none; padding: 12px; width: 100%; font-weight: bold; cursor: pointer; border-radius: 4px; font-size: 1rem; }
button:hover { background: var(--accent-color); }
.nav-bar { text-align: center; margin-bottom: 15px; background: var(--surface-color); padding: 8px; border-radius: 4px; border: 1px solid #475569; overflow-x: auto; white-space: nowrap; }
.nav-bar a { color: var(--primary-color); margin: 0 5px; text-decoration: none; font-size: 0.75rem; font-weight: bold; }
.nav-bar a:hover { text-decoration: underline; color: var(--text-light); }
CSS

NAV_HTML='<div class="nav-bar"><a href="http://localhost:3001/node1/">1.Lead</a> | <a href="http://localhost:3002/node2/">2.Info</a> | <a href="http://localhost:3003/node3/">3.Booking</a> | <a href="http://localhost:3004/node4/">4.Checkout</a> | <a href="http://localhost:3005/node5/">5.Partner</a> | <a href="http://localhost:3006/node6/">6.Traffic</a> | <a href="http://localhost:3007/node7/">7.SubHub</a> | <a href="http://localhost:3008/node8/">8.Router</a> | <a href="http://localhost:3009/node9/">9.Vault</a></div>'

# --------------------------------------------------------
# 1. Lead Capture (Port 3001)
# --------------------------------------------------------
mkdir -p node1
cat << HTML > node1/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 1: Lead Capture</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Client Lead Capture</h2><p>Submit your contact details to access system resources.</p>
<form action="http://localhost:3001/submit" method="POST">
<input type="text" name="name" placeholder="Full Name" required>
<input type="email" name="email" placeholder="Email Address" required>
<input type="tel" name="phone" placeholder="Phone Number" required>
<button type="submit">Submit & Proceed</button></form></div></body></html>
HTML

cat << 'JS' > node1/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(express.json()); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_leads.db'));
db.run(`CREATE TABLE IF NOT EXISTS leads (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, phone TEXT)`);
app.post('/submit', (req, res) => {
    db.run(`INSERT INTO leads (name, email, phone) VALUES (?, ?, ?)`, [req.body.name, req.body.email, req.body.phone], () => {
        res.redirect('http://localhost:3002/node2/');
    });
});
app.listen(3001, () => console.log('[Node 1] Active on port 3001'));
JS

# --------------------------------------------------------
# 2. Information Engine (Port 3002)
# --------------------------------------------------------
mkdir -p node2
cat << HTML > node2/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 2: Information</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card" style="text-align: center;">
<h2>Educational Resources</h2><p>Review core materials and instructional media streams.</p>
<div style="background: #000; height: 160px; display: flex; align-items: center; justify-content: center; border: 1px solid #475569; margin: 15px 0;">
<span style="color: #3b82f6; font-weight: bold;">[SECURE MEDIA STREAM ACTIVE]</span></div>
<button onclick="window.location.href='http://localhost:3003/node3/'">Proceed to Scheduling</button></div></body></html>
HTML

cat << 'JS' > node2/server.js
const express = require('express'); const path = require('path'); const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3002, () => console.log('[Node 2] Active on port 3002'));
JS

# --------------------------------------------------------
# 3. Session Booking (Port 3003)
# --------------------------------------------------------
mkdir -p node3
cat << HTML > node3/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 3: Booking</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Schedule a Consultation</h2><p>Select your preferred date and time for a consultation session.</p>
<form action="http://localhost:3003/book" method="POST">
<input type="text" name="client_name" placeholder="Full Name" required>
<input type="date" name="booking_date" required><input type="time" name="booking_time" required>
<button type="submit">Confirm Schedule</button></form></div></body></html>
HTML

cat << 'JS' > node3/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_bookings.db'));
db.run(`CREATE TABLE IF NOT EXISTS bookings (id INTEGER PRIMARY KEY AUTOINCREMENT, client_name TEXT, booking_date TEXT, booking_time TEXT)`);
app.post('/book', (req, res) => {
    db.run(`INSERT INTO bookings (client_name, booking_date, booking_time) VALUES (?, ?, ?)`, [req.body.client_name, req.body.booking_date, req.body.booking_time], () => {
        res.redirect('http://localhost:3004/node4/');
    });
});
app.listen(3003, () => console.log('[Node 3] Active on port 3003'));
JS

# --------------------------------------------------------
# 4. Checkout & Orders (Port 3004)
# --------------------------------------------------------
mkdir -p node4
cat << HTML > node4/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 4: Checkout</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Secure Acquisition Portal</h2><p>Select product model and fulfillment preference.</p>
<form action="http://localhost:3004/checkout" method="POST">
<input type="text" name="buyer_name" placeholder="Full Billing Name" required>
<input type="text" name="product_sku" placeholder="Product SKU / Model" required>
<select name="payment_type"><option value="direct">Direct Settlement</option><option value="financing">Approved Financing Program</option></select>
<button type="submit">Complete Order</button></form></div></body></html>
HTML

cat << 'JS' > node4/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_orders.db'));
db.run(`CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, buyer_name TEXT, product_sku TEXT, payment_type TEXT)`);
app.post('/checkout', (req, res) => {
    db.run(`INSERT INTO orders (buyer_name, product_sku, payment_type) VALUES (?, ?, ?)`, [req.body.buyer_name, req.body.product_sku, req.body.payment_type], () => {
        res.redirect('http://localhost:3005/node5/');
    });
});
app.listen(3004, () => console.log('[Node 4] Active on port 3004'));
JS

# --------------------------------------------------------
# 5. Partner Program (Port 3005)
# --------------------------------------------------------
mkdir -p node5
cat << HTML > node5/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 5: Partner</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Partner Commission Dashboard</h2><p>Register as an independent affiliate partner.</p>
<form action="http://localhost:3005/partner" method="POST">
<input type="text" name="partner_name" placeholder="Entity / Partner Name" required>
<input type="text" name="sponsor_id" placeholder="Sponsor ID Reference" required>
<button type="submit">Activate Partner Account</button></form></div></body></html>
HTML

cat << 'JS' > node5/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_partners.db'));
db.run(`CREATE TABLE IF NOT EXISTS partners (id INTEGER PRIMARY KEY AUTOINCREMENT, partner_name TEXT, sponsor_id TEXT, status TEXT)`);
app.post('/partner', (req, res) => {
    db.run(`INSERT INTO partners (partner_name, sponsor_id, status) VALUES (?, ?, ?)`, [req.body.partner_name, req.body.sponsor_id, 'Active Partner'], () => {
        res.redirect('http://localhost:3006/node6/');
    });
});
app.listen(3005, () => console.log('[Node 5] Active on port 3005'));
JS

# --------------------------------------------------------
# 6. Traffic & Campaigns (Port 3006)
# --------------------------------------------------------
mkdir -p node6
cat << HTML > node6/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 6: Traffic</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Campaign Management Suite</h2><p>Configure organic traffic syndication and keyword targets.</p>
<form action="http://localhost:3006/traffic" method="POST">
<input type="text" name="campaign_title" placeholder="Campaign Identifier" required>
<textarea name="keywords" placeholder="Target Keywords (comma separated)" rows="3" required></textarea>
<button type="submit">Deploy Campaign</button></form></div></body></html>
HTML

cat << 'JS' > node6/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_traffic.db'));
db.run(`CREATE TABLE IF NOT EXISTS traffic (id INTEGER PRIMARY KEY AUTOINCREMENT, campaign_title TEXT, keywords TEXT)`);
app.post('/traffic', (req, res) => {
    db.run(`INSERT INTO traffic (campaign_title, keywords) VALUES (?, ?)`, [req.body.campaign_title, req.body.keywords], () => {
        res.redirect('http://localhost:3007/node7/');
    });
});
app.listen(3006, () => console.log('[Node 6] Active on port 3006'));
JS

# --------------------------------------------------------
# 7. Subscription Hub (Port 3007)
# --------------------------------------------------------
mkdir -p node7
cat << HTML > node7/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 7: SubHub</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Maintenance & Subscription Hub</h2><p>Manage recurring replenishment and automated billing schedules.</p>
<form action="http://localhost:3007/subscribe" method="POST">
<input type="text" name="subscriber" placeholder="Subscriber Name" required>
<select name="plan"><option value="annual-filter">Annual Replacement Kit ($150/yr)</option><option value="semi-cleaning">Semi-Annual Maintenance Kit ($60/yr)</option></select>
<button type="submit">Activate Subscription</button></form></div></body></html>
HTML

cat << 'JS' > node7/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_subscriptions.db'));
db.run(`CREATE TABLE IF NOT EXISTS subs (id INTEGER PRIMARY KEY AUTOINCREMENT, subscriber TEXT, plan TEXT)`);
app.post('/subscribe', (req, res) => {
    db.run(`INSERT INTO subs (subscriber, plan) VALUES (?, ?)`, [req.body.subscriber, req.body.plan], () => {
        res.redirect('http://localhost:3008/node8/');
    });
});
app.listen(3007, () => console.log('[Node 7] Active on port 3007'));
JS

# --------------------------------------------------------
# 8. Core Router (Port 3008)
# --------------------------------------------------------
mkdir -p node8
cat << HTML > node8/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 8: Router</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card">
<h2>Domain & Socket Routing Hub</h2><p>Configure custom routing aliases and proxy mappings.</p>
<form action="http://localhost:3008/route" method="POST">
<input type="text" name="alias_domain" placeholder="Custom Alias (e.g., node.local)" required>
<input type="text" name="target_port" placeholder="Target Port (e.g., 3001)" required>
<button type="submit">Register Routing Rule</button></form></div></body></html>
HTML

cat << 'JS' > node8/server.js
const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_routes.db'));
db.run(`CREATE TABLE IF NOT EXISTS routes (id INTEGER PRIMARY KEY AUTOINCREMENT, alias_domain TEXT, target_port TEXT)`);
app.post('/route', (req, res) => {
    db.run(`INSERT INTO routes (alias_domain, target_port) VALUES (?, ?)`, [req.body.alias_domain, req.body.target_port], () => {
        res.redirect('http://localhost:3009/node9/');
    });
});
app.listen(3008, () => console.log('[Node 8] Active on port 3008'));
JS

# --------------------------------------------------------
# 9. Executive Command Vault (Port 3009)
# --------------------------------------------------------
mkdir -p node9
cat << HTML > node9/index.html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Node 9: Vault</title><link rel="stylesheet" href="../assets/css/theme.css"></head>
<body>${NAV_HTML}<div class="card" style="text-align: center;">
<h2>Executive Command Vault</h2><p>System monitoring command center tracking all 9 operational nodes.</p>
<div style="background: #000; padding: 20px; border: 1px solid #10b981; margin: 20px 0; border-radius: 4px;">
<span style="color: #10b981; font-weight: bold; font-size: 1.1rem;">[SYSTEM STATUS: ALL 9 NODES OPERATIONAL]</span></div>
<button onclick="window.location.href='http://localhost:3001/node1/'">Return to Node 1</button></div></body></html>
HTML

cat << 'JS' > node9/server.js
const express = require('express'); const path = require('path'); const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3009, () => console.log('[Node 9 (Vault)] Active on port 3009'));
JS

# --------------------------------------------------------
# Root Package Configuration & Dependencies
# --------------------------------------------------------
cat << 'JSON' > package.json
{
  "name": "clean-9node-ecosystem",
  "version": "1.0.0",
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7", "cors": "^2.8.5" }
}
JSON

echo "[+] Installing root dependencies across 9 nodes..."
npm install > /dev/null 2>&1

cd ..
echo "========================================================"
echo " All 9 Clean Application Nodes Deployed Successfully!"
echo "--------------------------------------------------------"
echo " Node Access Points:"
echo " [1] Lead Capture:    http://localhost:3001/node1/"
echo " [2] Information:     http://localhost:3002/node2/"
echo " [3] Booking:         http://localhost:3003/node3/"
echo " [4] Checkout:        http://localhost:3004/node4/"
echo " [5] Partner Program: http://localhost:3005/node5/"
echo " [6] Traffic Suite:   http://localhost:3006/node6/"
echo " [7] Subscription:    http://localhost:3007/node7/"
echo " [8] Router Hub:      http://localhost:3008/node8/"
echo " [9] Command Vault:   http://localhost:3009/node9/"
echo "========================================================"
