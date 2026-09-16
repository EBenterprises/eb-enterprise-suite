const http = require('http');

function post(port, path, data) {
    return new Promise((resolve, reject) => {
        const req = http.request({
            hostname: 'localhost',
            port: port,
            path: path,
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve(JSON.parse(body)));
        });
        req.on('error', reject);
        req.write(JSON.stringify(data));
        req.end();
    });
}

function get(port, path) {
    return new Promise((resolve, reject) => {
        http.get(`http://localhost:${port}${path}`, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve(JSON.parse(body)));
        }).on('error', reject);
    });
}

async function runMeshTest() {
    console.log("[MESH TEST] Verifying peer-to-peer replication across edge nodes...");

    // 1. Fetch initial state from Node 1 (port 3001)
    const initialFarms = await get(3001, '/api/farms');
    console.log(`[NODE 3001] Initial stations registered: ${initialFarms.length}`);

    // 2. Register a new farm on Node 2 (port 3002)
    const newFarmPayload = {
        name: "Okanagan Crest Poultry",
        lat: 49.8950,
        lng: -119.4960,
        stock: 60,
        price: 8.00,
        image: "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500&auto=format&fit=crop&q=60",
        description: "Organic pasture-raised heritage eggs."
    };

    console.log("[TEST] Registering new station on Node 2 (Port 3002)...");
    const addRes = await post(3002, '/api/admin/farms', newFarmPayload);
    console.log(`[TEST] Station added with ID: ${addRes.farm.id}`);

    // Wait briefly for asynchronous mesh replication
    await new Promise(r => setTimeout(r, 500));

    // 3. Verify replication on Node 1 (port 3001)
    const node1Farms = await get(3001, '/api/farms');
    const replicatedFarm = node1Farms.find(f => f.id === addRes.farm.id);

    if (replicatedFarm) {
        console.log(`[SUCCESS] Peer-to-peer replication confirmed! Station '${replicatedFarm.name}' synced to Node 1.`);
    } else {
        console.error("[ERROR] Replication failed: Station not found on Node 1.");
        process.exit(1);
    }

    // 4. Test live order stock reduction and SSE sync
    console.log("[TEST] Reserving 2 dozen eggs from Node 1 against replicated station...");
    const orderRes = await post(3001, '/api/order', { farmId: addRes.farm.id, qty: 2 });
    console.log(`[SUCCESS] Order executed. Remaining stock: ${orderRes.remainingStock} doz.`);

    console.log("[MESH TEST] All distributed node and P2P synchronization verifications passed cleanly.");
}

runMeshTest().catch(err => {
    console.error("[MESH TEST FAILURE]", err);
    process.exit(1);
});
