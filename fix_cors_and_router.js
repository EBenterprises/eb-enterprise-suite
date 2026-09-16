const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'cluster_server.js'), 'utf8');

// Ensure CORS headers and JSON parsing are present
if (!serverCode.includes('res.setHeader(\'Access-Control-Allow-Origin\'')) {
    const corsMiddleware = `
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});
app.use(express.json());
`;
    serverCode = serverCode.replace('const app = express();', 'const app = express();\n' + corsMiddleware);
    fs.writeFileSync(path.join(__dirname, 'cluster_server.js'), serverCode);
    console.log("[SERVER PATCH] Global CORS middleware and body parser added.");
}
