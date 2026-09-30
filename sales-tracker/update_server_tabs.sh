#!/bin/bash
set -e

echo "[+] Updating server.js across all instances to fix UI tab switching & rendering..."

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    dir="instances/$v"
    if [ -f "$dir/server.js" ]; then
        cd "$dir"
        node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Ensure switchTab loads data correctly without failing tab switching
        const oldSwitchTab = /function switchTab\(tab\) \{[\s\S]*?\n\}/;
        const newSwitchTab = `function switchTab(tab) {
            const tabs = [\x27new\x27, \x27cust\x27, \x27bals\x27, \x27hist\x27, \x27sets\x27];
            tabs.forEach(t => {
                const tabEl = document.getElementById(\x27tab\x27 + t.charAt(0).toUpperCase() + t.slice(1));
                const viewEl = document.getElementById(\x27view\x27 + t.charAt(0).toUpperCase() + t.slice(1));
                if (tabEl) tabEl.classList.remove(\x27active\x27);
                if (viewEl) viewEl.classList.remove(\x27active-view\x27);
            });

            const activeTabEl = document.getElementById(\x27tab\x27 + tab.charAt(0).toUpperCase() + tab.slice(1));
            const activeViewEl = document.getElementById(\x27view\x27 + tab.charAt(0).toUpperCase() + tab.slice(1));
            
            if (activeTabEl) activeTabEl.classList.add(\x27active\x27);
            if (activeViewEl) activeViewEl.classList.add(\x27active-view\x27);

            loadData().then(() => {
                if (tab === \x27cust\x27) renderProfilesList(allCustomersData);
                else if (tab === \x27bals\x27) renderBalancesList(allCustomersData);
                else if (tab === \x27hist\x27) renderGlobalHistory();
                else if (tab === \x27sets\x27) renderPresetConfig();
            }).catch(err => {
                console.error(\x27Failed to load data for tab:\x27, err);
            });
        }`;

        if (code.match(oldSwitchTab)) {
            code = code.replace(oldSwitchTab, newSwitchTab);
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Updated switchTab in " + "${v}");
        } else {
            console.log("-> switchTab pattern not found in " + "${v}");
        }
        '
        cd - > /dev/null
    fi
done

echo "[+] Restarting all instances..."
pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    if [ -d "instances/$v" ]; then
        cd "instances/$v"
        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

echo "[+] All instances restarted with fixed tab navigation!"
