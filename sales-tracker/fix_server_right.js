const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's inspect where the API endpoint parses actions or handles requests.
// We want to safely add an update_tx handler right inside the POST /api handler.
const updateHandler = `
    if (action === 'update_tx') {
        const txsFile = DATA_FILE || path.join(__dirname, 'data.json');
        let rawData = [];
        try {
            if (fs.existsSync(txsFile)) {
                let parsed = JSON.parse(fs.readFileSync(txsFile, 'utf8'));
                rawData = Array.isArray(parsed) ? parsed : (parsed.transactions || parsed.txs || []);
            }
        } catch (e) {}

        const targetId = Number(payload.id);
        const t = rawData.find(x => Number(x.id) === targetId);
        if (t) {
            t.customer = payload.customer !== undefined ? payload.customer : t.customer;
            t.landmark = payload.landmark !== undefined ? payload.landmark : t.landmark;
            t.amount = payload.amount !== undefined ? Number(payload.amount) : t.amount;
            t.cashCollected = payload.cashCollected !== undefined ? Number(payload.cashCollected) : t.cashCollected;
            if (t.balance !== undefined) {
                t.balance = Number(t.amount) - Number(t.cashCollected);
            }

            try {
                fs.writeFileSync(txsFile, JSON.stringify(rawData, null, 2));
            } catch (e) {}
            
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, tx: t }));
            return;
        }
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'Transaction not found' }));
        return;
    }
`;

// Insert after action is defined
if (code.includes("let action =") || code.includes("const action =")) {
    code = code.replace(
        /(let|const)\s+action\s*=\s*[^;]+;/i,
        match => match + '\n' + updateHandler
    );
    fs.writeFileSync(serverPath, code);
    console.log("[+] Successfully added update_tx handler to server.js");
} else {
    console.log("[!] Could not find action definition in server.js");
}
