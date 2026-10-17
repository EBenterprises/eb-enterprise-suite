const { execSync } = require('child_process');

console.log("[+] Cleaning up conflicting server instances...");
try {
    execSync('pkill -f node', { stdio: 'ignore' });
} catch (e) {}

console.log("[+] Starting EB Sales & Payments Tracker server...");
require('./server.js');
