#!/bin/bash

echo "=================================================="
echo "[-] Searching entire Termux storage for Vault code..."
echo "=================================================="

# Search across common development directories for python and html files related to the vault
find ~ -type f \( -name "*.py" -o -name "*.html" -o -name "*.sh" \) 2>/dev/null | while read -r file; do
    if grep -qE "Vault Sign In|EBenterprises|payload|order" "$file" 2>/dev/null; then
        echo "[+] MATCH FOUND: $file"
        echo "--------------------------------------------------"
        head -n 20 "$file"
        echo "..."
        echo "=================================================="
    fi
done

echo "[+] Search complete."
