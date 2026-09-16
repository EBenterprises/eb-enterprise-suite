#!/usr/bin/env bash
set -euo pipefail

SNIPPETS_DIR="${HOME}/termux_workspace/snippets"
GPASTE_BIN="${PREFIX}/bin/gpaste"
CLIP_DAEMON="${HOME}/termux_workspace/clip_daemon.sh"

mkdir -p "$SNIPPETS_DIR"

cat << 'INNER_EOF' > "$GPASTE_BIN"
#!/usr/bin/env bash
set -euo pipefail

SNIPPETS_DIR="${HOME}/termux_workspace/snippets"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
FILENAME="${SNIPPETS_DIR}/snippet_${TIMESTAMP}.txt"

if [ $# -gt 0 ]; then
    echo "$*" > "$FILENAME"
elif [ ! -t 0 ]; then
    cat > "$FILENAME"
elif command -v termux-clipboard-get &> /dev/null; then
    termux-clipboard-get > "$FILENAME"
else
    echo "No input provided and termux-clipboard-get is unavailable."
    exit 1
fi

if [ ! -s "$FILENAME" ]; then
    rm -f "$FILENAME"
    echo "Snippet is empty. Nothing saved."
    exit 0
fi

cd "${HOME}/termux_workspace"
git add "$FILENAME"
git commit -m "Snippet added: $(basename "$FILENAME")"
git push origin main >/dev/null 2>&1 || true

echo "Snippet saved and pushed: $(basename "$FILENAME")"
INNER_EOF

chmod +x "$GPASTE_BIN"

cat << 'INNER_EOF' > "$CLIP_DAEMON"
#!/usr/bin/env bash
LAST_CLIP=""
while true; do
    if command -v termux-clipboard-get &> /dev/null; then
        CURRENT_CLIP=$(termux-clipboard-get 2>/dev/null || true)
        if [ -n "$CURRENT_CLIP" ] && [ "$CURRENT_CLIP" != "$LAST_CLIP" ]; then
            LAST_CLIP="$CURRENT_CLIP"
            echo "$CURRENT_CLIP" | gpaste >/dev/null 2>&1 || true
        fi
    fi
    sleep 10
done
INNER_EOF

chmod +x "$CLIP_DAEMON"

if ! pgrep -f "clip_daemon.sh" > /dev/null; then
    nohup "$CLIP_DAEMON" > /dev/null 2>&1 &
    echo "Clipboard monitoring daemon started successfully."
else
    echo "Clipboard monitoring daemon is already running."
fi

echo "Clipboard synchronization workflow configured. Use 'gpaste' to manually pipe or capture snippets."
