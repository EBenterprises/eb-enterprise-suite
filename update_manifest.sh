#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Cross-Platform Responsive Viewport Setup
# ==============================================================================
set -e

# Update all index.html instances to guarantee perfect mobile/desktop responsiveness
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Mobile & Desktop Enterprise Terminal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>EB ENTERPRISES</h1>
        <p style="text-align: center; color: #94a3b8; font-size: 0.9rem;">Cross-Platform Mobile & Desktop Secure Gateway</p>
        
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

# Sync across root
cp public/index.html ./index.html

# Enhance CSS for ultra-smooth mobile and desktop scaling
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
}

.container {
    width: 100%;
    max-width: 500px;
    background: var(--surface-dark);
    border: 1px solid var(--border-color);
    padding: 1.5rem;
    border-radius: 10px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.6);
}

h1 {
    color: var(--highlight-gold);
    text-align: center;
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
}

.card {
    background: var(--surface-card);
    border: 1px solid var(--border-color);
    padding: 1.25rem;
    margin-top: 1rem;
    border-radius: 8px;
}

label {
    display: block;
    color: var(--text-muted);
    margin-bottom: 0.4rem;
    font-size: 0.85rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

input {
    width: 100%;
    padding: 0.75rem;
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    margin-bottom: 1rem;
    border-radius: 6px;
    font-size: 1rem;
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
    padding: 0.85rem;
    font-weight: bold;
    cursor: pointer;
    width: 100%;
    border-radius: 6px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 0.95rem;
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
    font-size: 0.9rem;
}

/* Desktop Expansion */
@media (min-width: 768px) {
    .container {
        max-width: 600px;
        padding: 2.5rem;
    }
    h1 {
        font-size: 2rem;
    }
    .card {
        padding: 2rem;
    }
}
CSS_EOF
cp public/style.css ./style.css

echo "[+] Restarting server for live mobile & desktop viewport sync..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 nohup node server.js > server.log 2>&1 &
echo "[+] Cross-platform responsive deployment active on port 5000."
