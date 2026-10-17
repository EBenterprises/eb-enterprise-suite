const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Terminating any rogue node processes (like Eggfinder on port 3000)...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

if (fs.existsSync('server.js')) {
    let code = fs.readFileSync('server.js', 'utf8');
    
    // Ensure correct port 51201 is used
    code = code.replace(/3000/g, '51201');
    fs.writeFileSync('server.js', code);
    console.log("[+] Updated server.js port bindings to 51201.");
}

console.log("[+] Launching EB Sales Tracker v5 Master Suite on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
