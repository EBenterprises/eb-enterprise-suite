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
