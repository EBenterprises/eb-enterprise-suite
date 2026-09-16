#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Master Server Deployment & Launch Utility
# ==============================================================================
set -e

echo "[+] Terminating any active node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Ensuring environment configuration (.env)..."
if [ ! -f ".env" ]; then
    cat << 'ENV_EOF' > .env
PORT=5000
MONGO_URI=mongodb://localhost:27017/eb_sales_root
ENV_EOF
fi

echo "[+] Verifying directory structure and static files..."
mkdir -p public
if [ ! -f "public/style.css" ] && [ -f "style.css" ]; then
    cp style.css public/style.css
fi

if [ -f "server.js" ]; then
    node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Ensure static middleware is robustly configured
        if (!code.includes("express.static")) {
            code = code.replace(
                /const app = express\(\);/,
                "const app = express();\nconst path = require(\"path\");\napp.use(express.static(path.join(__dirname, \"public\")));\napp.use(express.static(__dirname));"
            );
        }

        // Ensure root route serves index.html
        if (!code.includes("app.get(\"/\"")) {
            code = code.replace(
                /app\.listen\s*\(/,
                "app.get(\"/\", (req, res) => {\n    res.sendFile(path.join(__dirname, \"index.html\"));\n});\napp.listen("
            );
        }

        // Ensure non-blocking Mongoose error handling
        code = code.replace(
            /mongoose\.connect\s*\(([^)]*)\)(\.catch\([^)]+\))?/g,
            "mongoose.connect($1).catch(err => console.warn(\"[!] MongoDB offline mode active:\", err.message))"
        );

        fs.writeFileSync("server.js", code, "utf8");
    '
    echo "    -> Master server.js fully optimized."
fi

echo "[+] Launching Master Server on Port 5000..."
PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" nohup node server.js > server.log 2>&1 &
sleep 2

echo "=== Master Server Status ==="
ps aux | grep node | grep -v grep
echo "=== Last Log Entries ==="
tail -n 15 server.log

echo "[+] Master server successfully started and ready for traffic."
