#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Inventory Precision Update (0.01)
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Updating inventory quantity step to 0.01 in index.html..."
sed -i 's/step="0.1"/step="0.01"/g' public/index.html
sed -i 's/placeholder="Quantity (supports decimals e.g. 0.1)"/placeholder="Quantity (supports decimals e.g. 0.01)"/g' public/index.html

echo "[+] Updating app.js frontend rendering to display 2 decimal places for inventory quantities..."
sed -i 's/parseFloat(item.quantity).toFixed(1)/parseFloat(item.quantity).toFixed(2)/g' public/app.js

echo "[+] Inventory precision updated to 0.01 successfully. Restarting server..."
fuser -k 3000/tcp || true
node server.js
