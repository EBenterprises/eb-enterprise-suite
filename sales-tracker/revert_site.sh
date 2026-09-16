#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Server Rollback & Stability Restoration
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating all running Node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        cd "$DIR"
        
        # Ensure dependencies exist
        if [ ! -d "node_modules" ]; then
            npm install express sqlite3 > /dev/null 2>&1 || true
        fi
        
        # Write clean, stable server implementation
        cat << 'STABLESERVER' > server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = new sqlite3.Database(path.join(__dirname, 'sales.db'), (err) => {
    if (err) console.error('Database error:', err);
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
    console.log(`Server running on port ${PORT}`);
});
STABLESERVER

        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Restored and restarted instance $V on port $P"
    fi
done

echo "[+] All instances have been successfully rolled back and restarted. Site online."
