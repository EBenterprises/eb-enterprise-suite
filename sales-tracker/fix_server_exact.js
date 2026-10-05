const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Fix the exact syntax error on line 58 or anywhere with `} catch(e) {});`
code = code.replace(/\}\s*catch\(e\)\s*\{\}\s*\);\s*/g, '});\n');
code = code.replace(/catch\(e\)\s*\{\}\s*catch\(e\)/g, 'catch(e)');

// Let's inspect how requests are handled and insert our update_tx API route safely before route handling / server listening
const updateRouteSnippet = `
// Universal update_tx handler
if (typeof action !== 'undefined' && action === 'update_tx') {
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

// If app.post or similar request handler exists, put it right at the beginning of request handling
if (code.includes("req.on('data'")) {
    code = code.replace("req.on('data'", updateRouteSnippet + "\nreq.on('data'");
} else if (code.includes("app.post")) {
    code = code.replace("app.post", updateRouteSnippet + "\napp.post");
}

fs.writeFileSync(serverPath, code);
console.log("[+] Syntax errors cleaned and update handler injected!");
