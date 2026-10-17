const { execSync } = require('child_process');

console.log("[+] Terminating existing node processes safely...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Launching EB Sales & Payments Tracker v5 P2P Master Suite with Interactive Map Picker on port 51205...");
execSync('node server_v5_master.js', { stdio: 'inherit' });
