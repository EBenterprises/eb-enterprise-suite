#!/bin/bash
set -e
echo "--- EB Sales Tracker Status ---"
if pgrep -f "node server.js" > /dev/null; then
    echo "[+] Server Status: RUNNING (PID: $(pgrep -f "node server.js"))"
else
    echo "[-] Server Status: STOPPED"
fi

if [ -f "server.log" ]; then
    echo "--- Last 5 Log Entries ---"
    tail -n 5 server.log
else
    echo "[!] No server.log found."
fi

echo "--- Endpoint Health Check ---"
node -e '
const http = require("http");
http.get("http://localhost:3000/api/sales", (res) => {
    let data = "";
    res.on("data", chunk => data += chunk);
    res.on("end", () => {
        console.log(`[+] API /api/sales responded with status: ${res.statusCode} (payload size: ${data.length} bytes)`);
    });
}).on("error", err => {
    console.error(`[-] API health check failed: ${err.message}`);
});
'
