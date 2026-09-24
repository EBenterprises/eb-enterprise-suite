const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.json());

const PORT = process.env.PORT || 9000;

app.get('/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    ecosystem: 'eb-enterprise-universal-ecosystem',
    version: '10.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/v1/ecosystem/manifest', (req, res) => {
  const manifestPath = path.join(__dirname, '../../dist/universal-ecosystem-manifest.json');
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Universal manifest not compiled. Run npm run compile:all first.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'CONNECT', message: 'Connected to EB Enterprises® Universal Master Daemon' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Universal Master Daemon online across all platforms on port ${PORT}`);
});
