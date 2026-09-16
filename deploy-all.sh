#!/bin/bash
echo "========================================================"
echo " [EB Enterprises®] Initializing Global Enagic® Ecosystem "
echo "========================================================"

# Clean up any partial legacy folders
rm -rf enagic-ecosystem
mkdir -p enagic-ecosystem/{01-lead-capture,02-education-engine,03-consultation-booking,04-conversion-checkout,05-distributor-ascension}

# --------------------------------------------------------
# Build Module 1: Lead Capture
# --------------------------------------------------------
echo "[+] Building Module 1: Lead Capture..."
cd enagic-ecosystem/01-lead-capture
mkdir -p assets/css backend database

cat << 'CSS' > assets/css/executive-spectrum.css
:root { --bg-obsidian: #0B0C10; --gold-champagne: #D4AF37; --teal-accent: #008080; --text-light: #C5C6C7; --surface-dark: #1F2833; }
body { background-color: var(--bg-obsidian); color: var(--text-light); font-family: 'Segoe UI', Tahoma, sans-serif; margin: 0; padding: 40px; }
.card { background: var(--surface-dark); border-left: 4px solid var(--teal-accent); padding: 30px; max-width: 550px; margin: 0 auto; border-radius: 6px; box-shadow: 0 8px 16px rgba(0,0,0,0.5); }
h2 { color: var(--gold-champagne); margin-top: 0; }
input { width: 100%; padding: 12px; margin: 12px 0; background: var(--bg-obsidian); border: 1px solid var(--teal-accent); color: #fff; border-radius: 4px; box-sizing: border-box; }
button { background: var(--gold-champagne); color: var(--bg-obsidian); border: none; padding: 14px; width: 100%; font-weight: bold; cursor: pointer; border-radius: 4px; font-size: 1rem; }
button:hover { background: var(--teal-accent); color: #fff; }
CSS

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Stage 1: Lead Capture & Sovereign Traffic</title>
    <link rel="stylesheet" href="assets/css/executive-spectrum.css">
</head>
<body>
    <div class="card">
        <h2>Claim Your Free Kangen Water Guide®</h2>
        <p>Enter your details below to access medical-grade Japanese water ionizer research and sovereign hydration frameworks.</p>
        <form action="/api/lead/capture" method="POST">
            <input type="text" name="name" placeholder="Full Name" required>
            <input type="email" name="email" placeholder="Email Address" required>
            <input type="tel" name="phone" placeholder="Phone Number" required>
            <button type="submit">Unlock Educational Assets</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > backend/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, '../')));

const db = new sqlite3.Database(path.join(__dirname, '../database/leads.db'), (err) => {
    if (err) console.error("DB Error:", err.message);
    else console.log("[Module 1] Connected to SQLite Lead Store.");
});

db.run(`CREATE TABLE IF NOT EXISTS leads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT,
    phone TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)`);

app.post('/api/lead/capture', (req, res) => {
    const { name, email, phone } = req.body;
    db.run(`INSERT INTO leads (name, email, phone) VALUES (?, ?, ?)`, [name, email, phone], (err) => {
        if (err) {
            res.status(500).send("Database write failure.");
        } else {
            console.log(`[Lead Captured] ${email}`);
            res.redirect('/../02-education-engine/index.html');
        }
    });
});

app.listen(PORT, () => console.log(`[Module 1] Running on port ${PORT}`));
JS

cat << 'JSON' > package.json
{
  "name": "enagic-module-1-capture",
  "version": "1.0.0",
  "main": "backend/server.js",
  "scripts": { "start": "node backend/server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
JSON
npm install > /dev/null 2>&1
cd ../../..

# --------------------------------------------------------
# Build Module 2: Education Engine
# --------------------------------------------------------
echo "[+] Building Module 2: Education Engine..."
cd enagic-ecosystem/02-education-engine
mkdir -p assets/css

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Stage 2: Micro-Webinar & Science Breakdown</title>
    <link rel="stylesheet" href="../01-lead-capture/assets/css/executive-spectrum.css">
</head>
<body>
    <div class="card" style="max-width: 750px; text-align: center;">
        <h2>The Japanese Engineering & Science of Ionization</h2>
        <p>Asynchronous masterclass breaking down active hydrogen, negative ORP, and cellular hydration.</p>
        <div style="background: #000; height: 350px; display: flex; align-items: center; justify-content: center; border: 1px solid #008080; margin: 25px 0; border-radius: 4px;">
            <span style="color: #008080; font-weight: bold; font-size: 1.2rem;">[SECURE KANGEN WATER STREAM ACTIVE]</span>
        </div>
        <button onclick="window.location.href='../03-consultation-booking/index.html'">Proceed to Consultation & Water Sampling</button>
    </div>
</body>
</html>
HTML
cd ../../..

# --------------------------------------------------------
# Build Module 3: Consultation Booking
# --------------------------------------------------------
echo "[+] Building Module 3: Consultation Booking..."
cd enagic-ecosystem/03-consultation-booking
mkdir -p assets/css backend database

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Stage 3: Consultation & Sampling Booking</title>
    <link rel="stylesheet" href="../01-lead-capture/assets/css/executive-spectrum.css">
</head>
<body>
    <div class="card">
        <h2>Schedule Your Water Sampling Session</h2>
        <p>Select your preferred consultation window for live water testing and health ROI evaluation.</p>
        <form action="/api/booking/submit" method="POST">
            <input type="text" name="client_name" placeholder="Full Name" required>
            <input type="date" name="consult_date" required>
            <input type="time" name="consult_time" required>
            <button type="submit">Lock Consultation Slot</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > backend/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3003;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, '../')));

