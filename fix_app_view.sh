#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Upgrading index.html to display full operational dashboard instead of 404..."

cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Vault | EB Enterprises</title>
    <style>
        body { font-family: monospace; background: #0b0f19; color: #00ff66; margin: 0; padding: 2rem; }
        .container { max-width: 800px; margin: auto; border: 1px solid #00ff66; padding: 2rem; background: #111827; box-shadow: 0 0 20px rgba(0,255,102,0.1); }
        h1 { margin-top: 0; border-bottom: 1px dashed #00ff66; padding-bottom: 0.5rem; }
        .status { color: #38bdf8; font-weight: bold; }
        .card { background: #1f2937; border: 1px solid #374151; padding: 1rem; margin-top: 1rem; }
        code { background: #374151; padding: 0.2rem 0.4rem; color: #f3f4f6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>[+] EB Enterprises // Secure Vault</h1>
        <p>Operational Status: <span class="status">ACTIVE & SECURE</span></p>
        <p>Public Tunnel Node: <code>Online</code></p>
        
        <div class="card">
            <h3>System Modules</h3>
            <ul>
                <li>Multi-Remote Repository Sync: <code>Configured</code></li>
                <li>Local Daemon Watcher: <code>Running</code></li>
                <li>Zero-Dependency Architecture: <code>Enforced</code></li>
            </ul>
        </div>
    </div>
</body>
</html>
HTML

echo "[+] Dashboard updated successfully!"
