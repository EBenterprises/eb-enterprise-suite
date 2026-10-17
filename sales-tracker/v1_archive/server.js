const express = require('express');
const fs = require('fs');
const path = require('path');
const initSqlJs = require('sql.js');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db = null;
const dbPath = path.join(__dirname, 'data', 'sales.db');

async function initDatabase() {
    const SQL = await initSqlJs();
    if (fs.existsSync(dbPath)) {
        const filebuffer = fs.readFileSync(dbPath);
        db = new SQL.Database(filebuffer);
    } else {
        db = new SQL.Database();
        db.run(`
            CREATE TABLE IF NOT EXISTS sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                item_name TEXT NOT NULL,
                tier TEXT NOT NULL,
                weight_grams REAL NOT NULL,
                price REAL NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);
        saveDatabase();
    }
    console.log('[+] Database initialized successfully.');
}

function saveDatabase() {
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(dbPath, buffer);
}

// API Routes
app.get('/api/sales', (req, res) => {
    try {
        const stmt = db.prepare("SELECT * FROM sales ORDER BY timestamp DESC;");
        const results = [];
        while (stmt.step()) {
            results.push(stmt.getAsObject());
        }
        stmt.free();
        res.json(results);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/sales', (req, res) => {
    try {
        const { item_name, tier, weight_grams, price } = req.body;
        if (!item_name || !tier || !weight_grams || !price) {
            return res.status(400).json({ error: "Missing required sale parameters." });
        }
        const stmt = db.prepare("INSERT INTO sales (item_name, tier, weight_grams, price) VALUES (?, ?, ?, ?);");
        stmt.run([item_name, tier, weight_grams, price]);
        stmt.free();
        saveDatabase();
        res.json({ success: true, message: "Sale logged successfully." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

initDatabase().then(() => {
    app.listen(PORT, () => {
        console.log(`[+] Executive Spectrum Server running on http://0.0.0.0:${PORT}`);
    });
});
