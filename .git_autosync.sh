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
