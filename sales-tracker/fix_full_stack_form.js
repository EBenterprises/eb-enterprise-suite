const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's replace the entire sale form input area in server.js with a clean, fully stacked vertical layout matching the user's exact order:
// Customer Name -> Weight Presets -> Weight (g) -> Item Name -> Amount ($) -> Cash Collected ($) -> Landmark -> GPS Coordinates

const newFormHtml = `
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Customer Name</label>
    <input type="text" id="custInput" list="custOptions" placeholder="Enter name..." style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
    <datalist id="custOptions"></datalist>
</div>

<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Weight Presets</label>
    <div class="presets">
        <button type="button" onclick="setWeight(1.75)">1.75g</button>
        <button type="button" onclick="setWeight(3.5)">3.5g</button>
        <button type="button" onclick="setWeight(7)">7g</button>
        <button type="button" onclick="setWeight(14)">14g</button>
        <button type="button" onclick="setWeight(28)">28g</button>
    </div>
</div>

<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Weight (g)</label>
    <input type="number" id="weightInput" step="0.01" placeholder="Grams" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>

<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="e.g. Premium Item" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
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
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Nearest Landmark</label>
    <input type="text" id="landmarkInput" placeholder="Landmark or notes" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>

<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">GPS Location Stamp</label>
    <div style="display:flex; gap:6px; margin-bottom:4px;">
        <button type="button" id="openMapPickerBtn" style="background:#0284c7; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:10px; cursor:pointer; font-weight:bold;">🗺️ Pin on Map</button>
        <button type="button" onclick="refreshGps()" style="background:#334155; color:#fff; border:none; padding:4px 8px; border-radius:4px; font-size:10px; cursor:pointer;">🔄 Refresh GPS</button>
    </div>
    <input type="text" id="gpsInput" placeholder="Latitude, Longitude" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
`;

// Let's replace the split form layout between custInput and action buttons with newFormHtml
const startIndex = code.indexOf('<div style="margin-bottom:8px;">\n    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Customer Name</label>');
const endIndex = code.indexOf('<button onclick="recordSale()"');

if (startIndex !== -1 && endIndex !== -1) {
    code = code.substring(0, startIndex) + newFormHtml + "\n" + code.substring(endIndex);
    fs.writeFileSync(serverPath, code);
    console.log("[+] Successfully refactored sale form inputs to a clean vertical stack.");
} else {
    console.log("[-] Could not find exact form boundaries, trying alternative pattern match...");
}
