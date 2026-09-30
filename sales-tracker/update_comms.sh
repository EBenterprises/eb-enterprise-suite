#!/bin/bash
set -e

echo "[+] Adding direct Call and SMS action routes into Customer Profiles and Balances..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

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
const PROFILES_FILE = path.join(__dirname, 'profiles.json');

if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, date: '2026-09-27', customer: 'Alice', gps: '49.8880, -119.4960', item: '28g Oz Preset', amount: 250.00, cashCollected: 250.00, balance: 0.00, status: 'Paid' },
        { id: 2, date: '2026-09-27', customer: 'Bob', gps: '49.8850, -119.4910', item: '1.75g Tier', amount: 25.00, cashCollected: 0.00, balance: 25.00, status: 'Balance Owed' }
    ], null, 2));
}

if (!fs.existsSync(PROFILES_FILE)) {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify({
        'Alice': { phone: '555-0192', notes: 'VIP Client' },
        'Bob': { phone: '555-0144', notes: 'Standard Tier' }
    }, null, 2));
}

function getProfiles() {
    try {
        return JSON.phone(fs.readFileSync(PROFILES_FILE, 'utf8')); // safe read fallback below
    } catch (e) {
        try {
            return JSON.parse(fs.readFileSync(PROFILES_FILE, 'utf8'));
        } catch (err) {
            return {};
        }
    }
}

function saveProfiles(profiles) {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify(profiles, null, 2));
}

function recalculateLedger(data) {
    data.sort((a, b) => a.id - b.id);
    const customerBalances = {};

    data.forEach(tx => {
        const cust = tx.customer || 'Guest';
        if (customerBalances[cust] === undefined) {
            customerBalances[cust] = 0;
        }
        customerBalances[cust] = Math.max(0, customerBalances[cust] + (tx.amount || 0) - (tx.cashCollected || 0));
        tx.balance = customerBalances[cust];
        tx.status = tx.balance === 0 ? 'Paid' : (tx.cashCollected > 0 ? 'Partial' : 'Balance Owed');
    });

    data.sort((a, b) => b.id - a.id);
    return data;
}

app.get('/api/transactions', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        res.json(data);
    } catch (e) {
        res.status(500).json({ error: 'Failed to read' });
    }
});

app.get('/api/customers', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const profiles = getProfiles();
        const customerMap = {};
        const sorted = [...data].sort((a, b) => a.id - b.id);

        Object.keys(profiles).forEach(name => {
            customerMap[name] = {
                customer: name,
                phone: profiles[name].phone || '',
                notes: profiles[name].notes || '',
                totalPurchased: 0,
                totalPaid: 0,
                currentBalance: 0,
                transactions: []
            };
        });

        sorted.forEach(tx => {
            const name = tx.customer || 'Guest';
            if (!customerMap[name]) {
                customerMap[name] = {
                    customer: name,
                    phone: profiles[name]?.phone || '',
                    notes: profiles[name]?.notes || '',
                    totalPurchased: 0,
                    totalPaid: 0,
                    currentBalance: 0,
                    transactions: []
                };
            }
            customerMap[name].totalPurchased += (tx.amount || 0);
            customerMap[name].totalPaid += (tx.cashCollected || 0);
            customerMap[name].transactions.unshift(tx);
        });

        const customers = Object.values(customerMap).map(c => {
            c.currentBalance = Math.max(0, c.totalPurchased - c.totalPaid);
            return c;
        });

        res.json(customers);
    } catch (e) {
        res.status(500).json({ error: 'Failed to aggregate customers' });
    }
});

app.post('/api/profiles', (req, res) => {
    try {
        const profiles = getProfiles();
        const name = (req.body.customer || '').trim();
        if (!name) return res.status(400).json({ error: 'Customer name required' });

        profiles[name] = {
            phone: (req.body.phone || '').trim(),
            notes: (req.body.notes || '').trim()
        };
        saveProfiles(profiles);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: 'Failed to save profile' });
    }
});

