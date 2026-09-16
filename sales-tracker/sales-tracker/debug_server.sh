#!/bin/bash
set -e

echo "[+] Inspecting backend server.js and ensuring all API endpoints and database tables are correctly wired..."

cat << 'ESERVER' > server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize SQLite Database
const dbFile = path.join(__dirname, 'sales_tracker.db');
const db = new sqlite3.Database(dbFile, (err) => {
    if (err) {
        console.error('Error opening database', err.message);
    } else {
        console.log('Connected to SQLite database.');
        initDb();
    }
});

function initDb() {
    db.serialize(() => {
        db.run(`CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            name TEXT,
            quantity INTEGER DEFAULT 1,
            weight TEXT,
            item TEXT,
            cost REAL,
            payment_status TEXT
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER,
            customer TEXT,
            amount REAL,
            notes TEXT,
            timestamp TEXT
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity REAL,
            price REAL
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            notes TEXT
        )`);
    });
}

// --- API Endpoints ---

// Get all sales with calculated total paid
app.get('/api/sales', (req, res) => {
    const query = `
        SELECT s.*, 
               COALESCE(SUM(p.amount), 0) as totalPaid
        FROM sales s
        LEFT JOIN payments p ON s.id = p.sale_id
        GROUP BY s.id
        ORDER BY s.id DESC
    `;
    db.all(query, [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

// Record Sale
app.post('/api/sales', (req, res) => {
    const { timestamp, name, quantity, weight, item, cost, payment_status, paidAmount } = req.body;
    
    db.run(
        `INSERT INTO sales (timestamp, name, quantity, weight, item, cost, payment_status) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [timestamp, name, quantity || 1, weight, item, cost, payment_status],
        function(err) {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            const saleId = this.lastID;

            // If paid in full or partial, insert initial payment record
            if (payment_status === 'paid' && cost > 0) {
                db.run(
                    `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
                    [saleId, name, cost, 'Paid in full upon recording', timestamp],
                    (err) => {
                        if (err) console.error('Error recording initial payment:', err.message);
                    }
                );
            } else if (payment_status === 'partial' && paidAmount > 0) {
                db.run(
                    `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
                    [saleId, name, paidAmount, 'Initial partial payment', timestamp],
                    (err) => {
                        if (err) console.error('Error recording initial partial payment:', err.message);
                    }
                );
            }

            res.json({ id: saleId, message: 'Sale recorded successfully' });
        }
    );
});

// Delete Sale
app.delete('/api/sales/:id', (req, res) => {
    const id = req.params.id;
    db.serialize(() => {
        db.run(`DELETE FROM payments WHERE sale_id = ?`, [id]);
        db.run(`DELETE FROM sales WHERE id = ?`, [id], function(err) {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json({ deleted: this.changes });
        });
    });
});

// Payments Endpoints
app.get('/api/payments', (req, res) => {
    const sale_id = req.query.sale_id;
    let query = `SELECT * FROM payments`;
    let params = [];
    if (sale_id) {
        query += ` WHERE sale_id = ?`;
        params.push(sale_id);
    }
    query += ` ORDER BY id DESC`;

    db.all(query, params, (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

app.post('/api/payments', (req, res) => {
    const { sale_id, customer, amount, notes, timestamp } = req.body;
    db.run(
        `INSERT INTO payments (sale_id, customer, amount, notes, timestamp) VALUES (?, ?, ?, ?, ?)`,
        [sale_id || null, customer, amount, notes, timestamp || new Date().toISOString()],
        function(err) {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.json({ id: this.lastID, message: 'Payment recorded' });
        }
    );
});

app.delete('/api/payments/:id', (req, res) => {
    const id = req.params.id;
    db.run(`DELETE FROM payments WHERE id = ?`, [id], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ deleted: this.changes });
    });
});

// Inventory Endpoints
app.get('/api/inventory', (req, res) => {
    db.all(`SELECT * FROM inventory ORDER BY id DESC`, [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

app.post('/api/inventory', (req, res) => {
    const { name, quantity, price } = req.body;
    db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, quantity, price], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ id: this.lastID });
    });
});

app.delete('/api/inventory/:id', (req, res) => {
    db.run(`DELETE FROM inventory WHERE id = ?`, [req.params.id], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ deleted: this.changes });
    });
});

// Customer Endpoints
app.get('/api/customers', (req, res) => {
    db.all(`SELECT * FROM customers ORDER BY id DESC`, [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

app.post('/api/customers', (req, res) => {
    const { name, phone, notes } = req.body;
    db.run(`INSERT INTO customers (name, phone, notes) VALUES (?, ?, ?)`, [name, phone, notes], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ id: this.lastID });
    });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
ESERVER

echo "[+] Restarting application..."
./run.sh
