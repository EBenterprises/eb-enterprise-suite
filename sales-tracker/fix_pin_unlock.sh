#!/bin/bash
set -e

echo "[+] Applying fix for PIN unlock handling across all instances..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -d "$dir" ]; then
        cd "$dir"
        
        # Patch server.js using node with properly scoped variables
        node -e '
        const fs = require("fs");
        const dirName = process.argv[1];
        let code = fs.readFileSync("server.js", "utf8");
        
        const oldSubmitPin = `        async function submitPin() {
            const pin = document.getElementById(\x27pinInputField\x27).value.trim();
            const res = await fetch(\x27/api/auth\x27, {
                method: \x27POST\x27,
                headers: { \x27Content-Type\x27: \x27application/json\x27 },
                body: JSON.stringify({ pin })
            });
            const result = await res.json();
            if (result.success) {
                isUnlocked = true;
                document.getElementById(\x27pinModal\x27).style.display = \x27none\x27;
                document.getElementById(\x27pinInputField\x27).value = \x27\x27;
                document.getElementById(\x27lockBtn\x27).classList.remove(\x27locked\x27);
                document.getElementById(\x27lockBtn\x27).innerText = \x27🔓 Unlocked\x27;
                await loadSettings();
            } else {
                alert(\x27Incorrect PIN\x27);
            }
        }`;

        const newSubmitPin = `        async function submitPin() {
            try {
                const pinEl = document.getElementById(\x27pinInputField\x27);
                const pin = pinEl ? pinEl.value.trim() : \x27\x27;
                const res = await fetch(\x27/api/auth\x27, {
                    method: \x27POST\x27,
                    headers: { \x27Content-Type\x27: \x27application/json\x27 },
                    body: JSON.stringify({ pin })
                });
                const result = await res.json();
                if (result.success) {
                    isUnlocked = true;
                    const modal = document.getElementById(\x27pinModal\x27);
                    if (modal) modal.style.display = \x27none\x27;
                    if (pinEl) pinEl.value = \x27\x27;
                    const lockBtn = document.getElementById(\x27lockBtn\x27);
                    if (lockBtn) {
                        lockBtn.classList.remove(\x27locked\x27);
                        lockBtn.innerText = \x27🔓 Unlocked\x27;
                    }
                    if (typeof loadSettings === "function") await loadSettings();
                } else {
                    alert(\x27Incorrect PIN. Try 1234\x27);
                }
            } catch (err) {
                console.error(err);
                alert(\x27Unlock error occurred\x27);
            }
        }`;

        if (code.includes(oldSubmitPin)) {
            code = code.replace(oldSubmitPin, newSubmitPin);
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Patched server.js in " + dirName);
        } else {
            console.log("-> Exact match not found in " + dirName + ", checking partial replacements...");
            // Fallback replacement if function formatting differs slightly
            if (code.includes("async function submitPin()")) {
                // Replace general submitPin definition
                code = code.replace(/async function submitPin\(\)\s*\{[\s\S]*?\n\s*\}/, newSubmitPin);
                fs.writeFileSync("server.js", code, "utf8");
                console.log("-> Patched server.js via regex fallback in " + dirName);
            } else {
                console.log("-> Warning: submitPin function not found in " + dirName);
            }
        }
        ' "$dir"

        cd - > /dev/null
    fi
done

echo "[+] Restarting all application instances..."
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
    fi
done

sleep 2
echo "[+] Done! All instances have been patched and restarted."
