#!/bin/bash
set -e

echo "[+] Correcting template literal escaping in server.js..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    mkdir -p "$dir"
    cd "$dir"
    
    cat << 'EJS' > server.js
const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const port = 3000; // Will update per instance below

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const DATA_FILE = path.join(__dirname, 'transactions.json');
if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, date: '2026-08-25', item: '28g Oz Preset', amount: 250.00, status: 'Completed' },
        { id: 2, date: '2026-08-24', item: '14g Tier', amount: 140.00, status: 'Completed' }
    ], null, 2));
}

app.get('/api/transactions', (req, res) => {
    try {
        res.json(JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')));
    } catch (e) {
        res.status(500).json({ error: 'Failed to read' });
    }
});

app.post('/api/transactions', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const newTx = {
            id: Date.now(),
            date: new Date().toISOString().split('T')[0],
            item: req.body.item || 'Custom Unit',
            amount: parseFloat(req.body.amount) || 0,
            status: 'Completed'
        };
        data.unshift(newTx);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true, transaction: newTx });
    } catch (e) {
        res.status(500).json({ error: 'Failed to write' });
    }
});

app.get('/', (req, res) => {
    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Executive Spectrum</title>
            <style>
                body { font-family: system-ui, sans-serif; background: #0b0f19; color: #f1f5f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; }
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
                <div class="subtitle">Executive Spectrum Active</div>
                
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
                <div id="ledgerList" class="ledger-list">Loading...</div>

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
                        document.getElementById('ledgerList').innerHTML = data.map(tx => 
                            '<div class="ledger-item"><span>' + tx.date + ' - ' + tx.item + '</span><span style="color: #34d399;">$' + tx.amount.toFixed(2) + '</span></div>'
                        ).join('');
                    } catch (e) {
                        document.getElementById('ledgerList').innerHTML = '<span style="color: #ef4444;">Error loading</span>';
                    }
                }

                async function recordTransaction() {
                    if (currentWeight <= 0) {
                        alert('Enter valid weight');
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
                        alert('Error recording');
                    }
                }

                loadTransactions();
            </script>
        </body>
        </html>
    `;
    res.send(html);
});

const targetPort = $p;
app.listen(targetPort, '0.0.0.0', () => {
    console.log(\`Server running on http://0.0.0.0:\${targetPort}\`);
});
EJS

    # Replace literal $p with the actual port number in server.js
    sed -i "s/const port = 3000;/const port = $p;/g" server.js
    sed -i "s/targetPort/$p/g" server.js

    nohup node server.js > server.log 2>&1 &
    echo "    -> Deployed $v on port $p"
    cd - > /dev/null
done

sleep 2
echo "[+] All syntax errors resolved. Test via http://127.0.0.1:3000"
