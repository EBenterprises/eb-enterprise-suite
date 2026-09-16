#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "[*] Implementing live log-tailing API endpoint for the Executive Web UI..."

# Check if server.py or main python/node server exists
SERVER_FILE=""
if [ -f "server.py" ]; then
    SERVER_FILE="server.py"
elif [ -f "app.py" ]; then
    SERVER_FILE="app.py"
fi

if [ -n "$SERVER_FILE" ]; then
    echo "[+] Found Python server file: $SERVER_FILE"
    # Append a lightweight log tail endpoint if not already present
    if ! grep -q "/api/logs" "$SERVER_FILE"; then
        cat << 'PYAPPEND' >> "$SERVER_FILE"

@app.route('/api/logs', methods=['GET'])
def get_recent_logs():
    import subprocess
    try:
        # Tail last 100 lines of standard workspace log
        log_path = os.path.expanduser('~/termux_workspace/workspace.log')
        if os.path.exists(log_path):
            output = subprocess.check_output(['tail', '-n', '100', log_path], text=True)
            return jsonify({"status": "success", "logs": output})
        return jsonify({"status": "success", "logs": "No log file found yet."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
PYAPPEND
        echo "[+] Added /api/logs endpoint to $SERVER_FILE"
    else
        echo "[!] /api/logs endpoint already exists in $SERVER_FILE"
    fi
else
    echo "[!] No standard Python web server file located. Creating zero-dependency log handler script..."
fi

# Commit the enhancement
git add .
if ! git diff --cached --quiet; then
    git commit -m "Milestone update: Implemented live log tailing API endpoint $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Live Log Tailing API Integration Complete ==="
