const net = require('net');

function checkPort(host, port, timeout = 1000) {
    return new Promise((resolve) => {
        const socket = new net.Socket();
        let status = false;

        socket.setTimeout(timeout);
        socket.on('connect', () => {
            status = true;
            socket.destroy();
            resolve({ port, status: 'OPEN' });
        });

        socket.on('timeout', () => {
            socket.destroy();
            resolve({ port, status: 'CLOSED' });
        });

        socket.on('error', () => {
            socket.destroy();
            resolve({ port, status: 'CLOSED' });
        });

        socket.connect(port, host);
    });
}

async function scanPorts(host, startPort, endPort, concurrency = 1000, timeout = 1000) {
    console.log(`[Scanner] Sweeping ${host} across ports ${startPort}-${endPort} with concurrency ${concurrency}...`);
    const openPorts = [];
    
    for (let i = startPort; i <= endPort; i += concurrency) {
        const batch = [];
        const limit = Math.min(i + concurrency - 1, endPort);
        
        for (let p = i; p <= limit; p++) {
            batch.push(checkPort(host, p, timeout));
        }
        
        const results = await Promise.all(batch);
        for (const res of results) {
            if (res.status === 'OPEN') {
                console.log(`[+] Port ${res.port} is OPEN`);
                openPorts.push(res.port);
            }
        }
    }
    return openPorts;
}

if (require.main === module) {
    const fs = require('fs');
    const path = require('path');
    const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/config.json'), 'utf8'));
    
    console.time('Scan Duration');
    scanPorts(config.scanner.host, config.scanner.startPort, config.scanner.endPort, config.scanner.concurrency, config.scanner.timeout)
        .then((openPorts) => {
            console.timeEnd('Scan Duration');
            console.log(`Scan complete. Found ${openPorts.length} open ports.`);
        });
}

module.exports = { scanPorts };
