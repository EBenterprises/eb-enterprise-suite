#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Add 28g Preset Across All Instances
# ==============================================================================
set -e

echo "[+] Terminating active node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
i=0

for dir in instances/v*; do
    if [ -d "$dir" ]; then
        port="${PORTS[$i]}"
        
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
                body { font-family: system-ui, -apple-system, sans-serif; background: #0b0f19; color: #f1f5f9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                .card { background: #131c2e; padding: 40px; border-radius: 16px; width: 400px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #1e293b; }
                h1 { color: #38bdf8; font-size: 24px; margin-bottom: 8px; text-align: center; }
                .subtitle { color: #94a3b8; font-size: 14px; text-align: center; margin-bottom: 24px; }
                .preset-group { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 20px; }
                button { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 10px; border-radius: 8px; cursor: pointer; font-weight: 600; transition: all 0.2s; }
                button:hover { background: #0284c7; border-color: #38bdf8; }
                input { width: 100%; padding: 12px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 8px; box-sizing: border-box; margin-bottom: 16px; font-size: 16px; }
                .status { margin-top: 15px; font-size: 13px; color: #34d399; text-align: center; font-weight: 500; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>Sales & Payments Tracker</h1>
                <div class="subtitle">Environment: $dir | Port: $port</div>
                
                <div class="preset-group">
                    <button onclick="setWeight(3.5)">3.5g</button>
                    <button onclick="setWeight(7)">7g</button>
                    <button onclick="setWeight(14)">14g</button>
                    <button onclick="setWeight(28)" style="grid-column: span 3; background: #0369a1; border-color: #38bdf8;">28g (1 oz) Preset</button>
                </div>

                <label style="font-size: 12px; color: #94a3b8; display: block; margin-bottom: 6px;">Target Weight (grams)</label>
                <input type="number" id="weightInput" placeholder="Enter weight..." oninput="calculate(this.value)">

                <div id="output" style="background: #0b0f19; padding: 12px; border-radius: 8px; border: 1px solid #1e293b; font-family: monospace; font-size: 14px;">
                    Calculated Rate: $0.00
                </div>

                <div class="status">● Executive Spectrum Live & Synchronized</div>
            </div>

            <script>
                function setWeight(val) {
                    document.getElementById('weightInput').value = val;
                    calculate(val);
                }
                function calculate(val) {
                    const w = parseFloat(val) || 0;
                    // Recalibration scale mapping
                    let rate = 0;
                    if (w === 3.5) rate = 45;
                    else if (w === 7) rate = 80;
                    else if (w === 14) rate = 140; // Calibrated above 100
                    else if (w === 28) rate = 250; // Standardized oz tier
                    else rate = w * 12;
                    
                    document.getElementById('output').innerText = 'Calculated Rate: $' + rate.toFixed(2) + ' (' + w + 'g)';
                }
            </script>
        </body>
        </html>
    \`);
});

app.listen(port, '0.0.0.0', () => {
    console.log(\`Server running at http://0.0.0.0:\${port}\`);
});
EJS

        mkdir -p "$dir/public"
        cd "$dir"
        nohup node server.js > server.log 2>&1 &
        echo "    -> Updated & Deployed $dir on port $port with 28g preset"
        cd - > /dev/null
        i=$((i+1))
    fi
done

sleep 2
echo "[+] All instances successfully redeployed with the 28g preset integration."
