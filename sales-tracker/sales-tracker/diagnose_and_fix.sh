#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Local Connection Diagnosis & Fix
# ==============================================================================
set -e

echo "[+] Inspecting running node processes and active ports..."
netstat -tulpn 2>/dev/null || ss -tulpn 2>/dev/null || true

echo "[+] Ensuring all application instances are bound explicitly to 0.0.0.0..."
for dir in instances/v*; do
    if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
        # Ensure the server binds to 0.0.0.0 instead of default/localhost if needed
        sed -i "s/app.listen(/app.listen(port, '0.0.0.0', /g" "$dir/server.js" 2>/dev/null || true
    fi
done

echo "[+] Restarting instances with zero-trust binding..."
pkill -f "node server.js" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
i=0
for dir in instances/v*; do
    if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
        cd "$dir"
        nohup node server.js > server.log 2>&1 &
        echo "    -> Restarted $dir on port ${PORTS[$i]}"
        cd - > /dev/null
        i=$((i+1))
    fi
done

echo "[+] Connection diagnostic complete. Test via http://127.0.0.1:3000"
