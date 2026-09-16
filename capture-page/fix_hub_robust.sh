#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Bulletproof Capture Hub & Server Fix
# ==============================================================================
set -e

PORT=5000

echo "[+] Terminating existing node instances..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Rebuilding clean server.js without external MongoDB dependency blocks..."
cat << 'SRV_EOF' > server.js
const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const CONFIG_FILE = path.join(__dirname, 'templates.json');

let templates = {
    "executive": {
        name: "Executive Spectrum",
        pageTitle: "Executive Access Portal",
        badgeText: "EB Enterprises",
        headline: "High-Performance <span>Systems Access</span>",
        subheadline: "Secure authorization gateway for proprietary architecture deployments and executive infrastructure.",
        buttonText: "Authorize & Connect",
        accentColor: "#00d2c4",
        fields: [
            { id: "fullName", label: "Principal Name", type: "text", placeholder: "Alex Mercer", required: true },
            { id: "email", label: "Corporate Email", type: "email", placeholder: "alex@eb-enterprises.io", required: true },
            { id: "tier", label: "Access Tier", type: "text", placeholder: "Level 4 Principal Architect", required: true }
        ]
    },
    "community": {
        name: "Community Support",
        pageTitle: "Community Aid & Resource Hub",
        badgeText: "Dignity & Access",
        headline: "Find Shelter & <span>Support Services</span>",
        subheadline: "Connect directly with emergency housing, warm meals, healthcare services, and community advocates.",
        buttonText: "Request Assistance Now",
        accentColor: "#38bdf8",
        fields: [
            { id: "fullName", label: "Your Name or Alias", type: "text", placeholder: "Preferred identifier", required: true },
            { id: "contactInfo", label: "Contact Info (Phone/Shelter)", type: "text", placeholder: "How can support reach you?", required: true },
            { id: "resourceNeeded", label: "Primary Need", type: "text", placeholder: "Emergency Shelter / Meals / Medical", required: true },
            { id: "locationNotes", label: "Current Location / Area", type: "text", placeholder: "Downtown core / specific landmark", required: true }
        ]
    },
    "focus": {
        name: "Focus Matrix",
        pageTitle: "Focus Matrix Engine",
        badgeText: "Zero Noise",
        headline: "Absolute <span>Execution Focus</span>",
        subheadline: "Eliminate distractions, lock onto your single primary objective, and execute without hesitation.",
        buttonText: "Initialize Focus Matrix",
        accentColor: "#8b5cf6",
        fields: [
            { id: "fullName", label: "Your Name", type: "text", placeholder: "Sam Vance", required: true },
            { id: "email", label: "Email Address", type: "email", placeholder: "sam@focusmatrix.app", required: true },
            { id: "coreObjective", label: "Single Core Objective", type: "text", placeholder: "Finish full-stack build & verify core logic", required: true }
        ]
    }
};

if (fs.existsSync(CONFIG_FILE)) {
    try {
        templates = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    } catch (e) {
        console.warn("[!] Failed to parse templates.json, using defaults.");
    }
}

app.get('/api/templates', (req, res) => {
    res.json(templates);
});

app.post('/api/templates', (req, res) => {
    try {
        templates = req.body;
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(templates, null, 2));
        res.json({ success: true, message: 'Templates updated successfully.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/capture/:templateId', async (req, res) => {
    try {
        const { templateId } = req.params;
        const formData = req.body;

        console.log("\n==================================================");
        console.log(`📥 [CAPTURE RECEIVED] TEMPLATE: [${templateId}]`);
        console.log(JSON.stringify(formData, null, 2));
        console.log("==================================================\n");

        res.json({ success: true, message: 'Submission captured and logged successfully.', totalCount: 1 });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`[+] Resilient Hub server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Starting server..."
nohup node server.js > server.log 2>&1 &
sleep 2

if curl -s "http://localhost:$PORT/api/templates" > /dev/null; then
    echo "[+] Server check passed successfully!"
else
    echo "[!] Server failed to start. Log output:"
    cat server.log
    exit 1
fi

echo "[+] Launching LocalTunnel..."
rm -f public_url.log
npx -y localtunnel --port $PORT > public_url.log 2>&1 &

PUBLIC_URL=""
for i in {1..10}; do
    sleep 1
    if [ -f public_url.log ]; then
        PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+(\.loca\.lt|\.localtunnel\.me)' public_url.log || true)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] YOUR LIVE PUBLIC LINK:"
    echo "    $PUBLIC_URL"
    echo ""
    echo "    (Switch templates at the top or click gear to customize live!)"
else
    echo "[!] Tunnel URL lookup pending. Run manually: npx localtunnel --port $PORT"
    echo "    Local URL: http://localhost:$PORT"
fi
echo "=================================================="
echo ""
