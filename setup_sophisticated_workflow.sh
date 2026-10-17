#!/usr/bin/env bash
set -e

echo "=== Deploying Sophisticated Modular Workflow ==="

cd ~/eb-enterprise-suite/eb-enterprise-suite

# Create modules directory for structured micro-apps
mkdir -p modules gateway/routes dashboard/modules-ui

# =========================================================
# 1. Create the Module Registry CLI (`eb-mod`)
# =========================================================
cat << 'EOF_MOD' > eb-mod
#!/usr/bin/env bash
ACTION="$1"
MOD_NAME="$2"

if [ "$ACTION" == "create" ]; then
    if [ -z "$MOD_NAME" ]; then
        echo "Usage: eb-mod create <module_name>"
        exit 1
    }
    
    MOD_DIR="modules/$MOD_NAME"
    mkdir -p "$MOD_DIR/public" "$MOD_DIR/api"
    
    # Create Manifest
    cat << EOF_MANIFEST > "$MOD_DIR/manifest.json"
{
  "name": "$MOD_NAME",
  "version": "1.0.0",
  "description": "Sophisticated module for $MOD_NAME",
  "route": "/app/$MOD_NAME",
  "api_route": "/api/$MOD_NAME"
}
EOF_MANIFEST

    # Create Frontend UI Template
    cat << EOF_UI > "$MOD_DIR/public/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$MOD_NAME - EB Enterprise Suite</title>
    <style>
        body { font-family: monospace; background: #0d1117; color: #c9d1d9; padding: 30px; margin: 0; }
        .card { background: #161b22; border: 1px solid #30363d; padding: 25px; border-radius: 8px; max-width: 600px; margin: auto; }
        h1 { color: #58a6ff; margin-top: 0; }
        .badge { background: #238636; color: white; padding: 3px 8px; border-radius: 4px; font-size: 0.8em; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">Active Module</span>
        <h1>🚀 $MOD_NAME Module</h1>
        <p>This module was scaffolded and registered via the sophisticated EB workflow engine.</p>
        <a href="/" style="color: #58a6ff; text-decoration: none;">&larr; Return to Dashboard Hub</a>
    </div>
</body>
</html>
EOF_UI

    echo "=== Module '$MOD_NAME' created successfully in modules/$MOD_NAME ==="
    echo "Run './eb-mod build' to compile and register it into the system."

elif [ "$ACTION" == "list" ]; then
    echo "=== Registered Modules ==="
    for d in modules/*/; do
        if [ -f "${d}manifest.json" ]; then
            cat "${d}manifest.json" | grep -E '"name"|"route"'
            echo "--------------------------"
        fi
    done
else
    echo "Usage: eb-mod {create <name>|list}"
fi
EOF_MOD
chmod +x eb-mod

# =========================================================
# 2. Upgrade Master Dashboard to Read Modular Manifests
# =========================================================
cat << 'EOF_HUB_SRV' > dashboard/server.js
const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const rootPublic = path.join(__dirname, 'public');
app.use(express.static(rootPublic));

// Dynamically mount all modules found in ../modules/
const modulesDir = path.join(__dirname, '../modules');
if (fs.existsSync(modulesDir)) {
    fs.readdirSync(modulesDir).forEach(modName => {
        const modPath = path.join(modulesDir, modName);
        const manifestPath = path.join(modPath, 'manifest.json');
        
        if (fs.existsSync(manifestPath)) {
            try {
                const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
                const pubPath = path.join(modPath, 'public');
                
                if (fs.existsSync(pubPath)) {
                    app.use(manifest.route, express.static(pubPath));
                    console.log(`[Module Mounted] ${manifest.name} -> ${manifest.route}`);
                }
            } catch (e) {
                console.error(`Error loading manifest for ${modName}:`, e.message);
            }
        }
    });
}

// API endpoint listing all modules for the hub UI
app.get('/api/modules', (req, res) => {
    const modules = [];
    if (fs.existsSync(modulesDir)) {
        fs.readdirSync(modulesDir).forEach(modName => {
            const manifestPath = path.join(modulesDir, modName, 'manifest.json');
            if (fs.existsSync(manifestPath)) {
                try {
                    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
                    modules.push(manifest);
                } catch (e) {}
            }
        });
    }
    res.json({ success: true, modules });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Sophisticated Dashboard Hub running on port ${PORT}`);
});
EOF_HUB_SRV

# =========================================================
# 3. Upgrade Dashboard UI Hub to Render Structured Modules
# =========================================================
cat << 'EOF_INDEX' > dashboard/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprise Suite - Command Center</title>
    <style>
        body { font-family: monospace; background: #0d1117; color: #c9d1d9; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .container { background: #161b22; border: 1px solid #30363d; padding: 35px; border-radius: 8px; width: 450px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.6); }
        h1 { color: #58a6ff; font-size: 1.5em; margin-bottom: 5px; }
        .subtitle { font-size: 0.85em; color: #8b949e; margin-bottom: 25px; border-bottom: 1px solid #30363d; padding-bottom: 15px; }
        .module-btn { display: block; background: #21262d; border: 1px solid #30363d; color: #58a6ff; text-decoration: none; padding: 14px; margin: 12px 0; border-radius: 6px; font-weight: bold; text-align: left; padding-left: 20px; transition: all 0.2s; }
        .module-btn:hover { background: #30363d; border-color: #58a6ff; }
        .footer { font-size: 0.75em; color: #8b949e; margin-top: 25px; border-top: 1px solid #30363d; padding-top: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚡ EB Enterprise Suite</h1>
        <div class="subtitle">Sophisticated Manifest-Driven Architecture</div>
        
        <div id="moduleList">Loading registered modules...</div>

        <div class="footer">Use <code>eb-mod create &lt;name&gt;</code> to spin up new modules instantly.</div>
    </div>

    <script>
        async function loadModules() {
            try {
                const res = await fetch('/api/modules');
                const data = await res.json();
                const listEl = document.getElementById('moduleList');
                
                if (data.success && data.modules.length > 0) {
                    listEl.innerHTML = data.modules.map(mod => `
                        <a href="${mod.route}" class="module-btn">🚀 ${mod.name} <span style="font-size: 0.75em; color: #8b949e; float: right;">v${mod.version}</span></a>
                    `).join('');
                } else {
                    listEl.innerHTML = '<p style="color: #8b949e;">No modules registered yet.</p>';
                }
            } catch (e) {
                document.getElementById('moduleList').innerHTML = '<p style="color: #f85149;">Failed to load modules registry.</p>';
            }
        }
        loadModules();
    </script>
</body>
</html>
EOF_INDEX

# Restart services via PM2
pm2 restart eb-dashboard

echo "=== Sophisticated Workflow Deployed Successfully! ==="
echo "Try creating a new module right now using: ./eb-mod create inventory"
