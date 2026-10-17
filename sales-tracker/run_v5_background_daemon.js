const { spawn, execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Terminating any conflicting background node processes...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Spawning EB Enterprises P2P Master Suite v5 daemon in the background on port 51201...");

const out = fs.openSync('./server_v5_out.log', 'a');
const err = fs.openSync('./server_v5_err.log', 'a');

const server = spawn('node', ['server.js'], {
    detached: true,
    stdio: ['ignore', out, err]
});

server.unref();

console.log(`[+] SUCCESS! v5 Master Suite daemon is running in background (PID: ${server.pid}).`);
console.log("[+] Access your app locally at: http://127.0.0.1:51201");
console.log("[+] Full deployment archive ready at: ~/sales-tracker/eb_sales_tracker_v5_master_suite.tar.gz");
