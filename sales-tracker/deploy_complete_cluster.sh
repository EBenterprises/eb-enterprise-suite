#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/sales-tracker"
cd "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/backups"
mkdir -p "$PROJECT_DIR/data"
mkdir -p "$PROJECT_DIR/releases"

echo "[1/4] Cleaning existing node processes..."
pkill -9 -f node || true
sleep 1

echo "[2/4] Verifying legacy version stubs (V1 - V4)..."
for v in {1..4}; do
    if [ ! -f "server_v${v}.js" ]; then
        PORT=$((51200 + v))
        cat << SCRIPT_EOF > "server_v${v}.js"
const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = ${PORT};
const DATA_FILE = path.join(__dirname, 'transactions.json');

http.createServer((req, res) => {
    if (req.url === '/api/data' || req.url === '/data') {
        const data = fs.existsSync(DATA_FILE) ? JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')) : [];
        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        return res.end(JSON.stringify({ version: ${v}, transactions: data }));
    }
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(\`<h1>EB Sales Tracker V${v} Legacy Node</h1><p>Running on port \${PORT}</p>\`);
}).listen(PORT, '127.0.0.1', () => console.log(\`V${v} active on port \${PORT}\`));
SCRIPT_EOF
    fi
done

echo "[3/4] Starting servers V1-V5..."
declare -A PORTS=([1]=51201 [2]=51202 [3]=51203 [4]=51204 [5]=51205)

for v in {1..5}; do
    PORT=${PORTS[$v]}
    nohup node "server_v${v}.js" > "logs/server_v${v}.log" 2>&1 &
    echo $! > "logs/v${v}.pid"
done

sleep 2

echo "[4/4] Running health check..."
for v in {1..5}; do
    PORT=${PORTS[$v]}
    CODE=$(curl -s -o /dev/null -w "\%{http_code}" "http://127.0.0.1:${PORT}/api/data" || echo "000")
    echo "V${v} (Port ${PORT}): HTTP${CODE}"
done
