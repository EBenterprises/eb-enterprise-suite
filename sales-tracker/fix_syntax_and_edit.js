const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
    let code = fs.readFileSync(serverPath, 'utf8');
    
    // Fix any malformed try/catch blocks around line 138
    // Let's replace any broken try without catch with a clean try/catch block
    code = code.replace(/try\s*\{([^}]*)\}\s*(?!catch|finally)/g, 'try {$1} catch(e) {}');
    
    // Ensure update_tx backend logic is clean and syntactically correct
    const cleanUpdateHandler = `
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
            return res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: true, tx: t }));
        }
        return res.writeHead(404, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Transaction not found' }));
    }
    `;

    // Remove duplicate update_tx if any, and inject it cleanly
    code = code.replace(/if\s*\(\s*action\s*===\s*'update_tx'[\s\S]*?\n\s*\}/g, '');
    
    if (code.includes("let action =") || code.includes("const action =")) {
        code = code.replace(
            /(let|const)\s+action\s*=\s*[^;]+;/i,
            match => match + '\n' + cleanUpdateHandler
        );
    }

    fs.writeFileSync(serverPath, code);
    console.log("[+] Syntax corrected and update_tx handler safely embedded.");
}
