#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Customizable Public Capture Page
# ==============================================================================
set -e

echo "[+] Initializing customizable capture page infrastructure..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_custom_capture';

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
    data: { type: Object, required: true },
    createdAt: { type: Date, default: Date.now }
});

const Submission = mongoose.models.Submission || mongoose.model('Submission', SubmissionSchema);

// Config API to allow updating page title, headline, and fields dynamically
const CONFIG_FILE = path.join(__dirname, 'config.json');
let pageConfig = {
    pageTitle: "Custom Capture Portal",
    badgeText: "Live Deployment",
    headline: "Deploy & Capture <span>Your Vision</span>",
    subheadline: "Fully customizable capture page powered by EB Enterprises. Edit fields, configure endpoints, and collect data instantly.",
    fields: [
        { id: "fullName", label: "Full Name", type: "text", placeholder: "Alex Mercer", required: true },
        { id: "email", label: "Email Address", type: "email", placeholder: "alex@enterprise.io", required: true },
        { id: "message", label: "Project Notes / Message", type: "textarea", placeholder: "Enter details here...", required: false }
    ],
    buttonText: "Submit Information"
};

if (fs.existsSync(CONFIG_FILE)) {
    try {
        pageConfig = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
    } catch (e) {
        console.warn("[!] Failed to parse config.json, using defaults.");
    }
}

app.get('/api/config', (req, res) => {
    res.json(pageConfig);
});

