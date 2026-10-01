#!/bin/bash
echo "=== Setting up and launching all Sales Tracker versions ==="

# Create root directories
mkdir -p sales-tracker-v1 sales-tracker-v2 sales-tracker-v3 sales-tracker-v4 sales-tracker-v5

# --- VERSION 1 (Port 3001) ---
mkdir -p sales-tracker-v1/public sales-tracker-v1/data
cat << 'PKG' > sales-tracker-v1/package.json
{
  "name": "sales-tracker-v1",
  "version": "1.0.0",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
PKG
cat << 'SRV' > sales-tracker-v1/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = 3001;
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
const db = new sqlite3.Database(path.join(__dirname, 'data', 'v1.db'));
db.run(`CREATE TABLE IF NOT EXISTS sales (id INTEGER PRIMARY KEY AUTOINCREMENT, item_name TEXT, amount REAL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)`);
app.get('/api/sales', (req, res) => db.all(`SELECT * FROM sales`, [], (err, rows) => res.json(rows)));
app.post('/api/sales', (req, res) => {
    const { item_name, amount } = req.body;
    db.run(`INSERT INTO sales (item_name, amount) VALUES (?, ?)`, [item_name, amount], function() { res.json({ id: this.lastID }); });
});
app.listen(PORT, () => console.log(`[v1] Running on http://localhost:${PORT}`));
SRV
cat << 'PUB' > sales-tracker-v1/public/index.html
<!DOCTYPE html><html><head><title>Sales Tracker v1</title><link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet"></head>
<body class="bg-gray-900 text-white p-6"><h1 class="text-2xl font-bold text-blue-400">Sales Tracker v1 (Port 3001)</h1></body></html>
PUB

# --- VERSION 2 (Port 3002) ---
mkdir -p sales-tracker-v2/public sales-tracker-v2/data
cat << 'PKG' > sales-tracker-v2/package.json
{
  "name": "sales-tracker-v2",
  "version": "2.0.0",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
PKG
cat << 'SRV' > sales-tracker-v2/server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const app = express();
const PORT = 3002;
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
const db = new sqlite3.Database(path.join(__dirname, 'data', 'v2.db'));
db.run(`CREATE TABLE IF NOT EXISTS sales (id INTEGER PRIMARY KEY AUTOINCREMENT, item_name TEXT, amount REAL, category TEXT)`);
app.get('/api/sales', (req, res) => db.all(`SELECT * FROM sales`, [], (err, rows) => res.json(rows)));
app.listen(PORT, () => console.log(`[v2] Running on http://localhost:${PORT}`));
SRV
cat << 'PUB' > sales-tracker-v2/public/index.html
<!DOCTYPE html><html><head><title>Sales Tracker v2</title><link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet"></head>
<body class="bg-gray-900 text-white p-6"><h1 class="text-2xl font-bold text-green-400">Sales Tracker v2 (Port 3002)</h1></body></html>
PUB

# --- VERSION 3 (Port 3003) ---
mkdir -p sales-tracker-v3/public sales-tracker-v3/data
cat << 'PKG' > sales-tracker-v3/package.json
{
  "name": "sales-tracker-v3",
  "version": "3.0.0",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
PKG
cat << 'SRV' > sales-tracker-v3/server.js
const express = require('express');
const app = express();
const PORT = 3003;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v3] Running on http://localhost:${PORT}`));
SRV
cat << 'PUB' > sales-tracker-v3/public/index.html
<!DOCTYPE html><html><head><title>Sales Tracker v3</title><link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet"></head>
<body class="bg-gray-900 text-white p-6"><h1 class="text-2xl font-bold text-yellow-400">Sales Tracker v3 (Port 3003)</h1></body></html>
PUB

# --- VERSION 4 (Port 3004 - Map Enabled) ---
mkdir -p sales-tracker-v4/public sales-tracker-v4/data
cat << 'PKG' > sales-tracker-v4/package.json
{
  "name": "sales-tracker-v4",
  "version": "4.0.0",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7" }
}
PKG
cat << 'SRV' > sales-tracker-v4/server.js
const express = require('express');
const app = express();
const PORT = 3004;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v4 Map Edition] Running on http://localhost:${PORT}`));
SRV
cat << 'PUB' > sales-tracker-v4/public/index.html
<!DOCTYPE html><html><head><title>Sales Tracker v4</title><link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet"></head>
<body class="bg-gray-900 text-white p-6"><h1 class="text-2xl font-bold text-indigo-400">Sales Tracker v4 with Map (Port 3004)</h1></body></html>
PUB

# --- VERSION 5 (Port 3005 - Full Stack / Analytics) ---
mkdir -p sales-tracker-v5/public sales-tracker-v5/data
cat << 'PKG' > sales-tracker-v5/package.json
{
  "name": "sales-tracker-v5",
  "version": "5.0.0",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.19.2", "sqlite3": "^5.1.7", "cors": "^2.8.5" }
}
PKG
cat << 'SRV' > sales-tracker-v5/server.js
const express = require('express');
const app = express();
const PORT = 3005;
app.use(express.static(path.join(__dirname, 'public')));
app.listen(PORT, () => console.log(`[v5 Analytics] Running on http://localhost:${PORT}`));
SRV
cat << 'PUB' > sales-tracker-v5/public/index.html
<!DOCTYPE html><html><head><title>Sales Tracker v5</title><link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet"></head>
<body class="bg-gray-900 text-white p-6"><h1 class="text-2xl font-bold text-purple-400">Sales Tracker v5 Enterprise (Port 3005)</h1></body></html>
PUB

echo "=== Installing dependencies for all versions ==="
for d in sales-tracker-v1 sales-tracker-v2 sales-tracker-v3 sales-tracker-v4 sales-tracker-v5; do
  echo "Installing in $d..."
  (cd $d && npm install --silent)
done

echo "=== Launching all versions concurrently ==="
(cd sales-tracker-v1 && npm start) &
(cd sales-tracker-v2 && npm start) &
(cd sales-tracker-v3 && npm start) &
(cd sales-tracker-v4 && npm start) &
(cd sales-tracker-v5 && npm start) &

echo "All versions are now spinning up!"
echo "v1: http://localhost:3001"
echo "v2: http://localhost:3002"
echo "v3: http://localhost:3003"
echo "v4: http://localhost:3004"
echo "v5: http://localhost:3005"
