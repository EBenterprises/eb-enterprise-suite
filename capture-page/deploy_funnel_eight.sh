#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Enterprise Venture Launchpad (V8 - English)
# ==============================================================================
set -e

echo "[+] Initializing eighth enterprise venture launchpad (English localized)..."
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

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_english_launch_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryFounders = [
    { fullName: 'Oliver Sterling', email: 'oliver@sterlingventures.co.uk', businessModel: 'B2B SaaS & Automation', fundingStage: 'Pre-Seed / Bootstrapped', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory founder store.");
});

const VentureSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    businessModel: { type: String, required: true },
    fundingStage: { type: String, required: true },
    visionDetails: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const VentureFounder = mongoose.models.VentureFounder || mongoose.model('VentureFounder', VentureSchema);

function sendVentureAlert(fullName, email, businessModel, fundingStage, visionDetails, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🇬🇧 [ENGLISH LAUNCH] NEW FOUNDER REGISTRATION! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [FOUNDER]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🏛️ [MODEL]: ${businessModel}`);
    console.log(`💰 [STAGE]: ${fundingStage}`);
    console.log(`💡 [VISION]: ${visionDetails || 'None provided'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🇬🇧 *New English Market Venture Application!*\n\n👤 *Founder:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🏛️ *Model:* \`${businessModel}\`\n💰 *Stage:* \`${fundingStage}\`\n💡 *Vision:* \`${visionDetails || 'N/A'}\`\n🔢 *App #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram English market venture alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram alert failed:", err.message);
        });
    }
}

app.post('/api/venture/register', async (req, res) => {
    try {
        const { fullName, email, businessModel, fundingStage, visionDetails } = req.body;
        if (!fullName || !email || !businessModel || !fundingStage) {
            return res.status(400).json({ error: 'Founder name, email, business model, and stage are required.' });
        }

        let appCount;

        if (isMongoConnected) {
            const existing = await VentureFounder.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the venture registry.' });
            }
            const count = await VentureFounder.countDocuments();
            appCount = count + 1;
            const newVenture = new VentureFounder({ fullName, email, businessModel, fundingStage, visionDetails: visionDetails || '' });
            await newVenture.save();
        } else {
            const existing = memoryFounders.find(v => v.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the venture registry.' });
            }
            appCount = memoryFounders.length + 1;
            memoryFounders.unshift({ fullName, email, businessModel, fundingStage, visionDetails: visionDetails || '', createdAt: new Date() });
        }

        sendVentureAlert(fullName, email, businessModel, fundingStage, visionDetails, appCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Venture blueprint locked. Check your secure inbox for your immediate English market startup guide.', 
            appCount 
        });
    } catch (err) {
        console.error("[ERROR] Venture registration failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] English venture funnel server V8 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming applications.`);
});
SRV_EOF

echo "[+] Writing Venture Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #060913;
    --surface-bg: #0f1523;
    --card-bg: #161e31;
    --border-color: #232f4a;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.25);
    --gold: #fde047;
    --gold-bright: #d4af37;
    --success: #22c55e;
    --danger: #ef4444;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

body {
    background-color: var(--bg-app);
    color: var(--text-primary);
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 2rem 1rem;
}

.venture-container {
    width: 100%;
    max-width: 600px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 3rem 2.5rem;
    box-shadow: 0 40px 90px rgba(0, 0, 0, 0.9);
    position: relative;
    overflow: hidden;
}

.venture-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--gold-bright), var(--accent-teal));
}

.venture-header {
    text-align: center;
    margin-bottom: 2rem;
}

