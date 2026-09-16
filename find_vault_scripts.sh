#!/bin/bash

echo "Searching for script and python files related to Secure Vault..."
echo "------------------------------------------------------------------"

find ~ -type f \( -name "*.py" -o -name "*.sh" \) 2>/dev/null | while read -r file; do
    # Skip standard system or git paths to focus on user code
    if [[ "$file" =~ \.git|\.cache|\.config ]]; then
        continue
    fi
    
    if grep -qE "flask|app\.run|vault|EBenterprises|5000|5001" "$file" 2>/dev/null; then
        echo "FILE PATH: $file"
        echo "--------------------------------------------------"
        cat "$file"
        echo -e "\n==================================================\n"
    fi
done

echo "Script search complete."
