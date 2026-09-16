#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Server Route & Static File Fallback Patch
# ==============================================================================
set -e

if [ -f "server.js" ]; then
    node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Ensure express.static is serving public/ or current directory
        if (!code.includes("express.static")) {
            // Insert static middleware before routes
            code = code.replace(
                /const app = express\(\);/,
                "const app = express();\nconst path = require(\"path\");\napp.use(express.static(path.join(__dirname, \"public\")));\napp.use(express.static(__dirname));"
            );
        }

        // Add a root GET handler if none exists so "/" returns index.html explicitly
        if (!code.includes("app.get(\"/\"")) {
            code = code.replace(
                /app\.listen\s*\(/,
                "app.get(\"/\", (req, res) => {\n    res.sendFile(path.join(__dirname, \"index.html\"));\n});\napp.listen("
            );
        }

        fs.writeFileSync("server.js", code, "utf8");
    '
    echo "    -> Patched server.js with explicit static file serving and root index fallback."
fi

echo "[+] Restarting server..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" nohup node server.js > server.log 2>&1 &
echo "[+] Server active on port 5000."
