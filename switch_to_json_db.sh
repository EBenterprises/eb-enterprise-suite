#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Pure JS / JSON File DB Migration Script
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Removing problematic native sqlite3 module & dependency from package.json..."
npm uninstall sqlite3 --save || true

echo "[+] Rewriting server.js to use zero-dependency JSON file persistence (fs/promises)..."
cat << 'EJS' > server.js
const express = require('express');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'database.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize JSON database if not present
async function initDB() {
    try {
        await fs.access(DATA_FILE);
    } catch {
        const initialData = {
            sales: [],
            inventory: [],
            customers: []
        };
        await fs.writeFile(DATA_FILE, JSON.stringify(initialData, null, 2));
    }
}

async function readDB() {
    const data = await fs.readFile(DATA_FILE, 'utf8');
    return JSON.parse(data);
}

async function writeDB(data) {
    await fs.writeFile(DATA_FILE, JSON.stringify(data, null, 2));
}

// API Routes
app.get('/api/sales', async (req, res) => {
    try {
        const db = await readDB();
        res.json(db.sales);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/sales', async (req, res) => {
    try {
        const db = await readDB();
        const newSale = { id: Date.now(), ...req.body, created_at: new Date().toISOString() };
        db.sales.push(newSale);
        await writeDB(db);
        res.json(newSale);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/inventory', async (req, res) => {
    try {
        const db = await readDB();
        res.json(db.inventory);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/inventory', async (req, res) => {
    try {
        const db = await readDB();
        const newItem = { id: Date.now(), ...req.body };
        db.inventory.push(newItem);
        await writeDB(db);
        res.json(newItem);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

initDB().then(() => {
    app.listen(PORT, () => {
        console.log(`[+] EB Sales Tracker running live on port ${PORT} using zero-dependency JSON storage.`);
    });
});
EJS

echo "[+] Verifying Express installation..."
npm install express

echo "[+] Starting server..."
node server.js
