#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Revert & Native SQLite Setup
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Removing JSON database storage and restoring original SQLite architecture..."
rm -f database.json switch_to_json_db.sh continue_deployment.sh fix_sqlite.sh fix_deps.sh

echo "[+] Re-enabling native SQLite configuration and installing dependencies..."
# Ensure we have build dependencies / node-gyp configuration aligned for Termux
npm install sqlite3 express --save

echo "[+] Restoring original server.js with SQLite connection..."
cat << 'EJS' > server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'sales.db');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = new sqlite3.Database(DB_FILE, (err) => {
    if (err) {
        console.error('Error opening database', err.message);
    } else {
        console.log('Connected to the SQLite database.');
        db.run(`CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item TEXT NOT NULL,
            amount REAL NOT NULL,
            customer TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);
    }
});

app.get('/api/sales', (req, res) => {
    db.all("SELECT * FROM sales ORDER BY id DESC", [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

app.post('/api/sales', (req, res) => {
    const { item, amount, customer } = req.body;
    db.run(`INSERT INTO sales (item, amount, customer) VALUES (?, ?, ?)`, [item, amount, customer], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ id: this.lastID, item, amount, customer });
    });
});

app.listen(PORT, () => {
    console.log(`[+] Server running live on port ${PORT} with SQLite persistence.`);
});
EJS

echo "[+] Starting application server..."
node server.js
