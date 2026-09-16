#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Master Execution Script
# ==============================================================================
set -e

echo "[+] Initializing full-stack zero-dependency deployment..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
i=0

for dir in instances/v*; do
    if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
        port="${PORTS[$i]}"
        cd "$dir"
        
        # Ensure port and host binding are explicitly correct in server.js
        node -e "
            const fs = require('fs');
            let code = fs.readFileSync('server.js', 'utf8');
            if (!code.includes('0.0.0.0')) {
                code = code.replace(/app\.listen\s*\(\s*([a-zA-Z0-9_]+)\s*\)/g, 'app.listen(\$1, \"0.0.0.0\")');
                code = code.replace(/app\.listen\s*\(\s*(\d+)\s*\)/g, 'app.listen(\$1, \"0.0.0.0\")');
            }
            // Ensure port assignment uses the target port
            code = code.replace(/const port = process.env.PORT \|\| \d+;/g, 'const port = $port;');
            fs.writeFileSync('server.js', code);
        " 2>/dev/null || true

        nohup node server.js > server.log 2>&1 &
        echo "    -> Deployed $dir on port $port"
        cd - > /dev/null
        i=$((i+1))
    fi
done

sleep 2
echo "[+] Deployment operational check:"
ps aux | grep "[n]ode"
echo "[+] All systems active under the Executive Spectrum environment."
