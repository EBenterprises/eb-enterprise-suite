const http = require('http');

const TOTAL_REQUESTS = 100;
const CONCURRENCY = 10;
const ports = [3001, 3002, 3003, 3004, 3005];

function sendOrder(index) {
    return new Promise((resolve) => {
        const port = ports[index % ports.length];
        const data = JSON.stringify({ farmId: 1, qty: 1 });
        
        const start = Date.now();
        const req = http.request({
            hostname: 'localhost',
            port: port,
            path: '/api/order',
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': data.length }
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                const latency = Date.now() - start;
                resolve({ status: res.statusCode, latency, port });
            });
        });
        req.on('error', (err) => resolve({ status: 500, error: err.code, port }));
        req.write(data);
        req.end();
    });
}

async function runBenchmark() {
    console.log(`[BENCHMARK] Stresstesting distributed mesh with ${TOTAL_REQUESTS} concurrent orders across ${ports.length} nodes...`);
    const startTime = Date.now();
    let completed = 0;
    let successes = 0;
    let totalLatency = 0;

    for (let i = 0; i < TOTAL_REQUESTS; i += CONCURRENCY) {
        const batch = [];
        for (let j = 0; j < CONCURRENCY && (i + j) < TOTAL_REQUESTS; j++) {
            batch.push(sendOrder(i + j));
        }
        const results = await Promise.all(batch);
        for (const r of results) {
            completed++;
            if (r.status === 200) successes++;
            if (r.latency) totalLatency += r.latency;
        }
    }

    const duration = Date.now() - startTime;
    console.log("\n=================================================");
    console.log("⚡ MESH STRESS TEST RESULTS");
    console.log("=================================================");
    console.log(`  • Total Requests : ${TOTAL_REQUESTS}`);
    console.log(`  • Successful     : ${successes}`);
    console.log(`  • Failed         : ${TOTAL_REQUESTS - successes}`);
    console.log(`  • Total Duration : ${duration}ms`);
    console.log(`  • Avg Latency    : ${Math.round(totalLatency / TOTAL_REQUESTS)}ms`);
    console.log(`  • Throughput     : ${Math.round((TOTAL_REQUESTS / duration) * 1000)} req/sec`);
    console.log("=================================================");
}

runBenchmark();
