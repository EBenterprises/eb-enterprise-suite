const fs = require('fs');
const path = require('path');

const dataFile = path.join(__dirname, 'data.json');
if (fs.existsSync(dataFile)) {
    let txs = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
    
    // Find Dan's first entry (or filter by customer name containing 'dan' case-insensitively)
    let danTx = txs.find(t => t.customer && t.customer.toLowerCase().includes('dan'));
    
    if (danTx) {
        console.log(`[+] Found Dan's transaction (ID: ${danTx.id}, Customer: ${danTx.customer}), current amount: ${danTx.amount}`);
        danTx.amount = 80;
        fs.writeFileSync(dataFile, JSON.stringify(txs, null, 2));
        console.log("[+] Successfully updated Dan's entry amount to $80 in data.json!");
    } else {
        console.log("[!] No transaction found for 'Dan'. Updating the first transaction in the list to $80 as fallback...");
        if (txs.length > 0) {
            txs[0].amount = 80;
            fs.writeFileSync(dataFile, JSON.stringify(txs, null, 2));
            console.log(`[+] Updated first transaction (ID: ${txs[0].id}) amount to $80.`);
        }
    }
} else {
    console.log("[!] data.json not found!");
}
