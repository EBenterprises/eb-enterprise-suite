const { execSync } = require('child_process');

console.log("[+] Freeing port 51201 / 51205 and launching v5 Sales Tracker...");

try {
    // Kill any existing processes running on v5 ports
    execSync('fuser -k 51201/tcp || true', { stdio: 'inherit' });
    execSync('fuser -k 51205/tcp || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Starting v5 Sales Tracker server daemon...");
// Start the server using node directly
execSync('node server.js', { stdio: 'inherit' });
