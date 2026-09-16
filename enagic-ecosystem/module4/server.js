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
