const express = require('express');
const initSqlJs = require('sql.js');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'sales.sqlite');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db = null;

function saveDatabase() {
    if (db) {
        const data = db.export();
        const buffer = Buffer.from(data);
        fs.writeFileSync(DB_FILE, buffer);
    }
}

initSqlJs().then(SQL => {
    try {
        if (fs.existsSync(DB_FILE)) {
            const filebuffer = fs.readFileSync(DB_FILE);
            db = new SQL.Database(filebuffer);
            console.log('[+] Loaded existing SQLite database from disk.');
        } else {
            db = new SQL.Database();
            console.log('[+] Created new in-memory SQLite database.');
        }
    } catch (e) {
        console.log('[!] Error loading database file, initializing fresh:', e.message);
        db = new SQL.Database();
    }

    // Initialize Schema with payment status and paid amount
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        customer TEXT,
        payment_status TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        created_at TEXT NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        notes TEXT
    )`);
    
    saveDatabase();

    // Sales Routes
    app.get('/api/sales', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM sales ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) {
                rows.push(stmt.getAsObject());
            }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/analytics', (req, res) => {
        try {
            const revStmt = db.prepare("SELECT SUM(amount) as total_revenue, SUM(paid_amount) as total_collected FROM sales");
            revStmt.step();
            const revData = revStmt.getAsObject();
            const totalRev = revData.total_revenue || 0;
            const totalCollected = revData.total_collected || 0;
            revStmt.free();

            const custStmt = db.prepare("SELECT customer, SUM(amount) as total_spent, SUM(paid_amount) as total_paid, COUNT(*) as transaction_count FROM sales WHERE customer IS NOT NULL AND customer != '' GROUP BY customer");
            const perCustomer = [];
            while (custStmt.step()) {
                perCustomer.push(custStmt.getAsObject());
            }
            custStmt.free();

            const dayStmt = db.prepare("SELECT SUBSTR(created_at, 1, 10) as sale_date, SUM(amount) as daily_total, SUM(paid_amount) as daily_collected, COUNT(*) as daily_count FROM sales GROUP BY SUBSTR(created_at, 1, 10) ORDER BY sale_date DESC");
            const dayByDay = [];
            while (dayStmt.step()) {
                dayByDay.push(dayStmt.getAsObject());
            }
            dayStmt.free();

            res.json({
                total_revenue: totalRev,
                total_collected: totalCollected,
                per_customer: perCustomer,
                day_by_day: dayByDay
            });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        const { item, amount, customer, payment_status, paid_amount, timestamp } = req.body;
        const saleTime = timestamp || new Date().toLocaleString();
        const pStatus = payment_status || 'paid';
        const pAmount = pStatus === 'paid' ? amount : (pStatus === 'unpaid' ? 0 : parseFloat(paid_amount || 0));

        try {
            db.run(`INSERT INTO sales (item, amount, customer, payment_status, paid_amount, created_at) VALUES (?, ?, ?, ?, ?, ?)`, 
                [item, parseFloat(amount), customer || '', pStatus, pAmount, saleTime]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Inventory Routes
    app.get('/api/inventory', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM inventory ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/inventory', (req, res) => {
        const { name, quantity, price } = req.body;
        try {
            db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, parseFloat(quantity), parseFloat(price)]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    // Customer Routes
    app.get('/api/customers', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM customers ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/customers', (req, res) => {
        const { name, notes } = req.body;
        try {
            db.run(`INSERT INTO customers (name, notes) VALUES (?, ?)`, [name, notes]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.listen(PORT, () => {
        console.log(`[+] EB Sales Tracker running live on port ${PORT}.`);
    });
});
