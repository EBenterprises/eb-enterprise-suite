#!/bin/bash
set -e

for v in v1 v2 v3 v4 v5; do
    FILE="instances/$v/public/index.html"
    if [ -f "$FILE" ]; then
        echo "[+] Restoring clean header for $v..."
        sed -i 's/<span style="color: var(--accent-teal); font-size: 0.85rem;" id="versionBadge">Executive Spectrum OS<\/span>/<span style="color: var(--accent-teal); font-size: 0.85rem;">Executive Spectrum OS<\/span>/g' "$FILE"
        sed -i "s/document.getElementById('versionBadge').textContent = 'Executive Spectrum OS \[' + window.location.port + '\]';//g" "$FILE"
    fi
done

echo "[+] UI restored to original clean Executive Spectrum design."
