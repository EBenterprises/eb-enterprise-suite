const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Checking port 51201...");
try {
    execSync('fuser -k 51201/tcp || true', { stdio: 'inherit' });
} catch (e) {}

if (fs.existsSync('server.js')) {
    let code = fs.readFileSync('server.js', 'utf8');
    code = code.replace(/3000/g, '51201');
    fs.writeFileSync('server.js', code);
}

console.log("[+] Launching EB Sales Tracker v5 Master Suite on port 51201...");
require('./server.js');
