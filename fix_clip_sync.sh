#!/usr/bin/env bash
set -euo pipefail

DAEMON_DIR="${HOME}/github-snippets"
DAEMON_PATH="${DAEMON_DIR}/clip_sync_daemon.sh"

echo "[*] Checking clip sync daemon environment..."
if [ ! -d "$DAEMON_DIR" ]; then
    echo "[!] Directory $DAEMON_DIR does not exist. Initializing..."
    mkdir -p "$DAEMON_DIR"
fi

if [ ! -d "${DAEMON_DIR}/.git" ]; then
    echo "[!] Initializing missing git repository in $DAEMON_DIR to prevent git errors..."
    cd "$DAEMON_DIR"
    git init
    cd - > /dev/null
fi

if [ ! -f "$DAEMON_PATH" ]; then
    echo "[*] Creating placeholder daemon script at $DAEMON_PATH..."
    cat << 'INNER_EOF' > "$DAEMON_PATH"
#!/usr/bin/env bash
while true; do
    # Add your clipboard synchronization logic here
    sleep 60
done
INNER_EOF
    chmod +x "$DAEMON_PATH"
else
    echo "[*] Daemon script already exists at $DAEMON_PATH."
    chmod +x "$DAEMON_PATH"
fi

echo "[*] Restarting clip sync daemon..."
pkill -f "clip_sync_daemon.sh" || true
nohup "${DAEMON_PATH}" > /dev/null 2>&1 &
echo "[*] Clip sync daemon successfully restarted."
