#!/bin/bash
set -e

echo "[+] Adding custom Location input field to the transaction sale form across all instances..."

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
        
        // Add location input field into the sale view HTML if not already present
        const targetHtml = `<label>Cash Collected ($)</label>\n            <input type="number" id="cashInput"`;
        const replacementHtml = `<label>Location / Coordinates</label>\n            <input type="text" id="locationInput" placeholder="Auto-detected or custom location..." style="margin-bottom: 8px;">\n\n            <label>Cash Collected ($)</label>\n            <input type="number" id="cashInput"`;

        if (code.includes(targetHtml) && !code.includes("id=\"locationInput\"")) {
            code = code.replace(targetHtml, replacementHtml);
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Added location input HTML in " + "${v}");
        }

        // Update recordTransaction function to use the custom location input value
        const oldRecord = `            const sendPayload = (gpsVal) => {
                fetch(\x27/api/transactions\x27, {
                    method: \x27POST\x27,
                    headers: { \x27Content-Type\x27: \x27application/json\x27 },
                    body: JSON.stringify({ customer: customer, gps: gpsVal || \x27\x27, item: (weight > 0 ? weight + \x27g Unit\x27 : \x27Custom Unit\x27), amount: amount, cashCollected: cashCollected })
                })`;

        const newRecord = `            const customLoc = document.getElementById(\x27locationInput\x27).value.trim();
            const finalGps = customLoc !== \x27\x27 ? customLoc : (gpsVal || \x27\x27);

            const sendPayload = (gpsValFinal) => {
                fetch(\x27/api/transactions\x27, {
                    method: \x27POST\x27,
                    headers: { \x27Content-Type\x27: \x27application/json\x27 },
                    body: JSON.stringify({ customer: customer, gps: gpsValFinal, item: (weight > 0 ? weight + \x27g Unit\x27 : \x27Custom Unit\x27), amount: amount, cashCollected: cashCollected })
                })`;

        if (code.includes("const sendPayload = (gpsVal) => {")) {
            // Replace geolocation success handler population
            code = code.replace(/if \(navigator\.geolocation\) \{[\s\S]*?\} else \{[\s\S]*?\}/, `
            const customLoc = document.getElementById(\x27locationInput\x27).value.trim();
            if (customLoc) {
                sendPayload(customLoc);
            } else if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (pos) => { 
                        const autoLoc = pos.coords.latitude.toFixed(4) + \x27, \x27 + pos.coords.longitude.toFixed(4);
                        document.getElementById(\x27locationInput\x27).value = autoLoc;
                        sendPayload(autoLoc); 
                    },
                    (err) => { sendPayload(currentGPS); },
                    { enableHighAccuracy: true, timeout: 5000 }
                );
            } else {
                sendPayload(currentGPS);
            }`);
            
            fs.writeFileSync("server.js", code, "utf8");
            console.log("-> Patched geolocation & location input handling in " + "${v}");
        }

        // Prepopulate location input when geolocation resolves initially
        const oldGeoSuccess = `(pos) => { currentGPS = pos.coords.latitude.toFixed(4) + \x27, \x27 + pos.coords.longitude.toFixed(4); },`;
        const newGeoSuccess = `(pos) => { 
                currentGPS = pos.coords.latitude.toFixed(4) + \x27, \x27 + pos.coords.longitude.toFixed(4); 
                const locEl = document.getElementById(\x27locationInput\x27);
                if (locEl && !locEl.value) locEl.value = currentGPS;
            },`;
        if (code.includes(oldGeoSuccess)) {
            code = code.replace(oldGeoSuccess, newGeoSuccess);
            fs.writeFileSync("server.js", code, "utf8");
        }
        '

        PORT="$p" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Done! Location input field successfully integrated into all instances."
