#!/bin/bash

echo "Scanning all directories for any files containing Secure Vault components..."
echo "------------------------------------------------------------------"

find ~ -type f 2>/dev/null | while read -r file; do
    # Skip binary, log, and git files to keep it clean and readable
    if [[ "$file" =~ \.(log|pyc|git|zip|tar|gz)$ ]]; then
        continue
    fi
    
    if grep -qE "Vault Sign In|EBenterprises|Payload Hash|Secure Order" "$file" 2>/dev/null; then
        echo "FILE PATH: $file"
        echo "--------------------------------------------------"
        cat "$file"
        echo -e "\n==================================================\n"
    fi
done

echo "Scan complete."
