#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Portrait & Landscape Responsive Engine
# ==============================================================================
set -e

echo "[+] Updating directory structure..."
mkdir -p public

echo "[+] Generating Portrait & Landscape Optimized Stylesheet..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-obsidian: #0b0f19;
    --surface-dark: #131b2e;
    --surface-card: #182239;
    --border-color: #27354f;
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-hover: #00b3a6;
    --highlight-gold: #d4af37;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

body {
    background-color: var(--bg-obsidian);
    color: var(--text-main);
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 1rem;
    overflow-y: auto;
}

.container {
    width: 100%;
    max-width: 520px;
    background: var(--surface-dark);
    border: 1px solid var(--border-color);
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.6);
    transition: all 0.3s ease;
}

h1 {
    color: var(--highlight-gold);
    text-align: center;
    font-size: 1.5rem;
    margin-bottom: 0.25rem;
}

.subtitle {
    text-align: center;
    color: var(--text-muted);
    font-size: 0.85rem;
    margin-bottom: 1.25rem;
}

.card {
    background: var(--surface-card);
    border: 1px solid var(--border-color);
    padding: 1.25rem;
    border-radius: 8px;
}

label {
    display: block;
    color: var(--text-muted);
    margin-bottom: 0.35rem;
    font-size: 0.8rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

input {
    width: 100%;
    padding: 0.7rem;
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    margin-bottom: 1rem;
    border-radius: 6px;
    font-size: 0.95rem;
    outline: none;
}

input:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px rgba(0, 210, 196, 0.15);
}

button {
    background: var(--accent-teal);
    color: var(--bg-obsidian);
    border: none;
    padding: 0.8rem;
    font-weight: bold;
    cursor: pointer;
    width: 100%;
    border-radius: 6px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 0.9rem;
    transition: background 0.2s;
}

button:hover {
    background: var(--accent-teal-hover);
}

#output {
    margin-top: 1rem;
    padding: 0.75rem;
    display: none;
    border-radius: 6px;
    text-align: center;
    font-weight: 600;
    font-size: 0.85rem;
}

/* ==============================================================================
   ORIENTATION & VIEWPORT ADAPTATION RULES
   ============================================================================== */

/* Mobile Landscape Adjustments (Prevent vertical squishing) */
@media (max-height: 550px) and (orientation: landscape) {
    body {
        align-items: flex-start;
        padding: 0.5rem;
    }
    .container {
        max-width: 650px;
        padding: 1rem;
    }
    h1 {
        font-size: 1.25rem;
        margin-bottom: 0.1rem;
    }
    .subtitle {
        margin-bottom: 0.75rem;
    }
    .card {
        padding: 1rem;
    }
    input {
        margin-bottom: 0.5rem;
        padding: 0.5rem;
    }
}

/* Tablet & Desktop Landscape */
@media (min-width: 768px) and (orientation: landscape) {
    .container {
        max-width: 600px;
        padding: 2.5rem;
    }
    h1 {
        font-size: 2rem;
    }
    .subtitle {
        font-size: 0.95rem;
        margin-bottom: 1.75rem;
    }
    .card {
        padding: 2rem;
    }
}
CSS_EOF
cp public/style.css ./style.css

echo "[+] Verifying Client Script..."
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
        out.innerText = 'Success: Secure Session Authenticated for ' + email;
    } else {
        out.style.background = 'rgba(239, 68, 68, 0.2)';
        out.style.color = '#ef4444';
        out.style.border = '1px solid #ef4444';
        out.innerText = 'Error: Missing Required Credentials';
    }
}
JS_EOF
cp public/app.js ./app.js

echo "[+] Verifying HTML Markup..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Adaptive Orientation Gateway</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>EB ENTERPRISES</h1>
        <p class="subtitle">Adaptive Portrait & Landscape Secure Gateway</p>
        
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
cp public/index.html ./index.html

echo "[+] Restarting Live Server..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 nohup node server.js > server.log 2>&1 &
echo "[+] Adaptive portrait/landscape deployment active on port 5000."
