#!/bin/bash
echo "[+] Checking local offline server status and node processes..."
ps aux | grep "[n]ode server.js"
echo "[+] Local Endpoints:"
for port in 3000 3001 3002 3003 3004; do
    echo -n "Port $port: "
    curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port && echo " (Online)" || echo " (Offline)"
done
