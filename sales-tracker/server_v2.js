const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = 51202;
const DATA_FILE = path.join(__dirname, 'transactions.json');

http.createServer((req, res) => {
    if (req.url === '/api/data' || req.url === '/data') {
        const data = fs.existsSync(DATA_FILE) ? JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')) : [];
        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        return res.end(JSON.stringify({ version: 2, transactions: data }));
    }
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`<h1>EB Sales Tracker V2 Legacy Node</h1><p>Running on port ${PORT}</p>`);
}).listen(PORT, '127.0.0.1', () => console.log(`V2 active on port ${PORT}`));
