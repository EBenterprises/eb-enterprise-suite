#!/bin/bash
set -e

echo "[+] Removing PIN completely and disabling all PIN checks..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    mkdir -p "$dir"
    cd "$dir"
    
    # Reset settings.json to have empty pin
    cat << 'EJSON' > settings.json
{
  "pin": "",
  "presets": [
    { "weight": 1.75, "price": 25 },
    { "weight": 3.5, "price": 45 },
    { "weight": 7, "price": 80 },
    { "weight": 14, "price": 140 },
    { "weight": 28, "price": 250 }
  ]
}
EJSON

    # Update server.js settings route to completely ignore PIN verification
    node -e '
    const fs = require("fs");
    let code = fs.readFileSync("server.js", "utf8");
    
    // Replace api/settings post handler to not check pin
    const oldHandler = `app.post(\x27/api/settings\x27, (req, res) => {
    try {
        const { pin, newPin, presets } = req.body;
        const current = getSettings();
        
        // If a PIN is already set, verify current PIN before updating
        if (current.pin && current.pin.trim() !== \x27\x27) {
            if (!pin || pin.trim() !== current.pin.trim()) {
                return res.status(403).json({ error: \x27Invalid PIN\x27 });
            }
        }

        if (newPin !== undefined) {
            current.pin = newPin.trim();
        }
        if (presets) {
            current.presets = presets;
        }
        saveSettings(current);
        res.json({ success: true, presets: current.presets });
    } catch (e) {
        res.status(500).json({ error: \x27Failed to update settings\x27 });
    }
});`;

    const newHandler = `app.post(\x27/api/settings\x27, (req, res) => {
    try {
        const { newPin, presets } = req.body;
        const current = getSettings();

        if (newPin !== undefined) {
            current.pin = newPin.trim();
        }
        if (presets) {
            current.presets = presets;
        }
        saveSettings(current);
        res.json({ success: true, presets: current.presets });
    } catch (e) {
        res.status(500).json({ error: \x27Failed to update settings\x27 });
    }
});`;

    if (code.includes(oldHandler)) {
        code = code.replace(oldHandler, newHandler);
        fs.writeFileSync("server.js", code, "utf8");
        console.log("-> Successfully patched server.js for " + "${v}");
    } else {
        console.log("-> Warning: Handler match not found in " + "${v}");
    }
    '

    # Also update frontend in server.js to remove current PIN input field from Settings tab if present
    node -e '
    const fs = require("fs");
    let code = fs.readFileSync("server.js", "utf8");
    code = code.replace(/<label>Current PIN.*?<\/label>\s*<input[^>]*id="currentPinInput"[^>]*>/g, "");
    fs.writeFileSync("server.js", code, "utf8");
    '

    PORT="$p" nohup node server.js > server.log 2>&1 &
    cd - > /dev/null
done

sleep 2
echo "[+] Done! All PIN requirements and locks have been permanently removed."
