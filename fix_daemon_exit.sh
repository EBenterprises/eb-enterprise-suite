#!/usr/bin/env bash
set -euo pipefail

DAEMON_PATH="${HOME}/github-snippets/clip_sync_daemon.sh"

echo "[*] Inspecting and updating $DAEMON_PATH..."
if [ -f "$DAEMON_PATH" ]; then
    cp "$DAEMON_PATH" "${DAEMON_PATH}.bak"
fi

cat << 'INNER_EOF' > "$DAEMON_PATH"
#!/usr/bin/env bash
# Robust clipboard sync daemon wrapper
while true; do
    if command -v termux-clipboard-get &>/dev/null; then
        # Termux clipboard sync logic placeholder
        current_clip="$(termux-clipboard-get 2>/dev/null || true)"
        # Add your sync or file-writing logic here
    fi
    sleep 5
done
INNER_EOF

chmod +x "$DAEMON_PATH"

echo "[*] Restarting daemon..."
pkill -f "clip_sync_daemon.sh" || true
nohup "${DAEMON_PATH}" > /dev/null 2>&1 &
echo "[*] Clip sync daemon restarted successfully."
