const { spawn } = require('child_process');
const fs = require('fs');

console.log("[+] Starting v5 Sales Tracker server daemon in background...");

const out = fs.openSync('./server.log', 'a');
const err = fs.openSync('./server_err.log', 'a');

const server = spawn('node', ['server.js'], {
    detached: true,
    stdio: ['ignore', out, err]
});

server.unref();
console.log(`[+] Server daemon spawned successfully (PID: ${server.pid}).`);
console.log("[+] You can view logs via: cat server.log");
