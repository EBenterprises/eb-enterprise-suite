const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's locate the side-by-side flex container for weightInput and amountInput/itemInput
// and rewrite it so they are stacked vertically: Weight (g) -> Item / Product Name -> Amount ($)

const oldSnippet = `<div style="display:flex; gap:6px;">
                <div style="flex:1;"><label>Weight (g)</label><input type="number" id="weightInput" placeholder="Grams"></div>
                <div style="flex:1;"><label>Amount ($)</label>
<div style="margin-bottom:10px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:4px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="e.g. Premium Item" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>

<input type="number" id="amountInput" placeholder="0.00"></div>
            </div>`;

const newSnippet = `<div style="margin-bottom:8px;">
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
</div>`;

if (code.includes('id="weightInput"')) {
    // Let's do a more robust regex or direct search/replace around weightInput & itemInput
    // First let's check if oldSnippet matches directly
    if (code.includes(oldSnippet)) {
        code = code.replace(oldSnippet, newSnippet);
        fs.writeFileSync(serverPath, code);
        console.log("[+] Successfully replaced side-by-side inputs with stacked layout.");
    } else {
        // Let's find the containing block dynamically
        console.log("[-] Exact snippet match not found, performing dynamic block replacement...");
        const wIdx = code.indexOf('id="weightInput"');
        // Find the parent div start before wIdx
        const divStart = code.lastIndexOf('<div', wIdx);
        // Find the div end after itemInput/amountInput
        const amountIdx = code.indexOf('id="amountInput"', wIdx);
        const divEnd = code.indexOf('</div>', amountIdx) + 6;
        
        if (divStart !== -1 && divEnd !== -1) {
            code = code.substring(0, divStart) + newSnippet + code.substring(divEnd);
            fs.writeFileSync(serverPath, code);
            console.log("[+] Successfully replaced dynamic input block with stacked layout.");
        } else {
            console.log("[-] Could not locate dynamic block boundaries.");
        }
    }
} else {
    console.log("[-] weightInput not found in server.js");
}
