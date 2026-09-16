#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Classic Enterprise HTML/CSS/JS App Deployment
# ==============================================================================
set -e

echo "[+] Initializing clean classic project structure..."
mkdir -p public

echo "[+] Writing Classic Executive Spectrum Stylesheet..."
cat << 'CSS_EOF' > public/style.css
/* ==============================================================================
   CLASSIC EXECUTIVE SPECTRUM THEME
   ============================================================================== */
body {
    background-color: #0b0f19;
    color: #f8fafc;
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    background: #131b2e;
    border: 1px solid #27354f;
    padding: 30px;
    border-radius: 8px;
}

h1 {
    color: #d4af37;
    text-align: center;
}

.card {
    background: #182239;
    border: 1px solid #27354f;
    padding: 20px;
    margin-top: 20px;
    border-radius: 6px;
}

label {
    display: block;
    color: #94a3b8;
    margin-bottom: 5px;
    font-size: 0.9rem;
}

input, select {
    width: 100%;
    padding: 10px;
    background: #0b0f19;
    border: 1px solid #27354f;
    color: #f8fafc;
    margin-bottom: 15px;
    border-radius: 4px;
}

button {
    background: #00d2c4;
    color: #0b0f19;
    border: none;
    padding: 12px 20px;
    font-weight: bold;
    cursor: pointer;
    width: 100%;
    border-radius: 4px;
    text-transform: uppercase;
}

button:hover {
    background: #00b3a6;
}

#output {
    margin-top: 15px;
    padding: 10px;
    display: none;
    border-radius: 4px;
    text-align: center;
    font-weight: bold;
}
CSS_EOF

echo "[+] Writing Classic Client Logic..."
cat << 'JS_EOF' > public/app.js
function handleClassicSubmit(e) {
    e.preventDefault();
    var email = document.getElementById('email').value;
    var pass = document.getElementById('password').value;
    var out = document.getElementById('output');

    out.style.display = 'block';
    if (email && pass) {
        out.style.background = 'rgba(34, 197, 94, 0.2)';
        out.style.color = '#22c55e';
        out.style.border = '1px solid #22c55e';
        out.innerText = 'Success: Classic Enterprise Session Authenticated for ' + email;
    } else {
        out.style.background = 'rgba(239, 68, 68, 0.2)';
        out.style.color = '#ef4444';
        out.style.border = '1px solid #ef4444';
        out.innerText = 'Error: Missing Required Credentials';
    }
}
JS_EOF

echo "[+] Writing Classic HTML Structure..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>EB Enterprises - Classic Enterprise Terminal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>EB ENTERPRISES</h1>
        <p style="text-align: center; color: #94a3b8;">Classic Multi-Tier Enterprise Client</p>
        
        <div class="card">
            <form onsubmit="handleClassicSubmit(event)">
                <label>Operator Email</label>
                <input type="email" id="email" placeholder="operator@eb.enterprise" required>
                
                <label>Security Key / Password</label>
                <input type="password" id="password" placeholder="••••••••" required>
                
                <button type="submit">Authenticate Session</button>
            </form>
            <div id="output"></div>
        </div>
    </div>
    <script src="app.js"></script>
</body>
</html>
HTML_EOF

# Sync to root
cp public/index.html ./index.html
cp public/style.css ./style.css
cp public/app.js ./app.js

echo "[+] Writing Classic Node.js Server..."
cat << 'SRV_EOF' > server.js
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 5000;

const server = http.createServer((req, res) => {
    let filePath = path.join(__dirname, 'public', req.url === '/' ? 'index.html' : req.url);
    let extname = String(path.extname(filePath)).toLowerCase();
    
    let mimeTypes = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'text/javascript'
    };

    let contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            if(err.code == 'ENOENT') {
                fs.readFile(path.join(__dirname, 'public', 'index.html'), (err2, content2) => {
                    res.writeHead(200, { 'Content-Type': 'text/html' });
                    res.end(content2, 'utf-8');
                });
            } else {
                res.writeHead(500);
                res.end('Server Error: '+err.code);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, () => {
    console.log('Classic Enterprise Server running on port ' + PORT);
});
SRV_EOF

echo "[+] Launching Classic Server..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 nohup node server.js > server.log 2>&1 &
echo "[+] Classic deployment active on port 5000."
