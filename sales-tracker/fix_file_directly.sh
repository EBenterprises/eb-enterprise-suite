#!/bin/bash
set -e

echo "[+] Fixing line 647 syntax error in server.js across all instances..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -f "$dir/server.js" ]; then
        cd "$dir"
        
        node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Locate the problematic renderProfilesList function and replace it cleanly
        const faultyPattern = /function renderProfilesList\(data\) \{[\s\S]*?\n\}/;
        
        const cleanProfilesFunc = `function renderProfilesList(data) {
            const container = document.getElementById(\x27profilesList\x27);
            if (!container) return;
            container.innerHTML = data.map(c => {
                const phoneClean = c.phone || \x27\x27;
                const smsBody = encodeURIComponent(\x27Hi \x27 + c.customer + \x27, following up regarding your account balance.\x27);
                return \x27<div style="padding: 10px; border-bottom: 1px solid #1e293b; background: #0b0f19; border-radius: 6px; margin-bottom: 6px;">\x27 +
                    \x27<div style="display: flex; justify-content: space-between; font-weight: bold; color: #38bdf8; font-size: 13px;">\x27 +
                        \x27<span>\x27 + c.customer + \x27</span>\x27 +
                        \x27<span style="color: \x27 + (c.currentBalance > 0 ? \x27#f87171\x27 : \x27#34d399\x27) + \x27;">Bal: $\x27 + c.currentBalance.toFixed(2) + \x27</span>\x27 +
                    \x27</div>\x27 +
                    \x27<div style="margin-top: 6px;">\x27 +
                        \x27<label style="font-size:10px;">Phone Number</label>\x27 +
                        \x27<input type="tel" id="phone_edit_\x27 + btoa(c.customer) + \x27" value="\x27 + phoneClean + \x27" placeholder="Add phone..." style="margin-bottom:4px; padding:6px; font-size:12px;">\x27 +
                        (phoneClean ? \x27<div class="comms-row"><a class="call-btn" href="tel:\x27 + phoneClean + \x27">📞 Call</a><a class="sms-btn" href="sms:\x27 + phoneClean + \x27?body=\x27 + smsBody + \x27">💬 Message SMS</a></div>\x27 : \x27\x27) +
                        \x27<label style="font-size:10px; margin-top: 6px;">Notes / Preferences</label>\x27 +
                        \x27<input type="text" id="notes_edit_\x27 + btoa(c.customer) + \x27" value="\x27 + (c.notes || \x27\x27) + \x27" placeholder="Add notes..." style="margin-bottom:6px; padding:6px; font-size:12px;">\x27 +
                        \x27<button class="action-btn" style="padding:8px; font-size:11px; margin-bottom:0; background:#0284c7;" onclick="saveCustomerProfile(\\x27 + c.customer.replace(/\\x27/g, "\\\\+\\x27") + \x27\\x27)">Save Profile</button>\x27 +
                    \x27</div>\x27 +
                \x27</div>\x27;
            }).join(\x27\x27);
        }`;

        if (code.match(faultyPattern)) {
            code = code.replace(faultyPattern, cleanProfilesFunc);
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Successfully patched " + "${v}");
        } else {
            console.log("-> Pattern not found in " + "${v}");
        }
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! Checking server logs now..."
tail -n 5 instances/v1/server.log
