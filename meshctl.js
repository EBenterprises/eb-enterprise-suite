const http = require('http');
const fs = require('fs');
const path = require('path');

const command = process.argv[2] || 'status';
const ports = [3001, 3002, 3003];

function request(port, endpoint, method = 'GET', payload = null) {
    return new Promise((resolve, reject) => {
        const data = payload ? JSON.stringify(payload) : null;
        const req = http.request({
            hostname: 'localhost',
            port: port,
            path: endpoint,
            method: method,
            headers: data ? { 'Content-Type': 'application/json', 'Content-Length': data.length } : {}
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(body)); }
                catch (e) { resolve(body); }
            });
        });
        req.on('error', reject);
        if (data) req.write(data);
        req.end();
    });
}

async function main() {
    console.log(`[MESHCTL] Executing command: '${command}' across edge cluster...`);

    if (command === 'status') {
        for (const port of ports) {
            try {
                const farms = await request(port, '/api/farms');
                console.log(`  ➔ Node [Port ${port}]: ONLINE | Active Stations: ${Array.isArray(farms) ? farms.length : 'Unknown'}`);
            } catch (err) {
                console.log(`  ➔ Node [Port ${port}]: OFFLINE / UNREACHABLE`);
            }
        }
    } else if (command === 'backup') {
        const backupDir = path.join(__dirname, 'backups', `snapshot_${Date.now()}`);
        fs.mkdirSync(backupDir, { recursive: true });
        
        for (const port of ports) {
            const dataDir = path.join(__dirname, `data/node${ports.indexOf(port) + 1}/lsm`);
            if (fs.existsSync(dataDir)) {
                const dest = path.join(backupDir, `node${ports.indexOf(port) + 1}_lsm`);
                fs.cpSync(dataDir, dest, { recursive: true });
                console.log(`  ➔ Backed up Node ${ports.indexOf(port) + 1} LSM storage to ${dest}`);
            }
        }
        console.log(`[MESHCTL] Cluster backup snapshot completed successfully.`);
    } else {
        console.log(`[MESHCTL] Unknown command. Available commands: status, backup`);
    }
}

main().catch(console.error);
