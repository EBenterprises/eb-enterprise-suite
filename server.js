const express = require('express');
const http = require('http');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const FARMS_FILE = path.join(__dirname, 'data', 'farms.json');
const ORDERS_FILE = path.join(__dirname, 'data', 'orders.json');

function loadFarms() {
  if (!fs.existsSync(FARMS_FILE)) return [];
  return JSON.parse(fs.readFileSync(FARMS_FILE, 'utf8'));
}

function saveFarms(farms) {
  fs.writeFileSync(FARMS_FILE, JSON.stringify(farms, null, 2));
}

function loadOrders() {
  if (!fs.existsSync(ORDERS_FILE)) return [];
  return JSON.parse(fs.readFileSync(ORDERS_FILE, 'utf8'));
}

function saveOrders(orders) {
  fs.writeFileSync(ORDERS_FILE, JSON.stringify(orders, null, 2));
}

let sseClients = [];

function broadcastMeshEvent(eventData) {
  const payload = JSON.stringify(eventData);
  sseClients.forEach(client => {
    client.res.write(`data: ${payload}\n\n`);
  });
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

app.get('/api/farms', (req, res) => {
  const farms = loadFarms();
  const { lat, lng, radius } = req.query;

  if (lat && lng && radius) {
    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);
    const rad = parseFloat(radius);

    const filtered = farms.map(farm => {
      const dist = calculateDistance(userLat, userLng, farm.lat, farm.lng);
      return { ...farm, distanceKm: Math.round(dist * 10) / 10 };
    }).filter(farm => farm.distanceKm <= rad);

    return res.json(filtered);
  }

  res.json(farms);
});

app.get('/api/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const client = { res };
  sseClients.push(client);

  req.on('close', () => {
    sseClients = sseClients.filter(c => c !== client);
  });
});

app.post('/api/order', (req, res) => {
  const { farmId, qty } = req.body;
  let farms = loadFarms();
  const farm = farms.find(f => f.id === Number(farmId));

  if (!farm) return res.status(404).json({ error: "Farm not found" });
  if (farm.stock < qty) return res.status(400).json({ error: "Not enough stock available!" });

  farm.stock -= Number(qty);
  saveFarms(farms);

  let orders = loadOrders();
  const newOrder = {
    id: orders.length + 1,
    farmId: farm.id,
    qty: Number(qty),
    total: Number(qty) * farm.price,
    status: 'PRE_PURCHASED',
    created_at: new Date().toISOString()
  };
  orders.push(newOrder);
  saveOrders(orders);

  broadcastMeshEvent({ type: 'STOCK_UPDATE', farmId: farm.id, stock: farm.stock });
  res.json({ success: true, orderId: newOrder.id, remainingStock: farm.stock });
});

app.post('/api/admin/stock', (req, res) => {
  const { farmId, stock } = req.body;
  let farms = loadFarms();
  const farm = farms.find(f => f.id === Number(farmId));

  if (!farm) return res.status(404).json({ error: "Farm not found" });

  farm.stock = Number(stock);
  saveFarms(farms);

  broadcastMeshEvent({ type: 'STOCK_UPDATE', farmId: farm.id, stock: farm.stock });
  res.json({ success: true, farmId: farm.id, stock: farm.stock });
});

app.post('/api/admin/farms', (req, res) => {
  const { name, lat, lng, stock, price, image, description } = req.body;
  let farms = loadFarms();
  
  const newFarm = {
    id: farms.length > 0 ? Math.max(...farms.map(f => f.id)) + 1 : 1,
    name,
    lat: Number(lat),
    lng: Number(lng),
    stock: Number(stock),
    price: Number(price),
    image: image || 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=500&auto=format&fit=crop&q=60',
    description: description || 'Farm fresh eggs.'
  };

  farms.push(newFarm);
  saveFarms(farms);

  broadcastMeshEvent({ type: 'FARM_ADDED', farm: newFarm });
  res.json({ success: true, farm: newFarm });
});

app.delete('/api/admin/farms/:id', (req, res) => {
  const farmId = Number(req.params.id);
  let farms = loadFarms();
  farms = farms.filter(f => f.id !== farmId);
  saveFarms(farms);

  broadcastMeshEvent({ type: 'FARM_DELETED', farmId });
  res.json({ success: true, farmId });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`[EggFinder] Executive Spectrum Full-Stack Node active on port ${PORT}`);
});
