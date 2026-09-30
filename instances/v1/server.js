const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const DATA_FILE = path.join(__dirname, 'transactions.json');
const PROFILES_FILE = path.join(__dirname, 'profiles.json');
const SETTINGS_FILE = path.join(__dirname, 'settings.json');

if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, date: '2026-09-28 14:20', customer: 'Alice', gps: '49.8880, -119.4960', item: '28g Oz Preset', amount: 250.00, cashCollected: 250.00, balance: 0.00, status: 'Paid' },
        { id: 2, date: '2026-09-29 09:15', customer: 'Bob', gps: '49.8850, -119.4910', item: '3.5g Tier', amount: 45.00, cashCollected: 20.00, balance: 25.00, status: 'Partial' }
    ], null, 2));
}

if (!fs.existsSync(PROFILES_FILE)) {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify({
        'Alice': { phone: '555-0192', notes: 'VIP Client - Prefers evening drops' },
        'Bob': { phone: '555-0144', notes: 'Standard Tier' }
    }, null, 2));
}

if (!fs.existsSync(SETTINGS_FILE)) {
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify({
        pin: '',
        presets: [
            { weight: 1.75, price: 25 },
            { weight: 3.5, price: 45 },
            { weight: 7, price: 80 },
            { weight: 14, price: 140 },
            { weight: 28, price: 250 }
        ]
    }, null, 2));
}

function getProfiles() {
    try { return JSON.parse(fs.readFileSync(PROFILES_FILE, 'utf8')); } catch (e) { return {}; }
}
function saveProfiles(profiles) { fs.writeFileSync(PROFILES_FILE, JSON.stringify(profiles, null, 2)); }

function getSettings() {
    try { return JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf8')); } catch (e) { return { pin: '', presets: [] }; }
}
function saveSettings(settings) { fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2)); }

function recalculateLedger(data) {
    data.sort((a, b) => a.id - b.id);
    const customerBalances = {};
    data.forEach(tx => {
        const cust = tx.customer || 'Guest';
        if (customerBalances[cust] === undefined) customerBalances[cust] = 0;
        customerBalances[cust] = Math.max(0, customerBalances[cust] + (tx.amount || 0) - (tx.cashCollected || 0));
        tx.balance = customerBalances[cust];
        tx.status = tx.balance === 0 ? 'Paid' : (tx.cashCollected > 0 ? 'Partial' : 'Balance Owed');
    });
    data.sort((a, b) => b.id - a.id);
    return data;
}

app.get('/api/settings', (req, res) => {
    const s = getSettings();
    res.json({ presets: s.presets });
});

app.post('/api/settings', (req, res) => {
    try {
        const { newPin, presets } = req.body;
        const current = getSettings();
        if (newPin !== undefined) current.pin = newPin.trim();
        if (presets) current.presets = presets;
        saveSettings(current);
        res.json({ success: true, presets: current.presets });
    } catch (e) {
        res.status(500).json({ error: 'Failed to update settings' });
    }
});

app.get('/api/analytics', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        let totalRevenue = 0;
        let totalCollected = 0;
        let totalOutstanding = 0;
        let totalSalesCount = data.length;

        const customerMap = {};

        data.forEach(tx => {
            totalRevenue += (tx.amount || 0);
            totalCollected += (tx.cashCollected || 0);
            const cust = tx.customer || 'Guest';
            if (!customerMap[cust]) customerMap[cust] = 0;
            customerMap[cust] = Math.max(0, customerMap[cust] + (tx.amount || 0) - (tx.cashCollected || 0));
        });

        Object.values(customerMap).forEach(bal => { totalOutstanding += bal; });

        res.json({
            totalRevenue,
            totalCollected,
            totalOutstanding,
            totalSalesCount,
            activeCustomers: Object.keys(customerMap).length
        });
    } catch (e) {
        res.status(500).json({ error: 'Failed to compute analytics' });
    }
});

app.get('/api/export', (req, res) => {
    try {
        const data = {
            transactions: JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')),
            profiles: getProfiles(),
            settings: getSettings()
        };
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', 'attachment; filename=ledger_backup.json');
        res.send(JSON.stringify(data, null, 2));
    } catch (e) {
        res.status(500).json({ error: 'Export failed' });
    }
});

