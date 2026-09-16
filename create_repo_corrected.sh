#!/bin/bash

# Automatically fix the lowercase prefix if typed with a capital 'G'
RAW_TOKEN="Ghp_UKkbfA6XQMVMAU1u4qkhHdiuS0cWsE1luoJc"
GH_TOKEN="ghp_${RAW_TOKEN#*[Gg]hp_}"
GH_USER="ebenterprises"
REPO_NAME="secure-vault"

echo "[*] Using corrected token format..."
echo "[*] Creating repository '$REPO_NAME' via GitHub API..."

response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: token ${GH_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$REPO_NAME\", \"private\":true}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 422 ]; then
    echo "[*] Repository ready (HTTP status: $http_code)."
else
    echo "[!] Error creating repository. HTTP status code: $http_code"
    echo "[!] Response: $body"
    exit 1
fi

# Configure remote and push using token
git remote remove origin 2>/dev/null || true
git remote add origin "https://${GH_TOKEN}@github.com/${GH_USER}/${REPO_NAME}.git"

echo "[*] Pushing code to GitHub..."
git push -u origin main

echo "[*] Repository created and pushed successfully!"
