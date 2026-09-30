#!/bin/bash
set -e

echo "[+] Fixing tab switching logic and event listeners across all instances..."

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
        
        // Replace the switchTab function with a robust version that ensures elements exist and handles errors smoothly
        const oldSwitchTab = /async function switchTab\(tab\) \{[\s\S]*?\n\s*\}/;
        const newSwitchTab = `async function switchTab(tab) {
            try {
                const tabs = [ \x27new\x27, \x27cust\x27, \x27bals\x27, \x27hist\x27, \x27sets\x27 ];
                tabs.forEach(t => {
                    const tabEl = document.getElementById(\x27tab\x27 + t.charAt(0).toUpperCase() + t.slice(1));
                    const viewEl = document.getElementById(\x27view\x27 + t.charAt(0).toUpperCase() + t.slice(1));
                    if (tabEl) tabEl.classList.remove(\x27active\x27);
                    if (viewEl) viewEl.style.display = \x27none\x27;
                });

                const activeTabEl = document.getElementById(\x27tab\x27 + tab.charAt(0).toUpperCase() + tab.slice(1));
                const activeViewEl = document.getElementById(\x27view\x27 + tab.charAt(0).toUpperCase() + tab.slice(1));
                if (activeTabEl) activeTabEl.classList.add(\x27active\x27);
                if (activeViewEl) activeViewEl.style.display = \x27block\x27;

                await loadData();

                if (tab === \x27cust\x27) renderProfilesList(allCustomersData);
                else if (tab === \x27bals\x27) renderBalancesList(allCustomersData);
                else if (tab === \x27hist\x27) renderGlobalHistory();
                else if (tab === \x27sets\x27) renderPresetConfig();
            } catch (err) {
                console.error("Tab switch error:", err);
            }
        }`;

        if (oldSwitchTab.test(code)) {
            code = code.replace(oldSwitchTab, newSwitchTab);
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Fixed switchTab in " + "${v}");
        } else {
            console.log("-> Warning: switchTab pattern not matched in " + "${v}");
        }
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! All tab switching handlers have been repaired."
