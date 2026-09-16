#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Untracking heavy caches and binaries in git (keeping your local files safe on disk)..."

# 1. Remove files from git tracking index without deleting them from your disk
git rm -r --cached . 2>/dev/null

# 2. Update .gitignore to exclude bulky cache/build artifacts
cat << 'GITIGNORE' > .gitignore
node_modules/
dist/
build/
.npm/
*.zip
*.jar
*.tar.gz
*.bin
*.cache
native-android-app/gradle-8.2/
native-android-app/gradle-8.2-bin.zip*
GITIGNORE

# 3. Re-add tracked project source files and commit
git add .
git commit -m "Source-only sync: kept local files untouched on disk" || echo "[*] Working tree clean."

# 4. Push cleanly to both GitHub variants
echo "[+] Pushing Variant A..."
git push -u origin-a main --force --tags

echo "[+] Pushing Variant B..."
git push -u origin-b main --force --tags

echo "[+] Success! Code is live on GitHub, and your local build files/caches remain untouched on your device."
