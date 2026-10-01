const { spawn } = require('child_process');
const path = require('path');

const versions = [
  { name: 'v1', port: 51201 },
  { name: 'v2', port: 51202 },
  { name: 'v3', port: 51203 },
  { name: 'v4', port: 51204 },
  { name: 'v5', port: 51205 }
];

console.log('🚀 Booting all Sales-Tracker versions (v1 - v5)...');

versions.forEach(ver => {
  const serverPath = path.join(__dirname, 'server.js');
  const env = { ...process.env, PORT: ver.port, VERSION_NAME: ver.name };
  
  const child = spawn('node', [serverPath], { env, stdio: 'inherit' });
  
  child.on('error', (err) => {
    console.error(`[${ver.name}] Failed to start:`, err);
  });
});
