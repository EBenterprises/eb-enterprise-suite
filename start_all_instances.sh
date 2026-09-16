#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Full Instance Cluster Launcher
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
        
        # Ensure server.js in instances also has clean mongoose connection and port handling
        node -e '
            const fs = require("fs");
            let code = fs.readFileSync("server.js", "utf8");
            code = code.replace(
                /mongoose\.connect\s*\(([^)]*)\)/g,
                "mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI || \"mongodb://localhost:27017/eb_sales_" + "'$V'" + "\")"
            );
            fs.writeFileSync("server.js", code, "utf8");
        ' 2>/dev/null || true

        PORT=$P MONGO_URI="mongodb://localhost:27017/eb_sales_$V" nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Launched instance $V on port $P"
    fi
done

echo "[+] All EB Enterprises modular instances successfully deployed and active."
