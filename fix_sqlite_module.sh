#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - SQLite Resolution via Pure-JS fallback or build fix
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Removing native sqlite3 module which fails to compile on Android/Termux without full NDK..."
npm uninstall sqlite3 --save || true

echo "[+] Installing 'sql.js' (Pure JavaScript SQLite running in Node.js with zero native compilation issues)..."
npm install sql.js express

echo "[+] Updating server.js to use sql.js (fully compatible SQLite API in pure JS)..."
cat << 'EJS' > server.js
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

    db.run(`CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        customer TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    saveDatabase();

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

    app.post('/api/sales', (req, res) => {
        const { item, amount, customer } = req.body;
        try {
            db.run(`INSERT INTO sales (item, amount, customer) VALUES (?, ?, ?)`, [item, amount, customer || '']);
            saveDatabase();
            
            const resStmt = db.prepare("SELECT last_insert_rowid() as id");
            resStmt.step();
            const lastId = resStmt.getAsObject().id;
            resStmt.free();

            res.json({ id: lastId, item, amount, customer });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    });

    app.listen(PORT, () => {
        console.log(`[+] Server running live on port ${PORT} with pure-JS SQLite persistence.`);
    });
});
EJS

echo "[+] Starting server..."
node server.js
