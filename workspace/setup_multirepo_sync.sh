#!/bin/bash

# Configuration
WORKSPACE_DIR="$HOME/workspace"
GITHUB_USER="ebenterprises"
GITHUB_TOKEN="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"
GIT_NAME="Easton Bodeux"
GIT_EMAIL="eastonbodeuxenterprises@gmail.com"

mkdir -p "$WORKSPACE_DIR"

# 1. Upgrade the auto-sync handler to scan and sync infinite repositories under ~/workspace
cat << 'EOT' > "$HOME/.git_autosync.sh"
#!/bin/bash
WORKSPACE_DIR="$HOME/workspace"

if [ -d "$WORKSPACE_DIR" ]; then
    for repo in "$WORKSPACE_DIR"/*/; do
        if [ -d "${repo}.git" ]; then
            (
                cd "$repo" || exit
                if [[ -n $(git status -s) ]]; then
                    git add -A >/dev/null 2>&1
                    git commit -m "Auto-sync update: $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
                    git push origin HEAD >/dev/null 2>&1 &
                fi
            )
        fi
    done
fi
EOT

chmod +x "$HOME/.git_autosync.sh"

# 2. Ensure shell prompt hook is active
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q ".git_autosync.sh" "$SHELL_RC"; then
    echo -e "\n# Auto-sync infinite repositories on terminal interaction\nPROMPT_COMMAND=\"$HOME/.git_autosync.sh; \$PROMPT_COMMAND\"" >> "$SHELL_RC"
fi

echo "Multi-repository auto-sync engine configured. Any Git repository placed inside $WORKSPACE_DIR will now automatically sync in the background on terminal activity."
