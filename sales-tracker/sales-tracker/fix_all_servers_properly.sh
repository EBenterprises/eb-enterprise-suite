#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Complete Server Reset & Fixer
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating all running node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        echo "[+] Rebuilding clean server.js for $V on port $P..."
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
                item_name TEXT NOT NULL,
                tier TEXT NOT NULL,
                weight_grams REAL NOT NULL,
                price REAL NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
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
    app.listen(PORT, '0.0.0.0', () => {
        console.log(\`[+] EB Sales Tracker [$V] running on http://localhost:\${PORT}\`);
    });
});
ERS

        # Ensure public directory exists inside instance
        mkdir -p "$DIR/public"
        if [ ! -f "$DIR/public/index.html" ] && [ -f "public/index.html" ]; then
            cp public/index.html "$DIR/public/"
        fi

        # Install local dependencies if needed
        cd "$DIR"
        if [ ! -f "package.json" ]; then
            npm init -y > /dev/null 2>&1
        fi
        npm install express sql.js > /dev/null 2>&1

        echo "[+] Starting $V on port $P..."
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Verifying running servers..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    if pgrep -f "node.*$V/server.js" > /dev/null; then
        echo "    -> $V (Port $P): [RUNNING]"
    else
        echo "    -> $V (Port $P): [FAILED]"
        tail -n 3 "instances/$V/server.log" 2>/dev/null || true
    fi
done
