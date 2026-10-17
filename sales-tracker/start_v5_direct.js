const { execSync } = require('child_process');

console.log("[+] Clearing port 51201 and launching v5 Master Suite directly in foreground...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

execSync('node server.js', { stdio: 'inherit' });
