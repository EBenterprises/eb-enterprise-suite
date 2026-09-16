#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Root Server Mongoose & Port Fix Utility
# ==============================================================================
set -e

if [ -f "server.js" ]; then
    node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Fix mongoose.connect where URI might be undefined or use process.env variables directly
        code = code.replace(
            /mongoose\.connect\s*\(([^)]*)\)/g,
            "mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI || \"mongodb://localhost:27017/eb_sales_root\")"
        );

        fs.writeFileSync("server.js", code, "utf8");
    '
    echo "    -> Patched root server.js Mongoose connection."
fi

echo "[+] Starting root server with assigned port..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" nohup node server.js > server.log 2>&1 &
echo "[+] Root server started on port 5000."
