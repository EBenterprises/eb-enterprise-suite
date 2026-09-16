#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Termux Node.js Execution & Binding Fix
# ==============================================================================
set -e

echo "[+] Terminating any stalled background processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Inspecting server.js configuration across instances..."
for dir in instances/v*; do
    if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
        # Check how port is defined and ensure it actually calls listen()
        if ! grep -q "app.listen" "$dir/server.js"; then
            echo "    -> Fixing missing listen call in $dir/server.js"
            echo "app.listen(port, '0.0.0.0', () => console.log('Server running on port ' + port));" >> "$dir/server.js"
        fi
    fi
done

echo "[+] Launching instances directly with explicit output tracking..."
PORTS=(3000 3001 3002 3003 3004)
i=0
for dir in instances/v*; do
    if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
        port="${PORTS[$i]}"
        cd "$dir"
        # Overwrite port configuration variable if hardcoded incorrectly
        node -e "
            const fs = require('fs');
            let content = fs.readFileSync('server.js', 'utf8');
            content = content.replace(/const port = process.env.PORT \|\| \d+;/g, 'const port = $port;');
            fs.writeFileSync('server.js', content);
        " 2>/dev/null || true
        
        nohup node server.js > server.log 2>&1 &
        echo "    -> Started $dir on port $port (PID $!)"
        cd - > /dev/null
        i=$((i+1))
    fi
done

sleep 2
echo "[+] Current active Node processes:"
ps aux | grep "[n]ode"
