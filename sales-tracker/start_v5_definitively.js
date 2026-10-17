const { execSync } = require('child_process');

console.log("[+] Terminating any conflicting background Node daemons...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Launching EB Sales & Payments Tracker v5 P2P Master Suite on port 51205...");
execSync('node server_v5_master.js', { stdio: 'inherit' });
