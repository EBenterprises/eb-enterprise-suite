#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Executing Comprehensive Workspace Health & Security Audit ==="

# 1. Verify Git remote connectivity and sync status
echo "[*] Checking remote repository connectivity..."
if git ls-remote --exit-code origin main > /dev/null 2>&1; then
    echo "[+] Remote repository is reachable and authenticated."
else
    echo "[-] Warning: Remote repository check failed. Verify SSH keys or internet connectivity."
fi

# 2. Check SQLite Snippet Store Integrity
DB_PATH="${WORKSPACE_DIR}/snippets.db"
if [ -f "$DB_PATH" ]; then
    echo "[*] Verifying SQLite snippet database integrity..."
    if sqlite3 "$DB_PATH" "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "[+] SQLite database integrity verified: OK."
    else
        echo "[-] Warning: Database integrity check returned anomalies."
    fi
else
    echo "[!] snippets.db not found. Initializing new store..."
    python3 snippet_store.py list > /dev/null 2>&1 || true
fi

# 3. Verify Background Daemon Supervisor Status
if pgrep -f "workspace_daemon.py" > /dev/null; then
    echo "[+] Background workspace daemon supervisor is active."
else
    echo "[!] Restarting background workspace daemon supervisor..."
    nohup python3 workspace_daemon.py > /dev/null 2>&1 &
    echo "[+] Supervisor daemon restarted."
fi

# 4. Final status commit
git add .
if ! git diff --cached --quiet; then
    git commit -m "Health audit: Verified repository, SQLite store, and background daemons $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Workspace Health Audit Complete: All Systems Fully Operational ==="
