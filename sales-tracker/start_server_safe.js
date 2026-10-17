const { execSync } = require('child_process');

console.log("[+] Terminating any conflicting node processes...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Starting server.js directly...");
execSync('node server.js', { stdio: 'inherit' });
