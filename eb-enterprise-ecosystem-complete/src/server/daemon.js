const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.json());

const PORT = process.env.PORT || 9500;

app.get('/', (req, res) => {
  res.json({
    app: 'EB Enterprises® Complete Ecosystem Daemon',
    version: '12.0.0',
    status: 'ONLINE',
    organization: 'EBenterprises',
    endpoints: {
      health: '/health',
      manifest: '/api/v1/manifest'
    },
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'HEALTHY',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/v1/manifest', (req, res) => {
  const manifestPath = path.join(__dirname, '../../dist/ecosystem-manifest.json');
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Manifest not compiled. Run npm run compile:ecosystem first.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'CONNECTED', message: 'Established secure pipeline to EB Enterprises® Complete Daemon' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Complete Ecosystem Daemon online on port ${PORT}`);
});
