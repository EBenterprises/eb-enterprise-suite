const express = require('express');
const http = require('http');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ID = process.env.NODE_ID || '1';

// Global CORS & JSON parser
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// In-memory data store with fallback seed
const dbStore = new Map();
dbStore.set('farm_1', { id: 1, name: 'Okanagan Valley Acres', stock: 150, price: 7.50, lat: 49.8820, lng: -119.5900, description: 'Certified organic free-range heritage eggs.' });
dbStore.set('tokens', { 'token_ridgeview_99a': { farmId: 1 } });

// SSE clients for real-time mesh sync
let sseClients = [];

function broadcast(type, payload) {
    const data = JSON.stringify({ type, ...payload });
    sseClients.forEach(client => client.write(`data: ${data}\n\n`));
}

// Routes
app.get('/api/farms', (req, res) => {
    const farms = [];
    for (const [key, val] of dbStore.entries()) {
        if (key.startsWith('farm_')) farms.push(val);
    }
    res.json(farms);
});

app.post('/api/order', (req, res) => {
    const { farmId, qty } = req.body;
    const key = `farm_${farmId || 1}`;
    let farm = dbStore.get(key);
    
    if (!farm) {
        farm = { id: Number(farmId) || 1, name: 'Default Valley Farm', stock: 100, price: 7.50, lat: 49.8820, lng: -119.5900 };
        dbStore.set(key, farm);
    }
    
    const orderQty = Number(qty) || 1;
    if (farm.stock < orderQty) {
        return res.status(400).json({ error: "Insufficient stock" });
    }
    
    farm.stock -= orderQty;
    dbStore.set(key, farm);
    broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });
    
    res.json({ success: true, remainingStock: farm.stock });
});

app.post('/api/checkout', (req, res) => {
    const { farmId, qty } = req.body;
    const key = `farm_${farmId || 1}`;
    let farm = dbStore.get(key);
    
    if (!farm) return res.status(404).json({ error: "Station not found" });
    const orderQty = Number(qty) || 1;
    if (farm.stock < orderQty) return res.status(400).json({ error: "Insufficient stock for instant purchase" });

    farm.stock -= orderQty;
    dbStore.set(key, farm);
    broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });

    const receiptId = 'EGG-' + Math.random().toString(36).substring(2, 8).toUpperCase();
    res.json({
        success: true,
        receiptId,
        farmName: farm.name,
        qty: orderQty,
        totalPaid: orderQty * farm.price,
        remainingStock: farm.stock,
        timestamp: new Date().toISOString()
    });
});

app.get('/api/stream', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    sseClients.push(res);
    req.on('close', () => {
        sseClients = sseClients.filter(c => c !== res);
    });
});

app.get('/manage/:token', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'producer.html'));
});

app.get('/api/producer/:token', (req, res) => {
    const tokens = dbStore.get('tokens') || {};
    const mapping = tokens[req.params.token];
    if (!mapping) return res.status(403).json({ error: "Invalid producer token" });
    const farm = dbStore.get(`farm_${mapping.farmId}`);
    if (!farm) return res.status(404).json({ error: "Station not found" });
    res.json({ farm, token: req.params.token });
});

app.post('/api/producer/:token/stock', (req, res) => {
    const tokens = dbStore.get('tokens') || {};
    const mapping = tokens[req.params.token];
    if (!mapping) return res.status(403).json({ error: "Invalid producer token" });

    const { stock } = req.body;
    const key = `farm_${mapping.farmId}`;
    const farm = dbStore.get(key);
    if (!farm) return res.status(404).json({ error: "Station not found" });

    farm.stock = Number(stock);
    dbStore.set(key, farm);
    broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });
    res.json({ success: true, farmId: farm.id, stock: farm.stock });
});

app.get('/api/admin/tokens', (req, res) => {
    res.json(dbStore.get('tokens') || {});
});

app.post('/api/admin/farms', (req, res) => {
    const { name, lat, lng, stock, price, image, description } = req.body;
    const id = dbStore.size + 1;
    const newFarm = { id, name, lat, lng, stock, price, image, description };
    dbStore.set(`farm_${id}`, newFarm);

    const tokens = dbStore.get('tokens') || {};
    const newToken = 'token_' + name.toLowerCase().replace(/[^a-z0-9]/g, '') + '_' + Math.random().toString(36).substring(2, 8);
    tokens[newToken] = { farmId: id };
    dbStore.set('tokens', tokens);

    broadcast('FARM_ADDED', { farm: newFarm });
    res.json({ success: true, farm: newFarm, token: newToken });
});

app.listen(PORT, () => {
    console.log(`[EDGE NODE ${NODE_ID}] Listening on port ${PORT}`);
});
