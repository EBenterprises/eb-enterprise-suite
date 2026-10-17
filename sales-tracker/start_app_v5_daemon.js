const { execSync } = require('child_process');

console.log("[+] Terminating any lingering processes on port 51201...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Launching EB Enterprises P2P Master Suite v5 on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
