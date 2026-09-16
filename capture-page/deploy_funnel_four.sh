#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Sovereign Masterclass & Access Portal (V4)
# ==============================================================================
set -e

echo "[+] Initializing fourth high-converting masterclass and private access pipeline..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_masterclass_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryMasterclass = [
    { fullName: 'Morgan Vance', email: 'morgan@vancetec.io', accessLevel: 'VIP Executive Pass', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory masterclass store.");
});

const MasterclassSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    accessLevel: { type: String, default: 'VIP Executive Pass' },
    createdAt: { type: Date, default: Date.now }
});

const MasterclassRegistration = mongoose.models.MasterclassRegistration || mongoose.model('MasterclassRegistration', MasterclassSchema);

function sendMasterclassAlert(fullName, email, accessLevel, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🎯 [MASTERCLASS PORTAL] NEW REGISTRATION SECURED! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🎟️ [PASS TYPE]: ${accessLevel}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🎯 *New Masterclass Registration!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🎟️ *Pass:* \`${accessLevel}\`\n🔢 *Reg #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram masterclass alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram masterclass alert failed:", err.message);
        });
    }
}

app.post('/api/masterclass/register', async (req, res) => {
    try {
        const { fullName, email, accessLevel } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Name and email are required to secure your seat.' });
        }

        const selectedAccess = accessLevel || 'VIP Executive Pass';
        let regCount;

        if (isMongoConnected) {
            const existing = await MasterclassRegistration.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered for the masterclass.' });
            }
            const count = await MasterclassRegistration.countDocuments();
            regCount = count + 1;
            const newReg = new MasterclassRegistration({ fullName, email, accessLevel: selectedAccess });
            await newReg.save();
        } else {
            const existing = memoryMasterclass.find(r => r.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered for the masterclass.' });
            }
            regCount = memoryMasterclass.length + 1;
            memoryMasterclass.unshift({ fullName, email, accessLevel: selectedAccess, createdAt: new Date() });
        }

        sendMasterclassAlert(fullName, email, selectedAccess, regCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Seat reserved successfully. Access stream links will arrive shortly.', 
            regCount 
        });
    } catch (err) {
        console.error("[ERROR] Masterclass registration failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Masterclass portal server V4 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view real-time registrations.`);
});
SRV_EOF

echo "[+] Writing Masterclass Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #04060d;
    --surface-bg: #0a0f1d;
    --card-bg: #121a2e;
    --border-color: #1e2c4f;
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

.masterclass-container {
    width: 100%;
    max-width: 550px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 3rem 2.5rem;
    box-shadow: 0 40px 90px rgba(0, 0, 0, 0.85);
    position: relative;
    overflow: hidden;
}

.masterclass-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--gold-bright), var(--accent-teal));
}

.mc-header {
    text-align: center;
    margin-bottom: 2rem;
}

.mc-tag {
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

.mc-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.mc-header h1 span {
    color: var(--gold-bright);
}

.mc-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.agenda-box {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 1.25rem;
    margin-bottom: 2rem;
}

.agenda-box h3 {
    font-size: 0.8rem;
    color: var(--accent-teal);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 0.75rem;
    font-weight: 700;
}

.agenda-list {
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.agenda-list li {
    font-size: 0.85rem;
    color: var(--text-secondary);
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.agenda-list li::before {
    content: '✓';
    color: var(--success);
    font-weight: 800;
}

.masterclass-form {
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
    border-color: var(--gold-bright);
    box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.2);
}

select {
    cursor: pointer;
}

button.btn-masterclass {
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
    box-shadow: 0 6px 20px rgba(212, 175, 55, 0.3);
    margin-top: 0.5rem;
}

button.btn-masterclass:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(212, 175, 55, 0.45);
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

.mc-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Masterclass Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Sovereign Masterclass</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="masterclass-container">
        <div class="mc-header">
            <div class="mc-tag">Private Briefing &bull; Limited Seat Count</div>
            <h1>Architecting <span>Autonomous Wealth</span> &amp; Infrastructure</h1>
            <p>Join our private briefing session detailing zero-dependency microkernels, sovereign distribution pipelines, and automated asset routing.</p>
        </div>

        <div class="agenda-box">
            <h3>Briefing Curriculum Highlights</h3>
            <ul class="agenda-list">
                <li>Deploying zero-dependency infrastructure nodes from scratch</li>
                <li>Automating end-to-end client capture and payment pipelines</li>
                <li>Sovereign routing protocols and private network architectures</li>
            </ul>
        </div>

        <form id="masterclass-form" class="masterclass-form">
            <div class="input-group">
                <label for="fullName">Full Name</label>
                <input type="text" id="fullName" placeholder="Morgan Vance" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Secure Email Address</label>
                <input type="email" id="email" placeholder="morgan@vancetec.io" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="accessLevel">Select Access Tier</label>
                <select id="accessLevel">
                    <option value="VIP Executive Pass">VIP Executive Pass (Live Q&amp;A + Source Vault)</option>
                    <option value="General Observer">General Observer (Stream Access Only)</option>
                </select>
            </div>

            <button type="submit" class="btn-masterclass">Reserve My Briefing Seat</button>
        </form>

        <div id="toast"></div>

        <div class="mc-footer">
            EB Enterprises &bull; Zero Spam &bull; Confidential Briefing
        </div>
    </div>

    <script>
        document.getElementById('masterclass-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const accessLevel = document.getElementById('accessLevel').value;
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Reserving Seat...';

            try {
                const res = await fetch('/api/masterclass/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, accessLevel })
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
                    document.getElementById('masterclass-form').reset();
                    submitBtn.textContent = 'Seat Reserved ✓';
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
                submitBtn.textContent = 'Reserve My Briefing Seat';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of fourth masterclass portal..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_masterclass_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Masterclass portal successfully deployed and active on port 5000."
echo "[+] Monitor real-time registrations with:"
echo ""
echo "    tail -f server.log"
echo ""
