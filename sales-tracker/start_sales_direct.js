const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Ensuring port 51201 is configured and launching sales tracker directly...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

if (fs.existsSync('server.js')) {
    let code = fs.readFileSync('server.js', 'utf8');
    code = code.replace(/3000/g, '51201');
    fs.writeFileSync('server.js', code);
}

execSync('node server.js', { stdio: 'inherit' });
