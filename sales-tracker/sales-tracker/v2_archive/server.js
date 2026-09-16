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
        try {
            const data = db.export();
            const buffer = Buffer.from(data);
            fs.writeFileSync(DB_FILE, buffer);
        } catch (e) {
            console.error('[!] Error saving database to disk:', e.message);
        }
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

    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        name TEXT,
        weight TEXT NOT NULL,
        item TEXT NOT NULL,
        cost REAL NOT NULL,
        payment_status TEXT NOT NULL,
        paid_amount REAL NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        customer_name TEXT,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY(sale_id) REFERENCES sales(id)
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

    app.get('/api/sales', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM sales ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) {
                const row = stmt.getAsObject();
                const pStmt = db.prepare("SELECT * FROM payments WHERE sale_id = ? ORDER BY id DESC");
                pStmt.bind([row.id]);
                const payments = [];
                while (pStmt.step()) {
                    payments.push(pStmt.getAsObject());
                }
                pStmt.free();
                row.payments = payments;
                rows.push(row);
            }
            stmt.free();
            res.json(rows);
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/payments', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM payments ORDER BY id DESC");
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

    app.post('/api/payments', (req, res) => {
        const { customer_name, amount, notes, timestamp } = req.body;
        const payTime = timestamp || new Date().toISOString();
        const payAmount = parseFloat(amount);

        try {
            db.run(`INSERT INTO payments (sale_id, customer_name, amount, timestamp, notes) VALUES (NULL, ?, ?, ?, ?)`, 
                [customer_name || 'General', payAmount, payTime, notes || 'Direct payment']);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales', (req, res) => {
        const { timestamp, name, weight, item, cost, payment_status, paid_amount } = req.body;
        const saleTime = timestamp || new Date().toISOString();
        const pStatus = payment_status || 'paid';
        const initialPaid = pStatus === 'paid' ? parseFloat(cost) : (pStatus === 'unpaid' ? 0 : parseFloat(paid_amount || 0));

        try {
            db.run(`INSERT INTO sales (timestamp, name, weight, item, cost, payment_status, paid_amount) VALUES (?, ?, ?, ?, ?, ?, ?)`, 
                [saleTime, name || '', weight || 'N/A', item || '', parseFloat(cost), pStatus, initialPaid]);
            
            const idStmt = db.prepare("SELECT last_insert_rowid() as id");
            idStmt.step();
            const saleId = idStmt.getAsObject().id;
            idStmt.free();

            if (initialPaid > 0) {
                db.run(`INSERT INTO payments (sale_id, customer_name, amount, timestamp, notes) VALUES (?, ?, ?, ?, ?)`, 
                    [saleId, name || '', initialPaid, saleTime, 'Initial Payment']);
            }

            saveDatabase();
            res.json({ success: true, id: saleId });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.post('/api/sales/:id/payment', (req, res) => {
        const saleId = req.params.id;
        const { amount, notes } = req.body;
        const paymentTime = new Date().toISOString();
        const payAmount = parseFloat(amount);

        try {
            const sStmt = db.prepare("SELECT name, cost, paid_amount FROM sales WHERE id = ?");
            sStmt.bind([saleId]);
            if (sStmt.step()) {
                const sale = sStmt.getAsObject();
                sStmt.free();

                db.run(`INSERT INTO payments (sale_id, customer_name, amount, timestamp, notes) VALUES (?, ?, ?, ?, ?)`, 
                    [saleId, sale.name, payAmount, paymentTime, notes || 'Payment installment']);

                const newPaid = sale.paid_amount + payAmount;
                let newStatus = 'partial';
                if (newPaid >= sale.cost) {
                    newStatus = 'paid';
                } else if (newPaid <= 0) {
                    newStatus = 'unpaid';
                }

                db.run(`UPDATE sales SET paid_amount = ?, payment_status = ? WHERE id = ?`, [newPaid, newStatus, saleId]);
                saveDatabase();
                res.json({ success: true, new_paid: newPaid, payment_status: newStatus });
            } else {
                sStmt.free();
                res.status(404).json({ error: 'Sale not found' });
            }
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.delete('/api/payments/:id', (req, res) => {
        const paymentId = req.params.id;
        try {
            const pStmt = db.prepare("SELECT sale_id, amount FROM payments WHERE id = ?");
            pStmt.bind([paymentId]);
            if (pStmt.step()) {
                const pay = pStmt.getAsObject();
                pStmt.free();

                db.run(`DELETE FROM payments WHERE id = ?`, [paymentId]);

                if (pay.sale_id) {
                    const sStmt = db.prepare("SELECT cost, paid_amount FROM sales WHERE id = ?");
                    sStmt.bind([pay.sale_id]);
                    if (sStmt.step()) {
                        const sale = sStmt.getAsObject();
                        sStmt.free();

                        const newPaid = Math.max(0, sale.paid_amount - pay.amount);
                        let newStatus = 'partial';
                        if (newPaid >= sale.cost) {
                            newStatus = 'paid';
                        } else if (newPaid === 0) {
                            newStatus = 'unpaid';
                        }

                        db.run(`UPDATE sales SET paid_amount = ?, payment_status = ? WHERE id = ?`, [newPaid, newStatus, pay.sale_id]);
                    }
                }
                saveDatabase();
                res.json({ success: true });
            } else {
                pStmt.free();
                res.status(404).json({ error: 'Payment not found' });
            }
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.delete('/api/sales/:id', (req, res) => {
        const saleId = req.params.id;
        try {
            db.run(`DELETE FROM payments WHERE sale_id = ?`, [saleId]);
            db.run(`DELETE FROM sales WHERE id = ?`, [saleId]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/analytics', (req, res) => {
        const filter = req.query.filter || 'all';
        let dateConditionSales = "";
        let dateConditionPayments = "";
        const now = new Date();

        if (filter === 'day') {
            const todayStr = now.toISOString().split('T')[0];
            dateConditionSales = `WHERE SUBSTR(timestamp, 1, 10) = '${todayStr}'`;
            dateConditionPayments = `WHERE SUBSTR(timestamp, 1, 10) = '${todayStr}'`;
        } else if (filter === 'week') {
            const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
            dateConditionSales = `WHERE timestamp >= '${weekAgo}'`;
            dateConditionPayments = `WHERE timestamp >= '${weekAgo}'`;
        } else if (filter === 'month') {
            const monthPrefix = now.toISOString().substring(0, 7);
            dateConditionSales = `WHERE SUBSTR(timestamp, 1, 7) = '${monthPrefix}'`;
            dateConditionPayments = `WHERE SUBSTR(timestamp, 1, 7) = '${monthPrefix}'`;
        } else if (filter === 'year') {
            const yearPrefix = now.toISOString().substring(0, 4);
            dateConditionSales = `WHERE SUBSTR(timestamp, 1, 4) = '${yearPrefix}'`;
            dateConditionPayments = `WHERE SUBSTR(timestamp, 1, 4) = '${yearPrefix}'`;
        }

        try {
            const revStmt = db.prepare(`SELECT SUM(cost) as total_revenue, COUNT(*) as total_count FROM sales ${dateConditionSales}`);
            revStmt.step();
            const revData = revStmt.getAsObject();
            revStmt.free();

            const colStmt = db.prepare(`SELECT SUM(amount) as total_collected FROM payments ${dateConditionPayments}`);
            colStmt.step();
            const colData = colStmt.getAsObject();
            colStmt.free();

            // Fetch weights for g calculation
            const weightStmt = db.prepare(`SELECT weight FROM sales ${dateConditionSales}`);
            let totalGrams = 0;
            while (weightStmt.step()) {
                const wObj = weightStmt.getAsObject();
                if (wObj.weight) {
                    const match = wObj.weight.match(/([\d.]+)\s*g/i);
                    if (match) {
                        totalGrams += parseFloat(match[1]) || 0;
                    }
                }
            }
            weightStmt.free();

            const custStmt = db.prepare(`SELECT name, SUM(cost) as total_spent, COUNT(*) as transaction_count FROM sales ${dateConditionSales} AND name IS NOT NULL AND name != '' GROUP BY name`);
            const perCustomer = [];
            while (custStmt.step()) {
                perCustomer.push(custStmt.getAsObject());
            }
            custStmt.free();

            res.json({
                filter: filter,
                total_revenue: revData.total_revenue || 0,
                total_collected: colData.total_collected || 0,
                total_grams: totalGrams,
                total_count: revData.total_count || 0,
                per_customer: perCustomer
            });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/inventory', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM inventory ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });
    app.post('/api/inventory', (req, res) => {
        const { name, quantity, price } = req.body;
        try {
            db.run(`INSERT INTO inventory (name, quantity, price) VALUES (?, ?, ?)`, [name, parseFloat(quantity), parseFloat(price)]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.get('/api/customers', (req, res) => {
        try {
            const stmt = db.prepare("SELECT * FROM customers ORDER BY id DESC");
            const rows = [];
            while (stmt.step()) { rows.push(stmt.getAsObject()); }
            stmt.free();
            res.json(rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });
    app.post('/api/customers', (req, res) => {
        const { name, notes } = req.body;
        try {
            db.run(`INSERT INTO customers (name, notes) VALUES (?, ?)`, [name, notes]);
            saveDatabase();
            res.json({ success: true });
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.listen(PORT, () => {
        console.log(`[+] EB Sales Tracker running live on port ${PORT}.`);
    });
});
