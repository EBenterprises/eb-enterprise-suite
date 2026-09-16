#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Mongoose Connection & Port Sync Fix
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        
        # Patch server.js to fix mongoose connection string fallback and port mapping
        node -e '
            const fs = require("fs");
            let code = fs.readFileSync("server.js", "utf8");
            
            // Fix mongoose.connect if uri is undefined
            code = code.replace(
                /mongoose\.connect\s*\(\s*process\.env\.MONGO_URI[^)]*\)/g,
                "mongoose.connect(process.env.MONGO_URI || \"mongodb://localhost:27017/eb_sales_" + "'$V'" + "\", { useNewUrlParser: true, useUnifiedTopology: true })"
            );
            
            // Also ensure generic mongoose.connect without fallback is safe
            code = code.replace(
                /mongoose\.connect\s*\(\s*process\.env\.MONGODB_URI[^)]*\)/g,
                "mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI || \"mongodb://localhost:27017/eb_sales_" + "'$V'" + "\")"
            );

            // Fix port binding to use assigned port if process.env.PORT is missing
            code = code.replace(
                /app\.listen\s*\(\s*process\.env\.PORT[^)]*\)/g,
                "app.listen(process.env.PORT || " + "$P" + ", () => console.log(\"Server running on port \" + (process.env.PORT || " + "$P" + "))"
            );

            fs.writeFileSync("server.js", code, "utf8");
        '
        
        cd - > /dev/null
        echo "    -> Patched server.js for instance $V (Port $P)"
    fi
done

echo "[+] Restarting all server instances..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        PORT=$P nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Started instance $V on port $P"
    fi
done

echo "[+] Mongoose connection string fallback and port synchronization deployed successfully."