app.post('/api/transactions', (req, res) => {
    try {
        let data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const customer = (req.body.customer || 'Guest').trim();
        const phone = (req.body.phone || '').trim();
        const notes = (req.body.notes || '').trim();
        const gps = (req.body.gps || '').trim();
        const amount = parseFloat(req.body.amount) || 0;
        const cashCollected = parseFloat(req.body.cashCollected) || 0;

        if (phone || notes) {
            const profiles = getProfiles();
            if (!profiles[customer]) profiles[customer] = {};
            if (phone) profiles[customer].phone = phone;
            if (notes) profiles[customer].notes = notes;
            saveProfiles(profiles);
        }

        const newTx = {
            id: Date.now(),
            date: new Date().toISOString().split('T')[0],
            customer: customer,
            gps: gps,
            item: req.body.item || 'Custom Unit',
            amount: amount,
            cashCollected: cashCollected,
            balance: 0,
            status: 'Pending'
        };

        data.push(newTx);
        data = recalculateLedger(data);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true, transaction: newTx });
    } catch (e) {
        res.status(500).json({ error: 'Failed to write' });
    }
});

app.delete('/api/transactions/:id', (req, res) => {
    try {
        let data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const id = parseInt(req.params.id);
        data = data.filter(tx => tx.id !== id);
        data = recalculateLedger(data);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: 'Failed to delete' });
    }
});

