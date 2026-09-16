const fs = require('fs');
const path = require('path');

// Read cluster_server.js and inject secure producer token routes & management links
let serverCode = fs.readFileSync(path.join(__dirname, 'cluster_server.js'), 'utf8');

if (!serverCode.includes('/api/producer/:token')) {
    const tokenRouteSnippet = `
// --- Unique Producer Token Management ---
if (!db.get('tokens')) {
    db.put('tokens', {
        'token_ridgeview_99a': { farmId: 1 }
    });
}

app.get('/manage/:token', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'producer.html'));
});

app.get('/api/producer/:token', (req, res) => {
    const tokens = db.get('tokens') || {};
    const mapping = tokens[req.params.token];
    if (!mapping) return res.status(403).json({ error: "Invalid producer token" });
    const farm = db.get(\`farm_\${mapping.farmId}\`);
    if (!farm) return res.status(404).json({ error: "Station not found" });
    res.json({ farm, token: req.params.token });
});

app.post('/api/producer/:token/stock', (req, res) => {
    const tokens = db.get('tokens') || {};
    const mapping = tokens[req.params.token];
    if (!mapping) return res.status(403).json({ error: "Invalid producer token" });
    
    const { stock } = req.body;
    const key = \`farm_\${mapping.farmId}\`;
    const farm = db.get(key);
    if (!farm) return res.status(404).json({ error: "Station not found" });

    farm.stock = Number(stock);
    db.put(key, farm);
    broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });
    res.json({ success: true, farmId: farm.id, stock: farm.stock });
});

// Automatically generate unique management tokens when new farms register
const originalAdminFarmHandler = app._router.stack.filter(r => r.route && r.route.path === '/api/admin/farms');
`;

    // Append token mapping logic into farm creation
    serverCode = serverCode.replace(
        `db.put(\`farm_\${id}\`, newFarm);`,
        `db.put(\`farm_\${id}\`, newFarm);
        const tokens = db.get('tokens') || {};
        const newToken = 'token_' + name.toLowerCase().replace(/[^a-z0-9]/g, '') + '_' + Math.random().toString(36.substring(2, 8));
        tokens[newToken] = { farmId: id };
        db.put('tokens', tokens);
        console.log(\`[PRODUCER LINK] Generated management portal for '\${name}': http://localhost:3000/manage/\${newToken}\`);`
    );

    // Insert endpoints before server listen
    serverCode = serverCode.replace(
        `const PORT = process.env.PORT || 3000;`,
        tokenRouteSnippet + `\nconst PORT = process.env.PORT || 3000;`
    );

    fs.writeFileSync(path.join(__dirname, 'cluster_server.js'), serverCode);
    console.log("[SERVER PATCH] Unique producer token management routes successfully embedded into cluster server.");
}
