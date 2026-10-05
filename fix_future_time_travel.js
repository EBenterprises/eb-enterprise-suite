const fs = require('fs');
const path = require('path');

// 1. Fix Johnathon's future timestamp in transactions.json
const txPath = path.join(__dirname, 'transactions.json');
if (fs.existsSync(txPath)) {
    let txs = JSON.parse(fs.readFileSync(txPath, 'utf8'));
    const now = Date.now();
    
    txs.forEach(t => {
        if (t.timestamp > now || (t.id && t.id > now)) {
            console.log(`[!] Fixing future timestamp for transaction: ${t.customer} (${t.date})`);
            t.timestamp = now;
            t.id = now;
            // Format as YYYY-MM-DD HH:mm for October 1, 2026 current time
            t.date = "2026-10-01 02:46"; 
        }
    });

    txs.sort((a, b) => b.timestamp - a.timestamp);
    fs.writeFileSync(txPath, JSON.stringify(txs, null, 2));
    console.log("[+] transactions.json cleaned of future timestamps.");
}

// 2. Add validation in server.js to reject future dates
let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

const futureCheckCode = `
                                if (hasTimeMachine && payload.customTimestamp) {
                                    const customTs = new Date(payload.customTimestamp).getTime();
                                    if (customTs > Date.now()) {
                                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));
                                    }
                                    t.timestamp = customTs;
                                    t.id = customTs;
                                    t.date = payload.customTimestamp.replace('T', ' ');
                                }
`;

// Replace the timestamp assignment block with the future-check-enabled block
serverCode = serverCode.replace(
    /if \(hasTimeMachine && payload\.customTimestamp\) \{[\s\S]*?\}/,
    futureCheckCode.trim()
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] server.js updated to block future timestamp selection!");
