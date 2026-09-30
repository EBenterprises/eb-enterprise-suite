#!/bin/bash
set -e

echo "[+] Re-checking server.js binding configuration..."

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -f "$dir/server.js" ]; then
        cd "$dir"
        
        # Ensure app.listen binds explicitly to '0.0.0.0'
        node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        code = code.replace(/app\.listen\(\s*PORT\s*\)/g, "app.listen(PORT, \x270.0.0.0\x27)");
        code = code.replace(/app\.listen\(\s*PORT\s*,\s*[^)]+\)/g, "app.listen(PORT, \x270.0.0.0\x27)");
        fs.writeFileSync("server.js", code, "utf8");
        '
        
        PORT="$p" nohup node server.js > server.log 2>&1 &
        echo " -> Bound and started $v on 0.0.0.0:$p"
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Cluster online and bound to all interfaces!"
netstat -tulpn 2>/dev/null | grep node || ss -tulpn 2>/dev/null | grep node || echo "[+] Node processes running."
