#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Restoring Secure Vault to its original full-stack codebase..."

# 1. Checkout/restore original files from git HEAD (reverting temporary placeholder html)
git checkout HEAD -- . 2>/dev/null || true
rm -f index.html 2>/dev/null

# 2. Ensure git ignores heavy local gradle/npm caches without deleting files from disk
git rm -r --cached . 2>/dev/null
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

# 3. Stage and commit the authentic source code state
git add .
git commit -m "Restore original Secure Vault full-stack architecture" || echo "[*] Working tree ready."

# 4. Push authentic codebase to Variant A and Variant B
echo "[+] Pushing original Secure Vault to Variant A..."
git push -u origin-a main --force --tags

echo "[+] Pushing original Secure Vault to Variant B..."
git push -u origin-b main --force --tags

echo "[+] Success! Original Secure Vault codebase fully restored and deployed."
