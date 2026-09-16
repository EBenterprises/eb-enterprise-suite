#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
SHELL_RC="${HOME}/.bashrc"

if [ -f "${HOME}/.zshrc" ] && [ -n "${ZSH_VERSION:-}" ]; then
    SHELL_RC="${HOME}/.zshrc"
fi

HOOK_SNIPPET="
# Auto-sync termux workspace on shell interaction
if [ -d \"${WORKSPACE_DIR}\" ]; then
    (cd \"${WORKSPACE_DIR}\" && git add . && git diff-index --quiet HEAD -- || (git commit -m \"Auto-sync: \$(date '+%Y-%m-%d %H:%M:%S')\" && git push origin main) >/dev/null 2>&1 &)
fi
"

if ! grep -q "termux_workspace" "$SHELL_RC"; then
    echo "$HOOK_SNIPPET" >> "$SHELL_RC"
    echo "Auto-sync hook successfully added to $SHELL_RC"
else
    echo "Auto-sync hook already exists in $SHELL_RC"
fi

echo "Restart your terminal or run: source $SHELL_RC"
