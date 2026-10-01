const express = require('express');
const initSqlJs = require('sql.js');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

const dbFile = path.join(__dirname, 'sales_tracker.sqlite');
let db;

function saveDb() {
    if (db) {
        const data = db.export();
        const buffer = Buffer.from(data);
        fs.writeFileSync(dbFile, buffer);
    }
}

initSqlJs().then(SQL => {
    if (fs.existsSync(dbFile)) {
        const filebuffer = fs.readFileSync(dbFile);
        db = new SQL.Database(filebuffer);
        console.log('Loaded existing SQLite database.');
    } else {
        db = new SQL.Database();
        console.log('Created new SQLite database.');
    }

    // Initialize tables
    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        name TEXT,
        quantity INTEGER DEFAULT 1,
        weight TEXT,
        item TEXT,
        cost REAL,
        payment_status TEXT
    );`);

    db.run(`CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        customer TEXT,
        amount REAL,
        notes TEXT,
        timestamp TEXT
    );`);

    db.run(`CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        quantity REAL,
        price REAL
    );`);

    db.run(`CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        notes TEXT
    );`);
    saveDb();

    startServer();
}).catch(err => {
    console.error('Failed to initialize sql.js:', err);
    process.exit(1);
});

function startServer() {
    // --- API Endpoints ---

    app.get('/api/sales', (req, res) => {
        try {
            const stmt = db.prepare(`
                SELECT s.*, 
                       COALESCE(SUM(p.amount), 0) as totalPaid
                FROM sales s
                LEFT JOIN payments p ON s.id = p.sale_id
                GROUP BY s.id
                ORDER BY s.id DESC
            `);
            const rows = [];
            while (stmt.step()) {
                rows.push(stmt.getAsObject());
            }
            stmt.free();
            res.json(rows);
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        try {
            const { timestamp, name, quantity, weight, item, cost, payment_status, paidAmount } = req.body;
            
            db.run(
                `INSERT INTO sales (timestamp, name, quantity, weight, item, cost, payment_status) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [timestamp, name, quantity || 1, weight, item, cost, payment_status]
            );
            
            const resId = db.exec("SELECT last_insert_rowid() as id;");
            const saleId = resId[0].values[0][0];

            if (payment_status === 'paid' && cost > 0) {
                db.run(
                    `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
                    [saleId, name, cost, 'Paid in full upon recording', timestamp]
                );
            } else if (payment_status === 'partial' && paidAmount > 0) {
                db.run(
                    `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
                    [saleId, name, paidAmount, 'Initial partial payment', timestamp]
                );
            }

            saveDb();
            res.json({ id: saleId, message: 'Sale recorded successfully' });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.delete('/api/sales/:id', (req, res) => {
        try {
            const id = req.params.id;
            db.run(`DELETE FROM payments WHERE sale_id = ?`, [id]);
            db.run(`DELETE FROM sales WHERE id = ?`, [id]);
            saveDb();
            res.json({ deleted: 1 });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.get('/api/payments', (req, res) => {
        try {
            const sale_id = req.query.sale_id;
            let query = `SELECT * FROM payments`;
            let params = [];
            if (sale_id) {
                query += ` WHERE sale_id = ?`;
                params.push(sale_id);
            }
            query += ` ORDER BY id DESC`;

            const stmt = db.prepare(query);
            if (sale_id) stmt.bind(params);
            const rows = [];
            while (stmt.step()) {
                rows.push(stmt.getAsObject());
            }
            stmt.free();
            res.json(rows);
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.post('/api/payments', (req, res) => {
        try {
            const { sale_id, customer, amount, notes, timestamp } = req.body;
            db.run(
                `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
                [sale_id || null, customer, amount, notes, timestamp || new Date().toISOString()]
            );
            const resId = db.exec("SELECT last_insert_rowid() as id;");
            const payId = resId[0].values[0][0];
            saveDb();
            res.json({ id: payId, message: 'Payment recorded' });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.delete('/api/payments/:id', (req, res) => {
        try {
            db.run(`DELETE FROM payments WHERE id = ?`, [req.params.id]);
            saveDb();
            res.json({ deleted: 1 });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.get('/api/inventory', (req, res) => {
        try {
            const stmt = db.prepare(`SELECT * FROM inventory ORDER BY id DESC`);
            const rows = [];
            while (stmt.step()) rows.push(stmt.getAsObject());
            stmt.free();
            res.json(rows);
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.post('/api/inventory', (req, res) => {
        try {
            const { name, quantity, price } = req.body;
            db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, quantity, price]);
            const resId = db.exec("SELECT last_insert_rowid() as id;");
            saveDb();
            res.json({ id: resId[0].values[0][0] });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.delete('/api/inventory/:id', (req, res) => {
        try {
            db.run(`DELETE FROM inventory WHERE id = ?`, [req.params.id]);
            saveDb();
            res.json({ deleted: 1 });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.get('/api/customers', (req, res) => {
        try {
            const stmt = db.prepare(`SELECT * FROM customers ORDER BY id DESC`);
            const rows = [];
            while (stmt.step()) rows.push(stmt.getAsObject());
            stmt.free();
            res.json(rows);
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.post('/api/customers', (req, res) => {
        try {
            const { name, phone, notes } = req.body;
            db.run(`INSERT INTO customers (name, phone, notes) VALUES (?, ?, ?)`, [name, phone, notes]);
            const resId = db.exec("SELECT last_insert_rowid() as id;");
            saveDb();
            res.json({ id: resId[0].values[0][0] });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server running on http://0.0.0.0:${PORT}`);
    });
}
