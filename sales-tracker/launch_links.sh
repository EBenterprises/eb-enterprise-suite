#!/bin/bash
set -e

echo "[+] EB Sales Tracker - Active Application Links & Endpoints:"
echo "--------------------------------------------------------"
echo "  [UI] Main Application Dashboard: http://localhost:3000"
echo "  [API] Sales Ledger Endpoint:     http://localhost:3000/api/sales"
echo "  [API] Payments Endpoint:         http://localhost:3000/api/payments"
echo "  [API] Inventory Endpoint:        http://localhost:3000/api/inventory"
echo "  [API] Customers Endpoint:        http://localhost:3000/api/customers"
echo "  [API] Analytics Endpoint:        http://localhost:3000/api/analytics?filter=all"
echo "--------------------------------------------------------"

# Attempt to open browser/links if utilities are available
if command -v termux-open-url >/dev/null 2>&1; then
    echo "[+] Opening main dashboard via Termux..."
    termux-open-url "http://localhost:3000"
elif command -v xdg-open >/dev/null 2>&1; then
    echo "[+] Opening main dashboard via xdg-open..."
    xdg-open "http://localhost:3000"
elif command -v open >/dev/null 2>&1; then
    echo "[+] Opening main dashboard via macOS open..."
    open "http://localhost:3000"
else
    echo "[i] Browser launcher utility not found. Access links directly in your browser."
fi
