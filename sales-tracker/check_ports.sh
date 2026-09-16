#!/bin/bash
echo "[+] Checking active node processes and open ports..."
ps aux | grep node
echo "=== Port status ==="
ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null || echo "No netstat/ss available"

echo "[+] Verifying response on port 3000..."
curl -I http://127.0.0.1:3000 || echo "Failed to connect to 127.0.0.1:3000"
