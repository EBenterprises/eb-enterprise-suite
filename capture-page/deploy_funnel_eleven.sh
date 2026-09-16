#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Indie Maker Launchpad (V11)
# ==============================================================================
set -e

echo "[+] Initializing eleventh indie maker launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_indie_launch_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryMakers = [
    { fullName: 'Liam Brooks', email: 'liam@indiemaker.club', projectType: 'SaaS / Micro-Startup', launchTimeline: 'Within 30 days', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory maker store.");
});

const IndieSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    projectType: { type: String, required: true },
    launchTimeline: { type: String, required: true },
    projectNotes: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const IndieMaker = mongoose.models.IndieMaker || mongoose.model('IndieMaker', IndieSchema);

function sendIndieAlert(fullName, email, projectType, launchTimeline, projectNotes, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🚀 [INDIE LAUNCH] NEW MAKER REGISTRATION! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🛠️ [PROJECT]: ${projectType}`);
    console.log(`📅 [TIMELINE]: ${launchTimeline}`);
    console.log(`💡 [NOTES]: ${projectNotes || 'None provided'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🚀 *New Indie Maker Registration!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🛠️ *Project:* \`${projectType}\`\n📅 *Timeline:* \`${launchTimeline}\`\n💡 *Notes:* \`${projectNotes || 'N/A'}\`\n🔢 *Reg #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram indie alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram alert failed:", err.message);
        });
    }
}

app.post('/api/indie/register', async (req, res) => {
    try {
        const { fullName, email, projectType, launchTimeline, projectNotes } = req.body;
        if (!fullName || !email || !projectType || !launchTimeline) {
            return res.status(400).json({ error: 'Name, email, project type, and timeline are required.' });
        }

        let regCount;

        if (isMongoConnected) {
            const existing = await IndieMaker.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await IndieMaker.countDocuments();
            regCount = count + 1;
            const newMaker = new IndieMaker({ fullName, email, projectType, launchTimeline, projectNotes: projectNotes || '' });
            await newMaker.save();
        } else {
            const existing = memoryMakers.find(m => m.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            regCount = memoryMakers.length + 1;
            memoryMakers.unshift({ fullName, email, projectType, launchTimeline, projectNotes: projectNotes || '', createdAt: new Date() });
        }

        sendIndieAlert(fullName, email, projectType, launchTimeline, projectNotes, regCount);

        return res.status(200).json({ 
            success: true, 
            message: 'You are on the list! Check your inbox for your indie launch playbook.', 
            regCount 
        });
    } catch (err) {
        console.error("[ERROR] Registration failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Indie launch server V11 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming signups.`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #070913;
    --surface-bg: #0f1322;
    --card-bg: #161c30;
    --border-color: #242d4a;
    --text-primary: #ffffff;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.25);
    --gold: #fde047;
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

.indie-container {
    width: 100%;
    max-width: 580px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    padding: 3rem 2.5rem;
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.8);
    position: relative;
    overflow: hidden;
}

.indie-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--accent-teal), var(--gold));
}

.indie-header {
    text-align: center;
    margin-bottom: 2rem;
}

.indie-pill {
    display: inline-block;
    background: rgba(0, 210, 196, 0.1);
    border: 1px solid rgba(0, 210, 196, 0.3);
    color: var(--accent-teal);
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.indie-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.indie-header h1 span {
    color: var(--accent-teal);
}

.indie-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.phases-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.phase-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.phase-card .ph-title {
    font-size: 0.85rem;
    font-weight: 700;
    color: var(--gold);
    margin-bottom: 0.2rem;
}

.phase-card .ph-desc {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.indie-form {
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
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 80px;
}

button.btn-indie {
    background: linear-gradient(135deg, var(--accent-teal), #00b3a6);
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
    box-shadow: 0 6px 20px rgba(0, 210, 196, 0.3);
    margin-top: 0.5rem;
}

button.btn-indie:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(0, 210, 196, 0.45);
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

.indie-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
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
    <title>Build & Launch Your Project</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="indie-container">
        <div class="indie-header">
            <div class="indie-pill">Build Fast &bull; Ship Often</div>
            <h1>Ready to Launch Your <span>Indie Project?</span></h1>
            <p>Stop overthinking and start shipping. Tell us about your project, and we will send you a straightforward action plan to get live fast.</p>
        </div>

        <div class="phases-grid">
            <div class="phase-card">
                <div class="ph-title">1. Build</div>
                <div class="ph-desc">Core Product</div>
            </div>
            <div class="phase-card">
                <div class="ph-title">2. Package</div>
                <div class="ph-desc">Clear Pricing</div>
            </div>
            <div class="phase-card">
                <div class="ph-title">3. Launch</div>
                <div class="ph-desc">Get Users</div>
            </div>
        </div>

        <form id="indie-form" class="indie-form">
            <div class="input-group">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Liam Brooks" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Your Email Address</label>
                <input type="email" id="email" placeholder="liam@indiemaker.club" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="projectType">What kind of project are you building?</label>
                <select id="projectType" required>
                    <option value="" disabled selected>Choose your project type...</option>
                    <option value="SaaS / Micro-Startup">SaaS / Micro-Startup</option>
                    <option value="Digital Products / Guides">Digital Products / Guides</option>
                    <option value="Freelance / Consulting Offer">Freelance / Consulting Offer</option>
                    <option value="Content / Newsletter Business">Content / Newsletter Business</option>
                    <option value="Other Indie Project">Other Indie Project</option>
                </select>
            </div>

            <div class="input-group">
                <label for="launchTimeline">When do you plan to launch?</label>
                <select id="launchTimeline" required>
                    <option value="" disabled selected>Choose your timeline...</option>
                    <option value="Immediately (This week)">Immediately (This week)</option>
                    <option value="Within 30 days">Within 30 days</option>
                    <option value="Within 90 days">Within 90 days</option>
                    <option value="Just researching">Just researching</option>
                </select>
            </div>

            <div class="input-group">
                <label for="projectNotes">Tell us what your project does (Optional)</label>
                <textarea id="projectNotes" placeholder="Briefly describe your idea or what problem it solves..."></textarea>
            </div>

            <button type="submit" class="btn-indie">Get My Launch Playbook</button>
        </form>

        <div id="toast"></div>

        <div class="indie-footer">
            EB Enterprises &bull; Indie Maker Playbooks &bull; Zero Spam
        </div>
    </div>

    <script>
        document.getElementById('indie-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const projectType = document.getElementById('projectType').value;
            const launchTimeline = document.getElementById('launchTimeline').value;
            const projectNotes = document.getElementById('projectNotes').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !projectType || !launchTimeline) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Generating Playbook...';

            try {
                const res = await fetch('/api/indie/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, projectType, launchTimeline, projectNotes })
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
                    document.getElementById('indie-form').reset();
                    submitBtn.textContent = 'Playbook Sent ✓';
                } else {
                    throw new Error(data.error || 'Submission failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Get My Launch Playbook';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of indie maker launchpad (V11)..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_indie_launch_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Indie maker launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time signups with:"
echo ""
echo "    tail -f server.log"
echo ""
