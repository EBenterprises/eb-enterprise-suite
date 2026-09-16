#!/bin/bash
echo "[+] Restoring original UI layouts across secure vault instances..."

# If there's a git repository, reset app.py files to revert unintended modifications
for dir in secure_vault_local secure_vault_onion secure_vault_public; do
    if [ -d "$dir" ]; then
        cd "$dir"
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git checkout app.py 2>/dev/null
        fi
        cd - >/dev/null
    fi
done

echo "[+] UI reverted to the original version. Restarting runners..."
./run_public.sh