const db = new sqlite3.Database(path.join(__dirname, '../database/bookings.db'));
db.run(`CREATE TABLE IF NOT EXISTS bookings (id INTEGER PRIMARY KEY AUTOINCREMENT, client_name TEXT, consult_date TEXT, consult_time TEXT)`);

app.post('/api/booking/submit', (req, res) => {
    const { client_name, consult_date, consult_time } = req.body;
    db.run(`INSERT INTO bookings (client_name, consult_date, consult_time) VALUES (?, ?, ?)`, [client_name, consult_date, consult_time], () => {
        res.redirect('/../04-conversion-checkout/index.html');
    });
});

app.listen(PORT, () => console.log(`[Module 3] Running on port ${PORT}`));
JS

cat << 'JSON' > package.json
{
  "name": "enagic-module-3-booking",
  "version": "1.0.0",
  "main": "backend/server.js",
  "scripts": { "start": "node backend/server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
JSON
npm install > /dev/null 2>&1
cd ../../..

# --------------------------------------------------------
# Build Module 4: Conversion Checkout
# --------------------------------------------------------
echo "[+] Building Module 4: Conversion Checkout..."
cd enagic-ecosystem/04-conversion-checkout
mkdir -p assets/css backend database

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Stage 4: Core Product Closing & Checkout</title>
    <link rel="stylesheet" href="../01-lead-capture/assets/css/executive-spectrum.css">
</head>
<body>
    <div class="card">
        <h2>K8 / SD501 Secure Acquisition Portal</h2>
        <p>Select your fulfillment path: Direct Purchase or Approved In-House Financing.</p>
        <form action="/api/checkout/process" method="POST">
            <input type="text" name="buyer_name" placeholder="Full Billing Name" required>
            <input type="text" name="model" placeholder="Model Selection (K8 or SD501)" required>
            <select name="payment_type" style="width: 100%; padding: 12px; margin: 12px 0; background: #0B0C10; color: #fff; border: 1px solid #008080; border-radius: 4px;">
                <option value="direct">Direct Payment (Full Settlement)</option>
                <option value="financing">Enagic Approved Financing Program</option>
            </select>
            <button type="submit">Complete Secure Order</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > backend/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3004;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, '../')));

const db = new sqlite3.Database(path.join(__dirname, '../database/orders.db'));
db.run(`CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, buyer_name TEXT, model TEXT, payment_type TEXT)`);

app.post('/api/checkout/process', (req, res) => {
    const { buyer_name, model, payment_type } = req.body;
    db.run(`INSERT INTO orders (buyer_name, model, payment_type) VALUES (?, ?, ?)`, [buyer_name, model, payment_type], () => {
        res.redirect('/../05-distributor-ascension/index.html');
    });
});

app.listen(PORT, () => console.log(`[Module 4] Running on port ${PORT}`));
JS

cat << 'JSON' > package.json
{
  "name": "enagic-module-4-checkout",
  "version": "1.0.0",
  "main": "backend/server.js",
  "scripts": { "start": "node backend/server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
JSON
npm install > /dev/null 2>&1
cd ../../..

# --------------------------------------------------------
# Build Module 5: Distributor Ascension
# --------------------------------------------------------
echo "[+] Building Module 5: Distributor Ascension..."
cd enagic-ecosystem/05-distributor-ascension
mkdir -p assets/css backend database

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Stage 5: Distributor Ascension & Nexus Affiliate Engine®</title>
    <link rel="stylesheet" href="../01-lead-capture/assets/css/executive-spectrum.css">
</head>
<body>
    <div class="card">
        <h2>Nexus Affiliate Engine® Activation</h2>
        <p>Transition from customer to independent distributor. Unlock your 8-Point Commission Tracking Dashboard.</p>
        <form action="/api/distributor/activate" method="POST">
            <input type="text" name="distributor_name" placeholder="Legal Distributorship Name" required>
            <input type="text" name="sponsor_id" placeholder="Enagic Sponsor ID (e.g., 6A-Pool)" required>
            <button type="submit">Activate 6A Independent Distributorship</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > backend/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3005;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, '../')));

const db = new sqlite3.Database(path.join(__dirname, '../database/distributors.db'));
db.run(`CREATE TABLE IF NOT EXISTS distributors (id INTEGER PRIMARY KEY AUTOINCREMENT, distributor_name TEXT, sponsor_id TEXT, status TEXT)`);

app.post('/api/distributor/activate', (req, res) => {
    const { distributor_name, sponsor_id } = req.body;
    db.run(`INSERT INTO distributors (distributor_name, sponsor_id, status) VALUES (?, ?, ?)`, [distributor_name, sponsor_id, 'Active 8-Point Node'], () => {
        res.send(`<div style="background:#0B0C10;color:#D4AF37;padding:50px;text-align:center;font-family:sans-serif;"><h1>Distributorship Successfully Activated!</h1><p>Welcome to the EB Enterprises® / Enagic® Global Distribution Network.</p></div>`);
    });
});

app.listen(PORT, () => console.log(`[Module 5] Running on port ${PORT}`));
JS

cat << 'JSON' > package.json
{
  "name": "enagic-module-5-distributor",
  "version": "1.0.0",
  "main": "backend/server.js",
  "scripts": { "start": "node backend/server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
JSON
npm install > /dev/null 2>&1
cd ../../..

echo "========================================================"
echo " [EB Enterprises®] All Modules Provisioned Successfully!"
echo "========================================================"
