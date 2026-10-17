const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Copying true v5 implementation from fix_v5_true_enterprise_p2p.js to server.js...");
if (fs.existsSync('fix_v5_true_enterprise_p2p.js')) {
    fs.copyFileSync('fix_v5_true_enterprise_p2p.js', 'server.js');
}

console.log("[+] Terminating any running node processes...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Launching true v5 Master Suite on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
