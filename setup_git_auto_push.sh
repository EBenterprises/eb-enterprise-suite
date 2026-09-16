#!/usr/bin/env bash
set -e

# Target directory for auto-pushed code
REPO_DIR="${HOME}/github-snippets"

mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Initialize local git repository if not already initialized
if [ ! -d ".git" ]; then
    git init
    git branch -M main
    echo "# Code Snippets Vault" > README.md
    git add README.md
    git commit -m "Initial commit"
fi

# 1. Terminal Paste Helper Script
cat <<'SCRIPT' > "${REPO_DIR}/gpaste"
#!/usr/bin/env bash
set -e

REPO_DIR="${HOME}/github-snippets"
mkdir -p "$REPO_DIR"

EXT="${1:-txt}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="snippet_${TIMESTAMP}.${EXT}"
FILEPATH="${REPO_DIR}/${FILENAME}"

if [ -t 0 ]; then
    echo "[+] Reading from clipboard..."
    if command -v termux-clipboard-get &>/dev/null; then
        termux-clipboard-get > "$FILEPATH"
    elif command -v wl-paste &>/dev/null; then
        wl-paste > "$FILEPATH"
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -o > "$FILEPATH"
    elif command -v pbpaste &>/dev/null; then
        pbpaste > "$FILEPATH"
    else
        echo "[-] Clipboard utility not found. Paste your code below, then press CTRL+D:"
        cat > "$FILEPATH"
    fi
else
    cat > "$FILEPATH"
fi

if [ ! -s "$FILEPATH" ]; then
    echo "[-] Empty content. Aborting commit."
    rm -f "$FILEPATH"
    exit 1
fi

cd "$REPO_DIR"
git add "$FILENAME"
git commit -m "Auto-pasted code: ${FILENAME}"
git push origin main
echo "[✓] Pushed ${FILENAME} to GitHub successfully."
SCRIPT

chmod +x "${REPO_DIR}/gpaste"

# 2. Clipboard Monitor Daemon
cat <<'SCRIPT' > "${REPO_DIR}/clip_sync_daemon.sh"
#!/usr/bin/env bash

REPO_DIR="${HOME}/github-snippets"
LAST_HASH=""

get_clip() {
    if command -v termux-clipboard-get &>/dev/null; then
        termux-clipboard-get 2>/dev/null
    elif command -v wl-paste &>/dev/null; then
        wl-paste 2>/dev/null
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -o 2>/dev/null
    elif command -v pbpaste &>/dev/null; then
        pbpaste 2>/dev/null
    fi
}

echo "[*] Clipboard auto-push daemon started. Watching for changes..."

while true; do
    CLIP_CONTENT=$(get_clip)
    if [ -n "$CLIP_CONTENT" ]; then
        CURRENT_HASH=$(echo -n "$CLIP_CONTENT" | sha256sum | awk '{print $1}')
        if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
            LAST_HASH="$CURRENT_HASH"
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            FILENAME="${REPO_DIR}/auto_clip_${TIMESTAMP}.txt"
            
            echo "$CLIP_CONTENT" > "$FILENAME"
            
            cd "$REPO_DIR"
            git add "$FILENAME"
            git commit -m "Automated clipboard sync: ${TIMESTAMP}"
            git push origin main && echo "[✓] Auto-pushed clipboard content: ${FILENAME}" || echo "[!] Push failed. Ensure remote repository is configured."
        fi
    fi
    sleep 3
done
SCRIPT

chmod +x "${REPO_DIR}/clip_sync_daemon.sh"

# 3. Register global executable symlinks
SYSLIB_DIR="${HOME}/.local/bin"
mkdir -p "$SYSLIB_DIR"
ln -sf "${REPO_DIR}/gpaste" "${SYSLIB_DIR}/gpaste"

echo "[✓] Setup completed successfully."
echo "Directory created at: ${REPO_DIR}"
echo ""
echo "Next steps:"
echo "1. Connect your local repo to GitHub (run inside ${REPO_DIR}):"
echo "   cd ${REPO_DIR} && git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git"
echo "2. Ensure '${SYSLIB_DIR}' is in your PATH."
echo "3. Usage options:"
echo "   - Run 'gpaste' to push current clipboard content immediately."
echo "   - Run 'gpaste py' to push with a specific file extension."
echo "   - Pipe input: 'cat code.py | gpaste'"
echo "   - Run daemon: '${REPO_DIR}/clip_sync_daemon.sh &' to auto-push every copy event."
