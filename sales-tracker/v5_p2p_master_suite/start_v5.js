const { spawn } = require('child_process');
const path = require('path');

console.log("[+] Launching EB Enterprises P2P Master Suite v5 Server Daemon...");
const serverProcess = spawn('node', [path.join(__dirname, 'server/server.js')], {
    stdio: 'inherit'
});

serverProcess.on('error', (err) => {
    console.error('[-] Failed to start v5 server:', err);
});
