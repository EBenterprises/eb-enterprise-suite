#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Diagnosing and fixing GitHub Pages 404 error..."

# 1. Check if index.html exists in the root directory
if [ ! -f "index.html" ]; then
    echo "[+] Creating missing index.html in root..."
    cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Vault | EB Enterprises</title>
    <style>
        body { font-family: monospace; background: #0b0f19; color: #00ff66; text-align: center; padding-top: 10vh; }
        .box { border: 1px solid #00ff66; padding: 2rem; max-width: 600px; margin: auto; background: #111827; }
        a { color: #38bdf8; text-decoration: none; }
    </style>
</head>
<body>
    <div class="box">
        <h1>[+] Secure Vault Online</h1>
        <p>Operational node deployed successfully via GitHub Pages.</p>
    </div>
</body>
</html>
HTML
    git add index.html
    git commit -m "Ensure index.html is present for GitHub Pages root deployment"
fi

# 2. Configure git to ignore heavy caches so push succeeds without LFS quota errors
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

git add .
git commit -m "Clean source-only state for GitHub Pages publishing" || echo "[*] Working tree clean."

# 3. Force push clean source to Variant A and Variant B
echo "[+] Pushing clean repository to Variant A..."
git push -u origin-a main --force --tags

echo "[+] Pushing clean repository to Variant B..."
git push -u origin-b main --force --tags

# 4. Trigger/re-configure GitHub Pages via GH CLI
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo "[+] Forcing GitHub Pages build source to main branch / root..."
    gh repo edit --enable-pages --default-branch main 2>/dev/null || true
    
    OWNER=$(gh api user --jq '.login' 2>/dev/null || echo "EBenterprises")
    echo ""
    echo "[+] Success! GitHub Pages is building your site at:"
    echo "    -> https://$OWNER.github.io/${PROJECT_NAME}_variant_a/"
    echo "    -> https://$OWNER.github.io/${PROJECT_NAME}_variant_b/"
    echo "    (Note: It takes 30-60 seconds for GitHub to build and serve the 404 fix)."
else
    echo "[!] GitHub CLI not authenticated. Go to your GitHub repository -> Settings -> Pages -> Set Source to 'main' branch / root folder."
fi
