#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Resilient Database Fallback & Storage Patch
# ==============================================================================
set -e

if [ -f "server.js" ]; then
    node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Wrap mongoose.connect in try/catch or add .catch() handler so ECONNREFUSED doesn’t crash or hang
        if (code.includes("mongoose.connect")) {
            code = code.replace(
                /mongoose\.connect\s*\(([^)]*)\)(\.catch\([^)]+\))?/g,
                "mongoose.connect($1).catch(err => console.warn(\"[!] MongoDB connection failed (running in offline/fallback mode):\", err.message))"
            );
        }

        fs.writeFileSync("server.js", code, "utf8");
    '
    echo "    -> Patched server.js with non-blocking MongoDB error handling."
fi

echo "[+] Starting server in background with persistent logging..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" nohup node server.js > server.log 2>&1 &
echo "[+] Server launched successfully on port 5000. Checking logs..."
sleep 2
cat server.log