app.post('/api/import', (req, res) => {
    try {
        const backup = req.body;
        if (backup.transactions) fs.writeFileSync(DATA_FILE, JSON.stringify(backup.transactions, null, 2));
        if (backup.profiles) saveProfiles(backup.profiles);
        if (backup.settings) saveSettings(backup.settings);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: 'Import failed' });
    }
});

app.get('/api/transactions', (req, res) => {
    try { res.json(JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'))); } catch (e) { res.status(500).json({ error: 'Failed' }); }
});

app.get('/api/customers', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const profiles = getProfiles();
        const customerMap = {};
        const sorted = [...data].sort((a, b) => a.id - b.id);

        Object.keys(profiles).forEach(name => {
            customerMap[name] = { customer: name, phone: profiles[name].phone || '', notes: profiles[name].notes || '', totalPurchased: 0, totalPaid: 0, currentBalance: 0, transactions: [] };
        });

        sorted.forEach(tx => {
            const name = tx.customer || 'Guest';
            if (!customerMap[name]) {
                customerMap[name] = { customer: name, phone: profiles[name]?.phone || '', notes: profiles[name]?.notes || '', totalPurchased: 0, totalPaid: 0, currentBalance: 0, transactions: [] };
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
    } catch (e) { res.status(500).json({ error: 'Failed' }); }
});

app.post('/api/profiles', (req, res) => {
    try {
        const profiles = getProfiles();
        const name = (req.body.customer || '').trim();
        if (!name) return res.status(400).json({ error: 'Name required' });
        profiles[name] = { phone: (req.body.phone || '').trim(), notes: (req.body.notes || '').trim() };
        saveProfiles(profiles);
        res.json({ success: true });
    } catch (e) { res.status(500).json({ error: 'Failed' }); }
});

app.post('/api/transactions', (req, res) => {
    try {
        let data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const customer = (req.body.customer || 'Guest').trim();
        const gps = (req.body.gps || '').trim();
        const amount = parseFloat(req.body.amount) || 0;
        const cashCollected = parseFloat(req.body.cashCollected) || 0;

        const now = new Date();
        const dateStr = now.toISOString().split('T')[0] + ' ' + now.toTimeString().split(' ')[0].substring(0, 5);

        const newTx = { id: Date.now(), date: dateStr, customer: customer, gps: gps, item: req.body.item || 'Custom Unit', amount: amount, cashCollected: cashCollected, balance: 0, status: 'Pending' };
        data.push(newTx);
        data = recalculateLedger(data);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true, transaction: newTx });
    } catch (e) { res.status(500).json({ error: 'Failed' }); }
});

app.delete('/api/transactions/:id', (req, res) => {
    try {
        let data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        const id = parseInt(req.params.id);
        data = data.filter(tx => tx.id !== id);
        data = recalculateLedger(data);
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        res.json({ success: true });
    } catch (e) { res.status(500).json({ error: 'Failed' }); }
});

app.get(/.*/, (req, res) => {
    res.send(`<!DOCTYPE html>
<html>
<head>
    <title>Advanced Ledger & Analytics Suite</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #f1f5f9; margin: 0; padding: 8px; display: flex; justify-content: center; align-items: flex-start; min-height: 100vh; }
        .card { background: #131c2e; padding: 12px; border-radius: 14px; width: 100%; max-width: 480px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); border: 1px solid #1e293b; margin-top: 4px; }
        h1 { color: #38bdf8; font-size: 16px; margin: 0 0 2px 0; text-align: center; }
        .subtitle { color: #94a3b8; font-size: 10px; text-align: center; margin-bottom: 10px; }
        .tab-bar { display: grid; grid-template-columns: repeat(6, 1fr); gap: 2px; margin-bottom: 10px; }
        .tab { background: #1e293b; border: 1px solid #334155; color: #94a3b8; padding: 7px 1px; text-align: center; border-radius: 6px; cursor: pointer; font-size: 9px; font-weight: 600; user-select: none; }
        .tab.active { background: #0284c7; color: white; border-color: #38bdf8; }
        label { font-size: 11px; color: #94a3b8; display: block; margin-bottom: 3px; font-weight: 500; }
        input, select, textarea { width: 100%; padding: 10px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 8px; margin-bottom: 8px; font-size: 14px; }
        .preset-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 4px; margin-bottom: 8px; }
        button.preset-btn { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 8px 2px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; width: 100%; }
        button.preset-btn:hover, button.preset-btn.active { background: #0369a1; border-color: #38bdf8; color: #ffffff; }
        .cash-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-bottom: 8px; }
        button.cash-btn { background: #0f172a; color: #38bdf8; border: 1px solid #334155; padding: 7px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; width: 100%; }
        button.cash-btn:hover { background: #1e293b; border-color: #38bdf8; }
        .row { display: flex; gap: 8px; }
        .row > div { flex: 1; }
        .output-box { background: #0b0f19; padding: 10px; border-radius: 8px; border: 1px solid #1e293b; font-family: monospace; font-size: 11px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 12px; border-radius: 8px; font-weight: 700; cursor: pointer; font-size: 13px; margin-bottom: 10px; }
        .action-btn:hover { background: #059669; color: white; }
        .comms-row { display: flex; gap: 6px; margin-top: 6px; }
        .call-btn { flex: 1; background: #047857; color: white; border: none; padding: 6px; border-radius: 6px; font-size: 10px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .sms-btn { flex: 1; background: #1d4ed8; color: white; border: none; padding: 6px; border-radius: 6px; font-size: 10px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .ledger-title { font-size: 11px; font-weight: 600; color: #38bdf8; margin-bottom: 6px; border-top: 1px solid #1e293b; padding-top: 8px; display: flex; justify-content: space-between; align-items: center; }
        .ledger-list { max-height: 250px; overflow-y: auto; font-size: 11px; font-family: monospace; background: #0b0f19; padding: 6px; border-radius: 8px; border: 1px solid #1e293b; }
        .ledger-item { display: flex; justify-content: space-between; padding: 6px 4px; border-bottom: 1px solid #1e293b; align-items: center; }
        .status { font-size: 10px; color: #34d399; text-align: center; font-weight: 500; margin-top: 6px; }
        .del-btn { background: #7f1d1d; color: #fca5a5; border: none; padding: 3px 6px; border-radius: 4px; font-size: 10px; cursor: pointer; font-weight: bold; }
        .del-btn:hover { background: #991b1b; }
        .view-section { display: none; }
        .view-section.active-view { display: block; }
        .stat-card { background: #0b0f19; border: 1px solid #1e293b; padding: 10px; border-radius: 8px; margin-bottom: 8px; text-align: center; }
        .stat-val { font-size: 18px; font-weight: bold; color: #38bdf8; margin-top: 2px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Ledger & Analytics Suite</h1>
        <div class="subtitle">Secure Node Instance | POS & Tracking</div>

        <div class="tab-bar">
            <div id="tabNew" class="tab active" onclick="switchTab('new')">Sale</div>
            <div id="tabCust" class="tab" onclick="switchTab('cust')">Profiles</div>
            <div id="tabBals" class="tab" onclick="switchTab('bals')">Balances</div>
            <div id="tabHist" class="tab" onclick="switchTab('hist')">History</div>
            <div id="tabAnly" class="tab" onclick="switchTab('anly')">Analytics</div>
            <div id="tabSets" class="tab" onclick="switchTab('sets')">Config</div>
        </div>

        <div id="viewNew" class="view-section active-view">
            <label>Customer Name</label>
            <input type="text" id="customerInput" placeholder="Enter customer name..." list="customerListOptions" oninput="onCustomerInput(this.value)">
            <datalist id="customerListOptions"></datalist>

            <div id="existingBalNotice" style="display:none; font-size: 11px; background: #78350f; color: #fde68a; padding: 6px; border-radius: 6px; margin-bottom: 8px; font-weight: bold;"></div>

            <label>Quick Weight Presets</label>
            <div id="presetButtonsGrid" class="preset-grid"></div>

            <div class="row">
                <div>
                    <label>Weight (g)</label>
                    <input type="number" id="weightInput" placeholder="Grams" value="" oninput="calculate()">
                </div>
                <div>
                    <label>Amount ($)</label>
                    <input type="number" id="amountInput" placeholder="Total $" value="" oninput="calculate()">
                </div>
            </div>

            <label>Quick Cash Presets</label>
            <div class="cash-grid">
                <button class="cash-btn" onclick="setCash(0)">$0 (Credit)</button>
                <button class="cash-btn" onclick="setCash(25)">$25</button>
                <button class="cash-btn" onclick="setCash(50)">$50</button>
                <button class="cash-btn" onclick="setCashExact()">Exact</button>
            </div>

            <label>Location / Coordinates</label>
            <input type="text" id="locationInput" placeholder="Auto-detected or custom location..." style="margin-bottom: 8px;">

            <label>Cash Collected ($)</label>
            <input type="number" id="cashInput" placeholder="Cash paid now..." value="0" oninput="calculate()">

            <div class="output-box">
                <span id="outputSummary">Select preset or enter weight</span>
                <span id="outputBal" style="color: #34d399;">New Bal: $0.00</span>
            </div>

            <button class="action-btn" onclick="recordTransaction()">Record Sale & GPS</button>
        </div>

        <div id="viewCust" class="view-section">
            <input type="text" id="searchProfileInput" placeholder="Search customer profiles..." oninput="filterProfiles(this.value)">
            <div class="ledger-title"><span>Customer Directory & Profiles</span></div>
            <div id="profilesList" class="ledger-list">Loading profiles...</div>
        </div>

        <div id="viewBals" class="view-section">
            <input type="text" id="searchBalsInput" placeholder="Filter balances..." oninput="filterBalances(this.value)">
            <div class="ledger-title"><span>Customer Outstanding Balances</span></div>
            <div id="balancesList" class="ledger-list">Loading balances...</div>
        </div>

        <div id="viewHist" class="view-section">
            <div class="ledger-title"><span>Global Transaction Ledger</span></div>
            <div id="globalLedgerList" class="ledger-list">Loading history...</div>
        </div>

        <div id="viewAnly" class="view-section">
            <div class="ledger-title"><span>Business Performance & Cashflow</span></div>
            <div class="stat-card">
                <label>Total Sales Revenue</label>
                <div class="stat-val" id="statRev">$0.00</div>
            </div>
            <div class="stat-card">
                <label>Total Cash Collected</label>
                <div class="stat-val" id="statColl" style="color: #34d399;">$0.00</div>
            </div>
            <div class="stat-card">
                <label>Total Outstanding Balances</label>
                <div class="stat-val" id="statOut" style="color: #f87171;">$0.00</div>
            </div>
            <div class="row">
                <div class="stat-card">
                    <label>Total Transactions</label>
                    <div class="stat-val" id="statCount" style="font-size: 15px; color: #f1f5f9;">0</div>
                </div>
                <div class="stat-card">
                    <label>Active Customers</label>
                    <div class="stat-val" id="statCusts" style="font-size: 15px; color: #f1f5f9;">0</div>
                </div>
            </div>
        </div>

        <div id="viewSets" class="view-section">
            <div class="ledger-title"><span>Preset Configuration</span></div>
            <div id="presetConfigList" style="margin-bottom: 8px;"></div>
            <button class="action-btn" style="padding: 10px; font-size: 12px; margin-bottom: 10px;" onclick="savePresetsConfig()">Save Preset Changes</button>

            <div class="ledger-title"><span>Data Backup & Restoration</span></div>
            <div style="display: flex; gap: 6px; margin-top: 6px;">
                <button class="action-btn" style="background: #0284c7; margin-bottom: 0;" onclick="exportData()">📥 Export JSON</button>
                <label class="action-btn" style="background: #d97706; text-align: center; margin-bottom: 0; cursor: pointer;">
                    📤 Import <input type="file" id="importFile" style="display: none;" onchange="importData(event)">
                </label>
            </div>
        </div>

        <div class="status">● All Modules Online & Synchronized</div>
    </div>

    <script>
        let allCustomersData = [];
        let globalTxData = [];
        let currentGPS = '';
        let appPresets = [
            { weight: 1.75, price: 25 },
            { weight: 3.5, price: 45 },
            { weight: 7, price: 80 },
            { weight: 14, price: 140 },
            { weight: 28, price: 250 }
        ];

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (pos) => {
                    currentGPS = pos.coords.latitude.toFixed(4) + ', ' + pos.coords.longitude.toFixed(4);
                    const locEl = document.getElementById('locationInput');
                    if (locEl && !locEl.value) locEl.value = currentGPS;
                },
                (err) => {},
                { enableHighAccuracy: true, timeout: 10000 }
            );
        }

        function switchTab(tab) {
            const tabs = ['new', 'cust', 'bals', 'hist', 'anly', 'sets'];
            tabs.forEach(t => {
                const tabEl = document.getElementById('tab' + t.charAt(0).toUpperCase() + t.slice(1));
                const viewEl = document.getElementById('view' + t.charAt(0).toUpperCase() + t.slice(1));
                if (tabEl) tabEl.classList.remove('active');
                if (viewEl) viewEl.classList.remove('active-view');
            });

            const activeTabEl = document.getElementById('tab' + tab.charAt(0).toUpperCase() + tab.slice(1));
            const activeViewEl = document.getElementById('view' + tab.charAt(0).toUpperCase() + tab.slice(1));

            if (activeTabEl) activeTabEl.classList.add('active');
            if (activeViewEl) activeViewEl.classList.add('active-view');

            loadData().then(() => {
                if (tab === 'cust') renderProfilesList(allCustomersData);
                else if (tab === 'bals') renderBalancesList(allCustomersData);
                else if (tab === 'hist') renderGlobalHistory();
                else if (tab === 'anly') loadAnalytics();
                else if (tab === 'sets') renderPresetConfig();
            });
        }

        async function loadSettings() {
            try {
                const res = await fetch('/api/settings');
                const data = await res.json();
                if (data.presets && data.presets.length > 0) {
                    appPresets = data.presets;
                }
                renderPresetButtons();
            } catch (e) {
                renderPresetButtons();
            }
        }

        function renderPresetButtons() {
            const grid = document.getElementById('presetButtonsGrid');
            if (!grid) return;
            grid.innerHTML = appPresets.map(p =>
                '<button class="preset-btn" onclick="setPreset(' + p.weight + ', ' + p.price + ', this)">' + p.weight + 'g ($' + p.price + ')</button>'
            ).join('');
        }

        function renderPresetConfig() {
            const container = document.getElementById('presetConfigList');
            if (!container) return;
            container.innerHTML = appPresets.map((p, idx) =>
                '<div style="display: flex; gap: 6px; margin-bottom: 6px;">' +
                    '<input type="number" id="cfg_w_' + idx + '" value="' + p.weight + '" placeholder="Grams" style="margin-bottom:0;">' +
                    '<input type="number" id="cfg_p_' + idx + '" value="' + p.price + '" placeholder="Price $" style="margin-bottom:0;">' +
                '</div>'
            ).join('');
        }

        async function savePresetsConfig() {
            let newPresets = [];
            for (let i = 0; i < appPresets.length; i++) {
                const wInput = document.getElementById('cfg_w_' + i);
                const pInput = document.getElementById('cfg_p_' + i);
                if (wInput && pInput) {
                    newPresets.push({ weight: parseFloat(wInput.value) || 0, price: parseFloat(pInput.value) || 0 });
                }
            }

            const res = await fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ presets: newPresets })
            });
            const result = await res.json();
            if (result.success) {
                appPresets = result.presets;
                renderPresetButtons();
                alert('Presets updated successfully!');
            } else {
                alert('Failed to update presets.');
            }
        }

        async function loadAnalytics() {
            try {
                const res = await fetch('/api/analytics');
                const data = await res.json();
                document.getElementById('statRev').innerText = '$' + data.totalRevenue.toFixed(2);
                document.getElementById('statColl').innerText = '$' + data.totalCollected.toFixed(2);
                document.getElementById('statOut').innerText = '$' + data.totalOutstanding.toFixed(2);
                document.getElementById('statCount').innerText = data.totalSalesCount;
                document.getElementById('statCusts').innerText = data.activeCustomers;
            } catch (e) {}
        }

        function exportData() {
            window.location.href = '/api/export';
        }

        async function importData(event) {
            const file = event.target.files[0];
            if (!file) return;
            const reader = new FileReader();
            reader.onload = async function(e) {
                try {
                    const json = JSON.parse(e.target.result);
                    const res = await fetch('/api/import', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(json)
                    });
                    const result = await res.json();
                    if (result.success) {
                        alert('Backup successfully imported!');
                        window.location.reload();
                    }
                } catch (err) {
                    alert('Invalid JSON backup file.');
                }
            };
            reader.readAsText(file);
        }

        function setPreset(weight, price, btn) {
            document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
            if (btn) btn.classList.add('active');
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
            if (found && found.currentBalance > 0) {
                notice.style.display = 'block';
                notice.innerText = '⚠️ Existing Balance for ' + found.customer + ': $' + found.currentBalance.toFixed(2);
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
                const datalist = document.getElementById('customerListOptions');
                if (datalist) datalist.innerHTML = uniqueNames.map(n => '<option value="' + n + '">').join('');
            } catch (e) { }
        }

        function renderProfilesList(data) {
            const container = document.getElementById('profilesList');
            if (!container) return;
            container.innerHTML = data.map(c => {
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
                        '<button class="action-btn" style="padding:8px; font-size:11px; margin-bottom:0; background:#0284c7;" onclick="saveCustomerProfile(\'' + c.customer.replace(/'/g, "\\'") + '\')">Save Profile</button>' +
                    '</div>' +
                '</div>';
            }).join('');
        }

        async function saveCustomerProfile(name) {
            const phoneId = 'phone_edit_' + btoa(name);
            const notesId = 'notes_edit_' + btoa(name);
            const phoneEl = document.getElementById(phoneId);
            const notesEl = document.getElementById(notesId);
            const phone = phoneEl ? phoneEl.value.trim() : '';
            const notes = notesEl ? notesEl.value.trim() : '';

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
            const container = document.getElementById('balancesList');
            if (!container) return;
            container.innerHTML = data.map(c => {
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
                        c.transactions.map(t => '<div style="margin-bottom: 4px; border-bottom: 1px solid #1e293b; padding-bottom: 4px;">' +
                            '<b>' + t.date + '</b> - ' + t.item + ' (Amt: $' + t.amount + ', Cash: $' + t.cashCollected + ', Bal: $' + t.balance + ')' +
                            (t.gps ? '<br>📍 Location: <span style="color: #38bdf8;">' + t.gps + '</span>' : '') +
                        '</div>').join('') +
                    '</div>' +
                '</div>';
            }).join('');
        }

        function filterBalances(query) {
            const filtered = allCustomersData.filter(c => c.customer.toLowerCase().includes(query.toLowerCase()) || (c.phone && c.phone.includes(query)));
            renderBalancesList(filtered);
        }

        function renderGlobalHistory() {
            const container = document.getElementById('globalLedgerList');
            if (!container) return;
            container.innerHTML = globalTxData.map(tx =>
                '<div class="ledger-item">' +
                    '<div><b>' + (tx.customer || 'Guest') + '</b><br><span style="color: #94a3b8;">' + tx.date + ' - ' + tx.item + '</span>' + (tx.gps ? '<br>📍 Location: <span style="color: #38bdf8;">' + tx.gps + '</span>' : '') + '</div>' +
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

        function recordTransaction() {
            const customer = document.getElementById('customerInput').value.trim();
            if (!customer) { alert('Please enter customer name'); return; }
            const weight = parseFloat(document.getElementById('weightInput').value) || 0;
            const amount = parseFloat(document.getElementById('amountInput').value) || 0;
            const cashCollected = parseFloat(document.getElementById('cashInput').value) || 0;
            const locInput = document.getElementById('locationInput').value.trim();
            const finalGps = locInput !== '' ? locInput : currentGPS;

            if (amount <= 0) { alert('Please enter a valid amount'); return; }

            fetch('/api/transactions', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ customer: customer, gps: finalGps, item: (weight > 0 ? weight + 'g Unit' : 'Custom Unit'), amount: amount, cashCollected: cashCollected })
            }).then(res => res.json()).then(result => {
                if (result.success) {
                    document.getElementById('customerInput').value = '';
                    document.getElementById('cashInput').value = '0';
                    document.getElementById('existingBalNotice').style.display = 'none';
                    switchTab('bals');
                }
            }).catch(e => { alert('Error recording transaction'); });
        }

        loadSettings();
        loadData();
    </script>
</body>
</html>
