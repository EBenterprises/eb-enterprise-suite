const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's restore the original compact preset buttons and side-by-side weight/amount input layout,
// while updating only the preset weights & prices to:
// 1.75g ($30), 3.5g ($50), 7g ($100), 14g ($150), 28g ($300).

// Let's search for where presets are rendered and replace them with the exact original styling classes (e.g. class="p-btn" data-w="..." data-p="...")
// And let's update the JS event listener or button click handler that populates weight and amount.

const originalPresetBlock = `
            <div class="presets">
                <button class="p-btn" data-w="1.75" data-p="30">1.75g</button>
                <button class="p-btn" data-w="3.5" data-p="50">3.5g</button>
                <button class="p-btn" data-w="7" data-p="100">7g</button>
                <button class="p-btn" data-w="14" data-p="150">14g</button>
                <button class="p-btn" data-w="28" data-p="300">28g</button>
            </div>
`;

// Let's find where `<div class="presets">` is in server.js and replace it
const pIdx = code.indexOf('class="presets"');
if (pIdx !== -1) {
    const divStart = code.lastIndexOf('<div', pIdx);
    const divEnd = code.indexOf('</div>', pIdx) + 6;
    if (divStart !== -1 && divEnd !== -1) {
        code = code.substring(0, divStart) + originalPresetBlock + code.substring(divEnd);
        console.log("[+] Restored original preset buttons aesthetic with updated $30, $50, $100, $150, $300 values.");
    }
}

// Also let's ensure the side-by-side weight & amount input layout is restored if it was split
// Original layout had weightInput and amountInput side by side in flex:
const sideBySideInputs = `
            <div style="display:flex; gap:6px;">
                <div style="flex:1;"><label>Weight (g)</label><input type="number" id="weightInput" placeholder="Grams" step="0.01"></div>
                <div style="flex:1;"><label>Amount ($)</label><input type="number" id="amountInput" placeholder="0.00" step="0.01" oninput="calcBal()"></div>
            </div>
`;

// Let's check if we have itemInput and weightInput separate and merge them back to the original layout,
// putting itemInput right below or where appropriate, or keeping weight and amount side-by-side as it was originally.
// Let's check where weightInput and amountInput are.
const wIn = code.indexOf('id="weightInput"');
if (wIn !== -1) {
    // Let's find the enclosing div of weightInput and replace with side-by-side if requested, or keep original structure
    // Actually, let's look for how .p-btn click listener is set up in client JS script to auto-fill amount from data-p attribute.
}

// Let's update or inject the standard p-btn event listener script that auto-fills both weight and amount from data-w and data-p:
const pListenerSnippet = `
document.querySelectorAll('.p-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const w = btn.getAttribute('data-w');
        const p = btn.getAttribute('data-p');
        if(document.getElementById('weightInput')) document.getElementById('weightInput').value = w;
        if(document.getElementById('amountInput') && p) document.getElementById('amountInput').value = p;
        if(typeof calcBal === 'function') calcBal();
    });
});
`;

if (code.includes("document.querySelectorAll('.p-btn')")) {
    // Already has listener logic
    console.log("[+] Preset button listeners already present.");
} else {
    // Inject before closing </script>
    const scriptClose = code.lastIndexOf('</script>');
    if (scriptClose !== -1) {
        code = code.substring(0, scriptClose) + pListenerSnippet + "\n" + code.substring(scriptClose);
        console.log("[+] Injected p-btn click handler script.");
    }
}

fs.writeFileSync(serverPath, code);
console.log("[+] server.js updated successfully.");
