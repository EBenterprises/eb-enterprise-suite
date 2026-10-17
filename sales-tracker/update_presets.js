const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

const newPresetsHtml = `
<div class="presets" style="display:flex; gap:6px; flex-wrap:wrap; margin-bottom:8px;">
    <button type="button" onclick="setWeight(1.75, 30)" style="flex:1; padding:6px; background:#1e293b; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:11px; cursor:pointer;">1.75g ($30)</button>
    <button type="button" onclick="setWeight(3.5, 50)" style="flex:1; padding:6px; background:#1e293b; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:11px; cursor:pointer;">3.5g ($50)</button>
    <button type="button" onclick="setWeight(7, 100)" style="flex:1; padding:6px; background:#1e293b; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:11px; cursor:pointer;">7g ($100)</button>
    <button type="button" onclick="setWeight(14, 150)" style="flex:1; padding:6px; background:#1e293b; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:11px; cursor:pointer;">14g ($150)</button>
    <button type="button" onclick="setWeight(28, 300)" style="flex:1; padding:6px; background:#1e293b; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:11px; cursor:pointer;">28g ($300)</button>
</div>
`;

const pStart = code.indexOf('Weight Presets');
if (pStart !== -1) {
    const divPresStart = code.lastIndexOf('<div', pStart);
    const divPresEnd = code.indexOf('</div>', code.indexOf('class="presets"', pStart)) + 6;
    if (divPresStart !== -1 && divPresEnd !== -1) {
        code = code.substring(0, divPresStart) + `<div style="margin-bottom:8px;">\n    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:2px;">Weight Presets</label>\n` + newPresetsHtml + `\n</div>` + code.substring(divPresEnd);
        fs.writeFileSync(serverPath, code);
        console.log("[+] Successfully updated presets HTML in server.js.");
    } else {
        console.log("[-] Could not locate preset container boundaries.");
    }
} else {
    console.log("[-] 'Weight Presets' label not found in server.js.");
}

const newSetWeightFunc = `function setWeight(w, p) {
    document.getElementById('weightInput').value = w;
    if (p !== undefined) {
        document.getElementById('amountInput').value = p;
        if (typeof calcBal === 'function') calcBal();
    }
}`;

if (code.includes('function setWeight')) {
    code = code.replace(/function\s+setWeight\s*\([^)]*\)\s*\{[^}]*\}/, newSetWeightFunc);
    fs.writeFileSync(serverPath, code);
    console.log("[+] Successfully updated setWeight JavaScript function.");
} else {
    const scriptIdx = code.indexOf('<script>');
    if (scriptIdx !== -1) {
        code = code.slice(0, scriptIdx + 8) + `\n` + newSetWeightFunc + `\n` + code.slice(scriptIdx + 8);
        fs.writeFileSync(serverPath, code);
        console.log("[+] Injected setWeight function.");
    }
}
