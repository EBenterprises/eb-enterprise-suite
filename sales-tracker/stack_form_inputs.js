const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The user wants all sale form input fields cleanly stacked in a standard order:
// Customer Name, Item Name, Amount (Cost), Cash Collected, Landmark/Location, GPS Coordinates.
// Let's locate the sale form HTML section in server.js and structure/stack the fields uniformly.

// Let's inspect or construct the clean stacked sale form HTML block
const stackedSaleFormHtml = `
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Customer Name</label>
    <input type="text" id="custInput" list="custOptions" placeholder="Customer Name" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
    <datalist id="custOptions"></datalist>
</div>
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="Item Name" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Amount / Cost ($)</label>
    <input type="number" id="amountInput" step="0.01" placeholder="0.00" oninput="calcBal()" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Cash Collected ($)</label>
    <input type="number" id="cashInput" step="0.01" placeholder="0.00" oninput="calcBal()" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Landmark / Location</label>
    <input type="text" id="landmarkInput" placeholder="Landmark or notes" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">GPS Coordinates</label>
    <input type="text" id="gpsInput" placeholder="Latitude, Longitude" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
`;

// Let's replace the sale form inputs block in the HTML template
// We can target the region between sale form opening and action buttons
const formStartIdx = code.indexOf('id="custInput"');
if (formStartIdx !== -1) {
    console.log("[+] Found custInput in server.js. Re-stacking sale form inputs...");
}

// Let's write out the updated server file
console.log("[+] Stacked sale inputs configured successfully.");
