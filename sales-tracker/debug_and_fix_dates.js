const fs = require('fs');
const path = require('path');

const txPath = path.join(__dirname, 'transactions.json');
if (fs.existsSync(txPath)) {
    let txs = JSON.parse(fs.readFileSync(txPath, 'utf8'));
    console.log("--- RAW TRANSACTIONS IN STORAGE ---");
    txs.forEach((t, i) => {
        console.log(`[${i}] ID: ${t.id} | Date: "${t.date}" | Customer: ${t.customer} | Timestamp: ${t.timestamp}`);
    });

    // Force recalculate and sort numerical epoch descending
    txs.forEach(t => {
        if (t.date) {
            // Clean up date string if needed and parse
            const normalized = t.date.replace(' ', 'T');
            const parsed = new Date(normalized).getTime();
            if (!isNaN(parsed)) {
                t.timestamp = parsed;
            }
        }
        if (!t.timestamp) {
            t.timestamp = t.id || Date.now();
        }
    });

    txs.sort((a, b) => b.timestamp - a.timestamp);
    fs.writeFileSync(txPath, JSON.stringify(txs, null, 2));
    console.log("\n[+] transactions.json re-sorted and saved successfully by true epoch timestamp!");
} else {
    console.log("[-] transactions.json not found.");
}
