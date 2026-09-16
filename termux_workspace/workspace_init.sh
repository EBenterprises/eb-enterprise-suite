#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Environment Initializer & Setup
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

WORKSPACE_DIR="$HOME/termux_workspace"
mkdir -p "$WORKSPACE_DIR/.vault" "$WORKSPACE_DIR/modules" "$WORKSPACE_DIR/plugins"

echo "[+] Setting executable permissions across workspace utilities..."
chmod +x "$WORKSPACE_DIR"/exec-spec
chmod +x "$WORKSPACE_DIR"/*.sh
chmod +x "$WORKSPACE_DIR"/*.py

echo "[+] Executive Spectrum environment initialized successfully."
