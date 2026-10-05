
function recalculateRunningBalances(transactions) {
    const sorted = [...transactions].sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
    const customerTotals = {};
    sorted.forEach(t => {
        const cust = (t.customer || '').trim().toLowerCase();
        if (!cust) return;
        const amt = Number(t.amount) || 0;
        const cash = Number(t.cashCollected) || 0;
        customerTotals[cust] = (customerTotals[cust] || 0) + amt - cash;
        t.balance = customerTotals[cust];
    });
    return sorted;
}


function getSortedTransactions() {
    let txs = getSortedTransactions();
    if (Array.isArray(txs)) {
        txs.sort((a, b) => {
            const timeA = a.date ? new Date(a.date.replace(' ', 'T')).getTime() : (a.timestamp || a.id || 0);
            const timeB = b.date ? new Date(b.date.replace(' ', 'T')).getTime() : (b.timestamp || b.id || 0);
            return timeB - timeA;
        });
    }
    return txs;
}

const http = require('http');
const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, 'transactions.json');
const PROFILES_FILE = path.join(__dirname, 'profiles.json');
const EXPENSES_FILE = path.join(__dirname, 'expenses.json');

// Ensure data files exist
if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, timestamp: Date.now(), date: '2026-09-30 05:11', customer: 'Alice', landmark: 'Downtown', gps: '49.8880, -119.4960', item: '28g Preset', amount: 250, cashCollected: 250, balance: 0, status: 'Paid' }
    ], null, 2));
}
if (!fs.existsSync(PROFILES_FILE)) {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify({
        'Alice': { phone: '555-0192', notes: 'VIP Client - Cash on delivery preferred' }
    }, null, 2));
}
if (!fs.existsSync(EXPENSES_FILE)) {
    fs.writeFileSync(EXPENSES_FILE, JSON.stringify([
        { id: 1, timestamp: Date.now(), date: '2026-09-30', category: 'Packaging', amount: 15.00, notes: 'Ziploc bags & scales' }
    ], null, 2));
}

function getProfiles() {
    try { return JSON.parse(fs.readFileSync(PROFILES_FILE, 'utf8')); } catch(e) { return {}; }
}
function getExpenses() {
    try { return JSON.parse(fs.readFileSync(EXPENSES_FILE, 'utf8')); } catch(e) { return []; }
}

