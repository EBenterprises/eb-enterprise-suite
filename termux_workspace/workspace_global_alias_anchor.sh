#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

echo "=== Anchoring Global Bin Shortcuts & Termux Aliases ==="

mkdir -p "$PREFIX_BIN"

# 1. Master Workspace Shortcut
cat << 'WRK' > "${PREFIX_BIN}/workspace"
#!/usr/bin/env bash
cd "${HOME}/termux_workspace"
python3 master_orchestrator.py "$@"
WRK
chmod +x "${PREFIX_BIN}/workspace"

# 2. Interactive TUI Dashboard Shortcut
cat << 'DASH' > "${PREFIX_BIN}/dashboard"
#!/usr/bin/env bash
cd "${HOME}/termux_workspace"
python3 dashboard_tui.py "$@"
DASH
chmod +x "${PREFIX_BIN}/dashboard"

# 3. Snippet Manager Shortcut
cat << 'SNIP' > "${PREFIX_BIN}/snippets"
#!/usr/bin/env bash
cd "${HOME}/termux_workspace"
python3 snippet_store.py "$@"
SNIP
chmod +x "${PREFIX_BIN}/snippets"

# 4. Ensure automatic alias injection in bashrc / zshrc for every terminal session
RC_FILE="${HOME}/.bashrc"
if [ -f "${HOME}/.zshrc" ]; then
    RC_FILE="${HOME}/.zshrc"
fi

ANCHOR_BLOCK="# --- Executive Spectrum Terminal Anchor ---
export WORKSPACE_DIR=\"\${HOME}/termux_workspace\"
alias ws=\"cd \${WORKSPACE_DIR} && python3 master_orchestrator.py\"
alias wsd=\"cd \${WORKSPACE_DIR} && python3 dashboard_tui.py\"
alias wss=\"cd \${WORKSPACE_DIR} && python3 snippet_store.py\"
# --------------------------------------------"

if ! grep -q "Executive Spectrum Terminal Anchor" "$RC_FILE" 2>/dev/null; then
    echo "$ANCHOR_BLOCK" >> "$RC_FILE"
    echo "[+] Injected terminal anchor blocks into $RC_FILE"
else
    echo "[*] Terminal anchor blocks already present in $RC_FILE"
fi

cd "$WORKSPACE_DIR"
git add .
if ! git diff --cached --quiet; then
    git commit -m "Anchor update: Deployed global bin commands and terminal session hooks $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Global Bin Anchors & Terminal Hooks Successfully Deployed ==="
