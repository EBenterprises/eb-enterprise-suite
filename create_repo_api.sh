#!/bin/bash
set -e

read -p "Enter your GitHub Username (e.g. ebenterprises): " gh_user
read -p "Enter your Personal Access Token (PAT): " gh_token
read -p "Enter the new repository name to create: " repo_name
read -p "Make repository private? (y/n, default y): " is_private
is_private=${is_private:-y}

private_bool="true"
if [ "$is_private" = "n" ]; then
    private_bool="false"
fi

echo "[*] Creating repository '$repo_name' via GitHub API..."
response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Authorization: token ${gh_token}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$repo_name\", \"private\":$private_bool}")

if [ "$response" -eq 201 ] || [ "$response" -eq 422 ]; then
    echo "[*] Repository ready (HTTP status: $response)."
else
    echo "[!] Error creating repository. HTTP status code: $response"
    exit 1
fi

# Configure remote and push using token
git remote remove origin 2>/dev/null || true
git remote add origin "https://${gh_token}@github.com/${gh_user}/${repo_name}.git"

echo "[*] Pushing code to GitHub..."
git push -u origin main

echo "[*] Repository created and pushed successfully!"
