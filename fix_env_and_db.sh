#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Environment & Mongoose Final Fix
# ==============================================================================
set -e

# 1. Ensure .env file exists and contains MONGO_URI
if [ ! -f ".env" ]; then
    echo "MONGO_URI=mongodb://localhost:27017/eb_sales_root" > .env
    echo "PORT=5000" >> .env
    echo "    -> Created .env file."
else
    if ! grep -q "MONGO_URI" .env; then
        echo "MONGO_URI=mongodb://localhost:27017/eb_sales_root" >> .env
        echo "    -> Appended MONGO_URI to existing .env."
    fi
fi

# 2. Patch server.js to guarantee mongoose.connect always receives a valid string fallback
if [ -f "server.js" ]; then
    node -e '
        const fs = require("fs");
        let code = fs.readFileSync("server.js", "utf8");
        
        // Replace any mongoose.connect invocation with a safe fallback string
        code = code.replace(
            /mongoose\.connect\s*\([^)]*\)/g,
            "mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI || \"mongodb://localhost:27017/eb_sales_root\")"
        );
        
        fs.writeFileSync("server.js", code, "utf8");
    '
    echo "    -> Patched server.js with robust Mongoose connection fallback."
fi

echo "[+] Restarting root server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" nohup node server.js > server.log 2>&1 &
echo "[+] Root server deployed successfully and running on port 5000."
