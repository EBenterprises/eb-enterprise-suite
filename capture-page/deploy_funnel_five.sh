#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Online Business Launchpad (V5)
# ==============================================================================
set -e

echo "[+] Initializing fifth high-converting online business launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_business_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryFounders = [
    { fullName: 'Elena Rostova', email: 'elena@startupscale.io', niche: 'SaaS & Digital Infrastructure', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory founder store.");
});

const BusinessSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    niche: { type: String, default: 'SaaS & Digital Infrastructure' },
    createdAt: { type: Date, default: Date.now }
});

const BusinessFounder = mongoose.models.BusinessFounder || mongoose.model('BusinessFounder', BusinessSchema);

function sendBusinessAlert(fullName, email, niche, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🚀 [BIZ LAUNCHPAD] NEW FOUNDER APPLICATION! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🎯 [NICHE]: ${niche}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🚀 *New Online Business Founder!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🎯 *Niche:* \`${niche}\`\n🔢 *Founder #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram business alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram business alert failed:", err.message);
        });
    }
}

app.post('/api/business/register', async (req, res) => {
    try {
        const { fullName, email, niche } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Name and email are required to launch.' });
        }

        const selectedNiche = niche || 'SaaS & Digital Infrastructure';
        let founderCount;

        if (isMongoConnected) {
            const existing = await BusinessFounder.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the launch directory.' });
            }
            const count = await BusinessFounder.countDocuments();
            founderCount = count + 1;
            const newFounder = new BusinessFounder({ fullName, email, niche: selectedNiche });
            await newFounder.save();
        } else {
            const existing = memoryFounders.find(f => f.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the launch directory.' });
            }
            founderCount = memoryFounders.length + 1;
            memoryFounders.unshift({ fullName, email, niche: selectedNiche, createdAt: new Date() });
        }

        sendBusinessAlert(fullName, email, selectedNiche, founderCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Blueprint unlocked. Check your secure inbox for your immediate startup checklist.', 
            founderCount 
        });
    } catch (err) {
        console.error("[ERROR] Business registration failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Online business funnel server V5 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view founder signups.`);
});
SRV_EOF

echo "[+] Writing Business Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #030712;
    --surface-bg: #0b0f19;
    --card-bg: #111827;
    --border-color: #1f2937;
    --text-primary: #f9fafb;
    --text-secondary: #9ca3af;
    --accent-teal: #06b6d4;
    --accent-teal-glow: rgba(6, 182, 212, 0.25);
    --gold: #fbbf24;
    --gold-bright: #d97706;
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

.biz-container {
    width: 100%;
    max-width: 580px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 3rem 2.5rem;
    box-shadow: 0 35px 80px rgba(0, 0, 0, 0.85);
    position: relative;
    overflow: hidden;
}

.biz-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--accent-teal), var(--gold));
}

.biz-header {
    text-align: center;
    margin-bottom: 2rem;
}

.biz-pill {
    display: inline-block;
    background: rgba(6, 182, 212, 0.1);
    border: 1px solid rgba(6, 182, 212, 0.3);
    color: var(--accent-teal);
    font-size: 0.7rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.biz-header h1 {
    font-size: 2.1rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.biz-header h1 span {
    color: var(--accent-teal);
}

.biz-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.blueprint-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.bp-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.bp-card .bp-val {
    font-size: 0.9rem;
    font-weight: 800;
    color: var(--gold);
    margin-bottom: 0.2rem;
}

.bp-card .bp-lbl {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight: 600;
}

.biz-form {
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

input, select {
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

input:focus, select:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

select {
    cursor: pointer;
}

button.btn-biz {
    background: linear-gradient(135deg, var(--accent-teal), #0891b2);
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
    box-shadow: 0 6px 20px rgba(6, 182, 212, 0.35);
    margin-top: 0.5rem;
}

button.btn-biz:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(6, 182, 212, 0.5);
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

.biz-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Business Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Online Business Launchpad</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="biz-container">
        <div class="biz-header">
            <div class="biz-pill">Zero to Revenue Blueprint</div>
            <h1>Launch Your <span>Profitable Online Business</span> Today</h1>
            <p>Skip the trial and error. Access our proven framework for structuring high-margin digital products, automated funnels, and sovereign scale.</p>
        </div>

        <div class="blueprint-grid">
            <div class="bp-card">
                <div class="bp-val">Step 1</div>
                <div class="bp-lbl">Niche Validation</div>
            </div>
            <div class="bp-card">
                <div class="bp-val">Step 2</div>
                <div class="bp-lbl">Automated Funnel</div>
            </div>
            <div class="bp-card">
                <div class="bp-val">Step 3</div>
                <div class="bp-lbl">Live Deployment</div>
            </div>
        </div>

        <form id="biz-form" class="biz-form">
            <div class="input-group">
                <label for="fullName">Your Full Name</label>
                <input type="text" id="fullName" placeholder="Elena Rostova" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Primary Email Address</label>
                <input type="email" id="email" placeholder="elena@startupscale.io" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="niche">Target Business Model / Niche</label>
                <select id="niche">
                    <option value="SaaS & Digital Infrastructure">SaaS &amp; Digital Infrastructure</option>
                    <option value="High-Ticket Consulting & Funnels">High-Ticket Consulting &amp; Funnels</option>
                    <option value="Automated Content & Media Syndicates">Automated Content &amp; Media Syndicates</option>
                </select>
            </div>

            <button type="submit" class="btn-biz">Unlock Business Blueprint</button>
        </form>

        <div id="toast"></div>

        <div class="biz-footer">
            EB Enterprises &bull; Zero Spam &bull; Instant Framework Dispatch
        </div>
    </div>

    <script>
        document.getElementById('biz-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const niche = document.getElementById('niche').value;
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Generating Blueprint...';

            try {
                const res = await fetch('/api/business/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, niche })
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
                    document.getElementById('biz-form').reset();
                    submitBtn.textContent = 'Blueprint Unlocked ✓';
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
                submitBtn.textContent = 'Unlock Business Blueprint';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of online business launchpad..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_business_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Online business launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time founder signups with:"
echo ""
echo "    tail -f server.log"
echo ""
