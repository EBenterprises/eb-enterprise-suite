const fs = require('fs');
const path = require('path');

// 1. Update cluster_server.js to include a robust /api/checkout endpoint
let serverCode = fs.readFileSync(path.join(__dirname, 'cluster_server.js'), 'utf8');

if (!serverCode.includes('/api/checkout')) {
    const checkoutEndpoint = `
app.post('/api/checkout', (req, res) => {
    const { farmId, qty, paymentMethod } = req.body;
    const key = \`farm_\${farmId}\`;
    const farm = db.get(key);

    if (!farm) return res.status(404).json({ error: "Station not found" });
    if (farm.stock < qty) return res.status(400).json({ error: "Insufficient stock for instant purchase" });

    farm.stock -= Number(qty);
    db.put(key, farm);
    broadcast('STOCK_UPDATE', { farmId: farm.id, stock: farm.stock });

    const receiptId = 'EGG-' + Math.random().toString(36).substring(2, 8).toUpperCase();
    res.json({
        success: true,
        receiptId,
        farmName: farm.name,
        qty: Number(qty),
        totalPaid: Number(qty) * farm.price,
        remainingStock: farm.stock,
        timestamp: new Date().toISOString()
    });
});
`;

    serverCode = serverCode.replace(
        `const PORT = process.env.PORT || 3000;`,
        checkoutEndpoint + `\nconst PORT = process.env.PORT || 3000;`
    );

    fs.writeFileSync(path.join(__dirname, 'cluster_server.js'), serverCode);
    console.log("[SERVER PATCH] /api/checkout instant payment simulation endpoint successfully added.");
}
