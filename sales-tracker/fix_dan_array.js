const fs = require('fs');
const path = require('path');

const dataFile = path.join(__dirname, 'data.json');
if (fs.existsSync(dataFile)) {
    let raw = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
    let txs = Array.isArray(raw) ? raw : (raw.transactions || raw.txs || Object.values(raw));
    
    if (Array.isArray(txs)) {
        let danTx = txs.find(t => t && t.customer && String(t.customer).toLowerCase().includes('dan'));
        if (danTx) {
            danTx.amount = 80;
            console.log(`[+] Updated Dan's entry (ID: ${danTx.id}, Customer: ${danTx.customer}) to $80.`);
        } else if (txs.length > 0) {
            txs[0].amount = 80;
            console.log(`[+] Updated first transaction (ID: ${txs[0].id}) to $80.`);
        }
        fs.writeFileSync(dataFile, JSON.stringify(txs, null, 2));
        console.log("[+] data.json successfully saved!");
    } else {
        console.log("[!] Could not parse transactions array from data.json format.");
    }
} else {
    console.log("[!] data.json not found!");
}
