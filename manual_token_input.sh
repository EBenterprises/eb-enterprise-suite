#!/bin/bash
set -e

echo "=========================================================="
echo "GitHub API returned 'Bad credentials'."
echo "Please generate a fresh Personal Access Token (PAT) from:"
echo "https://github.com/settings/tokens"
echo "Make sure to check the 'repo' scope."
echo "=========================================================="
echo ""

read -p "Enter your GitHub Username: " gh_user
read -p "Enter your NEW Personal Access Token (PAT): " gh_token
read -p "Enter the repository name (e.g., secure-vault): " repo_name

echo "[*] Creating repository '$repo_name' via GitHub API..."
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: token ${gh_token}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$repo_name\", \"private\":true}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 422 ]; then
    echo "[*] Repository ready (HTTP status: $http_code)."
else
    echo "[!] Error creating repository. HTTP status code: $http_code"
    echo "[!] Response: $body"
    exit 1
fi

git remote remove origin 2>/dev/null || true
git remote add origin "https://${gh_token}@github.com/${gh_user}/${repo_name}.git"

echo "[*] Pushing code to GitHub..."
git push -u origin main

echo "[*] Repository created and pushed successfully!"
