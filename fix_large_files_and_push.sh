#!/bin/bash
set -e

echo "[*] Removing large Gradle binary zips and build caches from Git tracking..."
git rm --cached native-android-app/gradle-8.2-bin.zip 2>/dev/null || true
find . -name "*.zip" -o -name "*.tar.gz" | xargs git rm --cached 2>/dev/null || true

echo "[*] Adding .gitignore rules to block heavy binary files..."
cat << 'GITIGNORE' >> .gitignore
*.zip
*.tar.gz
.buildozer/
bin/
build/
.gradle/
GITIGNORE

git add .gitignore
git commit -m "Chore: Exclude heavy Gradle distribution zips and build caches" || echo "No changes to commit."

echo "[*] Configuring Git credential helper via GitHub CLI..."
gh auth setup-git

echo "[*] Pushing cleaned project to GitHub..."
git push -u origin main --force

echo "[*] Successfully pushed to GitHub!"
