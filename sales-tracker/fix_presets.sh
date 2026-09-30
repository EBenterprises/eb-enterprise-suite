#!/bin/bash
set -e

echo "[+] Fixing weight increment selection logic across all instances..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -f "$dir/server.js" ]; then
        cd "$dir"
        
        # We will update server.js in-place using a node patch script or rewrite the HTML part correctly
        node -e '
            const fs = require("fs");
            let code = fs.readFileSync("server.js", "utf8");
            
            // Fix setPreset function in the HTML string
            const oldPresetFunc = `function setPreset(weight, price, btn) {
            document.querySelectorAll(\x27.preset-btn\x27).forEach(b => b.classList.remove(\x27active\x27));
            btn.classList.add(\x27active\x27);
            document.getElementById(\x27weightInput\x27).value = weight;
            document.getElementById(\x27amountInput\x27).value = price;
            calculate();
        }`;

            const newPresetFunc = `function setPreset(weight, price, btn) {
            document.querySelectorAll(\x27.preset-btn\x27).forEach(b => b.classList.remove(\x27active\x27));
            if (btn) btn.classList.add(\x27active\x27);
            document.getElementById(\x27weightInput\x27).value = weight;
            document.getElementById(\x27amountInput\x27).value = price;
            calculate();
        }`;

            if (code.includes(oldPresetFunc)) {
                code = code.replace(oldPresetFunc, newPresetFunc);
                fs.writeFileSync("server.js", code, "utf8");
                console.log("Patched setPreset in " + process.cwd());
            } else {
                console.log("Could not find exact setPreset match in " + process.cwd());
            }
        '
        
        cd - > /dev/null
    fi
done

echo "[+] Restarting all server instances..."
pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    if [ -d "$dir" ]; then
        cd "$dir"
        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Restarted $v on port$p"
    fi
done

sleep 2
echo "[+] Verification check..."
for port in "${PORTS[@]}"; do
    echo -n "Port $port: "
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port | grep -q "200"; then
        echo "🟢 ACTIVE (HTTP 200)"
    else
        echo "🔴 OFFLINE"
    fi
done
