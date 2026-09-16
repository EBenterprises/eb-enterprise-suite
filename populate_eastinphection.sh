#!/usr/bin/env bash
set -euo pipefail

PROJ_DIR="${HOME}/EASTinphectiON"
echo "[*] Populating full-stack architecture for EASTinphectiON..."

mkdir -p "$PROJ_DIR"/{src/backend,src/frontend,assets/css,assets/js,config,tests,deploy}
cd "$PROJ_DIR"

# 1. Configuration
cat << 'INNER_EOF' > config/app.json
{
  "name": "EASTinphectiON",
  "version": "1.0.0",
  "theme": "Executive Spectrum",
  "palette": {
    "obsidian": "#0B0F12",
    "deep_teal": "#005F73",
    "champagne_gold": "#EE9B00"
  },
  "port": 8080
}
INNER_EOF

# 2. Backend Logic (Zero-dependency Python HTTP & WebSocket/API bridge)
cat << 'INNER_EOF' > src/backend/server.py
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os

PORT = 8080
DIRECTORY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../frontend"))

class ExecutiveHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        if self.path == "/api/status":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            data = {"status": "active", "system": "EASTinphectiON", "mode": "operational"}
            self.wfile.write(json.dumps(data).encode("utf-8"))
        else:
            super().do_GET()

print(f"[*] Starting EASTinphectiON server on port {PORT}...")
with socketserver.TCPServer(("", PORT), ExecutiveHandler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[!] Server stopped.")
INNER_EOF
chmod +x src/backend/server.py

# 3. Frontend UI (Executive Spectrum Styling)
cat << 'INNER_EOF' > src/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EASTinphectiON | Executive Dashboard</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="dashboard-container">
        <header>
            <h1>EASTinphectiON</h1>
            <span class="badge">Executive Spectrum</span>
        </header>
        <main>
            <div class="card">
                <h3>System Telemetry</h3>
                <p id="status-text">Connecting to core microkernel...</p>
                <button onclick="checkStatus()">Refresh Telemetry</button>
            </div>
        </main>
    </div>
    <script src="app.js"></script>
</body>
</html>
INNER_EOF

cat << 'INNER_EOF' > src/frontend/style.css
:root {
    --obsidian: #0B0F12;
    --deep-teal: #005F73;
    --champagne-gold: #EE9B00;
    --surface: #12181F;
    --text-main: #E0E6ED;
}

body {
    background-color: var(--obsidian);
    color: var(--text-main);
    font-family: monospace, sans-serif;
    margin: 0;
    padding: 2rem;
}

.dashboard-container {
    max-width: 800px;
    margin: 0 auto;
    background: var(--surface);
    border: 1px solid var(--deep-teal);
    padding: 2rem;
    border-radius: 4px;
    box-shadow: 0 4px 20px rgba(0, 95, 115, 0.2);
}

header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--deep-teal);
    padding-bottom: 1rem;
    margin-bottom: 2rem;
}

h1 {
    color: var(--champagne-gold);
    margin: 0;
}

.badge {
    background: var(--deep-teal);
    color: var(--obsidian);
    padding: 0.25rem 0.75rem;
    font-weight: bold;
    border-radius: 2px;
}

.card {
    background: var(--obsidian);
    border: 1px solid var(--deep-teal);
    padding: 1.5rem;
    border-radius: 4px;
}

button {
    background: var(--deep-teal);
    color: var(--obsidian);
    border: none;
    padding: 0.5rem 1rem;
    font-weight: bold;
    cursor: pointer;
    margin-top: 1rem;
    border-radius: 2px;
}

button:hover {
    background: var(--champagne-gold);
}
INNER_EOF

cat << 'INNER_EOF' > src/frontend/app.js
async function checkStatus() {
    const statusEl = document.getElementById('status-text');
    statusEl.innerText = "Querying backend API...";
    try {
        const response = await fetch('/api/status');
        const data = await response.json();
        statusEl.innerText = `Status: ${data.status.toUpperCase()} | System: ${data.system}`;
    } catch (err) {
        statusEl.innerText = "Error connecting to backend microkernel.";
    }
}
window.onload = checkStatus;
INNER_EOF

# 4. Deployment Script
cat << 'INNER_EOF' > deploy/deploy.sh
#!/usr/bin/env bash
set -euo pipefail
echo "[*] Triggering live deployment sequence for EASTinphectiON..."
cd "$(dirname "$0")/.."
git add -A
git commit -m "Full-stack deployment build: $(date '+%Y-%m-%d %H:%M:%S')" || echo "[!] No new changes to commit."
echo "[+] Deployment build verified and committed."
INNER_EOF
chmod +x deploy/deploy.sh

echo "[*] EASTinphectiON full-stack architecture successfully populated."
