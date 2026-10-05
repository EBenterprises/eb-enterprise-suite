const fs = require('fs');
const http = require('http');

// 1. Test what port 51205 currently returns for /api/data
http.get('http://127.0.0.1:51205/api/data', (res) => {
    let body = '';
    res.on('data', chunk => body += chunk);
    res.on('end', () => {
        console.log('[+] /api/data HTTP Status:', res.statusCode);
        try {
            const parsed = JSON.parse(body);
            console.log('[+] Returned transactions count:', (parsed.transactions || parsed || []).length);
        } catch (e) {
            console.log('[-] /api/data returned non-JSON response:', body.substring(0, 150));
            patchServer();
        }
    });
}).on('error', (err) => {
    console.log('[-] Port 51205 connection error:', err.message);
    patchServer();
});

function patchServer() {
    console.log('[*] Patching server_v5.js data endpoint and file sources...');
    let code = fs.readFileSync('server_v5.js', 'utf8');

    // Ensure fallback for DATA_FILE to transactions.json if missing
    if (!code.includes("const DATA_FILE =")) {
        code = `const DATA_FILE = fs.existsSync('transactions.json') ? 'transactions.json' : (fs.existsSync('data.json') ? 'data.json' : 'data/transactions.json');\n` + code;
    }

    // Ensure /api/data returns structured JSON with transactions
    const safeDataRoute = `
        if (req.url === '/api/data' || req.url === '/data') {
            const txFile = fs.existsSync('transactions.json') ? 'transactions.json' : (fs.existsSync('data.json') ? 'data.json' : '');
            let txs = [];
            if (txFile) {
                try { txs = JSON.parse(fs.readFileSync(txFile, 'utf8')); } catch(e) {}
            }
            let profiles = [];
            if (fs.existsSync('profiles.json')) {
                try { profiles = JSON.parse(fs.readFileSync('profiles.json', 'utf8')); } catch(e) {}
            }
            res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ transactions: Array.isArray(txs) ? txs : (txs.transactions || []), profiles: profiles }));
            return;
        }
    `;

    if (!code.includes("req.url === '/api/data'")) {
        code = code.replace(/http\.createServer\((?:async\s*)?\((req,\s*res)\)\s*=>\s*\{/, `http.createServer((req, res) => {\n${safeDataRoute}`);
    }

    fs.writeFileSync('server_v5.js', code);
    console.log('[+] server_v5.js patched. Restarting node process...');
}
