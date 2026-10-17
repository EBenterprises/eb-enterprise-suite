const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's update the preset click event listener script so that clicking a preset ONLY fills
// the weight and the amount ($), but leaves cash collected alone!
// Let's search for the .p-btn listener or setWeight function and ensure cashInput is untouched.

const targetListener = `
document.querySelectorAll('.p-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const w = btn.getAttribute('data-w');
        const p = btn.getAttribute('data-p');
        if(document.getElementById('weightInput')) document.getElementById('weightInput').value = w;
        if(document.getElementById('amountInput') && p) document.getElementById('amountInput').value = p;
        // Explicitly ensuring cashInput is NOT modified by presets
        if(typeof calcBal === 'function') calcBal();
    });
});
`;

// Let's replace any existing p-btn listener or setWeight preset logic
if (code.includes("document.querySelectorAll('.p-btn')")) {
    // Replace the block containing p-btn listener
    const startIdx = code.indexOf("document.querySelectorAll('.p-btn')");
    const endIdx = code.indexOf('});', startIdx) + 4;
    // Let's find a broader range if needed
    const blockStart = code.lastIndexOf('document.querySelectorAll', startIdx);
    const blockEnd = code.indexOf('});', startIdx) + 3;
    if (blockStart !== -1 && blockEnd !== -1) {
        code = code.substring(0, blockStart) + targetListener.trim() + code.substring(blockEnd);
        console.log("[+] Updated .p-btn listener to populate weight & amount without touching cash collected.");
    }
} else {
    // Inject before </script>
    const scriptClose = code.lastIndexOf('</script>');
    if (scriptClose !== -1) {
        code = code.substring(0, scriptClose) + "\n" + targetListener + "\n" + code.substring(scriptClose);
        console.log("[+] Injected .p-btn listener.");
    }
}

fs.writeFileSync(serverPath, code);
console.log("[+] server.js updated successfully.");
