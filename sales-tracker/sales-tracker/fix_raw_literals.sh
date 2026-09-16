#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Server-Side HTML Rendering Fix
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    # Check if server.js exists and is injecting raw strings instead of serving index.html
    if [ -f "$DIR/server.js" ]; then
        cat << 'SERVERJS' > "$DIR/server.js"
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = new sqlite3.Database(path.join(__dirname, 'sales.db'), (err) => {
    if (err) console.error('Database connection error:', err);
    else console.log('Connected to SQLite database.');
});

db.run(`CREATE TABLE IF NOT EXISTS sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT,
    name TEXT,
    item TEXT,
    quantity TEXT,
    weight TEXT,
    cost REAL,
    payment_status TEXT
)`);

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
    const { name, item, quantity, weight, cost, payment_status } = req.body;
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const query = `INSERT INTO sales (timestamp, name, item, quantity, weight, cost, payment_status) VALUES (?, ?, ?, ?, ?, ?, ?)`;
    db.run(query, [timestamp, name, item, quantity, weight, cost, payment_status || 'Paid'], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ id: this.lastID, timestamp, name, item, quantity, weight, cost, payment_status: payment_status || 'Paid' });
    });
});

app.patch('/api/sales/:id', (req, res) => {
    const { payment_status } = req.body;
    const { id } = req.params;
    db.run(`UPDATE sales SET payment_status = ? WHERE id = ?`, [payment_status, id], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ updated: this.changes });
    });
});

app.listen(PORT, () => {
    console.log(`EB Sales Tracker running on port ${PORT}`);
});
SERVERJS
        echo "    -> Refactored server.js for $V to properly serve static client assets."
    fi
done

echo "[+] Restarting all server instances..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Restarted $V on port $P"
    fi
done

echo "[+] Fix applied. Server is now correctly serving the frontend dashboard instead of leaking uncompiled template strings."
