#!/usr/bin/env bash
echo "=== Search Results for Git Repositories & Projects ==="
find $HOME -maxdepth 4 -name ".git" -type d 2>/dev/null | while read -r gitdir; do
    repo_path=$(dirname "$gitdir")
    echo "------------------------------------------------"
    echo "Path: $repo_path"
    cd "$repo_path"
    echo -n "Remote: "
    git config --get remote.origin.url 2>/dev/null || echo "No remote"
    echo -n "Last Commit: "
    git log -1 --format="%h - %s (%cr)" 2>/dev/null || echo "No commits"
done
