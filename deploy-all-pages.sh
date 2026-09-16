#!/bin/bash
echo "========================================================"
echo " [EB Enterprises®] Deploying All Ecosystem Pages & Servers "
echo "========================================================"

rm -rf enagic-ecosystem
mkdir -p enagic-ecosystem/assets/css
cd enagic-ecosystem

# --------------------------------------------------------
# Global Executive Spectrum Styling
# --------------------------------------------------------
cat << 'CSS' > assets/css/executive-spectrum.css
:root { --bg-obsidian: #0B0C10; --gold-champagne: #D4AF37; --teal-accent: #008080; --text-light: #C5C6C7; --surface-dark: #1F2833; }
body { background-color: var(--bg-obsidian); color: var(--text-light); font-family: 'Segoe UI', Tahoma, sans-serif; margin: 0; padding: 40px; }
.card { background: var(--surface-dark); border-left: 4px solid var(--teal-accent); padding: 30px; max-width: 550px; margin: 0 auto; border-radius: 6px; box-shadow: 0 8px 16px rgba(0,0,0,0.5); }
h2 { color: var(--gold-champagne); margin-top: 0; }
input, select { width: 100%; padding: 12px; margin: 12px 0; background: var(--bg-obsidian); border: 1px solid var(--teal-accent); color: #fff; border-radius: 4px; box-sizing: border-box; }
button { background: var(--gold-champagne); color: var(--bg-obsidian); border: none; padding: 14px; width: 100%; font-weight: bold; cursor: pointer; border-radius: 4px; font-size: 1rem; }
button:hover { background: var(--teal-accent); color: #fff; }
.nav-bar { text-align: center; margin-bottom: 25px; }
.nav-bar a { color: var(--gold-champagne); margin: 0 10px; text-decoration: none; font-size: 0.9rem; }
.nav-bar a:hover { text-decoration: underline; }
CSS

# --------------------------------------------------------
# 1. Lead Capture (Port 3001)
# --------------------------------------------------------
mkdir -p module1
cat << 'HTML' > module1/index.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Stage 1: Lead Capture</title><link rel="stylesheet" href="../assets/css/executive-spectrum.css"></head>
<body>
    <div class="nav-bar">
        <a href="http://localhost:3001">1. Lead</a> | <a href="http://localhost:3002">2. Education</a> | <a href="http://localhost:3003">3. Booking</a> | <a href="http://localhost:3004">4. Checkout</a> | <a href="http://localhost:3005">5. Distributor</a>
    </div>
    <div class="card">
        <h2>Claim Your Free Kangen Water Guide®</h2>
        <p>Enter your details to access research and hydration frameworks.</p>
        <form action="http://localhost:3001/capture" method="POST">
            <input type="text" name="name" placeholder="Full Name" required>
            <input type="email" name="email" placeholder="Email Address" required>
            <input type="tel" name="phone" placeholder="Phone Number" required>
            <button type="submit">Unlock Educational Assets</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > module1/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_leads.db'));
db.run(`CREATE TABLE IF NOT EXISTS leads (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, phone TEXT)`);

app.post('/capture', (req, res) => {
    const { name, email, phone } = req.body;
    db.run(`INSERT INTO leads (name, email, phone) VALUES (?, ?, ?)`, [name, email, phone], () => {
        res.redirect('http://localhost:3002');
    });
});
app.listen(3001, () => console.log('[Module 1] Lead Capture active on http://localhost:3001'));
JS

# --------------------------------------------------------
# 2. Education Engine (Port 3002)
# --------------------------------------------------------
mkdir -p module2
cat << 'HTML' > module2/index.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Stage 2: Education Engine</title><link rel="stylesheet" href="../assets/css/executive-spectrum.css"></head>
<body>
    <div class="nav-bar">
        <a href="http://localhost:3001">1. Lead</a> | <a href="http://localhost:3002">2. Education</a> | <a href="http://localhost:3003">3. Booking</a> | <a href="http://localhost:3004">4. Checkout</a> | <a href="http://localhost:3005">5. Distributor</a>
    </div>
    <div class="card" style="text-align: center;">
        <h2>The Science of Ionized Water</h2>
        <p>Masterclass breaking down active hydrogen and cellular hydration.</p>
        <div style="background: #000; height: 220px; display: flex; align-items: center; justify-content: center; border: 1px solid #008080; margin: 20px 0;">
            <span style="color: #008080; font-weight: bold;">[SECURE KANGEN WATER STREAM ACTIVE]</span>
        </div>
        <button onclick="window.location.href='http://localhost:3003'">Proceed to Consultation Booking</button>
    </div>
</body>
</html>
HTML

cat << 'JS' > module2/server.js
const express = require('express');
const path = require('path');
const app = express();
app.use(express.static(path.join(__dirname)));
app.listen(3002, () => console.log('[Module 2] Education Engine active on http://localhost:3002'));
JS

# --------------------------------------------------------
# 3. Consultation Booking (Port 3003)
# --------------------------------------------------------
mkdir -p module3
cat << 'HTML' > module3/index.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Stage 3: Consultation</title><link rel="stylesheet" href="../assets/css/executive-spectrum.css"></head>
<body>
    <div class="nav-bar">
        <a href="http://localhost:3001">1. Lead</a> | <a href="http://localhost:3002">2. Education</a> | <a href="http://localhost:3003">3. Booking</a> | <a href="http://localhost:3004">4. Checkout</a> | <a href="http://localhost:3005">5. Distributor</a>
    </div>
    <div class="card">
        <h2>Schedule Your Water Sampling Session</h2>
        <p>Select your consultation window for live water testing.</p>
        <form action="http://localhost:3003/book" method="POST">
            <input type="text" name="client_name" placeholder="Full Name" required>
            <input type="date" name="consult_date" required>
            <input type="time" name="consult_time" required>
            <button type="submit">Lock Consultation Slot</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > module3/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_bookings.db'));
db.run(`CREATE TABLE IF NOT EXISTS bookings (id INTEGER PRIMARY KEY AUTOINCREMENT, client_name TEXT, consult_date TEXT, consult_time TEXT)`);

app.post('/book', (req, res) => {
    const { client_name, consult_date, consult_time } = req.body;
    db.run(`INSERT INTO bookings (client_name, consult_date, consult_time) VALUES (?, ?, ?)`, [client_name, consult_date, consult_time], () => {
        res.redirect('http://localhost:3004');
    });
});
app.listen(3003, () => console.log('[Module 3] Consultation active on http://localhost:3003'));
JS

# --------------------------------------------------------
# 4. Conversion Checkout (Port 3004)
# --------------------------------------------------------
mkdir -p module4
cat << 'HTML' > module4/index.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Stage 4: Checkout</title><link rel="stylesheet" href="../assets/css/executive-spectrum.css"></head>
<body>
    <div class="nav-bar">
        <a href="http://localhost:3001">1. Lead</a> | <a href="http://localhost:3002">2. Education</a> | <a href="http://localhost:3003">3. Booking</a> | <a href="http://localhost:3004">4. Checkout</a> | <a href="http://localhost:3005">5. Distributor</a>
    </div>
    <div class="card">
        <h2>K8 / SD501 Secure Acquisition Portal</h2>
        <p>Select fulfillment path: Direct Purchase or Financing.</p>
        <form action="http://localhost:3004/checkout" method="POST">
            <input type="text" name="buyer_name" placeholder="Full Billing Name" required>
            <input type="text" name="model" placeholder="Model Selection (K8 or SD501)" required>
            <select name="payment_type">
                <option value="direct">Direct Payment (Full Settlement)</option>
                <option value="financing">Enagic Approved Financing Program</option>
            </select>
            <button type="submit">Complete Secure Order</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > module4/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_orders.db'));
db.run(`CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, buyer_name TEXT, model TEXT, payment_type TEXT)`);

app.post('/checkout', (req, res) => {
    const { buyer_name, model, payment_type } = req.body;
    db.run(`INSERT INTO orders (buyer_name, model, payment_type) VALUES (?, ?, ?)`, [buyer_name, model, payment_type], () => {
        res.redirect('http://localhost:3005');
    });
});
app.listen(3004, () => console.log('[Module 4] Checkout active on http://localhost:3004'));
JS

# --------------------------------------------------------
# 5. Distributor Ascension (Port 3005)
# --------------------------------------------------------
mkdir -p module5
cat << 'HTML' > module5/index.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Stage 5: Distributor Ascension</title><link rel="stylesheet" href="../assets/css/executive-spectrum.css"></head>
<body>
    <div class="nav-bar">
        <a href="http://localhost:3001">1. Lead</a> | <a href="http://localhost:3002">2. Education</a> | <a href="http://localhost:3003">3. Booking</a> | <a href="http://localhost:3004">4. Checkout</a> | <a href="http://localhost:3005">5. Distributor</a>
    </div>
    <div class="card">
        <h2>Nexus Affiliate Engine® Activation</h2>
        <p>Transition to independent distributor and unlock your 8-Point Commission Dashboard.</p>
        <form action="http://localhost:3005/activate" method="POST">
            <input type="text" name="distributor_name" placeholder="Legal Distributorship Name" required>
            <input type="text" name="sponsor_id" placeholder="Enagic Sponsor ID (e.g., 6A-Pool)" required>
            <button type="submit">Activate 6A Independent Distributorship</button>
        </form>
    </div>
</body>
</html>
HTML

cat << 'JS' > module5/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(cors());

const db = new sqlite3.Database(path.join(__dirname, '../database_distributors.db'));
db.run(`CREATE TABLE IF NOT EXISTS distributors (id INTEGER PRIMARY KEY AUTOINCREMENT, distributor_name TEXT, sponsor_id TEXT, status TEXT)`);

app.post('/activate', (req, res) => {
    const { distributor_name, sponsor_id } = req.body;
    db.run(`INSERT INTO distributors (distributor_name, sponsor_id, status) VALUES (?, ?, ?)`, [distributor_name, sponsor_id, 'Active 8-Point Node'], () => {
        res.send(`<div style="background:#0B0C10;color:#D4AF37;padding:50px;text-align:center;font-family:sans-serif;"><h1>Distributorship Successfully Activated!</h1><p>Welcome to the EB Enterprises® / Enagic® Global Distribution Network.</p><br><a href="http://localhost:3001" style="color:#008080;">Return to Ecosystem Start</a></div>`);
    });
});
app.listen(3005, () => console.log('[Module 5] Distributor Engine active on http://localhost:3005'));
JS

# Generate Root Package Configuration & Install Dependencies
cat << 'JSON' > package.json
{
  "name": "enagic-ecosystem-suite",
  "version": "1.0.0",
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7", "cors": "^2.8.5" }
}
JSON

echo "[+] Installing root dependencies..."
npm install > /dev/null 2>&1

cd ..
echo "========================================================"
echo " [EB Enterprises®] All Pages & Servers Ready!"
echo "--------------------------------------------------------"
echo " Access URLs:"
echo " Stage 1 (Lead Capture): http://localhost:3001/module1/"
echo " Stage 2 (Education Engine): http://localhost:3002/module2/"
echo " Stage 3 (Consultation Booking): http://localhost:3003/module3/"
echo " Stage 4 (Conversion Checkout): http://localhost:3004/module4/"
echo " Stage 5 (Distributor Ascension): http://localhost:3005/module5/"
echo "========================================================"
