const http = require('http');

const nodes = [
    { port: 3001, active: true },
    { port: 3002, active: true },
    { port: 3003, active: true }
];
let currentIndex = 0;

function getNextNode() {
    let attempts = nodes.length;
    while (attempts > 0) {
        const node = nodes[currentIndex];
        currentIndex = (currentIndex + 1) % nodes.length;
        if (node.active) return node.port;
        attempts--;
    }
    return 3001; // Fallback default
}

// Background health check loop
setInterval(() => {
    nodes.forEach(node => {
        const req = http.request({
            hostname: 'localhost',
            port: node.port,
            path: '/api/farms',
            method: 'GET',
            timeout: 1000
        }, (res) => {
            node.active = (res.statusCode === 200);
            res.on('data', () => {});
        });
        req.on('error', () => { node.active = false; });
        req.end();
    });
}, 3000);

const server = http.createServer((clientReq, clientRes) => {
    const targetPort = getNextNode();

    const proxyReq = http.request({
        hostname: 'localhost',
        port: targetPort,
        path: clientReq.url,
        method: clientReq.method,
        headers: { ...clientReq.headers, 'X-Proxy-Gateway': 'EggFinder-Global-Balancer' }
    }, (proxyRes) => {
        clientRes.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(clientRes, { end: true });
    });

    proxyReq.on('error', (err) => {
        clientRes.writeHead(502, { 'Content-Type': 'application/json' });
        clientRes.end(JSON.stringify({ error: "Edge gateway node unreachable", details: err.message }));
    });

    clientReq.pipe(proxyReq, { end: true });
});

const PORT = 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`[GLOBAL LOAD BALANCER] Active on port ${PORT} | Routing across dynamic edge mesh pool.`);
});
