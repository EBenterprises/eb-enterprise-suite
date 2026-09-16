#!/bin/bash
set -e

echo "[+] Terminating any stalled Node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

cd ~/sales-tracker/instances/v1

cat << 'EJS' > server.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send('<h1>EB Enterprises - Executive Spectrum Online</h1>');
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server listening on http://0.0.0.0:${port}`);
});
EJS

nohup node server.js > server.log 2>&1 &
echo "[+] Started v1 on port 3000 (PID $!)"

sleep 2
curl -I http://127.0.0.1:3000