app.get(/.*/, (req, res) => {
    const html = `<!DOCTYPE html>
<html>
<head>
    <title>Customer Ledger & Comms Suite</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #f1f5f9; margin: 0; padding: 10px; display: flex; justify-content: center; align-items: flex-start; min-height: 100vh; }
        .card { background: #131c2e; padding: 14px; border-radius: 14px; width: 100%; max-width: 480px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); border: 1px solid #1e293b; margin-top: 6px; }
        h1 { color: #38bdf8; font-size: 17px; margin: 0 0 2px 0; text-align: center; }
        .subtitle { color: #94a3b8; font-size: 10px; text-align: center; margin-bottom: 12px; }
        .tab-bar { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-bottom: 10px; }
        .tab { background: #1e293b; border: 1px solid #334155; color: #94a3b8; padding: 8px 2px; text-align: center; border-radius: 8px; cursor: pointer; font-size: 11px; font-weight: 600; }
        .tab.active { background: #0284c7; color: white; border-color: #38bdf8; }
        label { font-size: 11px; color: #94a3b8; display: block; margin-bottom: 3px; font-weight: 500; }
        input, select, textarea { width: 100%; padding: 11px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 8px; margin-bottom: 8px; font-size: 15px; }
        .preset-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 4px; margin-bottom: 8px; }
        button.preset-btn { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 8px 2px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; }
        button.preset-btn:hover, button.preset-btn.active { background: #0369a1; border-color: #38bdf8; color: #ffffff; }
        .cash-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-bottom: 8px; }
        button.cash-btn { background: #0f172a; color: #38bdf8; border: 1px solid #334155; padding: 7px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; }
        button.cash-btn:hover { background: #1e293b; border-color: #38bdf8; }
        .row { display: flex; gap: 8px; }
        .row > div { flex: 1; }
        .output-box { background: #0b0f19; padding: 10px; border-radius: 8px; border: 1px solid #1e293b; font-family: monospace; font-size: 12px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 13px; border-radius: 8px; font-weight: 700; cursor: pointer; font-size: 14px; margin-bottom: 12px; }
        .action-btn:hover { background: #059669; color: white; }
        .gps-btn { background: #0284c7; color: white; border: none; padding: 8px 12px; border-radius: 6px; font-size: 11px; cursor: pointer; font-weight: 600; margin-bottom: 8px; width: 100%; }
        .gps-btn:hover { background: #0369a1; }
        .comms-row { display: flex; gap: 6px; margin-top: 6px; }
        .call-btn { flex: 1; background: #047857; color: white; border: none; padding: 7px; border-radius: 6px; font-size: 11px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .call-btn:hover { background: #065f46; }
        .sms-btn { flex: 1; background: #1d4ed8; color: white; border: none; padding: 7px; border-radius: 6px; font-size: 11px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .sms-btn:hover { background: #1e40af; }
        .ledger-title { font-size: 11px; font-weight: 600; color: #38bdf8; margin-bottom: 6px; border-top: 1px solid #1e293b; padding-top: 8px; display: flex; justify-content: space-between; align-items: center; }
        .ledger-list { max-height: 260px; overflow-y: auto; font-size: 11px; font-family: monospace; background: #0b0f19; padding: 6px; border-radius: 8px; border: 1px solid #1e293b; }
        .ledger-item { display: flex; justify-content: space-between; padding: 6px 4px; border-bottom: 1px solid #1e293b; align-items: center; }
        .status { font-size: 10px; color: #34d399; text-align: center; font-weight: 500; margin-top: 8px; }
        .del-btn { background: #7f1d1d; color: #fca5a5; border: none; padding: 3px 6px; border-radius: 4px; font-size: 10px; cursor: pointer; font-weight: bold; }
        .del-btn:hover { background: #991b1b; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Customer Account Ledger</h1>
        <div class="subtitle">Direct Call & SMS Integration Enabled</div>
        
        <div class="tab-bar">
            <div id="tabNew" class="tab active" onclick="switchTab('new')">New Sale</div>
            <div id="tabCust" class="tab" onclick="switchTab('cust')">Profiles</div>
            <div id="tabBals" class="tab" onclick="switchTab('bals')">Balances</div>
            <div id="tabHist" class="tab" onclick="switchTab('hist')">History</div>
        </div>

        <div id="viewNew">
            <label>Customer Name</label>
            <input type="text" id="customerInput" placeholder="Enter customer name..." list="customerListOptions" oninput="onCustomerInput(this.value)">
            <datalist id="customerListOptions"></datalist>

            <div id="existingBalNotice" style="display:none; font-size: 11px; background: #78350f; color: #fde68a; padding: 6px; border-radius: 6px; margin-bottom: 8px; font-weight: bold;"></div>

            <div class="row">
                <div>
                    <label>Phone Number</label>
                    <input type="tel" id="phoneInput" placeholder="555-0192">
                </div>
                <div>
                    <label>GPS Location</label>
                    <input type="text" id="gpsInput" placeholder="Lat, Lng">
                </div>
            </div>
            <button class="gps-btn" onclick="captureGPS()">📍 Tag Current GPS Location</button>

            <label>Quick Weight Presets</label>
            <div class="preset-grid">
                <button class="preset-btn active" onclick="setPreset(1.75, 25, this)">1.75g</button>
                <button class="preset-btn" onclick="setPreset(3.5, 45, this)">3.5g</button>
                <button class="preset-btn" onclick="setPreset(7, 80, this)">7g</button>
                <button class="preset-btn" onclick="setPreset(14, 140, this)">14g</button>
                <button class="preset-btn" onclick="setPreset(28, 250, this)">28g</button>
            </div>

            <div class="row">
                <div>
                    <label>Weight (g)</label>
                    <input type="number" id="weightInput" placeholder="Grams" value="1.75" oninput="calculate()">
                </div>
                <div>
                    <label>Amount ($)</label>
                    <input type="number" id="amountInput" placeholder="Total $" value="25" oninput="calculate()">
                </div>
            </div>

            <label>Quick Cash Presets</label>
            <div class="cash-grid">
                <button class="cash-btn" onclick="setCash(0)">$0 (Credit)</button>
                <button class="cash-btn" onclick="setCash(25)">$25</button>
                <button class="cash-btn" onclick="setCash(50)">$50</button>
                <button class="cash-btn" onclick="setCashExact()">Exact</button>
            </div>

            <label>Cash Collected ($)</label>
            <input type="number" id="cashInput" placeholder="Cash paid now..." value="0" oninput="calculate()">

            <div class="output-box">
                <span id="outputSummary">1.75g | Total: $25.00</span>
                <span id="outputBal" style="color: #f87171;">New Bal: $25.00</span>
            </div>

            <button class="action-btn" onclick="recordTransaction()">Record Sale & Update</button>
        </div>

        <div id="viewCust" style="display: none;">
            <input type="text" id="searchProfileInput" placeholder="Search customer profiles..." oninput="filterProfiles(this.value)">
            <div class="ledger-title"><span>Customer Directory & Profiles</span></div>
            <div id="profilesList" class="ledger-list">Loading...</div>
        </div>

        <div id="viewBals" style="display: none;">
            <input type="text" id="searchBalsInput" placeholder="Filter balances..." oninput="filterBalances(this.value)">
            <div class="ledger-title"><span>Customer Outstanding Balances</span></div>
            <div id="balancesList" class="ledger-list">Loading...</div>
        </div>

        <div id="viewHist" style="display: none;">
            <div class="ledger-title"><span>Global Transaction Ledger (GPS Tagged)</span></div>
            <div id="globalLedgerList" class="ledger-list">Loading...</div>
        </div>

        <div class="status">● Call & SMS Routing Active</div>
    </div>

    <script>
        let allCustomersData = [];
        let globalTxData = [];

        async function switchTab(tab) {
            ['new', 'cust', 'bals', 'hist'].forEach(t => {
                document.getElementById('tab' + t.charAt(0).toUpperCase() + t.slice(1)).classList.remove('active');
                document.getElementById('view' + t.charAt(0).toUpperCase() + t.slice(1)).style.display = 'none';
            });
            document.getElementById('tab' + tab.charAt(0).toUpperCase() + tab.slice(1)).classList.add('active');
            document.getElementById('view' + tab.charAt(0).toUpperCase() + tab.slice(1)).style.display = 'block';

            await loadData();

            if (tab === 'cust') {
                renderProfilesList(allCustomersData);
            } else if (tab === 'bals') {
                renderBalancesList(allCustomersData);
            } else if (tab === 'hist') {
                renderGlobalHistory();
            }
        }

        function captureGPS() {
            if (!navigator.geolocation) {
                alert('Geolocation is not supported by your browser');
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const lat = position.coords.latitude.toFixed(4);
                    const lng = position.coords.longitude.toFixed(4);
                    document.getElementById('gpsInput').value = lat + ', ' + lng;
                },
                (error) => {
                    alert('Unable to retrieve location: ' + error.message);
                },
                { enableHighAccuracy: true }
            );
        }

        function setPreset(weight, price, btn) {
            document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById('weightInput').value = weight;
            document.getElementById('amountInput').value = price;
            calculate();
        }

        function setCash(val) {
            document.getElementById('cashInput').value = val;
            calculate();
        }

        function setCashExact() {
            const amount = document.getElementById('amountInput').value;
            document.getElementById('cashInput').value = amount;
            calculate();
        }

        function calculate() {
            const weight = parseFloat(document.getElementById('weightInput').value) || 0;
            const amount = parseFloat(document.getElementById('amountInput').value) || 0;
            const cash = parseFloat(document.getElementById('cashInput').value) || 0;

            const custName = document.getElementById('customerInput').value.trim();
            let existingBal = 0;
            const found = allCustomersData.find(c => c.customer.toLowerCase() === custName.toLowerCase());
            if (found) existingBal = found.currentBalance;

            const newTotalBalance = Math.max(0, existingBal + amount - cash);

            document.getElementById('outputSummary').innerText = (weight > 0 ? weight + 'g' : 'Custom') + ' | Total: $' + amount.toFixed(2);
            document.getElementById('outputBal').innerText = 'New Bal: $' + newTotalBalance.toFixed(2);
            document.getElementById('outputBal').style.color = newTotalBalance > 0 ? '#f87171' : '#34d399';
        }

        function onCustomerInput(name) {
            const notice = document.getElementById('existingBalNotice');
            const found = allCustomersData.find(c => c.customer.toLowerCase() === name.trim().toLowerCase());
            if (found) {
                if (found.phone) {
                    document.getElementById('phoneInput').value = found.phone;
                }
                if (found.currentBalance > 0) {
                    notice.style.display = 'block';
                    notice.innerText = '⚠️ Existing Balance for ' + found.customer + ': $' + found.currentBalance.toFixed(2);
                } else {
                    notice.style.display = 'none';
                }
            } else {
                notice.style.display = 'none';
            }
            calculate();
        }

        async function loadData() {
            try {
                const resCust = await fetch('/api/customers');
                allCustomersData = await resCust.json();

                const resTx = await fetch('/api/transactions');
                globalTxData = await resTx.json();

                const uniqueNames = allCustomersData.map(c => c.customer);
                document.getElementById('customerListOptions').innerHTML = uniqueNames.map(n => '<option value="' + n + '">').join('');
            } catch (e) {
                console.error(e);
            }
        }

        function renderProfilesList(data) {
            document.getElementById('profilesList').innerHTML = data.map(c => {
                const phoneClean = c.phone || '';
                const smsBody = encodeURIComponent('Hi ' + c.customer + ', following up regarding your account balance.');
                return '<div style="padding: 10px; border-bottom: 1px solid #1e293b; background: #0b0f19; border-radius: 6px; margin-bottom: 6px;">' +
                    '<div style="display: flex; justify-content: space-between; font-weight: bold; color: #38bdf8; font-size: 13px;">' +
                        '<span>' + c.customer + '</span>' +
                        '<span style="color: ' + (c.currentBalance > 0 ? '#f87171' : '#34d399') + ';">Bal: $' + c.currentBalance.toFixed(2) + '</span>' +
                    '</div>' +
                    '<div style="margin-top: 6px;">' +
                        '<label style="font-size:10px;">Phone Number</label>' +
                        '<input type="tel" id="phone_edit_' + btoa(c.customer) + '" value="' + phoneClean + '" placeholder="Add phone..." style="margin-bottom:4px; padding:6px; font-size:12px;">' +
                        (phoneClean ? '<div class="comms-row"><a class="call-btn" href="tel:' + phoneClean + '">📞 Call</a><a class="sms-btn" href="sms:' + phoneClean + '?body=' + smsBody + '">💬 Message SMS</a></div>' : '') +
                        '<label style="font-size:10px; margin-top: 6px;">Notes / Preferences</label>' +
                        '<input type="text" id="notes_edit_' + btoa(c.customer) + '" value="' + (c.notes || '') + '" placeholder="Add notes..." style="margin-bottom:6px; padding:6px; font-size:12px;">' +
                        '<button class="gps-btn" style="padding:6px; font-size:10px; margin-bottom:0;" onclick="saveCustomerProfile(\'' + c.customer.replace(/'/g, "\\'") + '\')">Save Profile</button>' +
                    '</div>' +
                '</div>';
            }).join('');
        }

        async function saveCustomerProfile(name) {
            const phoneId = 'phone_edit_' + btoa(name);
            const notesId = 'notes_edit_' + btoa(name);
            const phone = document.getElementById(phoneId).value.trim();
            const notes = document.getElementById(notesId).value.trim();

            const res = await fetch('/api/profiles', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ customer: name, phone: phone, notes: notes })
            });
            const result = await res.json();
            if (result.success) {
                alert('Profile updated for ' + name);
                await loadData();
                renderProfilesList(allCustomersData);
            }
        }

        function filterProfiles(query) {
            const filtered = allCustomersData.filter(c => c.customer.toLowerCase().includes(query.toLowerCase()) || (c.phone && c.phone.includes(query)) || (c.notes && c.notes.toLowerCase().includes(query.toLowerCase())));
            renderProfilesList(filtered);
        }

        function renderBalancesList(data) {
            document.getElementById('balancesList').innerHTML = data.map(c => {
                const phoneClean = c.phone || '';
                const smsBody = encodeURIComponent('Hi ' + c.customer + ', checking in regarding your balance of $' + c.currentBalance.toFixed(2));
                return '<div style="padding: 8px 0; border-bottom: 1px solid #1e293b;">' +
                    '<div style="display: flex; justify-content: space-between; font-weight: bold; color: #38bdf8; font-size: 12px;">' +
                        '<span>' + c.customer + ' ' + (phoneClean ? '<span style="color:#94a3b8; font-weight:normal;">(' + phoneClean + ')</span>' : '') + '</span>' +
                        '<span style="color: ' + (c.currentBalance > 0 ? '#f87171' : '#34d399') + ';">Bal: $' + c.currentBalance.toFixed(2) + '</span>' +
                    '</div>' +
                    (phoneClean ? '<div class="comms-row" style="margin: 4px 0;"><a class="call-btn" href="tel:' + phoneClean + '">📞 Call</a><a class="sms-btn" href="sms:' + phoneClean + '?body=' + smsBody + '">💬 Message SMS</a></div>' : '') +
                    '<div style="color: #94a3b8; font-size: 10px; margin-top: 2px;">Purchased: $' + c.totalPurchased.toFixed(2) + ' | Paid: $' + c.totalPaid.toFixed(2) + (c.notes ? ' | Notes: ' + c.notes : '') + '</div>' +
                    '<div style="margin-top: 6px; font-size: 10px; background: #0b0f19; padding: 6px; border-radius: 4px;">' +
                        c.transactions.map(t => '<div>' + t.date + ': ' + t.item + ' (Amt: $' + t.amount + ', Cash: $' + t.cashCollected + ', Bal: $' + t.balance + ')' + (t.gps ? '<br>📍 <span style="color: #38bdf8;">' + t.gps + '</span>' : '') + '</div>').join('') +
                    '</div>' +
                '</div>';
            }).join('');
        }

        function filterBalances(query) {
            const filtered = allCustomersData.filter(c => c.customer.toLowerCase().includes(query.toLowerCase()) || (c.phone && c.phone.includes(query)));
            renderBalancesList(filtered);
        }

        function renderGlobalHistory() {
            document.getElementById('globalLedgerList').innerHTML = globalTxData.map(tx => 
                '<div class="ledger-item">' +
                    '<div><b>' + (tx.customer || 'Guest') + '</b><br><span style="color: #94a3b8;">' + tx.date + ' - ' + tx.item + '</span>' + (tx.gps ? '<br>📍 <span style="color: #38bdf8;">' + tx.gps + '</span>' : '') + '</div>' +
                    '<div style="text-align: right;">Amt: $' + tx.amount + ' | Cash: $' + tx.cashCollected + '<br><b style="color: ' + ((tx.balance || 0) > 0 ? '#f87171' : '#34d399') + ';">Bal: $' + tx.balance + '</b></div>' +
                    '<button class="del-btn" onclick="deleteTx(' + tx.id + ')">X</button>' +
                '</div>'
            ).join('');
        }

        async function deleteTx(id) {
            if (!confirm('Delete this transaction?')) return;
            await fetch('/api/transactions/' + id, { method: 'DELETE' });
            await loadData();
            renderGlobalHistory();
        }

        async function recordTransaction() {
            const customer = document.getElementById('customerInput').value.trim();
            if (!customer) {
                alert('Please enter customer name');
                return;
            }
            const phone = document.getElementById('phoneInput').value.trim();
            const gps = document.getElementById('gpsInput').value.trim();
            const weight = parseFloat(document.getElementById('weightInput').value) || 0;
            const amount = parseFloat(document.getElementById('amountInput').value) || 0;
            const cashCollected = parseFloat(document.getElementById('cashInput').value) || 0;

            if (amount <= 0) {
                alert('Please enter a valid amount');
                return;
            }

            try {
                const res = await fetch('/api/transactions', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        customer: customer,
                        phone: phone,
                        gps: gps,
                        item: (weight > 0 ? weight + 'g Unit' : 'Custom Unit'), 
                        amount: amount,
                        cashCollected: cashCollected
                    })
                });
                const result = await res.json();
                if (result.success) {
                    document.getElementById('customerInput').value = '';
                    document.getElementById('phoneInput').value = '';
                    document.getElementById('gpsInput').value = '';
                    document.getElementById('cashInput').value = '0';
                    document.getElementById('existingBalNotice').style.display = 'none';
                    switchTab('bals');
                }
            } catch (e) {
                alert('Error recording transaction');
            }
        }

        loadData();
    </script>
</body>
</html>`;
    res.send(html);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log("Server running on port " + PORT);
});
EJS

    PORT="$p" nohup node server.js > server.log 2>&1 &
    echo "    -> Launched $v on port$p"
    cd - > /dev/null
done

sleep 2
echo "[+] Verifying cluster status..."
for port in "${PORTS[@]}"; do
    echo -n "Port $port: "
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port | grep -q "200"; then
        echo "🟢 ACTIVE (HTTP 200)"
    else
        echo "🔴 OFFLINE"
    fi
done
