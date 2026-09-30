const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

const PORT = process.env.PORT || 3100;

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const DATA_FILE = path.join(__dirname, 'transactions.json');
const PROFILES_FILE = path.join(__dirname, 'profiles.json');
const SETTINGS_FILE = path.join(__dirname, 'settings.json');

if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, date: '2026-09-27 21:30', customer: 'Alice', gps: '49.8880, -119.4960', item: '28g Oz Preset', amount: 250.00, cashCollected: 250.00, balance: 0.00, status: 'Paid' },
        { id: 2, date: '2026-09-27 21:35', customer: 'Bob', gps: '49.8850, -119.4910', item: '1.75g Tier', amount: 25.00, cashCollected: 0.00, balance: 25.00, status: 'Balance Owed' }
    ], null, 2));
}

if (!fs.existsSync(PROFILES_FILE)) {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify({
        'Alice': { phone: '555-0192', notes: 'VIP Client' },
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
    try { return JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf8')); } catch (e) { return { pin: '', presets: [{ weight: 1.75, price: 25 }, { weight: 3.5, price: 45 }, { weight: 7, price: 80 }, { weight: 14, price: 140 }, { weight: 28, price: 250 }] }; }
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
    <title>Ledger Suite</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <style>
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0b0f19; color: #f1f5f9; margin: 0; padding: 10px; display: flex; justify-content: center; align-items: flex-start; min-height: 100vh; }
        .card { background: #131c2e; padding: 14px; border-radius: 14px; width: 100%; max-width: 480px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); border: 1px solid #1e293b; margin-top: 6px; }
        h1 { color: #38bdf8; font-size: 17px; margin: 0 0 2px 0; text-align: center; }
        .subtitle { color: #94a3b8; font-size: 10px; text-align: center; margin-bottom: 12px; }
        .tab-bar { display: grid; grid-template-columns: repeat(5, 1fr); gap: 3px; margin-bottom: 10px; }
        .tab { background: #1e293b; border: 1px solid #334155; color: #94a3b8; padding: 8px 2px; text-align: center; border-radius: 8px; cursor: pointer; font-size: 10px; font-weight: 600; user-select: none; }
        .tab.active { background: #0284c7; color: white; border-color: #38bdf8; }
        label { font-size: 11px; color: #94a3b8; display: block; margin-bottom: 3px; font-weight: 500; }
        input, select, textarea { width: 100%; padding: 11px; background: #0b0f19; border: 1px solid #334155; color: white; border-radius: 8px; margin-bottom: 8px; font-size: 15px; }
        .preset-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 4px; margin-bottom: 8px; }
        button.preset-btn { background: #1e293b; color: #f1f5f9; border: 1px solid #334155; padding: 8px 2px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; width: 100%; }
        button.preset-btn:hover, button.preset-btn.active { background: #0369a1; border-color: #38bdf8; color: #ffffff; }
        .cash-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-bottom: 8px; }
        button.cash-btn { background: #0f172a; color: #38bdf8; border: 1px solid #334155; padding: 7px; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 11px; width: 100%; }
        button.cash-btn:hover { background: #1e293b; border-color: #38bdf8; }
        .row { display: flex; gap: 8px; }
        .row > div { flex: 1; }
        .output-box { background: #0b0f19; padding: 10px; border-radius: 8px; border: 1px solid #1e293b; font-family: monospace; font-size: 12px; margin-bottom: 10px; display: flex; justify-content: space-between; align-items: center; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 13px; border-radius: 8px; font-weight: 700; cursor: pointer; font-size: 14px; margin-bottom: 12px; }
        .action-btn:hover { background: #059669; color: white; }
        .comms-row { display: flex; gap: 6px; margin-top: 6px; }
        .call-btn { flex: 1; background: #047857; color: white; border: none; padding: 7px; border-radius: 6px; font-size: 11px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .sms-btn { flex: 1; background: #1d4ed8; color: white; border: none; padding: 7px; border-radius: 6px; font-size: 11px; cursor: pointer; font-weight: 600; text-align: center; text-decoration: none; display: inline-block; }
        .ledger-title { font-size: 11px; font-weight: 600; color: #38bdf8; margin-bottom: 6px; border-top: 1px solid #1e293b; padding-top: 8px; display: flex; justify-content: space-between; align-items: center; }
        .ledger-list { max-height: 260px; overflow-y: auto; font-size: 11px; font-family: monospace; background: #0b0f19; padding: 6px; border-radius: 8px; border: 1px solid #1e293b; }
        .ledger-item { display: flex; justify-content: space-between; padding: 6px 4px; border-bottom: 1px solid #1e293b; align-items: center; }
        .status { font-size: 10px; color: #34d399; text-align: center; font-weight: 500; margin-top: 8px; }
        .del-btn { background: #7f1d1d; color: #fca5a5; border: none; padding: 3px 6px; border-radius: 4px; font-size: 10px; cursor: pointer; font-weight: bold; }
        .del-btn:hover { background: #991b1b; }
        .view-section { display: none; }
        .view-section.active-view { display: block; }
    </style>
</head>
<body>

    <div class="location-capture-group" style="background: #f8f9fa; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6; margin-bottom: 15px; font-family: sans-serif;">
        <h4 style="margin-top: 0; margin-bottom: 10px; color: #333;">Location Details</h4>
        
        <!-- Field 1: Auto-Captured Coordinates -->
        <div style="margin-bottom: 12px;">
            <label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 14px;">Coordinates (Auto-Captured):</label>
            <div style="display: flex; gap: 8px;">
                <input type="text" id="coordinates" name="coordinates" placeholder="Fetching GPS coordinates..." style="flex: 1; padding: 8px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px;" readonly>
                <button type="button" onclick="captureCoordinates()" style="padding: 8px 12px; background: #28a745; color: white; border: none; cursor: pointer; border-radius: 4px; font-weight: bold;">Recapture</button>
            </div>
        </div>

        <!-- Field 2: Manual Nearest Landmark Input -->
        <div style="margin-bottom: 5px;">
            <label style="display: block; font-weight: bold; margin-bottom: 4px; font-size: 14px;">Nearest Landmark / Location Name:</label>
            <input type="text" id="nearestLandmark" name="nearest_landmark" placeholder="e.g., Beside Central Park fountain, Near 4th & Main" style="width: 100%; padding: 8px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 4px;">
        </div>
    </div>

    <script>
    function captureCoordinates() {
        const coordInput = document.getElementById('coordinates');
        if (!navigator.geolocation) {
            coordInput.value = 'Geolocation not supported';
            return;
        }
        coordInput.value = 'Acquiring GPS fix...';
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const lat = position.coords.latitude.toFixed(6);
                const lon = position.coords.longitude.toFixed(6);
                coordInput.value = `${lat}, ${lon}`;
            },
            (error) => {
                coordInput.value = 'GPS Error: ' + error.message;
            },
            { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
        );
    }

    window.addEventListener('DOMContentLoaded', () => {
        captureCoordinates();
    });
    </script>


    

    <div class="card">
        <h1>Customer Account Ledger</h1>
        <div class="subtitle">Open Access Suite & Location Tracking</div>
        
        <div class="tab-bar">
            <div id="tabNew" class="tab active" onclick="switchTab('new')">Sale</div>
            <div id="tabCust" class="tab" onclick="switchTab('cust')">Profiles</div>
            <div id="tabBals" class="tab" onclick="switchTab('bals')">Balances</div>
            <div id="tabHist" class="tab" onclick="switchTab('hist')">History</div>
            <div id="tabSets" class="tab" onclick="switchTab('sets')">Settings</div>
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

        <div id="viewSets" class="view-section">
            <div class="ledger-title"><span>Preset Configuration</span></div>
            <div id="presetConfigList" style="margin-bottom: 10px;"></div>
            <button class="action-btn" style="padding: 10px; font-size: 12px; margin-bottom: 12px;" onclick="savePresetsConfig()">Save Preset Changes</button>

            <div class="ledger-title"><span>Data Backup & Restoration</span></div>
            <div style="display: flex; gap: 8px; margin-top: 8px;">
                <button class="action-btn" style="background: #0284c7; margin-bottom: 0;" onclick="exportData()">📥 Export JSON Backup</button>
                <label class="action-btn" style="background: #d97706; text-align: center; margin-bottom: 0; cursor: pointer;">
                    📤 Import Backup <input type="file" id="importFile" style="display: none;" onchange="importData(event)">
                </label>
            </div>
        </div>

        <div class="status">● All Tabs & Presets Ready</div>
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
            const tabs = ['new','cust','bals','hist','sets'];
            tabs.forEach(function(t) {
                const tabEl = document.getElementById('tab' + t.charAt(0).toUpperCase() + t.slice(1));
                const viewEl = document.getElementById('view' + t.charAt(0).toUpperCase() + t.slice(1));
                if (tabEl) tabEl.classList.toggle('active', t === tab);
                if (viewEl) viewEl.classList.toggle('active-view', t === tab);
            });

            if (tab === 'cust') {
                loadData().then(function() { renderProfilesList(allCustomersData); });
            } else if (tab === 'bals') {
                loadData().then(function() { renderBalancesList(allCustomersData); });
            } else if (tab === 'hist') {
                loadData().then(function() { renderGlobalHistory(); });
            } else if (tab === 'sets') {
                renderPresetConfig();
            }
        }

        async function loadData() {
            const response = await fetch('/api/data');
            if (!response.ok) throw new Error('Unable to load data');
            const data = await response.json();

            allCustomersData = Array.isArray(data.customers)
                ? data.customers
                : [];

            globalTxData = Array.isArray(data.transactions)
                ? data.transactions
                : [];

            populateCustomerOptions();
            renderPresetButtons();

            return data;
        }

        function populateCustomerOptions() {
            const select = document.getElementById('customerSelect');
            if (!select) return;

            const current = select.value;
            select.innerHTML =
                '<option value="">Select customer</option>' +
                allCustomersData.map(function(c) {
                    const id = c.id != null ? c.id : '';
                    const name = c.name || 'Unnamed customer';
                    return '<option value="' + escapeHtml(String(id)) + '">' +
                        escapeHtml(name) +
                        '</option>';
                }).join('');

            if (current) select.value = current;
        }

        function renderPresetButtons() {
            const container = document.getElementById('presetButtons');
            if (!container) return;

            const presets = Array.isArray(appPresets) ? appPresets : [];

            container.innerHTML = presets.map(function(p, i) {
                return '<button type="button" class="preset-btn" onclick="setCash(' +
                    Number(p.amount || 0) + ')">' +
                    escapeHtml(p.label || ('$' + Number(p.amount || 0).toFixed(2))) +
                    '</button>';
            }).join('');
        }

        function calculate() {
            const qty = parseFloat(document.getElementById('quantity')?.value || '0');
            const price = parseFloat(document.getElementById('price')?.value || '0');
            const total = qty * price;

            const output = document.getElementById('calculatedTotal');
            if (output) output.textContent = '$' + total.toFixed(2);

            return total;
        }

        function setCash(amount) {
            const input = document.getElementById('cashCollected');
            if (input) input.value = Number(amount || 0).toFixed(2);
            updateBalanceDisplay();
        }

        function setCashExact() {
            const total = calculate();
            setCash(total);
        }

        function updateBalanceDisplay() {
            const total = calculate();
            const paid = parseFloat(document.getElementById('cashCollected')?.value || '0');
            const balance = total - paid;
            const output = document.getElementById('balanceDisplay');
            if (output) {
                output.textContent =
                    '$' + balance.toFixed(2);
            }
        }

        function onCustomerInput() {
            const select = document.getElementById('customerSelect');
            const input = document.getElementById('customerName');
            if (select && input && select.value) {
                const c = allCustomersData.find(function(x) {
                    return String(x.id) === String(select.value);
                });
                if (c) input.value = c.name || '';
            }
        }

        async function recordTransaction() {
            const customerSelect = document.getElementById('customerSelect');
            const customerNameInput = document.getElementById('customerName');
            const quantityInput = document.getElementById('quantity');
            const priceInput = document.getElementById('price');
            const cashInput = document.getElementById('cashCollected');
            const itemInput = document.getElementById('item');
            const notesInput = document.getElementById('notes');

            const customerId = customerSelect ? customerSelect.value : '';
            const customerName = customerNameInput ? customerNameInput.value.trim() : '';
            const quantity = parseFloat(quantityInput ? quantityInput.value : '0') || 0;
            const price = parseFloat(priceInput ? priceInput.value : '0') || 0;
            const cashCollected = parseFloat(cashInput ? cashInput.value : '0') || 0;
            const item = itemInput ? itemInput.value.trim() : '';
            const notes = notesInput ? notesInput.value.trim() : '';

            if (!customerName && !customerId) {
                alert('Enter or select a customer.');
                return;
            }

            if (!quantity && !price) {
                alert('Enter a quantity or amount.');
                return;
            }

            const total = quantity * price;

            const payload = {
                customerId: customerId || null,
                customerName: customerName,
                quantity: quantity,
                price: price,
                amount: total,
                cashCollected: cashCollected,
                item: item,
                notes: notes,
                timestamp: new Date().toISOString()
            };

            const response = await fetch('/api/transactions', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                const text = await response.text();
                throw new Error(text || 'Transaction failed');
            }

            await loadData();

            if (typeof clearSaleForm === 'function') {
                clearSaleForm();
            } else {
                if (quantityInput) quantityInput.value = '';
                if (priceInput) priceInput.value = '';
                if (cashInput) cashInput.value = '';
                if (itemInput) itemInput.value = '';
                if (notesInput) notesInput.value = '';
            }

            switchTab('hist');
        }

        function renderProfilesList(data) {
            const container = document.getElementById('profilesList');
            if (!container) return;

            const filter = (
                document.getElementById('profileSearch')?.value || ''
            ).toLowerCase();

            const rows = (data || []).filter(function(c) {
                return String(c.name || '').toLowerCase().includes(filter);
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No customer profiles found.</div>';
                return;
            }

            container.innerHTML = rows.map(function(c) {
                const txs = Array.isArray(c.transactions) ? c.transactions : [];
                const purchased = txs.reduce(function(sum, t) {
                    return sum + (Number(t.quantity) || 0);
                }, 0);
                const paid = txs.reduce(function(sum, t) {
                    return sum + (Number(t.cashCollected ?? t.paid ?? t.payment) || 0);
                }, 0);
                const billed = txs.reduce(function(sum, t) {
                    return sum + (Number(t.amount ?? t.total) || 0);
                }, 0);
                const balance = billed - paid;

                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(c.name || 'Unnamed') + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Transactions</small><strong>' + txs.length + '</strong></div>' +
                    '<div><small>Quantity</small><strong>' + purchased + '</strong></div>' +
                    '<div><small>Billed</small><strong>$' + billed.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Balance</small><strong>$' + balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    (c.phone ? '<div class="muted">' + escapeHtml(c.phone) + '</div>' : '') +
                    (c.notes ? '<div class="muted">' + escapeHtml(c.notes) + '</div>' : '') +
                    '</div>';
            }).join('');
        }

        function renderBalancesList(data) {
            const container = document.getElementById('balancesList');
            if (!container) return;

            const rows = (data || []).map(function(c) {
                const txs = Array.isArray(c.transactions) ? c.transactions : [];
                const billed = txs.reduce(function(sum, t) {
                    return sum + (Number(t.amount ?? t.total) || 0);
                }, 0);
                const paid = txs.reduce(function(sum, t) {
                    return sum + (Number(t.cashCollected ?? t.paid ?? t.payment) || 0);
                }, 0);
                return {
                    customer: c,
                    billed: billed,
                    paid: paid,
                    balance: billed - paid
                };
            }).filter(function(x) {
                return Math.abs(x.balance) > 0.005;
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No outstanding balances.</div>';
                return;
            }

            container.innerHTML = rows.map(function(x) {
                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(x.customer.name || 'Unnamed') + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Billed</small><strong>$' + x.billed.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + x.paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Outstanding</small><strong>$' + x.balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    '</div>';
            }).join('');
        }

        function renderGlobalHistory() {
            const container = document.getElementById('historyList');
            if (!container) return;

            const rows = Array.isArray(globalTxData) ? globalTxData.slice() : [];

            rows.sort(function(a, b) {
                return new Date(b.timestamp || b.date || 0) -
                    new Date(a.timestamp || a.date || 0);
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No transaction history.</div>';
                return;
            }

            container.innerHTML = rows.map(function(t) {
                const customer = t.customerName || t.customer || 'Unknown';
                const amount = Number(t.amount ?? t.total) || 0;
                const paid = Number(t.cashCollected ?? t.paid ?? t.payment) || 0;
                const balance = amount - paid;
                const date = t.timestamp || t.date || '';

                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(customer) + '</div>' +
                    '<div class="muted">' + escapeHtml(String(date)) + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Qty</small><strong>' + (Number(t.quantity) || 0) + '</strong></div>' +
                    '<div><small>Amount</small><strong>$' + amount.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Balance</small><strong>$' + balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    (t.item ? '<div>' + escapeHtml(String(t.item)) + '</div>' : '') +
                    (t.notes ? '<div class="muted">' + escapeHtml(String(t.notes)) + '</div>' : '') +
                    '</div>';
            }).join('');
        }

        function renderPresetConfig() {
            const container = document.getElementById('presetConfig');
            if (!container) return;

            const presets = Array.isArray(appPresets) ? appPresets : [];

            container.innerHTML = presets.map(function(p, i) {
                return '<div class="preset-config-row">' +
                    '<input data-preset-label="' + i + '" value="' +
                    escapeHtml(p.label || '') + '">' +
                    '<input data-preset-amount="' + i + '" type="number" step="0.01" value="' +
                    Number(p.amount || 0).toFixed(2) + '">' +
                    '</div>';
            }).join('');
        }

        function savePresetsConfig() {
            const presets = Array.isArray(appPresets) ? appPresets : [];

            presets.forEach(function(p, i) {
                const label = document.querySelector('[data-preset-label="' + i + '"]');
                const amount = document.querySelector('[data-preset-amount="' + i + '"]');

                if (label) p.label = label.value;
                if (amount) p.amount = parseFloat(amount.value) || 0;
            });

            localStorage.setItem('salesTrackerPresets', JSON.stringify(presets));
            renderPresetButtons();
        }

        function exportData() {
            const payload = {
                customers: allCustomersData,
                transactions: globalTxData,
                exportedAt: new Date().toISOString()
            };

            const blob = new Blob(
                [JSON.stringify(payload, null, 2)],
                {type: 'application/json'}
            );

            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'sales-tracker-export-' +
                new Date().toISOString().slice(0, 10) + '.json';
            document.body.appendChild(a);
            a.click();
            a.remove();
            URL.revokeObjectURL(url);
        }

        async function importData(file) {
            if (!file) return;

            const text = await file.text();
            const payload = JSON.parse(text);

            const response = await fetch('/api/import', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                throw new Error('Import failed');
            }

            await loadData();
            switchTab('hist');
        }

        function filterProfiles() {
            renderProfilesList(allCustomersData);
        }

        function filterBalances() {
            renderBalancesList(allCustomersData);
        }

        function escapeHtml(value) {
            return String(value ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        document.addEventListener('DOMContentLoaded', function() {
            try {
                const saved = localStorage.getItem('salesTrackerPresets');
                if (saved) {
                    const parsed = JSON.parse(saved);
                    if (Array.isArray(parsed)) appPresets = parsed;
                }
            } catch (e) {}

            loadData().catch(function(err) {
                console.error('Initial data load failed:', err);
            });

            renderPresetButtons();
        });

    </script>
    </body>
    </html>
    `);
    });

    app.listen(PORT, "0.0.0.0", () => {
        console.log("Server running on port " + PORT);
    });
