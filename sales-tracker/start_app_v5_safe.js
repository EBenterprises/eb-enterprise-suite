const { execSync } = require('child_process');

console.log("[+] Terminating existing Node processes in Termux...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Launching v5 Sales Tracker server daemon on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
