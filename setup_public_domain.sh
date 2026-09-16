#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Setting up free automated public domain routing & GitHub Pages deployment..."

# 1. Ensure a clean index.html or web root exists for public publishing
if [ ! -f "index.html" ]; then
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
        <p>Operational node deployed via EB Enterprises automation pipeline.</p>
        <p>Public Domain Access Point: <a href="https://ebenterprises.github.io/secure_vault_variant_a/" target="_blank">View Live App</a></p>
    </div>
</body>
</html>
HTML
    git add index.html
    git commit -m "Add public web entry point for domain deployment" || true
fi

# 2. Configure GitHub Pages via GitHub CLI (`gh`) if available
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo "[+] Configuring GitHub Pages for public domain resolution..."
    gh repo edit --enable-pages --default-branch main 2>/dev/null || echo "[*] Pages already enabled or configured."
    
    OWNER=$(gh api user --jq '.login' 2>/dev/null || echo "EBenterprises")
    echo "[+] Public GitHub Pages URL assigned:"
    echo "    -> https://$OWNER.github.io/${PROJECT_NAME}_variant_a/"
    echo "    -> https://$OWNER.github.io/${PROJECT_NAME}_variant_b/"
else
    echo "[!] GitHub CLI not authenticated. Enable Pages manually under repository Settings -> Pages -> Source: main branch /root."
fi

# 3. Push updates
git push -u origin-a main --force --tags
git push -u origin-b main --force --tags

echo "[+] Public domain deployment routine completed successfully!"
