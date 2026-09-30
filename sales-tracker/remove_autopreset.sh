#!/bin/bash
set -e

echo "[+] Removing automatic preset selection on page load across all instances..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -d "$dir" ]; then
        cd "$dir"
        
        node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Remove the automatic setting of the first preset on startup in renderPresetButtons and reset inputs
        code = code.replace(/document\.getElementById\(\x27weightInput\x27\)\.value = appPresets\[0\]\.weight;[\s\S]*?calculate\(\);/g, "");
        code = code.replace(/if \(appPresets\[0\]\) \{[\s\S]*?\}/g, "");
        
        // Ensure default values are empty or neutral rather than locked to 1.75g / $25
        code = code.replace(/value="1\.75"/g, `value=""`);
        code = code.replace(/value="25"/g, `value=""`);
        code = code.replace(/<button class="preset-btn active"/g, `<button class="preset-btn"`);

        fs.writeFileSync("server.js", code, "utf8");
        console.log("-> Removed auto-preset from " + "${v}");
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! Auto-preset behavior removed. Inputs start blank."
