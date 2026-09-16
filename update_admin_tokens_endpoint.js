const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'cluster_server.js'), 'utf8');

if (!serverCode.includes('/api/admin/tokens')) {
    const adminTokensRoute = `
app.get('/api/admin/tokens', (req, res) => {
    const tokens = db.get('tokens') || {};
    res.json(tokens);
});
`;
    serverCode = serverCode.replace(
        `const PORT = process.env.PORT || 3000;`,
        adminTokensRoute + `\nconst PORT = process.env.PORT || 3000;`
    );
    fs.writeFileSync(path.join(__dirname, 'cluster_server.js'), serverCode);
    console.log("[SERVER PATCH] /api/admin/tokens endpoint successfully added.");
}
