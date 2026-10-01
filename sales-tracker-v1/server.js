const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = 3001;
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
const db = new sqlite3.Database(path.join(__dirname, 'data', 'v1.db'));
db.run(`CREATE TABLE IF NOT EXISTS sales (id INTEGER PRIMARY KEY AUTOINCREMENT, item_name TEXT, amount REAL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)`);
app.get('/api/sales', (req, res) => db.all(`SELECT * FROM sales`, [], (err, rows) => res.json(rows)));
app.post('/api/sales', (req, res) => {
    const { item_name, amount } = req.body;
    db.run(`INSERT INTO sales (item_name, amount) VALUES (?, ?)`, [item_name, amount], function() { res.json({ id: this.lastID }); });
});
app.listen(PORT, () => console.log(`[v1] Running on http://localhost:${PORT}`));
