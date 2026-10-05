#!/bin/bash
# Sales Tracker - Multi-Version Manager & V5 Deployment Script

REPO_DIR="$HOME/sales-tracker"
PORT=51205

mkdir -p "$REPO_DIR"
cd "$REPO_DIR" || exit 1

echo "=================================================="
echo "   EBENTERPRISES SALES-TRACKER SYSTEM MANAGER    "
echo "=================================================="

# Step 1: Ensure Git sync and tags
if [ -d ".git" ]; then
    echo "[*] Fetching all remote branches and tags from GitHub..."
    git fetch --all --tags --quiet
else
    echo "[*] Initializing local git context or pulling isolated repository..."
    git init
    git remote add origin https://github.com/EBenterprises/sales-tracker.git 2>/dev/null
    git fetch --all --tags --quiet
fi

# Step 2: Extract transactions across all Tagged Versions (V1 - V5)
echo ""
echo "[*] Checking transaction snapshots across versions:"
echo "--------------------------------------------------"

for TAG in v1 v2 v3 v4 v5; do
    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo ">>> Snapshot from Tag: $TAG"
        git show "$TAG:transactions.json" 2>/dev/null || git show "$TAG:v5/transactions.json" 2>/dev/null || echo "   (No transactions.json file found in tag $TAG)"
        echo ""
    fi
done

# Step 3: Ensure current working transactions file exists
if [ ! -f "$REPO_DIR/v5/transactions.json" ] && [ ! -f "$REPO_DIR/transactions.json" ]; then
    echo "[*] Creating active transactions.json baseline..."
    mkdir -p "$REPO_DIR/v5"
    cat << 'JSON' > "$REPO_DIR/v5/transactions.json"
[
  {
    "id": 1,
    "timestamp": "2026-09-28 11:30",
    "customer": "Dan",
    "location": "Johnson Bentley skate park camp",
    "item": "3.5g Unit",
    "total": 55,
    "paid": 50,
    "balance": 5
  },
  {
    "id": 2,
    "timestamp": "2026-09-29 01:30",
    "customer": "Lane",
    "location": "Bayview Entrance",
    "item": "28g Unit",
    "total": 300,
    "paid": 0,
    "balance": 300
  },
  {
    "id": 3,
    "timestamp": "2026-09-30 10:39",
    "customer": "Chris Bell",
    "location": "Kenny's House",
    "item": "1.75g Unit",
    "total": 40,
    "paid": 0,
    "balance": 40
  },
  {
    "id": 4,
    "timestamp": "2026-09-30 10:41",
    "customer": "Chris Bell",
    "location": "Kennys House (front door)",
    "item": "1.75g Unit",
    "total": 40,
    "paid": 0,
    "balance": 40
  },
  {
    "id": 5,
    "timestamp": "2026-09-30 12:30",
    "customer": "Johnathon",
    "location": "Dead end at Walmart Westbank",
    "item": "3.5g Unit",
    "total": 80,
    "paid": 0,
    "balance": 80
  },
  {
    "id": 6,
    "timestamp": "2026-10-01 00:13",
    "customer": "Dan",
    "location": "Johnson Bentley skateboard park camp",
    "item": "3.5g Unit",
    "total": 80,
    "paid": 40,
    "balance": 40
  },
  {
    "id": 7,
    "timestamp": "2026-10-01 04:16",
    "customer": "Brian",
    "location": "London Drugs, Westbank",
    "item": "3.5g Unit",
    "total": 80,
    "paid": 0,
    "balance": 80
  },
  {
    "id": 8,
    "timestamp": "2026-10-01 17:30",
    "customer": "Angel",
    "location": "Value Village parking lot by bus stop",
    "item": "7g Unit",
    "total": 150,
    "paid": 0,
    "balance": 150
  }
]
JSON
fi

# Step 4: Write zero-dependency Node.js V5 standalone server
cat << 'NODE_EOF' > "$REPO_DIR/v5_server.js"
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51205;
const DATA_FILE = fs.existsSync(path.join(__dirname, 'v5', 'transactions.json'))
  ? path.join(__dirname, 'v5', 'transactions.json')
  : path.join(__dirname, 'transactions.json');

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/api/transactions' && req.method === 'GET') {
    fs.readFile(DATA_FILE, 'utf8', (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Failed to read transactions' }));
        return;
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(data);
    });
  } else if (req.url === '/api/transactions' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk.toString());
    req.on('end', () => {
      try {
        const newTx = JSON.parse(body);
        fs.readFile(DATA_FILE, 'utf8', (err, data) => {
          let txs = err ? [] : JSON.parse(data);
          newTx.id = txs.length ? txs[txs.length - 1].id + 1 : 1;
          txs.push(newTx);
          fs.writeFile(DATA_FILE, JSON.stringify(txs, null, 2), (err) => {
            if (err) {
              res.writeHead(500, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: 'Failed to save transaction' }));
              return;
            }
            res.writeHead(201, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(newTx));
          });
        });
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
      }
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`[+] V5 Sales Tracker running on http://localhost:${PORT}`);
  console.log(`[+] Reading/Writing from: ${DATA_FILE}`);
});
NODE_EOF

echo ""
echo "[*] Launching Standalone V5 Server on Port $PORT..."
node "$REPO_DIR/v5_server.js"
