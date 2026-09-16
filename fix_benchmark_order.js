const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'cluster_server.js'), 'utf8');

if (!serverCode.includes("app.post('/api/order'")) {
    const orderEndpoint = `
app.post('/api/order', (req, res) => {
    const { farmId, qty } = req.body;
    const key = \`farm_\${farmId || 1}\`;
    let farm = db.get(key);
    
    if (!farm) {
        farm = { id: 1, name: 'Default Valley Farm', stock: 100, price: 7.50, lat: 49.8820, lng: -119.5900 };
    }
    
    const orderQty = qty || 1;
    if (farm.stock < orderQty) {
        return res.status(400).json({ error: "Insufficient stock" });
    }
    
    farm.stock -= orderQty;
    db.put(key, farm);
    if (typeof broadcast === 'function') {
        broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });
    }
    
    res.json({ success: true, remainingStock: farm.stock });
});
`;
    serverCode = serverCode.replace(
        `const PORT = process.env.PORT || 3000;`,
        orderEndpoint + `\nconst PORT = process.env.PORT || 3000;`
    );
    fs.writeFileSync(path.join(__dirname, 'cluster_server.js'), serverCode);
    console.log("[SERVER PATCH] /api/order endpoint explicitly added to cluster server.");
}