app.post('/api/config', (req, res) => {
    try {
        pageConfig = req.body;
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(pageConfig, null, 2));
        res.json({ success: true, message: 'Configuration updated successfully.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/capture', async (req, res) => {
    try {
        const formData = req.body;
        let totalCount;

        if (isMongoConnected) {
            const count = await Submission.countDocuments();
            totalCount = count + 1;
            const sub = new Submission({ data: formData });
            await sub.save();
        } else {
            totalCount = memoryStore.length + 1;
            memoryStore.unshift({ data: formData, createdAt: new Date() });
        }

        console.log("\n==================================================");
        console.log(`📥 [CUSTOM CAPTURE] NEW SUBMISSION! [#${totalCount}]`);
        console.log(JSON.stringify(formData, null, 2));
        console.log("==================================================\n");

        if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
            let text = `📥 *New Submission [#${totalCount}]*\n\n`;
            for (const [k, v] of Object.entries(formData)) {
                text += `*${k}:* \`${v}\`\n`;
            }
            const message = encodeURIComponent(text);
            const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;
            https.get(url, (resp) => {}).on('error', () => {});
        }

        res.json({ success: true, message: 'Data captured successfully.', totalCount });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`[+] Custom Capture server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-base: #060810;
    --surface: #0d121f;
    --card: #141b2c;
    --border: #212d47;
    --text-main: #ffffff;
    --text-muted: #94a3b8;
    --teal: #00d2c4;
    --teal-glow: rgba(0, 210, 196, 0.25);
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
    justify-content: center;
    align-items: center;
    padding: 2rem 1rem;
}

.wrapper {
    width: 100%;
    max-width: 640px;
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
    background: linear-gradient(90deg, var(--teal), var(--gold));
}

.header {
    text-align: center;
    margin-bottom: 2rem;
}

.badge {
    display: inline-block;
    background: rgba(0, 210, 196, 0.1);
    border: 1px solid rgba(0, 210, 196, 0.3);
    color: var(--teal);
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
    color: var(--teal);
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
    border-color: var(--teal);
    box-shadow: 0 0 0 3px var(--teal-glow);
}

textarea {
    resize: vertical;
    min-height: 90px;
}

button.submit-btn {
    background: linear-gradient(135deg, var(--teal), #00a89d);
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
    box-shadow: 0 6px 20px rgba(0, 210, 196, 0.3);
    margin-top: 0.5rem;
}

button.submit-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(0, 210, 196, 0.45);
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
    <title id="docTitle">Custom Capture Portal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <div id="badgeEl" class="badge">Live Deployment</div>
            <h1 id="headlineEl">Deploy &amp; Capture <span>Your Vision</span></h1>
            <p id="subheadlineEl">Fully customizable capture page powered by EB Enterprises. Edit fields, configure endpoints, and collect data instantly.</p>
        </div>

        <form id="dynamic-form" class="form">
            <div id="formFieldsContainer"></div>
            <button type="submit" id="submitBtn" class="submit-btn">Submit Information</button>
        </form>

        <div id="feedback"></div>

        <div class="customizer-toggle">
            <button type="button" onclick="toggleCustomizer()">⚙️ Customize Page Copy &amp; Fields</button>
        </div>

        <div id="customizerPanel" class="customizer-panel">
            <h3>Live Page Configurator</h3>
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
                <button type="submit" class="submit-btn" style="background: var(--gold); color: #000;">Save &amp; Apply Changes</button>
            </form>
        </div>

        <div class="footer">
            EB Enterprises &bull; Customizable Capture Engine &bull; All Rights Reserved
        </div>
    </div>

    <script>
        let currentConfig = {};

        async function loadConfig() {
            const res = await fetch('/api/config');
            currentConfig = await res.json();
            renderPage(currentConfig);
        }

        function renderPage(cfg) {
            document.getElementById('docTitle').textContent = cfg.pageTitle;
            document.getElementById('badgeEl').textContent = cfg.badgeText;
            document.getElementById('headlineEl').innerHTML = cfg.headline;
            document.getElementById('subheadlineEl').textContent = cfg.subheadline;
            document.getElementById('submitBtn').textContent = cfg.buttonText;

            // Populate configurator fields
            document.getElementById('cfgTitle').value = cfg.pageTitle;
            document.getElementById('cfgBadge').value = cfg.badgeText;
            document.getElementById('cfgHeadline').value = cfg.headline;
            document.getElementById('cfgSubheadline').value = cfg.subheadline;
            document.getElementById('cfgButton').value = cfg.buttonText;

            const container = document.getElementById('formFieldsContainer');
            container.innerHTML = '';

            cfg.fields.forEach(f => {
                const div = document.createElement('div');
                div.className = 'field';
                
                const label = document.createElement('label');
                label.setAttribute('for', f.id);
                label.textContent = f.label + (f.required ? ' *' : '');
                div.appendChild(label);

                if (f.type === 'textarea') {
                    const ta = document.createElement('textarea');
                    ta.id = f.id;
                    ta.placeholder = f.placeholder;
                    if (f.required) ta.required = true;
                    div.appendChild(ta);
                } else {
                    const input = document.createElement('input');
                    input.type = f.type;
                    input.id = f.id;
                    input.placeholder = f.placeholder;
                    if (f.required) input.required = true;
                    div.appendChild(input);
                }
                container.appendChild(div);
            });
        }

        function toggleCustomizer() {
            const panel = document.getElementById('customizerPanel');
            panel.style.display = panel.style.display === 'block' ? 'none' : 'block';
        }

        document.getElementById('dynamic-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const feedback = document.getElementById('feedback');
            const submitBtn = document.getElementById('submitBtn');

            const formData = {};
            currentConfig.fields.forEach(f => {
                formData[f.id] = document.getElementById(f.id).value.trim();
            });

            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting...';

            try {
                const res = await fetch('/api/capture', {
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
                submitBtn.textContent = currentConfig.buttonText;
            }
        });

        document.getElementById('config-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            currentConfig.pageTitle = document.getElementById('cfgTitle').value.trim();
            currentConfig.badgeText = document.getElementById('cfgBadge').value.trim();
            currentConfig.headline = document.getElementById('cfgHeadline').value.trim();
            currentConfig.subheadline = document.getElementById('cfgSubheadline').value.trim();
            currentConfig.buttonText = document.getElementById('cfgButton').value.trim();

            const res = await fetch('/api/config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(currentConfig)
            });
            const data = await res.json();
            if (res.ok) {
                renderPage(currentConfig);
                toggleCustomizer();
                alert('Configuration saved successfully!');
            } else {
                alert('Error: ' + data.error);
            }
        });

        loadConfig();
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
    # Fallback to loca.lt pattern check
    PUBLIC_URL=$(grep -o 'https://[a-z0-9.-]*\.loca\.lt' public_url.log || true)
fi

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] YOUR CUSTOMIZABLE PUBLIC LINK:"
    echo "    $PUBLIC_URL"
    echo ""
    echo "    (Click the gear icon at the bottom of the page to customize live!)"
else
    echo "[!] Tunnel URL lookup pending. Check your terminal or run: npx localtunnel --port 5000"
    echo "    Local URL: http://localhost:5000"
fi
echo "=================================================="
echo ""
