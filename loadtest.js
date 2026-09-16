const http = require('http');

const CONCURRENT_USERS = 500;
console.log(`[STRESS TEST] Simulating ${CONCURRENT_USERS} concurrent requests against cluster nodes...`);

let completed = 0;
const startTime = Date.now();

for (let i = 0; i < CONCURRENT_USERS; i++) {
    const req = http.request({
        hostname: 'localhost',
        port: 3000,
        path: '/api/order',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    }, (res) => {
        res.on('data', () => {});
        res.on('end', () => {
            completed++;
            if (completed === CONCURRENT_USERS) {
                console.log(`[STRESS TEST COMPLETE] Processed ${CONCURRENT_USERS} requests in ${Date.now() - startTime}ms.`);
            }
        });
    });

    req.write(JSON.stringify({ farmId: 1, qty: 1 }));
    req.end();
}
