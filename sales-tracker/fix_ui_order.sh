#!/bin/bash
set -e

echo "[*] Updating backend query and frontend render sorting..."

# Ensure server.js queries with ORDER BY id DESC or ORDER BY created_at DESC
if [ -f "server.js" ]; then
    node -e '
    const fs = require("fs");
    let code = fs.readFileSync("server.js", "utf8");
    // Replace SELECT statements on transactions to order descending
    code = code.replace(/SELECT\s+\*\s+FROM\s+transactions/gi, "SELECT * FROM transactions ORDER BY id DESC");
    fs.writeFileSync("server.js", code);
    console.log("[+] Updated backend query in server.js");
    '
fi

# Ensure frontend JavaScript / HTML template sorts arrays before rendering
if [ -f "server.js" ] || [ -f "public/index.html" ] || [ -f "src/App.js" ]; then
    # Add .reverse() or .sort() to transaction map/render loops if present
    node -e '
    const fs = require("fs");
    ["server.js", "src/App.js", "public/index.html"].forEach(file => {
        if (fs.existsSync(file)) {
            let content = fs.readFileSync(file, "utf8");
            // If data.map or transactions.map exists without sort/reverse, add .reverse()
            if (content.includes(".map(") && !content.includes(".reverse()") && !content.includes(".sort(")) {
                content = content.replace(/\.map\(/g, ".slice().reverse().map(");
                fs.writeFileSync(file, content);
                console.log(`[+] Added .reverse() to render loop in ${file}`);
            }
        }
    });
    '
fi

echo "[*] Restarting application server..."
pkill -f "node server.js" || true
nohup node server.js > server.log 2>&1 &
echo "[+] Application restarted successfully. Check your UI now!"
