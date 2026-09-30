#!/bin/bash
set -e

echo "[+] Updating server.js across all instances so preset buttons correctly populate both grams and cost..."

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

        // Make sure renderPresetButtons correctly binds weight and price
        const oldRender = `function renderPresetButtons() {
            const grid = document.getElementById(\x27presetButtonsGrid\x27);
            if (!grid) return;
            grid.innerHTML = appPresets.map((p, idx) => 
                \x27<button class="preset-btn \x27 + (idx === 0 ? \x27active\x27 : \x27\x27) + \x27" onclick="setPreset(\x27 + p.weight + \x27, \x27 + p.price + \x27, this)">\x27 + p.weight + \x27g</button>\x27
            ).join(\x27\x27);
        }`;

        const newRender = `function renderPresetButtons() {
            const grid = document.getElementById(\x27presetButtonsGrid\x27);
            if (!grid) return;
            grid.innerHTML = appPresets.map(p => 
                \x27<button class="preset-btn" onclick="setPreset(\x27 + p.weight + \x27, \x27 + p.price + \x27, this)">\x27 + p.weight + \x27g ($\x27 + p.price + \x27)</button>\x27
            ).join(\x27\x27);
        }`;

        if (code.includes(oldRender)) {
            code = code.replace(oldRender, newRender);
        } else {
            // Fallback replacement for renderPresetButtons definition
            code = code.replace(/function renderPresetButtons\(\) \{[\s\S]*?\}/, newRender);
        }

        // Ensure setPreset updates both inputs and recalculates properly
        const setPresetFunc = `function setPreset(weight, price, btn) {
            document.querySelectorAll(\x27.preset-btn\x27).forEach(b => b.classList.remove(\x27active\x27));
            if (btn) btn.classList.add(\x27active\x27);
            document.getElementById(\x27weightInput\x27).value = weight;
            document.getElementById(\x27amountInput\x27).value = price;
            calculate();
        }`;

        if (!code.includes("document.getElementById('amountInput').value = price;")) {
            code = code.replace(/function setPreset\([\s\S]*?\}/, setPresetFunc);
        }

        fs.writeFileSync("server.js", code, "utf8");
        console.log("-> Updated presets filling logic for " + "${v}");
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! Preset buttons now correctly populate grams and cost fields."
