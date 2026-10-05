const fs = require('fs');
const path = require('path');

// Let's inspect server.js to see how edit/save transactions are handled
const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
    let serverCode = fs.readFileSync(serverPath, 'utf8');
    console.log("[*] Server.js read successfully.");
    
    // Check if there is an update / edit endpoint
    // Let's add or patch an explicit PUT/POST endpoint for updating transactions by id
    const updateEndpointCode = `
// Added or ensured robust update endpoint
app.post('/api/transactions/update', (express.json()), (req, res) => {
    try {
        const updatedTx = req.body;
        const dataFile = path.join(__dirname, 'data.json');
        if (!fs.existsSync(dataFile)) return res.status(404).json({ error: 'Data file not found' });
        
        let raw = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
        let txs = Array.isArray(raw) ? raw : (raw.transactions || raw.txs || null);
        
        if (Array.isArray(txs)) {
            let index = txs.findIndex(t => String(t.id) === String(updatedTx.id));
            if (index !== -1) {
                txs[index] = { ...txs[index], ...updatedTx };
            } else {
                txs.push(updatedTx);
            }
            
            if (Array.isArray(raw)) {
                fs.writeFileSync(dataFile, JSON.stringify(txs, null, 2));
            } else {
                raw.transactions = txs;
                fs.writeFileSync(dataFile, JSON.stringify(raw, null, 2));
            }
            return res.json({ success: true, transactions: txs });
        }
        res.status(400).json({ error: 'Invalid data format' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
`;

    if (!serverCode.includes('/api/transactions/update')) {
        // Insert right before app.listen
        serverCode = serverCode.replace('app.listen', updateEndpointCode + '\n\napp.listen');
        fs.writeFileSync(serverPath, serverCode);
        console.log("[+] Added /api/transactions/update endpoint to server.js");
    }
}

// Also check public/index.js or frontend script for edit form submission handler
const publicDir = path.join(__dirname, 'public');
if (fs.existsSync(publicDir)) {
    const files = fs.readdirSync(publicDir);
    files.forEach(file => {
        if (file.endsWith('.js')) {
            const jsPath = path.join(publicDir, file);
            let code = fs.readFileSync(jsPath, 'utf8');
            
            // Check how edit saves are currently structured
            // Make sure any edit submit calls fetch('/api/transactions/update', ...) or correctly updates the backend
            console.log(`[*] Checked frontend script: ${file}`);
        }
    });
}
