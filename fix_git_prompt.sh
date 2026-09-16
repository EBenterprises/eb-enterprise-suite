#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${HOME}/.bashrc"
[ -f "$HOME/.zshrc" ] && TARGET_FILE="$HOME/.zshrc"

echo "[*] Inspecting $TARGET_FILE..."
cp "$TARGET_FILE" "${TARGET_FILE}.bak_$(date +%s)"

# Use Python for robust regex replacement to avoid sed ampersand parsing issues, with a sed fallback
if command -v python3 &>/dev/null; then
    python3 -c '
import re
path = "'"$TARGET_FILE"'"
with open(path, "r") as f:
    content = f.read()
new_content = re.sub(r"\bgit\s+(?!rev-parse)", "git rev-parse --is-inside-work-tree &>/dev/null && git ", content)
with open(path, "w") as f:
    f.write(new_content)
'
else
    sed -i 's/\bgit /git rev-parse --is-inside-work-tree >\/dev\/null 2>\&1 \&\& git /g' "$TARGET_FILE"
fi

echo "[*] Reloading shell configuration..."
source "$TARGET_FILE" || true
echo "[*] Fix applied successfully."
