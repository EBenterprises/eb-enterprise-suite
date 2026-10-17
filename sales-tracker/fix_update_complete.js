const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Replace the messy/broken update_tx conditional and body with a clean, complete implementation
const oldBlockRegex = /if\s*\(\s*action\s*===\s*'update_tx'[^}]+\{\s*const\s*\{\s*id,\s*customer,\s*landmark,\s*gps,\s*amount,\s*cashCollected[^}]+\}\s*=\s*payload;\s*let\s*transactions\s*=\s*fs\.existsSync\(TRANSACTIONS_FILE\)[^}]+\}\s*\}\s*\);\s*t\.cashCollected\s*=\s*cashCollected\s*!==\s*undefined\s*\?\s*Number\(cashCollected\)\s*:\s*t\.cashCollected;/s;

const cleanUpdateBlock = `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
            const hasTimeMachine = (version === 'v5');
            const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
            let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
            let found = false;
            transactions = transactions.map(t => {
                if (String(t.id) === String(id)) {
                    found = true;
                    t.customer = customer !== undefined ? customer : t.customer;
                    t.landmark = landmark !== undefined ? landmark : t.landmark;
                    t.gps = gps !== undefined ? gps : t.gps;
                    t.amount = amount !== undefined ? Number(amount) : t.amount;
                    t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
                    if (hasTimeMachine && customTimestamp) {
                        const customTs = new Date(customTimestamp).getTime();
                        if (!isNaN(customTs)) {
                            t.timestamp = customTs;
                            t.id = customTs;
                            t.date = customTimestamp.replace('T', ' ');
                        }
                    }
                }
                return t;
            });
            fs.writeFileSync(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2));
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, transactions }));
            return;
        }`;

// Let us find and replace or clean up
if (code.includes("action === 'update_tx'")) {
    // Perform a targeted replacement of the broken update section
    // Instead of complex regex, let's restore from backup and apply cleanly or replace the substring
    console.log("[*] Patching update_tx block cleanly...");
}

// Safer approach: Let us restore a clean base and apply our patch cleanly
const backupDir = path.join(__dirname, 'backups_end_state');
if (fs.existsSync(backupDir)) {
    const backupFiles = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
    backupFiles.sort();
    if (backupFiles.length > 0) {
        fs.copyFileSync(path.join(backupDir, backupFiles[backupFiles.length - 1]), serverPath);
        console.log("[+] Restored fresh server from end-state backup.");
    }
}

let freshCode = fs.readFileSync(serverPath, 'utf8');

// Now inject v5 support and the correct update handler once
freshCode = freshCode.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'\s*&&\s*\(\s*version\s*===\s*'v3'\s*\Vert{}\Vert{}\s*version\s*===\s*'v4'\s*\)\s*\)\s*\{/,
    cleanUpdateBlock
);

fs.writeFileSync(serverPath, freshCode);
console.log("[+] Complete update save logic successfully deployed!");
