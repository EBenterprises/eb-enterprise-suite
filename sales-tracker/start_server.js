const { spawn } = require('child_process');

console.log("[+] Initializing EB Sales & Payments Tracker server daemon...");
const server = spawn('node', ['server.js'], {
    stdio: 'inherit',
    detached: true
});

server.unref();
console.log("[+] Server daemon running cleanly in background.");
