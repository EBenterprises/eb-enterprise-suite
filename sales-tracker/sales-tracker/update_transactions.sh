#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Transaction Ledger & Persistence Integration
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
const fs = require('fs');
const app = express();
const port = $port;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

const DATA_FILE = path.join(__dirname, 'transactions.json');

// Initialize dummy transactions if none exist
if (!fs.existsSync(DATA_FILE)) {
    const initialTx = [
        { id: 1, date: '2026-08-25', item: '28g Oz Preset', amount: 250.00, status: 'Completed' },
        { id: 2, date: '2026-08-24', item: '14g Tier', amount: 140.00, status: 'Completed' },
        { id: 3, date: '2026-08-22', item: '7g Preset', amount: 80.00, status: 'Completed' }
    ];
    fs.writeFileSync(DATA_FILE, JSON.stringify(initialTx, null, 2));
}

app.get('/api/transactions', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        res.json(data);
    } catch (e) {
        res.status(500).json({ error: 'Failed to load transaction ledger' });
    }
});

app.post('/api/transactions', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const newTx = {
            id: Date.now(),
            date: new Date().toISOString().split('T')[0],
            item: req.body.item || 'Custom Weight',
            amount: parseFloat(req.body.amount) || 0,
            status: 'Completed'
        };
        data.unshift(newTx);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true, transaction: newTx });
    } catch (e) {
        res.status(500).json({ error: 'Failed to save transaction' });
    }
});

app.get('/', (req, res) => {
    res.send(\`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Executive Spectrum - Instance $dir</title>
            <style>
                body { font-family: system-ui, -apple-system, sans-serif; background: #0b0f19; color: #f1f5f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; }
                .card { background: #131c2e; padding: 30px; border-radius: 16px; width: 460px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #1e293b; }
                h1 { color: #38bdf8; font-size: 22px; margin-bottom: 4px; text-align: center; }
                .subtitle { color: #94a3b8; font-size: 13px; text-align: center; margin-bottom: 20px; }
                .preset-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 16px; }
                button { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 10px 4px; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 14px; transition: all 0.2s; }
                button:hover { background: #0284c7; border-color: #38bdf8; }
                .btn-28g { background: #0369a1; border-color: #38bdf8; color: #ffffff; }
                input { width: 100%; padding: 12px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 8px; box-sizing: border-box; margin-bottom: 12px; font-size: 16px; }
                .output-box { background: #0b0f19; padding: 12px; border-radius: 8px; border: 1px solid #1e293b; font-family: monospace; font-size: 14px; margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center; }
                .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 12px; border-radius: 8px; font-weight: 700; cursor: pointer; margin-bottom: 20px; font-size: 15px; }
                .action-btn:hover { background: #059669; color: white; }
                .ledger-title { font-size: 14px; font-weight: 600; color: #38bdf8; margin-bottom: 8px; border-top: 1px solid #1e293b; padding-top: 14px; }
                .ledger-list { max-height: 150px; overflow-y: auto; font-size: 12px; font-family: monospace; background: #0b0f19; padding: 8px; border-radius: 8px; border: 1px solid #1e293b; }
                .ledger-item { display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #1e293b; }
                .status { font-size: 12px; color: #34d399; text-align: center; font-weight: 500; margin-top: 15px; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>Sales & Payments Tracker</h1>
                <div class="subtitle">Environment: $dir | Port: $port</div>
                
                <label style="font-size: 12px; color: #94a3b8; display: block; margin-bottom: 6px;">Quick Weight Presets</label>
                <div class="preset-grid">
                    <button onclick="setWeight(3.5)">3.5g</button>
                    <button onclick="setWeight(7)">7g</button>
                    <button onclick="setWeight(14)">14g</button>
                    <button class="btn-28g" onclick="setWeight(28)">28g</button>
                </div>

                <label style="font-size: 12px; color: #94a3b8; display: block; margin-bottom: 6px;">Target Weight (grams)</label>
                <input type="number" id="weightInput" placeholder="Enter weight..." oninput="calculate(this.value)">

                <div class="output-box">
                    <span id="output">Rate: $0.00</span>
                    <span id="calculatedWeight" style="color: #94a3b8;">0g</span>
                </div>

                <button class="action-btn" onclick="recordTransaction()">Record Transaction</button>

                <div class="ledger-title">Transaction Ledger</div>
                <div id="ledgerList" class="ledger-list">
                    Loading transactions...
                </div>

                <div class="status">● Executive Spectrum Synchronized</div>
            </div>

            <script>
                let currentRate = 0;
                let currentWeight = 0;

                function setWeight(val) {
                    document.getElementById('weightInput').value = val;
                    calculate(val);
                }

                function calculate(val) {
                    currentWeight = parseFloat(val) || 0;
                    if (currentWeight === 3.5) currentRate = 45;
                    else if (currentWeight === 7) currentRate = 80;
                    else if (currentWeight === 14) currentRate = 140;
                    else if (currentWeight === 28) currentRate = 250;
                    else currentRate = currentWeight * 12;
                    
                    document.getElementById('output').innerText = 'Rate: $' + currentRate.toFixed(2);
                    document.getElementById('calculatedWeight').innerText = currentWeight + 'g';
                }

                async function loadTransactions() {
                    try {
                        const res = await fetch('/api/transactions');
                        const data = await res.json();
                        const list = document.getElementById('ledgerList');
                        list.innerHTML = data.map(tx => \`
                            <div class="ledger-item">
                                <span>\${tx.date} - \${tx.item}</span>
                                <span style="color: #34d399;">$\${tx.amount.toFixed(2)}</span>
                            </div>
                        \`).join('');
                    } catch (e) {
                        document.getElementById('ledgerList').innerHTML = '<span style="color: #ef4444;">Failed to load</span>';
                    }
                }

                async function recordTransaction() {
                    if (currentWeight <= 0) {
                        alert('Please enter a valid weight.');
                        return;
                    }
                    try {
                        const res = await fetch('/api/transactions', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ item: currentWeight + 'g Unit', amount: currentRate })
                        });
                        const result = await res.json();
                        if (result.success) {
                            loadTransactions();
                            document.getElementById('weightInput').value = '';
                            calculate(0);
                        }
                    } catch (e) {
                        alert('Error recording transaction.');
                    }
                }

                loadTransactions();
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
        echo "    -> Refreshed $dir on port $port with active transaction ledger"
        cd - > /dev/null
        i=$((i+1))
    fi
done

sleep 2
echo "[+] All instances successfully updated and live with persistent transaction logging."
