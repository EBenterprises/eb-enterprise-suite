#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Live Timestamp Clock Integration
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Adding live clock header to index.html..."
sed -i 's/<p class="subtitle">Executive Spectrum Edition<\/p>/<p class="subtitle">Executive Spectrum Edition<\/p><div id="live-clock" style="color: var(--gold-highlight); font-family: monospace; font-size: 0.9rem; margin-top: 0.4rem;">Loading clock...</div>/g' public/index.html

echo "[+] Adding live clock update loop to app.js..."
cat << 'EJS' >> public/app.js

// Live Timestamp Clock
function updateLiveClock() {
    const clockEl = document.getElementById('live-clock');
    if (clockEl) {
        const now = new Date();
        clockEl.innerText = now.toLocaleString();
    }
}
setInterval(updateLiveClock, 1000);
updateLiveClock();
EJS

echo "[+] Live timestamp clock integrated successfully. Restarting server..."
fuser -k 3000/tcp || true
node server.js
