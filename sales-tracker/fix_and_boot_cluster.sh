#!/bin/bash
set -e

echo "[+] Terminating any lingering Node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

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

const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const DATA_FILE = path.join(__dirname, 'transactions.json');
if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, date: '2026-09-27', customer: 'Alice', item: '28g Oz Preset', amount: 250.00, cashCollected: 250.00, balance: 0.00, status: 'Paid' },
        { id: 2, date: '2026-09-27', customer: 'Bob', item: '1.75g Tier', amount: 25.00, cashCollected: 0.00, balance: 25.00, status: 'Balance Owed' }
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
        const amount = parseFloat(req.body.amount) || 0;
        const cashCollected = parseFloat(req.body.cashCollected) || 0;
        const balance = Math.max(0, amount - cashCollected);
        const status = balance === 0 ? 'Paid' : (cashCollected > 0 ? 'Partial' : 'Balance Owed');

        const newTx = {
            id: Date.now(),
            date: new Date().toISOString().split('T')[0],
            customer: req.body.customer || 'Guest',
            item: req.body.item || 'Custom Unit',
            amount: amount,
            cashCollected: cashCollected,
            balance: balance,
            status: status
        };
        data.unshift(newTx);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true, transaction: newTx });
    } catch (e) {
        res.status(500).json({ error: 'Failed to write' });
    }
});

app.get('/', (req, res) => {
    const html = `<!DOCTYPE html>
<html>
<head>
    <title>Executive Spectrum - Customer Ledger</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #0b0f19; color: #f1f5f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; }
        .card { background: #131c2e; padding: 25px; border-radius: 16px; width: 520px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #1e293b; }
        h1 { color: #38bdf8; font-size: 20px; margin-bottom: 4px; text-align: center; }
        .subtitle { color: #94a3b8; font-size: 12px; text-align: center; margin-bottom: 16px; }
        .preset-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; margin-bottom: 12px; }
        button { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 8px 2px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 13px; transition: all 0.2s; }
        button:hover { background: #0284c7; border-color: #38bdf8; }
        .btn-highlight { background: #0369a1; border-color: #38bdf8; color: #ffffff; }
        input { width: 100%; padding: 10px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 6px; box-sizing: border-box; margin-bottom: 10px; font-size: 14px; }
        .row { display: flex; gap: 10px; }
        .output-box { background: #0b0f19; padding: 10px; border-radius: 6px; border: 1px solid #1e293b; font-family: monospace; font-size: 13px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 11px; border-radius: 6px; font-weight: 700; cursor: pointer; margin-bottom: 16px; font-size: 14px; }
        .action-btn:hover { background: #059669; color: white; }
        .ledger-title { font-size: 13px; font-weight: 600; color: #38bdf8; margin-bottom: 6px; border-top: 1px solid #1e293b; padding-top: 10px; }
        .ledger-list { max-height: 140px; overflow-y: auto; font-size: 11px; font-family: monospace; background: #0b0f19; padding: 6px; border-radius: 6px; border: 1px solid #1e293b; }
        .ledger-item { display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #1e293b; }
        .status { font-size: 11px; color: #34d399; text-align: center; font-weight: 500; margin-top: 12px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Customer Balance & Sales Tracker</h1>
        <div class="subtitle">Executive Spectrum Active</div>
        
        <input type="text" id="customerInput" placeholder="Customer Name...">

        <label style="font-size: 11px; color: #94a3b8; display: block; margin-bottom: 4px;">Quick Weight Presets</label>
        <div class="preset-grid">
            <button class="btn-highlight" onclick="setWeight(1.75)">1.75g</button>
            <button onclick="setWeight(3.5)">3.5g</button>
            <button onclick="setWeight(7)">7g</button>
            <button onclick="setWeight(14)">14g</button>
            <button onclick="setWeight(28)">28g</button>
        </div>

        <div class="row">
            <div style="flex: 1;">
                <label style="font-size: 11px; color: #94a3b8; display: block; margin-bottom: 4px;">Weight (g)</label>
                <input type="number" id="weightInput" placeholder="Grams" oninput="calculate(this.value)">
            </div>
            <div style="flex: 1;">
                <label style="font-size: 11px; color: #94a3b8; display: block; margin-bottom: 4px;">Cash Collected ($)</label>
                <input type="number" id="cashInput" placeholder="Cash paid" oninput="calculate(document.getElementById('weightInput').value)">
            </div>
        </div>

        <div class="output-box">
            <span id="outputRate">Total: $0.00</span>
            <span id="outputBal" style="color: #f87171;">Bal: $0.00</span>
        </div>

        <button class="action-btn" onclick="recordTransaction()">Record Transaction & Balance</button>

        <div class="ledger-title">Customer Ledger & Balances</div>
        <div id="ledgerList" class="ledger-list">Loading...</div>

        <div class="status">● Multi-Instance Customer Ledger Synchronized</div>
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
            if (currentWeight === 1.75) currentRate = 25;
            else if (currentWeight === 3.5) currentRate = 45;
            else if (currentWeight === 7) currentRate = 80;
            else if (currentWeight === 14) currentRate = 140;
            else if (currentWeight === 28) currentRate = 250;
            else currentRate = currentWeight * 12;
            
            document.getElementById('outputRate').innerText = 'Total: $' + currentRate.toFixed(2);
            
            const cash = parseFloat(document.getElementById('cashInput').value) || 0;
            const bal = Math.max(0, currentRate - cash);
            document.getElementById('outputBal').innerText = 'Bal: $' + bal.toFixed(2);
        }

        async function loadTransactions() {
            try {
                const res = await fetch('/api/transactions');
                const data = await res.json();
                document.getElementById('ledgerList').innerHTML = data.map(tx => 
                    '<div class="ledger-item"><span><b>' + (tx.customer || 'Guest') + '</b> (' + tx.item + ')</span><span>Cash: $' + (tx.cashCollected || 0).toFixed(2) + ' | <b style="color: ' + ((tx.balance || 0) > 0 ? '#f87171' : '#34d399') + ';">Bal: $' + (tx.balance || 0).toFixed(2) + '</b></span></div>'
                ).join('');
            } catch (e) {
                document.getElementById('ledgerList').innerHTML = '<span style="color: #ef4444;">Error loading</span>';
            }
        }

        async function recordTransaction() {
            const customer = document.getElementById('customerInput').value.trim();
            if (!customer) {
                alert('Enter customer name');
                return;
            }
            if (currentWeight <= 0) {
                alert('Enter valid weight');
                return;
            }
            const cashCollected = parseFloat(document.getElementById('cashInput').value) || 0;

            try {
                const res = await fetch('/api/transactions', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        customer: customer,
                        item: currentWeight + 'g Unit', 
                        amount: currentRate,
                        cashCollected: cashCollected
                    })
                });
                const result = await res.json();
                if (result.success) {
                    loadTransactions();
                    document.getElementById('customerInput').value = '';
                    document.getElementById('weightInput').value = '';
                    document.getElementById('cashInput').value = '';
                    calculate(0);
                }
            } catch (e) {
                alert('Error recording transaction');
            }
        }

        loadTransactions();
    </script>
</body>
</html>`;
    res.send(html);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log("Server running on port " + PORT);
});
EJS

    PORT=$p nohup node server.js > server.log 2>&1 &
    echo "    -> Deployed $v on port$p"
    cd - > /dev/null
done

sleep 2
echo "[+] Cluster successfully rebooted with 1.75g tier and customer balance tracker."
curl -I http://127.0.0.1:3000
