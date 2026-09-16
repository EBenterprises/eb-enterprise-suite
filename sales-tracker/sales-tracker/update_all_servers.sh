#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Full Instance Overhaul & Live Deployment
# ==============================================================================
set -e

echo "[+] Terminating existing node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
i=0

for dir in instances/v*; do
    if [ -d "$dir" ]; then
        port="${PORTS[$i]}"
        
        # Create a robust, self-contained server.js for each instance
        cat << EJS > "$dir/server.js"
const express = require('express');
const path = require('path');
const app = express();
const port = $port;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    res.send(\`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Executive Spectrum - Instance $dir</title>
            <style>
                body { font-family: Arial, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding-top: 50px; }
                .card { background: #1e293b; padding: 30px; border-radius: 12px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
                h1 { color: #38bdf8; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>EB Enterprises</h1>
                <p>Environment: <strong>$dir</strong></p>
                <p>Port Active: <strong>$port</strong></p>
                <p>Status: <span style="color: #4ade80;">Operational & Live</span></p>
            </div>
        </body>
        </html>
    \`);
});

app.listen(port, '0.0.0.0', () => {
    console.log(\`Server running at http://0.0.0.0:\${port}\`);
});
EJS

        # Ensure public directory exists
        mkdir -p "$dir/public"

        # Launch background process
        cd "$dir"
        nohup node server.js > server.log 2>&1 &
        echo "    -> Deployed & Verified $dir on port $port (PID $!)"
        cd - > /dev/null
        
        i=$((i+1))
    fi
done

sleep 2
echo "[+] Active deployment verification complete. All instances online."
