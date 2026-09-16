#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Database Schema Adapter & Server Update
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Updating server.js across all instances to handle sales_tracker.sqlite schema (id, timestamp, name, quantity, weight, item, cost, payment_status)..."

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    cat << ERS > "$DIR/server.js"
const express = require('express');
const fs = require('fs');
const path = require('path');
const initSqlJs = require('sql.js');

const app = express();
const PORT = $P;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let db = null;
const dbPath = path.join(__dirname, 'data', 'sales.db');

async function initDatabase() {
    const dataDir = path.dirname(dbPath);
    if (!fs.existsSync(dataDir)){
        fs.mkdirSync(dataDir, { recursive: true });
    }
    const SQL = await initSqlJs();
    if (fs.existsSync(dbPath)) {
        const filebuffer = fs.readFileSync(dbPath);
        db = new SQL.Database(filebuffer);
    } else {
        db = new SQL.Database();
        db.run(\`
            CREATE TABLE IF NOT EXISTS sales (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                name TEXT,
                quantity TEXT,
                weight TEXT,
                item TEXT,
                cost REAL,
                payment_status TEXT
            );
        \`);
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
        const { name, quantity, weight, item, cost, payment_status } = req.body;
        const stmt = db.prepare("INSERT INTO sales (name, quantity, weight, item, cost, payment_status) VALUES (?, ?, ?, ?, ?, ?);");
        stmt.run([name || '', quantity || '', weight || '', item || '', cost || 0, payment_status || 'Paid']);
        stmt.free();
        saveDatabase();
        res.json({ success: true, message: "Transaction logged successfully." });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

initDatabase().then(() => {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(\`[+] EB Sales Tracker [$V] running on http://localhost:\${PORT}\`);
    });
});
ERS

    # Restart server instance
    cd "$DIR"
    nohup node server.js > server.log 2>&1 &
    cd - > /dev/null
done

sleep 2
echo "[+] All instances updated with unified schema and restarted."
