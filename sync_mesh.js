const http = require('http');
const DistributedLSMStore = require('./storage/engine');
const path = require('path');

const nodeId = process.env.NODE_ID || '1';
const db = new DistributedLSMStore(path.join(__dirname, `data/node${nodeId}/lsm`));
const peers = (process.env.CLUSTER_PEERS || '').split(',').filter(Boolean);

function broadcastToPeers(endpoint, payload) {
    peers.forEach(peer => {
        const url = new URL(endpoint, peer);
        const req = http.request({
            hostname: url.hostname,
            port: url.port,
            path: url.pathname,
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-Cluster-Source': nodeId }
        }, (res) => { res.on('data', () => {}); });
        req.on('error', () => {}); // Handle network partition tolerance gracefully
        req.write(JSON.stringify(payload));
        req.end();
    });
}

module.exports = { db, broadcastToPeers };