// ==========================================
// CREATE APP HANDLER FACTORY (v1, v2, v3, v4)
// ==========================================
function createAppHandler(version) {
    return (req, res) => {
        const url = new URL(req.url, `http://${req.headers.host}`);
        
        if (url.pathname === '/api/data') {
            try {
                const txs = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
                const profiles = getProfiles();
                const expenses = getExpenses();
                res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store, no-cache, must-validate' });
                res.end(JSON.stringify({ transactions: txs, profiles, expenses }));
            } catch(e) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: e.message }));
            }
            return;
        }

        if (url.pathname === '/api/action' && req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
                try {
                    const { action, payload } = JSON.parse(body);
                    let txs = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
                    
                    if (action === 'add_sale') {
                        const hasTimeMachine = version === 'v2' || version === 'v3' || ((version === 'v4' || version === 'v5') || version === 'v5');
                        const customTs = (hasTimeMachine && payload.customTimestamp) ? new Date(payload.customTimestamp).getTime() : Date.now();
                        const formattedDate = (hasTimeMachine && payload.customTimestamp) ? payload.customTimestamp.replace('T', ' ') : new Date().toISOString().replace('T', ' ').substring(0, 16);
                        
                        const newTx = {
                            id: customTs,
                            timestamp: customTs,
                            date: formattedDate,
                            customer: payload.customer || 'Guest',
                            landmark: payload.landmark || '',
                            gps: payload.gps || 'No GPS',
                            item: payload.item || 'Unit',
                            amount: parseFloat(payload.amount) || 0,
                            cashCollected: parseFloat(payload.cashCollected) || 0,
                            balance: 0,
                            status: 'Pending'
                        };
                        txs.push(newTx);
                        
                        let bals = {};
                        txs.sort((a,b)=>a.timestamp - b.timestamp).forEach(t => {
                            const c = t.customer;
                            if(bals[c] === undefined) bals[c] = 0;
                            bals[c] = Math.max(0, bals[c] + t.amount - t.cashCollected);
                            t.balance = bals[c];
                            t.status = t.balance === 0 ? 'Paid' : 'Balance';
                        });
                        txs.sort((a,b)=>b.timestamp - a.timestamp);
                        txs = recalculateRunningBalances(txs);
            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true, timestamp: customTs }));
                        return;
                    }

                    if (action === 'update_tx' && (version === 'v3' || ((version === 'v4' || version === 'v5') || version === 'v5') || version === 'v5')) {
    const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
    let transactions = fs.existsSync(DATA_FILE) ? JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')) : [];
    transactions = transactions.map(t => {
        if (String(t.id) === String(id)) {
            t.customer = customer !== undefined ? customer : t.customer;
            t.landmark = landmark !== undefined ? landmark : t.landmark;
            t.gps = gps !== undefined ? gps : t.gps;
            t.amount = amount !== undefined ? Number(amount) : t.amount;
            t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
            
            if (version === 'v5' && customTimestamp) {
                const newTs = new Date(customTimestamp).getTime();
                if (!isNaN(newTs)) {
                    t.timestamp = newTs;
                    t.id = newTs;
                    t.date = customTimestamp.replace('T', ' ');
                }
            }
        }
        return t;
    });
    transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));
    fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true }));
    return;
}

                    if (action === 'add_expense') {
                        let expenses = getExpenses();
                        const hasTimeMachine = version === 'v2' || version === 'v3' || ((version === 'v4' || version === 'v5') || version === 'v5');
                        const customTs = (hasTimeMachine && payload.customTimestamp) ? new Date(payload.customTimestamp).getTime() : Date.now();
                        const formattedDate = (hasTimeMachine && payload.customTimestamp) ? payload.customTimestamp.split('T')[0] : new Date().toISOString().split('T')[0];
                        
                        expenses.unshift({
                            id: customTs,
                            timestamp: customTs,
                            date: formattedDate,
                            category: payload.category || 'General',
                            amount: parseFloat(payload.amount) || 0,
                            notes: payload.notes || ''
                        });
                        expenses.sort((a,b)=>b.timestamp - a.timestamp);
                        fs.writeFileSync(EXPENSES_FILE, JSON.stringify(expenses, null, 2));
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true, timestamp: customTs }));
                        return;
                    }
                    
                    if (action === 'save_profile') {
                        let profiles = getProfiles();
                        profiles[payload.customer] = { phone: payload.phone || '', notes: payload.notes || '', updated_at: Date.now() };
                        fs.writeFileSync(PROFILES_FILE, JSON.stringify(profiles, null, 2));
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true, timestamp: Date.now() }));
                        return;
                    }

                    if (action === 'delete_tx') {
                        txs = txs.filter(t => t.id !== payload.id);
                        txs = recalculateRunningBalances(txs);
            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true }));
                        return;
                    }

                    if (action === 'delete_expense') {
                        let expenses = getExpenses().filter(e => e.id !== payload.id);
                        fs.writeFileSync(EXPENSES_FILE, JSON.stringify(expenses, null, 2));
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true }));
                        return;
                    }

                    res.writeHead(400, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: false }));
                } catch(e) {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: false, error: e.message }));
                }
            });
            return;
        }

        const titles = {
            'v5': 'Enterprise P2P Master Suite v5 - History Time Travel',
            'v1': 'Enterprise P2P Master Suite v1',
            'v2': 'Enterprise P2P Master Suite v2 - Time Machine',
            'v3': 'Enterprise P2P Master Suite v3 - Map & Edit',
            'v4': 'Enterprise P2P Master Suite v4 - Interactive Pin Picker'
        ,
            'v5': 'Enterprise P2P Master Suite v5 - Pin Picker & Time Travel'};
        const badges = {
            'v5': 'v5 History Time Travel & Edit Active',
            'v1': 'v1 Standard Mode',
            'v2': 'Time Machine Active',
            'v3': 'v3 Geo-Navigation & Edit Active',
            'v4': 'v4 Interactive Map Pin Picker Active'
        ,
            'v5': 'v5 Pin Picker & History Time Travel Active'};
        const title = titles[version] || titles['v1'];
        const versionBadge = badges[version] || badges['v1'];
        
        const hasTimeMachine = version === 'v2' || version === 'v3' || ((version === 'v4' || version === 'v5') || version === 'v5');
        const timeMachineBox = hasTimeMachine ? `
            <div class="timetravel-box">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
                    <label style="color:#a5b4fc; font-weight:bold; margin:0;">⏳ Entry Timestamp (Time Machine)</label>
                    <button id="nowBtn" style="background:#312e81; color:#c7d2fe; border:1px solid #6366f1; padding:2px 6px; border-radius:4px; font-size:9px; cursor:pointer;">Reset to Now</button>
                </div>
                <input type="datetime-local" id="saleTimestampInput" style="background:#0f172a; border-color:#4338ca; color:#e0e7ff; margin-bottom:0; font-size:12px;">
            </div>
        ` : '';

        const expTimeMachineBox = hasTimeMachine ? `
            <div class="timetravel-box" style="margin-bottom:8px;">
                <label style="color:#a5b4fc; font-weight:bold; margin-bottom:2px;">⏳ Expense Timestamp</label>
                <input type="datetime-local" id="expTimestampInput" style="background:#0f172a; border-color:#4338ca; color:#e0e7ff; margin-bottom:0; font-size:12px;">
            </div>
        ` : '';

        const mapPickerModal = ((version === 'v4' || version === 'v5') || version === 'v5') ? `
            <div id="mapPickerModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.85); z-index:9999; justify-content:center; align-items:center; padding:10px;">
                <div style="background:#131c2e; border:1px solid #334155; width:100%; max-width:440px; border-radius:12px; padding:14px; display:flex; flex-direction:column; height:85vh;">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
                        <span style="font-weight:bold; color:#38bdf8; font-size:14px;">📍 Pin Point Exact Location</span>
                        <button id="closeMapModal" style="background:#7f1d1d; color:#fca5a5; border:none; padding:4px 8px; border-radius:6px; font-weight:bold; cursor:pointer;">✕ Close</button>
                    </div>
                    <div style="font-size:11px; color:#94a3b8; margin-bottom:8px;">Tap anywhere on the map or drag the pin to set precise coordinates.</div>
                    <div id="leafletMapContainer" style="flex:1; width:100%; border-radius:8px; border:1px solid #1e293b; background:#0b0f19;"></div>
                    <div style="margin-top:8px;">
                        <label>Selected Coordinates & Landmark:</label>
                        <input type="text" id="modalCoordsOutput" readonly style="background:#0b0f19; color:#34d399; font-family:monospace; font-size:11px; text-align:center; margin-bottom:6px;">
                        <button id="confirmPinBtn" class="action-btn" style="background:#0284c7; color:#fff; margin-top:0;">Confirm Location Pin</button>
                    </div>
                </div>
            </div>
            <!-- Leaflet CSS & JS -->
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
        ` : '';

        const htmlContent = `<!DOCTYPE html>
<html>
<head>
    <title>${title}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <style>
        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #0b0f19; color: #f1f5f9; margin: 0; padding: 10px; }
        .card { background: #131c2e; padding: 14px; border-radius: 12px; max-width: 440px; margin: 0 auto; border: 1px solid #1e293b; }
        h2 { color: #38bdf8; margin: 0 0 4px 0; text-align: center; font-size: 18px; }
        .sub { color: #94a3b8; font-size: 11px; text-align: center; margin-bottom: 12px; }
        .tabs { display: grid; grid-template-columns: repeat(5, 1fr); gap: 3px; margin-bottom: 12px; }
        .tab { background: #1e293b; border: 1px solid #334155; color: #94a3b8; padding: 8px 2px; text-align: center; border-radius: 6px; cursor: pointer; font-size: 10px; font-weight: bold; }
        .tab.active { background: #0284c7; color: #fff; border-color: #38bdf8; }
        .pane { display: none; }
        .pane.active { display: block; }
        label { font-size: 11px; color: #94a3b8; display: block; margin-bottom: 3px; }
        input, select { width: 100%; padding: 12px; background: #0b0f19; border: 1px solid #334155; color: #fff; border-radius: 8px; margin-bottom: 8px; font-size: 14px; }
        .presets { display: grid; grid-template-columns: repeat(5, 1fr); gap: 4px; margin-bottom: 8px; }
        .p-btn { background: #1e293b; color: #38bdf8; border: 1px solid #334155; padding: 10px 2px; font-size: 11px; border-radius: 6px; text-align: center; cursor: pointer; font-weight: bold; }
        .p-btn.active { background: #0369a1; color: #fff; }
        .action-btn { width: 100%; background: #10b981; color: #064e3b; border: none; padding: 14px; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 14px; margin-top: 4px; }
        .ledger-box { background: #0b0f19; border: 1px solid #1e293b; border-radius: 8px; padding: 8px; max-height: 300px; overflow-y: auto; font-family: monospace; font-size: 11px; }
        .stat-card { background: #0b0f19; border: 1px solid #1e293b; padding: 12px; border-radius: 8px; margin-bottom: 8px; text-align: center; }
        .stat-val { font-size: 20px; font-weight: bold; color: #38bdf8; margin-top: 4px; }
        .ts-badge { font-size: 9px; color: #38bdf8; margin-top: 2px; display: block; }
        .timetravel-box { background: #1e1b4b; border: 1px solid #4338ca; padding: 10px; border-radius: 8px; margin-bottom: 8px; }
    </style>
</head>
<body>
    <div class="card">
        <h2>${title}</h2>
        <div class="sub" id="liveTimestamp">${versionBadge}</div>

        <div class="tabs">
            <button class="tab active" data-tab="sale">Sale</button>
            <button class="tab" data-tab="cust">Profiles</button>
            <button class="tab" data-tab="exp">Expenses</button>
            <button class="tab" data-tab="hist">History</button>
            <button class="tab" data-tab="anly">Analytics</button>
        </div>

        <div id="paneSale" class="pane active">
            ${timeMachineBox}

            <label>Customer Name</label>
            <input type="text" id="custInput" placeholder="Enter name..." list="custOptions">
            <datalist id="custOptions"></datalist>

            <div id="warnBal" style="display:none; background:#78350f; color:#fde68a; padding:6px; border-radius:6px; font-size:11px; margin-bottom:8px; font-weight:bold;"></div>

            <label>Weight Presets</label>
            <div class="presets">
                <button class="p-btn" data-w="1.75" data-p="25">1.75g</button>
                <button class="p-btn" data-w="3.5" data-p="45">3.5g</button>
                <button class="p-btn" data-w="7" data-p="80">7g</button>
                <button class="p-btn" data-w="14" data-p="140">14g</button>
                <button class="p-btn" data-w="28" data-p="250">28g</button>
            </div>

            <div style="display:flex; gap:6px;">
                <div style="flex:1;"><label>Weight (g)</label><input type="number" id="weightInput" placeholder="Grams"></div>
                <div style="flex:1;"><label>Amount ($)</label>
<div style="margin-bottom:10px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:4px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="e.g. Premium Item" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>

<input type="number" id="amountInput" placeholder="0.00"></div>
            </div>

            <label>Cash Collected ($)</label>
            <input type="number" id="cashInput" value="0">

            <label>Nearest Landmark</label>
            <input type="text" id="landmarkInput" placeholder="Closest landmark...">

            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
                <label style="margin:0;">GPS Location Stamp:</label>
                <div>
                    ${((version === 'v4' || version === 'v5') || version === 'v5') ? '<button id="openMapPickerBtn" style="background:#0284c7; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:10px; cursor:pointer; font-weight:bold; margin-right:4px;">🗺️ Pin on Map</button>' : ''}
                    <button id="gpsBtn" style="background:#1e293b; color:#38bdf8; border:1px solid #334155; padding:4px 8px; border-radius:4px; font-size:10px; cursor:pointer;">🔄 Refresh GPS</button>
                </div>
            </div>
            <input type="text" id="gpsInput" readonly placeholder="Acquiring GPS..." style="background:#0f172a; color:#34d399; font-family:monospace; font-size:11px; text-align:center;">

            <div style="background:#0b0f19; border:1px solid #1e293b; padding:10px; border-radius:8px; margin-bottom:8px; display:flex; justify-content:space-between; font-size:12px;">
                <span id="summaryText">Ready for entry</span>
                <span id="newBalText" style="color:#34d399; font-weight:bold;">New Bal: $0.00</span>
            </div>

            <button class="action-btn" id="saveBtn">Record Sale${hasTimeMachine ? ' with Selected Time' : ''}</button>
        </div>

        <div id="paneCust" class="pane">
            <div style="font-weight:bold; color:#38bdf8; margin-bottom:6px; font-size:12px;">Customer Directory & Contacts</div>
            <div id="profilesList" class="ledger-box">Loading profiles...</div>
        </div>

        <div id="paneExp" class="pane">
            ${expTimeMachineBox}

            <div style="font-weight:bold; color:#38bdf8; margin-bottom:6px; font-size:12px;">Add Business Expense</div>
            <input type="text" id="expCat" placeholder="Category (e.g. Packaging, Transport)">
            <input type="number" id="expAmount" placeholder="Amount ($)">
            <input type="text" id="expNotes" placeholder="Notes...">
            <button class="action-btn" id="saveExpBtn" style="background:#0284c7; color:#fff; margin-bottom:8px;">Add Expense${hasTimeMachine ? ' with Time' : ''}</button>
            <div style="font-weight:bold; color:#38bdf8; margin-bottom:6px; font-size:12px;">Expense Log</div>
            <div id="expenseList" class="ledger-box">Loading expenses...</div>
        </div>

        <div id="paneHist" class="pane">
            <div style="font-weight:bold; color:#38bdf8; margin-bottom:6px; font-size:12px;">Transaction History (Chronological Order)</div>
            <div id="historyList" class="ledger-box">Loading history...</div>
        </div>

        <div id="paneAnly" class="pane">
            <div class="stat-card"><label>Total Revenue</label><div class="stat-val" id="statRev">$0.00</div></div>
            <div class="stat-card"><label>Cash Collected</label><div class="stat-val" id="statColl" style="color:#34d399;">$0.00</div></div>
            <div class="stat-card"><label>Total Outstanding Balances</label><div class="stat-val" id="statOut" style="color:#f87171;">$0.00</div></div>
            <div class="stat-card"><label>Total Expenses</label><div class="stat-val" id="statExp" style="color:#fbbf24;">$0.00</div></div>
            <div class="stat-card"><label>Net Profit</label><div class="stat-val" id="statNet" style="color:#34d399;">$0.00</div></div>
        </div>
    </div>

    ${mapPickerModal}

<script>
let globalData = { transactions: [], profiles: {}, expenses: [] };
const APP_VERSION = '${version}';
let mapInstance = null;
let markerInstance = null;
let selectedMapLat = 49.8880;
let selectedMapLng = -119.4960;

function setDateTimeInputsToNow() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const localIso = \`\${year}-\${month}-\${day}T\${hours}:\${minutes}\`;
    
    const saleInput = document.getElementById('saleTimestampInput');
    const expInput = document.getElementById('expTimestampInput');
    if(saleInput) saleInput.value = localIso;
    if(expInput) expInput.value = localIso;
}

setInterval(() => {
    const now = new Date();
    const yr = now.getFullYear();
    const mo = String(now.getMonth() + 1).padStart(2, '0');
    const da = String(now.getDate()).padStart(2, '0');
    const hr = String(now.getHours()).padStart(2, '0');
    const mi = String(now.getMinutes()).padStart(2, '0');
    const se = String(now.getSeconds()).padStart(2, '0');
    document.getElementById('liveTimestamp').innerText = 'Local System Time: ' + \`\${yr}-\${mo}-\${da} \${hr}:\${mi}:\${se}\`;
}, 1000);

function getGPS() {
    const gpsField = document.getElementById('gpsInput');
    gpsField.value = 'Acquiring GPS...';
    if(navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            pos => {
                selectedMapLat = pos.coords.latitude;
                selectedMapLng = pos.coords.longitude;
                gpsField.value = selectedMapLat.toFixed(4) + ', ' + selectedMapLng.toFixed(4);
                reverseGeocode(selectedMapLat, selectedMapLng);
            },
            () => { gpsField.value = '49.8880, -119.4960'; },
            { enableHighAccuracy: true, timeout: 5000 }
        );
    } else {
        gpsField.value = '49.8880, -119.4960';
    }
}

async function reverseGeocode(lat, lng) {
    try {
        const res = await fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng, {
            headers: { 'Accept-Language': 'en' }
        });
        const data = await res.json();
        if(data && data.display_name) {
            const parts = data.display_name.split(',');
            const landmark = parts[0] + (parts[1] ? ', ' + parts[1] : '');
            const landInput = document.getElementById('landmarkInput');
            if(landInput && !landInput.value) {
                landInput.value = landmark;
            }
        }
    } catch(e) {}
}

async function loadData() {
    try {
        const res = await fetch('/api/data?t=' + Date.now());
        globalData = await res.json();
        render();
    } catch(e) {}
}

function render() {
    const names = [...new Set(globalData.transactions.map(t => t.customer))];
    document.getElementById('custOptions').innerHTML = names.map(n => '<option value="' + n + '">').join('');
    
    const hist = document.getElementById('historyList');
    if(!globalData.transactions || globalData.transactions.length === 0) {
        hist.innerHTML = 'No transactions recorded.';
    } else {
        hist.innerHTML = [...globalData.transactions].sort((a,b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0)).map(t => {
            const hasGps = t.gps && t.gps.includes(',') && !t.gps.includes('No') && !t.gps.includes('Unavailable') && !t.gps.includes('Not');
            const mapLink = hasGps ? 'https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(t.gps) : '#';
            const landmarkDisplay = t.landmark ? '<span style="color:#fbbf24; font-size:10px;">🏷️ ' + t.landmark + '</span><br>' : '';
            
            const isV3OrV4 = APP_VERSION === 'v3' || ((APP_VERSION === 'v4' || APP_VERSION === 'v5') || APP_VERSION === 'v5');
            const editControls = isV3OrV4 ? 
                '<div id="edit_view_' + t.id + '" style="display:none; margin-top:6px; background:#0f172a; padding:6px; border-radius:6px; border:1px solid #334155;">' +
                '<input type="text" id="edit_cust_' + t.id + '" value="' + t.customer.replace(/"/g, '&quot;') + '" placeholder="Customer" style="padding:6px; font-size:11px; margin-bottom:4px;">' +
                '<input type="text" id="edit_land_' + t.id + '" value="' + (t.landmark || '').replace(/"/g, '&quot;') + '" placeholder="Landmark" style="padding:6px; font-size:11px; margin-bottom:4px;">' +
                '<div style="display:flex; gap:4px; margin-bottom:4px;">' +
                '<input type="text" id="edit_gps_' + t.id + '" value="' + (t.gps || '').replace(/"/g, '&quot;') + '" placeholder="GPS" style="padding:6px; font-size:11px; margin-bottom:0; flex:1;">' +
                (((APP_VERSION === 'v4' || APP_VERSION === 'v5') || APP_VERSION === 'v5') ? '<button class="pick-map-edit-btn" data-id="' + t.id + '" style="background:#0284c7; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:10px; font-weight:bold; cursor:pointer;">🗺️ Pin</button>' : '') +
                '</div>' +
                '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '" value="' + t.amount + '" placeholder="Amt" style="padding:6px; font-size:11px; margin-bottom:0;"><input type="number" id="edit_cash_' + t.id + '" value="' + t.cashCollected + '" placeholder="Cash" style="padding:6px; font-size:11px; margin-bottom:0;"></div>' +
                '<button class="save-edit-btn" data-id="' + t.id + '" style="background:#059669; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:10px; font-weight:bold; width:100%; margin-top:4px; cursor:pointer;">Save Changes</button>' +
                '</div>' : '';

            const editBtn = isV3OrV4 ? '<button class="toggle-edit-btn" data-id="' + t.id + '" style="background:#1e293b; color:#38bdf8; border:1px solid #334155; padding:3px 6px; border-radius:4px; margin-top:2px; cursor:pointer; font-weight:bold; margin-right:4px;">Edit</button>' : '';

            const gpsDisplay = hasGps ? (
                ((APP_VERSION === 'v4' || APP_VERSION === 'v5') || APP_VERSION === 'v5') ? 
                '<span class="clickable-gps" data-gps="' + t.gps + '" style="color:#38bdf8; font-size:10px; text-decoration:underline; cursor:pointer;">📍 ' + t.gps + ' (Map)</span>' :
                '<a href="' + mapLink + '" target="_blank" style="color:#38bdf8; font-size:10px; text-decoration:underline;">📍 ' + t.gps + ' (Map)</a>'
            ) : '<span style="color:#94a3b8; font-size:10px;">📍 ' + t.gps + '</span>';

            return '<div style="padding:6px 0; border-bottom:1px solid #1e293b;">' +
                '<div style="display:flex; justify-content:space-between; align-items:flex-start;">' +
                '<div><b>' + t.customer + '</b><br><span style="color:#94a3b8">' + t.item + '</span><span class="ts-badge">📅 ' + t.date + '</span>' + landmarkDisplay + gpsDisplay + '</div>' +
                '<div style="text-align:right">$' + t.amount + '<br><span style="color:' + (t.balance > 0 ? '#f87171' : '#34d399') + '">Bal: $' + t.balance + '</span><br>' +
                editBtn + '<button class="del-btn" data-id="' + t.id + '" style="background:#7f1d1d; color:#fca5a5; border:none; padding:3px 6px; border-radius:4px; margin-top:2px; cursor:pointer; font-weight:bold;">Del</button></div>' +
                '</div>' +
                editControls +
                '</div>';
        }).join('');
    }

    const expList = document.getElementById('expenseList');
    if(!globalData.expenses || globalData.expenses.length === 0) {
        expList.innerHTML = 'No expenses logged.';
    } else {
        expList.innerHTML = globalData.expenses.map(e =>
            '<div style="padding:6px 0; border-bottom:1px solid #1e293b; display:flex; justify-content:space-between; align-items:center;">' +
            '<div><b>[' + e.category + ']</b> $' + e.amount.toFixed(2) + '<br><span style="color:#94a3b8">' + (e.notes || '') + '</span><span class="ts-badge">📅 ' + e.date + '</span></div>' +
            '<button class="del-exp-btn" data-id="' + e.id + '" style="background:#7f1d1d; color:#fca5a5; border:none; padding:3px 6px; border-radius:4px; cursor:pointer; font-weight:bold;">Del</button>' +
            '</div>'
        ).join('');
    }

    const custMap = {};
    const sortedForBal = [...globalData.transactions].sort((a,b)=>a.timestamp - b.timestamp);
    let runningBals = {};
    sortedForBal.forEach(t => {
        if(runningBals[t.customer] === undefined) runningBals[t.customer] = 0;
        runningBals[t.customer] = Math.max(0, runningBals[t.customer] + t.amount - t.cashCollected);
        custMap[t.customer] = { balance: runningBals[t.customer] };
    });

    document.getElementById('profilesList').innerHTML = Object.keys(custMap).map(name => {
        const p = globalData.profiles[name] || { phone: '', notes: '' };
        const b64 = btoa(unescape(encodeURIComponent(name)));
        return '<div style="padding:8px 0; border-bottom:1px solid #1e293b;">' +
            '<div style="display:flex; justify-content:space-between; font-weight:bold; color:#38bdf8;"><span>' + name + '</span><span style="color:' + (custMap[name].balance > 0 ? '#f87171' : '#34d399') + '">Bal: $' + custMap[name].balance.toFixed(2) + '</span></div>' +
            '<input type="tel" id="phone_' + b64 + '" value="' + p.phone + '" placeholder="Phone..." style="margin:4px 0; padding:8px; font-size:12px;">' +
            (p.phone ? '<div style="display:flex; gap:4px; margin-bottom:4px;"><a href="tel:' + p.phone + '" style="flex:1; background:#047857; color:#fff; text-align:center; padding:6px; border-radius:4px; text-decoration:none; font-size:11px;">📞 Call</a><a href="sms:' + p.phone + '" style="flex:1; background:#1d4ed8; color:#fff; text-align:center; padding:6px; border-radius:4px; text-decoration:none; font-size:11px;">💬 SMS</a></div>' : '') +
            '<input type="text" id="notes_' + b64 + '" value="' + p.notes + '" placeholder="Notes..." style="margin-bottom:6px; padding:8px; font-size:12px;">' +
            '<button class="save-profile-btn" data-name="' + name.replace(/"/g, '&quot;') + '" data-b64="' + b64 + '" style="background:#0284c7; color:#fff; border:none; padding:8px; width:100%; border-radius:4px; font-size:12px; font-weight:bold; cursor:pointer;">Save Profile</button>' +
        '</div>';
    }).join('');

    let rev = 0, coll = 0, out = 0, totalExp = 0;
    globalData.transactions.forEach(t => { rev += t.amount; coll += t.cashCollected; });
    Object.values(custMap).forEach(c => { out += c.balance; });
    globalData.expenses.forEach(e => { totalExp += e.amount; });

    document.getElementById('statRev').innerText = '$' + rev.toFixed(2);
    document.getElementById('statColl').innerText = '$' + coll.toFixed(2);
    document.getElementById('statOut').innerText = '$' + out.toFixed(2);
    document.getElementById('statExp').innerText = '$' + totalExp.toFixed(2);
    document.getElementById('statNet').innerText = '$' + (rev - totalExp).toFixed(2);

    attachDynamicListeners();
}

function calcBal() {
    const amt = parseFloat(document.getElementById('amountInput').value) || 0;
    const cash = parseFloat(document.getElementById('cashInput').value) || 0;
    const cust = document.getElementById('custInput').value.trim();
    
    let existingBal = 0;
    const found = globalData.transactions.find(t => t.customer.toLowerCase() === cust.toLowerCase());
    if(found) existingBal = found.balance;

    const newBal = Math.max(0, existingBal + amt - cash);
    document.getElementById('summaryText').innerText = 'Total: $' + amt.toFixed(2);
    document.getElementById('newBalText').innerText = 'New Bal: $' + newBal.toFixed(2);
    document.getElementById('newBalText').style.color = newBal > 0 ? '#f87171' : '#34d399';
}

function checkCustomer(name) {
    const found = globalData.transactions.find(t => t.customer.toLowerCase() === name.trim().toLowerCase());
    const warn = document.getElementById('warnBal');
    if(found && found.balance > 0) {
        warn.style.display = 'block';
        warn.innerText = '⚠ Existing Balance for ' + found.customer + ': $' + found.balance.toFixed(2);
    } else {
        warn.style.display = 'none';
    }
    calcBal();
}

function openMapModal(initialCoords, targetInputId) {
    const modal = document.getElementById('mapPickerModal');
    if(!modal) return;
    modal.style.display = 'flex';

    let lat = 49.8880;
    let lng = -119.4960;
    if(initialCoords && initialCoords.includes(',')) {
        const parts = initialCoords.split(',');
        const parsedLat = parseFloat(parts[0]);
        const parsedLng = parseFloat(parts[1]);
        if(!isNaN(parsedLat) && !isNaN(parsedLng)) {
            lat = parsedLat;
            lng = parsedLng;
        }
    }

    setTimeout(() => {
        if(!mapInstance) {
            mapInstance = L.map('leafletMapContainer').setView([lat, lng], 15);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '© OpenStreetMap'
            }).addTo(mapInstance);

            markerInstance = L.marker([lat, lng], { draggable: true }).addTo(mapInstance);
            
            markerInstance.on('dragend', function(e) {
                const pos = markerInstance.getLatLng();
                selectedMapLat = pos.lat;
                selectedMapLng = pos.lng;
                updateModalCoordsText(selectedMapLat, selectedMapLng);
            });

            mapInstance.on('click', function(e) {
                markerInstance.setLatLng(e.latlng);
                selectedMapLat = e.latlng.lat;
                selectedMapLng = e.latlng.lng;
                updateModalCoordsText(selectedMapLat, selectedMapLng);
            });
        } else {
            mapInstance.setView([lat, lng], 15);
            markerInstance.setLatLng([lat, lng]);
            selectedMapLat = lat;
            selectedMapLng = lng;
        }
        updateModalCoordsText(lat, lng);
        mapInstance.invalidateSize();
    }, 100);

    const confirmBtn = document.getElementById('confirmPinBtn');
    confirmBtn.onclick = function() {
        const coordStr = selectedMapLat.toFixed(4) + ', ' + selectedMapLng.toFixed(4);
        if(targetInputId === 'gpsInput') {
            document.getElementById('gpsInput').value = coordStr;
            reverseGeocode(selectedMapLat, selectedMapLng);
        } else {
            const target = document.getElementById(targetInputId);
            if(target) target.value = coordStr;
        }
        modal.style.display = 'none';
    };

    document.getElementById('closeMapModal').onclick = function() {
        modal.style.display = 'none';
    };
}

function updateModalCoordsText(lat, lng) {
    const out = document.getElementById('modalCoordsOutput');
    if(out) out.value = lat.toFixed(4) + ', ' + lng.toFixed(4);
}

function attachDynamicListeners() {
    document.querySelectorAll('.del-btn').forEach(btn => {
        btn.onclick = async function() {
            const id = parseInt(this.getAttribute('data-id'));
            if(!confirm('Delete transaction?')) return;
            await fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'delete_tx', payload: { id } })
            });
            loadData();
        };
    });

    document.querySelectorAll('.toggle-edit-btn').forEach(btn => {
        btn.onclick = function() {
            const id = this.getAttribute('data-id');
            const box = document.getElementById('edit_view_' + id);
            if(box) box.style.display = box.style.display === 'none' ? 'block' : 'none';
        };
    });

    document.querySelectorAll('.pick-map-edit-btn').forEach(btn => {
        btn.onclick = function() {
            const id = this.getAttribute('data-id');
            const gpsField = document.getElementById('edit_gps_' + id);
            openMapModal(gpsField ? gpsField.value : '', 'edit_gps_' + id);
        };
    });

    document.querySelectorAll('.clickable-gps').forEach(el => {
        el.onclick = function() {
            const gps = this.getAttribute('data-gps');
            openMapModal(gps, 'gpsInput');
        };
    });

    document.querySelectorAll('.save-edit-btn').forEach(btn => {
        btn.onclick = async function() {
            const id = parseInt(this.getAttribute('data-id'));
            const customer = document.getElementById('edit_cust_' + id).value.trim();
            const landmark = document.getElementById('edit_land_' + id).value.trim();
            const gps = document.getElementById('edit_gps_' + id).value.trim();
            const amount = document.getElementById('edit_amt_' + id).value;
            const cashCollected = document.getElementById('edit_cash_' + id).value;

            const res = await fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })
            });
            const json = await res.json();
            if(json.success) {
                alert('Transaction updated!');
                loadData();
            }
        };
    });

    document.querySelectorAll('.del-exp-btn').forEach(btn => {
        btn.onclick = async function() {
            const id = parseInt(this.getAttribute('data-id'));
            if(!confirm('Delete expense?')) return;
            await fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'delete_expense', payload: { id } })
            });
            loadData();
        };
    });

    document.querySelectorAll('.save-profile-btn').forEach(btn => {
        btn.onclick = async function() {
            const name = this.getAttribute('data-name');
            const b64 = this.getAttribute('data-b64');
            const phone = document.getElementById('phone_' + b64).value.trim();
            const notes = document.getElementById('notes_' + b64).value.trim();
            await fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'save_profile', payload: { customer: name, phone, notes } })
            });
            alert('Profile saved!');
            loadData();
        };
    });
}

document.addEventListener('DOMContentLoaded', () => {
    getGPS();
    if(document.getElementById('saleTimestampInput')) setDateTimeInputsToNow();
    loadData();

    const nowBtn = document.getElementById('nowBtn');
    if(nowBtn) nowBtn.onclick = setDateTimeInputsToNow;

    const openMapPickerBtn = document.getElementById('openMapPickerBtn');
    if(openMapPickerBtn) {
        openMapPickerBtn.onclick = function() {
            openMapModal(document.getElementById('gpsInput').value, 'gpsInput');
        };
    }

    document.querySelectorAll('.tab').forEach(t => {
        t.onclick = function() {
            document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
            document.querySelectorAll('.pane').forEach(x => x.classList.remove('active'));
            this.classList.add('active');
            document.getElementById('pane' + this.getAttribute('data-tab').charAt(0).toUpperCase() + this.getAttribute('data-tab').slice(1)).classList.add('active');
            loadData();
        };
    });

    document.querySelectorAll('.p-btn').forEach(b => {
        b.onclick = function() {
            document.querySelectorAll('.p-btn').forEach(x => x.classList.remove('active'));
            this.classList.add('active');
            document.getElementById('weightInput').value = this.getAttribute('data-w');
            document.getElementById('amountInput').value = this.getAttribute('data-p');
            document.getElementById('cashInput').value = this.getAttribute('data-p');
            calcBal();
        };
    });

    document.getElementById('custInput').oninput = function() { checkCustomer(this.value); };
    document.getElementById('amountInput').oninput = calcBal;
    document.getElementById('cashInput').oninput = calcBal;
    document.getElementById('gpsBtn').onclick = getGPS;

    const saveExpBtn = document.getElementById('saveExpBtn');
    if(saveExpBtn) {
        saveExpBtn.onclick = async function() {
            const category = document.getElementById('expCat').value.trim();
            const amount = document.getElementById('expAmount').value;
            const notes = document.getElementById('expNotes').value.trim();
            const expTsInput = document.getElementById('expTimestampInput');
            const customTimestamp = expTsInput ? expTsInput.value : null;
            if(!amount) { alert('Enter expense amount'); return; }

            const res = await fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'add_expense', payload: { category, amount, notes, customTimestamp } })
            });
            const json = await res.json();
            if(json.success) {
                document.getElementById('expCat').value = '';
                document.getElementById('expAmount').value = '';
                document.getElementById('expNotes').value = '';
                alert('Expense added!');
                loadData();
            }
        };
    }

    document.getElementById('saveBtn').onclick = async function() {
        const customer = document.getElementById('custInput').value.trim();
        const amount = document.getElementById('amountInput').value;
        const cashCollected = document.getElementById('cashInput').value;
        const weight = document.getElementById('weightInput').value;
        const landmark = document.getElementById('landmarkInput').value.trim();
        const gps = document.getElementById('gpsInput').value;
        const saleTsInput = document.getElementById('saleTimestampInput');
        const customTimestamp = saleTsInput ? saleTsInput.value : null;

        if(!customer) { alert('Enter customer name'); return; }
        if(!amount) { alert('Enter amount'); return; }

        const res = await fetch('/api/action', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                action: 'add_sale',
                payload: { customer, amount, cashCollected, item: (weight ? weight + 'g Unit' : 'Custom Unit'), landmark, gps, customTimestamp }
            })
        });
        const json = await res.json();
        if(json.success) {
            document.getElementById('custInput').value = '';
            document.getElementById('amountInput').value = '';
            document.getElementById('weightInput').value = '';
            document.getElementById('landmarkInput').value = '';
            document.getElementById('cashInput').value = '0';
            document.querySelectorAll('.p-btn').forEach(x => x.classList.remove('active'));
            const warn = document.getElementById('warnBal');
            if(warn) warn.style.display = 'none';
            getGPS();
            if(saleTsInput) setDateTimeInputsToNow();
            alert('Sale saved successfully!');
            document.querySelector('[data-tab="hist"]').click();
        }
    };
});
</script>
</body>
</html>`;

        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store, no-cache, must-validate' });
        res.end(htmlContent);
    };
}

// ==========================================
// START SERVERS ON PORTS (v1, v2, v3, v4)
// ==========================================
const PORT_V1 = 51201;
const PORT_V2 = 51202;
const PORT_V3 = 51203;
const PORT_V4 = 51204;

http.createServer(createAppHandler('v1')).listen(PORT_V1, '127.0.0.1', () => {
    console.log(`🚀 Version 1 running at: http://127.0.0.1:${PORT_V1}`);
});

http.createServer(createAppHandler('v2')).listen(PORT_V2, '127.0.0.1', () => {
    console.log(`⏳ Version 2 running at: http://127.0.0.1:${PORT_V2}`);
});

http.createServer(createAppHandler('v3')).listen(PORT_V3, '127.0.0.1', () => {
    console.log(`🗺️ Version 3 running at: http://127.0.0.1:${PORT_V3}`);
});

http.createServer(createAppHandler('v4')).listen(PORT_V4, '127.0.0.1', () => {
    console.log(`📍 Version 4 (Interactive Pin Picker) running at: http://127.0.0.1:${PORT_V4}`);
});

const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:${PORT_V5}`);
});
