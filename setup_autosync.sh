#!/bin/bash

# Configuration
REPO_DIR="$HOME/workspace"
GITHUB_USER="ebenterprises"
GITHUB_TOKEN="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"
REPO_NAME="sync-vault"

# 1. Create workspace directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR" || exit 1

# 2. Initialize Git and set authenticated remote URL
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

git remote remove origin 2>/dev/null
git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

git config user.name "EB Enterprises Automation"
git config user.email "automation@ebenterprises.local"

# 3. Create the auto-sync handler script
cat << 'EOT' > "$HOME/.git_autosync.sh"
#!/bin/bash
TARGET_DIR="$HOME/workspace"

if [ -d "$TARGET_DIR/.git" ]; then
    cd "$TARGET_DIR" || exit
    if [[ -n $(git status -s) ]]; then
        git add -A >/dev/null 2>&1
        git commit -m "Auto-sync update: $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
        git push origin main >/dev/null 2>&1 &
    fi
fi
EOT

chmod +x "$HOME/.git_autosync.sh"

# 4. Bind the auto-sync script to the shell prompt hook
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q ".git_autosync.sh" "$SHELL_RC"; then
    echo -e "\n# Auto-sync to GitHub on terminal interaction\nPROMPT_COMMAND=\"$HOME/.git_autosync.sh; \$PROMPT_COMMAND\"" >> "$SHELL_RC"
fi

echo "Auto-sync script configured successfully."
