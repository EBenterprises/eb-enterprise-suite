import os
import json
from flask import Flask, render_template_string, request, jsonify, redirect, url_for

app = Flask(__name__)

DATA_FILE = os.path.join(os.path.dirname(__file__), 'transactions.json')
PROFILES_FILE = os.path.join(os.path.dirname(__file__), 'profiles.json')
EXPENSES_FILE = os.path.join(os.path.dirname(__file__), 'expenses.json')

# Ensure data files exist
if not os.path.exists(DATA_FILE):
    with open(DATA_FILE, 'w') as f:
        json.dump([
            { "id": 1, "timestamp": 1759291860000, "date": "2026-09-30 05:11", "customer": "Alice", "landmark": "Downtown", "gps": "49.8880, -119.4960", "item": "28g Preset", "amount": 250, "cashCollected": 250, "balance": 0, "status": "Paid" }
        ], f, indent=2)

if not os.path.exists(PROFILES_FILE):
    with open(PROFILES_FILE, 'w') as f:
        json.dump({
            "Alice": { "phone": "555-0192", "notes": "VIP Client - Cash on delivery preferred" }
        }, f, indent=2)

if not os.path.exists(EXPENSES_FILE):
    with open(EXPENSES_FILE, 'w') as f:
        json.dump([
            { "id": 1, "timestamp": 1759291860000, "date": "2026-09-30", "category": "Packaging", "amount": 15.00, "notes": "Ziploc bags & scales" }
        ], f, indent=2)

def get_transactions():
    try:
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    except:
        return []

def save_transactions(txs):
    with open(DATA_FILE, 'w') as f:
        json.dump(txs, f, indent=2)

def get_profiles():
    try:
        with open(PROFILES_FILE, 'r') as f:
            return json.load(f)
    except:
        return {}

def save_profiles(profiles):
    with open(PROFILES_FILE, 'w') as f:
        json.dump(profiles, f, indent=2)

def get_expenses():
    try:
        with open(EXPENSES_FILE, 'r') as f:
            return json.load(f)
    except:
        return []

def save_expenses(expenses):
    with open(EXPENSES_FILE, 'w') as f:
        json.dump(expenses, f, indent=2)

@app.route('/api/data')
def api_data():
    return jsonify({
        "transactions": get_transactions(),
        "profiles": get_profiles(),
        "expenses": get_expenses()
    })

@app.route('/api/action', methods=['POST'])
def api_action():
    data = request.get_json() or {}
    action = data.get('action')
    payload = data.get('payload', {})
    
    txs = get_transactions()
    
    if action == 'add_sale':
        custom_ts = int(payload.get('customTimestamp')) if payload.get('customTimestamp') else 1759291860000 # Fallback or current
        # In flask/python backend we can use time or payload timestamp
        import time
        ts = int(time.time() * 1000)
        new_tx = {
            "id": ts,
            "timestamp": ts,
            "date": "2026-09-30 05:11",
            "customer": payload.get('customer', 'Guest'),
            "landmark": payload.get('landmark', ''),
            "gps": payload.get('gps', 'No GPS'),
            "item": payload.get('item', 'Unit'),
            "amount": float(payload.get('amount', 0)),
            "cashCollected": float(payload.get('cashCollected', 0)),
            "balance": 0,
            "status": "Pending"
        }
        txs.append(new_tx)
        # Recalculate balances
        txs.sort(key=lambda x: x['timestamp'])
        bals = {}
        for t in txs:
            c = t['customer']
            if c not in bals:
                bals[c] = 0.0
            bals[c] = max(0.0, bals[c] + t['amount'] - t['cashCollected'])
            t['balance'] = bals[c]
            t['status'] = 'Paid' if t['balance'] == 0 else 'Balance'
        txs.sort(key=lambda x: x['timestamp'], reverse=True)
        save_transactions(txs)
        return jsonify({"success": True, "timestamp": ts})

    elif action == 'delete_tx':
        tx_id = payload.get('id')
        txs = [t for t in txs if t['id'] != tx_id]
        save_transactions(txs)
        return jsonify({"success": True})

    return jsonify({"success": False, "error": "Unknown action"})

@app.route('/')
def index():
    return render_template_string("""<!DOCTYPE html>
<html>
<head>
    <title>Enterprise P2P Master Suite - Flask Edition</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <style>
        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #0b0f19; color: #f1f5f9; margin: 0; padding: 10px; }
        .card { background: #131c2e; padding: 14px; border-radius: 12px; max-width: 440px; margin: 0 auto; border: 1px solid #1e293b; }
        h2 { color: #38bdf8; margin: 0 0 4px 0; text-align: center; font-size: 18px; }
        .sub { color: #94a3b8; font-size: 11px; text-align: center; margin-bottom: 12px; }
        input, select { width: 100%; padding: 12px; background: #0b0f19; border: 1px solid #334155; color: #fff; border-radius: 8px; margin-bottom: 8px; font-size: 14px; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 14px; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 14px; margin-top: 4px; }
        .ledger-box { background: #0b0f19; border: 1px solid #1e293b; border-radius: 8px; padding: 8px; max-height: 300px; overflow-y: auto; font-family: monospace; font-size: 11px; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Enterprise P2P Master Suite (Flask)</h2>
        <div class="sub">Python Full-Stack Runtime Active</div>
        
        <label>Customer Name</label>
        <input type="text" id="custInput" placeholder="Enter name...">
        
        <label>Amount ($)</label>
        <input type="number" id="amountInput" placeholder="0.00">
        
        <label>Cash Collected ($)</label>
        <input type="number" id="cashInput" value="0">
        
        <button class="action-btn" id="saveBtn">Record Sale</button>
        
        <div style="font-weight:bold; color:#38bdf8; margin: 12px 0 6px 0; font-size:12px;">Transaction History</div>
        <div id="historyList" class="ledger-box">Loading...</div>
    </div>

<script>
async function loadData() {
    const res = await fetch('/api/data');
    const data = await res.json();
    const hist = document.getElementById('historyList');
    if(!data.transactions || data.transactions.length === 0) {
        hist.innerHTML = 'No transactions.';
    } else {
        hist.innerHTML = data.transactions.map(t => 
            '<div style="padding:4px 0; border-bottom:1px solid #1e293b;"><b>' + t.customer + '</b>: $' + t.amount + ' (Bal: $' + t.balance + ')</div>'
        ).join('');
    }
}

document.getElementById('saveBtn').onclick = async function() {
    const customer = document.getElementById('custInput').value.trim();
    const amount = document.getElementById('amountInput').value;
    const cashCollected = document.getElementById('cashInput').value;
    
    if(!customer || !amount) { alert('Fill fields'); return; }
    
    await fetch('/api/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'add_sale', payload: { customer, amount, cashCollected } })
    });
    document.getElementById('custInput').value = '';
    document.getElementById('amountInput').value = '';
    alert('Saved!');
    loadData();
};

loadData();
</script>
</body>
</html>""")

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