.venture-pill {
    display: inline-block;
    background: rgba(212, 175, 55, 0.1);
    border: 1px solid rgba(212, 175, 55, 0.3);
    color: var(--gold-bright);
    font-size: 0.7rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.venture-header h1 {
    font-size: 2.1rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.venture-header h1 span {
    color: var(--gold-bright);
}

.venture-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.metrics-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.metric-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.metric-card .mc-val {
    font-size: 0.95rem;
    font-weight: 800;
    color: var(--accent-teal);
    margin-bottom: 0.2rem;
}

.metric-card .mc-lbl {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight: 600;
}

.venture-form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.input-group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

label {
    font-size: 0.75rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-weight: 700;
}

input, select, textarea {
    width: 100%;
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 0.95rem 1.1rem;
    border-radius: 8px;
    font-size: 0.95rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus, textarea:focus {
    border-color: var(--gold-bright);
    box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.25);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 80px;
}

button.btn-venture {
    background: linear-gradient(135deg, var(--gold-bright), #b89728);
    color: var(--bg-app);
    border: none;
    padding: 1.15rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    font-size: 0.95rem;
    transition: all 0.2s;
    box-shadow: 0 6px 20px rgba(212, 175, 55, 0.35);
    margin-top: 0.5rem;
}

button.btn-venture:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(212, 175, 55, 0.5);
}

#toast {
    margin-top: 1.25rem;
    padding: 0.95rem;
    border-radius: 8px;
    display: none;
    font-weight: 600;
    font-size: 0.85rem;
    text-align: center;
}

.venture-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Venture Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - English Market Venture Launchpad</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="venture-container">
        <div class="venture-header">
            <div class="venture-pill">English Market Launchpad</div>
            <h1>Start &amp; Grow Your <span>English Market Business</span></h1>
            <p>Access specialized frameworks, legal structuring, and automated customer acquisition pipelines tailored for the English-speaking market.</p>
        </div>

        <div class="metrics-grid">
            <div class="metric-card">
                <div class="mc-val">Foundation</div>
                <div class="mc-lbl">Legal &amp; Setup</div>
            </div>
            <div class="metric-card">
                <div class="mc-val">Automation</div>
                <div class="mc-lbl">Funnels &amp; Sales</div>
            </div>
            <div class="metric-card">
                <div class="mc-val">Execution</div>
                <div class="mc-lbl">Live Deployment</div>
            </div>
        </div>

        <form id="venture-form" class="venture-form">
            <div class="input-group">
                <label for="fullName">Founder Full Name</label>
                <input type="text" id="fullName" placeholder="Oliver Sterling" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Secure Business Email</label>
                <input type="email" id="email" placeholder="oliver@sterlingventures.co.uk" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="businessModel">Target Business Model</label>
                <select id="businessModel" required>
                    <option value="" disabled selected>Select your venture model...</option>
                    <option value="B2B SaaS & Automation">B2B SaaS &amp; Automation Infrastructure</option>
                    <option value="High-Ticket Advisory & Consulting">High-Ticket Advisory &amp; Consulting</option>
                    <option value="E-Commerce & Proprietary Brands">E-Commerce &amp; Proprietary Goods</option>
                    <option value="Digital Media & Syndication">Digital Media &amp; Content Syndication</option>
                    <option value="Full-Stack Agency & Services">Full-Stack Agency &amp; Professional Services</option>
                    <option value="Custom English Venture">Custom English Market Venture</option>
                </select>
            </div>

            <div class="input-group">
                <label for="fundingStage">Current Venture Stage</label>
                <select id="fundingStage" required>
                    <option value="" disabled selected>Select your current stage...</option>
                    <option value="Idea & Concept Phase">Idea &amp; Concept Phase</option>
                    <option value="Pre-Seed / Bootstrapped">Pre-Seed / Bootstrapped Startup</option>
                    <option value="Revenue Generating / Scaling">Revenue Generating &amp; Scaling</option>
                    <option value="Enterprise Expansion">Established Enterprise Expansion</option>
                </select>
            </div>

            <div class="input-group">
                <label for="visionDetails">Venture Vision &amp; Core Objectives</label>
                <textarea id="visionDetails" placeholder="Briefly describe your business goals, target audience, or primary product offerings..."></textarea>
            </div>

            <button type="submit" class="btn-venture">Deploy English Blueprint</button>
        </form>

        <div id="toast"></div>

        <div class="venture-footer">
            EB Enterprises &bull; English Market Infrastructure &bull; Confidential Dispatch
        </div>
    </div>

    <script>
        document.getElementById('venture-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const businessModel = document.getElementById('businessModel').value;
            const fundingStage = document.getElementById('fundingStage').value;
            const visionDetails = document.getElementById('visionDetails').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !businessModel || !fundingStage) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Generating English Blueprint...';

            try {
                const res = await fetch('/api/venture/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, businessModel, fundingStage, visionDetails })
                });

                const contentType = res.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new Error("Received non-JSON response from server.");
                }

                const data = await res.json();

                toast.style.display = 'block';
                if (res.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = data.message;
                    document.getElementById('venture-form').reset();
                    submitBtn.textContent = 'Blueprint Deployed ✓';
                } else {
                    throw new Error(data.error || 'Registration failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Deploy English Blueprint';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of English market venture launchpad (V8)..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_english_launch_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] English market venture launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time applications with:"
echo ""
echo "    tail -f server.log"
echo ""
