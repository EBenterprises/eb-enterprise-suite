#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Version Reordering Utility
# ==============================================================================
set -e

echo "[+] Reordering versions..."

# 1. If v1 exists, move/rename it to v2 (backing up or replacing old v2)
if [ -d "instances/v1" ]; then
    echo "[+] Moving current v1 -> v2..."
    rm -rf "instances/v2"
    mv "instances/v1" "instances/v2"
    
    # Update server.js port in v2 to 3001
    if [ -f "instances/v2/server.js" ]; then
        sed -i 's/app.listen(3000/app.listen(3001/g' "instances/v2/server.js"
        sed -i 's/localhost:3000/localhost:3001/g' "instances/v2/server.js"
    fi
fi

# 2. Make a copy of the current root state (or instance v1 state) as the new v1
echo "[+] Copying current state as new v1..."
mkdir -p "instances/v1"

# If root server.js exists, copy root state; otherwise copy from current working directory
if [ -f "server.js" ]; then
    cp -r server.js public data instances/v1/ 2>/dev/null || true
else
    # Fallback to copying whatever instance was active or root assets
    cp -r public data instances/v1/ 2>/dev/null || true
    cat << 'ESERVER' > instances/v1/server.js
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
}

function saveDatabase() {
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(dbPath, buffer);
}

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
    app.listen(3000, () => {
        console.log('[+] EB Sales Tracker [v1] running on http://localhost:3000');
    });
});
ESERVER
fi

# Ensure v1 server.js listens on port 3000
if [ -f "instances/v1/server.js" ]; then
    sed -i 's/app.listen([0-9]*/app.listen(3000/g' "instances/v1/server.js"
fi

echo "[+] Version reordering complete:"
echo "    - New v1 (Current state) -> Port 3000"
echo "    - Old v1 -> Renamed to v2 -> Port 3001"
