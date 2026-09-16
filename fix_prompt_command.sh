#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${HOME}/.bashrc"

echo "[*] Fixing unbound PROMPT_COMMAND error in $TARGET_FILE..."
cp "$TARGET_FILE" "${TARGET_FILE}.bak_$(date +%s)"

# Replace unsafe $PROMPT_COMMAND references with safe parameter expansion ${PROMPT_COMMAND:-}
if command -v python3 &>/dev/null; then
    python3 -c '
path = "'"$TARGET_FILE"'"
with open(path, "r") as f:
    content = f.read()
# Replace direct $PROMPT_COMMAND with ${PROMPT_COMMAND:-}
new_content = content.replace("$PROMPT_COMMAND", "${PROMPT_COMMAND:-}")
with open(path, "w") as f:
    f.write(new_content)
'
else
    sed -i 's/\$PROMPT_COMMAND/\${PROMPT_COMMAND:-}/g' "$TARGET_FILE"
fi

echo "[*] Testing configuration reload..."
source "$TARGET_FILE"
echo "[*] Configuration reloaded successfully without errors."
