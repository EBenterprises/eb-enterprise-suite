#!/bin/bash
set -e

echo "[+] Inspecting exact crash reason for v1..."
if [ -f "instances/v1/server.log" ]; then
    node instances/v1/server.js || true
fi

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
        
        # Let's write a clean, reliable server.js snippet or restore the preset logic cleanly without breaking syntax
        node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");

        // Ensure proper renderPresetButtons definition
        const targetRender = `function renderPresetButtons() {
            const grid = document.getElementById(\x27presetButtonsGrid\x27);
            if (!grid) return;
            grid.innerHTML = appPresets.map(p => 
                \x27<button class="preset-btn" onclick="setPreset(\x27 + p.weight + \x27, \x27 + p.price + \x27, this)">\x27 + p.weight + \x27g ($\x27 + p.price + \x27)</button>\x27
            ).join(\x27\x27);
        }`;

        if (!code.includes("renderPresetButtons")) {
            code += "\n" + targetRender;
        } else {
            code = code.replace(/function renderPresetButtons\(\) \{[\s\S]*?\}/, targetRender);
        }

        // Ensure setPreset definition is correct and doesn\'t break
        const targetSetPreset = `function setPreset(weight, price, btn) {
            document.querySelectorAll(\x27.preset-btn\x27).forEach(b => b.classList.remove(\x27active\x27));
            if (btn) btn.classList.add(\x27active\x27);
            document.getElementById(\x27weightInput\x27).value = weight;
            document.getElementById(\x27amountInput\x27).value = price;
            calculate();
        }`;

        if (!code.includes("function setPreset")) {
            code += "\n" + targetSetPreset;
        } else {
            code = code.replace(/function setPreset\([\s\S]*?\}/, targetSetPreset);
        }

        fs.writeFileSync("server.js", code, "utf8");
        console.log("-> Repaired " + "${v}");
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! Servers restarted. Checking process status..."
ps aux | grep node
