const http = require('http');

const TOTAL_REQUESTS = 1000;
const CONCURRENCY = 50;
let completed = 0;
let successful = 0;
let failed = 0;

const startTime = Date.now();

function makeRequest(index) {
  const req = http.request({
    hostname: 'localhost',
    port: 5000,
    path: '/health',
    method: 'GET'
  }, (res) => {
    res.on('data', () => {});
    res.on('end', () => {
      if (res.statusCode === 200) successful++;
      else failed++;
      checkComplete();
    });
  });

  req.on('error', () => {
    failed++;
    checkComplete();
  });

  req.end();
}

function checkComplete() {
  completed++;
  if (completed === TOTAL_REQUESTS) {
    const duration = (Date.now() - startTime) / 1000;
    console.log('\n--- Load Test Results ---');
    console.log(`Total Requests: ${TOTAL_REQUESTS}`);
    console.log(`Concurrency: ${CONCURRENCY}`);
    console.log(`Duration: ${duration.toFixed(2)}s`);
    console.log(`Successful: ${successful}`);
    console.log(`Failed: ${failed}`);
    console.log(`Throughput: ${(TOTAL_REQUESTS / duration).toFixed(2)} req/sec`);
  }
}

console.log(`[Load Test] Launching ${TOTAL_REQUESTS} requests with concurrency of ${CONCURRENCY}...`);

let active = 0;
let nextIndex = 0;

function spawnBatch() {
  while (active < CONCURRENCY && nextIndex < TOTAL_REQUESTS) {
    active++;
    makeRequest(nextIndex++);
    // Reset active counter on request completion inside checkComplete
  }
}

// Simple loop simulation
for (let i = 0; i < CONCURRENCY; i++) {
  if (nextIndex < TOTAL_REQUESTS) {
    makeRequest(nextIndex++);
  }
}
