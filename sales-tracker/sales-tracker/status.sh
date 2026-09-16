#!/bin/bash
if pgrep -f "node server.js" > /dev/null; then
    PID=$(pgrep -f "node server.js")
    echo "[+] Server Status: RUNNING (PID: $PID)"
    echo "--- Last 5 Log Entries ---"
    tail -n 5 server.log
    echo "--------------------------"
    echo "--- Endpoint Health Check ---"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/sales || echo "Failed")
    echo "[+] API /api/sales responded with status: $STATUS"
else
    echo "[!] Server Status: STOPPED"
fi
