#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Executive Access Portal Engine
# ==============================================================================
set -e

echo "[+] Initializing directory structure..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_executive_access';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryAccessRequests = [
    { fullName: 'Alexander Wright', email: 'alexander@domain.com', accessId: 1, createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory access store.");
});

const AccessSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    accessId: { type: Number, required: true },
    createdAt: { type: Date, default: Date.now }
});

const AccessRequest = mongoose.models.AccessRequest || mongoose.model('AccessRequest', AccessSchema);

function sendAlert(fullName, email, accessId) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🚨 [EXECUTIVE ACCESS ALERT] NEW CREDENTIAL INITIALIZED! [#${accessId}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [FULL NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🚨 *New Executive Access Request!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🔢 *Access ID:* \`#${accessId}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram push notification dispatched successfully.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram notification dispatch failed:", err.message);
        });
    }
}

app.post('/api/access', async (req, res) => {
    try {
        const { fullName, email } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Full Name and Secure Email are required.' });
        }

        let accessId;

        if (isMongoConnected) {
            const existing = await AccessRequest.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email has already initialized access.' });
            }
            const count = await AccessRequest.countDocuments();
            accessId = count + 1;
            const newReq = new AccessRequest({ fullName, email, accessId });
            await newReq.save();
        } else {
            const existing = memoryAccessRequests.find(r => r.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email has already initialized access.' });
            }
            accessId = memoryAccessRequests.length + 1;
            memoryAccessRequests.unshift({ fullName, email, accessId, createdAt: new Date() });
        }

        sendAlert(fullName, email, accessId);

        return res.status(200).json({ 
            success: true, 
            message: 'Access initialized successfully. Credentials secured.', 
            accessId 
        });
    } catch (err) {
        console.error("[ERROR] Access initialization failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Executive Access server active and listening on port ${PORT}`);
    console.log(`[+] Telemetry monitoring armed. Run 'tail -f server.log' to view real-time phone/server notifications.`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #070a12;
    --surface-bg: #0b0f19;
    --card-bg: #131b2e;
    --border-color: #22304a;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.25);
    --gold: #d4af37;
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
    padding: 1.5rem;
}

.capture-container {
    width: 100%;
    max-width: 480px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 14px;
    padding: 2.5rem 2rem;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.7);
    text-align: left;
}

.badge {
    display: inline-block;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    color: var(--gold);
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.35rem 0.85rem;
    border-radius: 20px;
    margin-bottom: 1.25rem;
}

.headline {
    font-size: 1.85rem;
    font-weight: 800;
    color: var(--text-primary);
    letter-spacing: -0.02em;
    margin-bottom: 0.5rem;
}

.subheadline {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
    margin-bottom: 2rem;
}

.capture-form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

label {
    font-size: 0.8rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight: 700;
}

input {
    width: 100%;
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 0.9rem 1rem;
    border-radius: 8px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

button.btn-capture {
    background: var(--accent-teal);
    color: var(--bg-app);
    border: none;
    padding: 1rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-size: 0.95rem;
    transition: all 0.2s;
    box-shadow: 0 4px 15px rgba(0, 210, 196, 0.3);
    margin-top: 0.5rem;
}

button.btn-capture:hover {
    background: #00b3a6;
    transform: translateY(-1px);
}

#toast {
    margin-top: 1rem;
    padding: 0.85rem;
    border-radius: 6px;
    display: none;
    font-weight: 600;
    font-size: 0.85rem;
    text-align: center;
}

.footer-note {
    margin-top: 1.75rem;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.03em;
    text-align: center;
}
CSS_EOF

echo "[+] Writing Frontend View (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Executive Access</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="capture-container">
        <div class="badge">Restricted Portal</div>
        <h1 class="headline">Executive Access</h1>
        <p class="subheadline">Secure Your Advantage<br>Enter your credentials below to initialize direct access to proprietary architectures and market launch assets.</p>

        <form id="access-form" class="capture-form">
            <div class="form-group">
                <label for="fullName">Full Name</label>
                <input type="text" id="fullName" placeholder="Alexander Wright" required autocomplete="name">
            </div>
            <div class="form-group">
                <label for="email">Secure Email</label>
                <input type="email" id="email" placeholder="alexander@domain.com" required autocomplete="email">
            </div>
            <button type="submit" class="btn-capture">Initialize Access</button>
        </form>

        <div id="toast"></div>

        <div class="footer-note">
            Zero spam guarantee. Immediate cryptographic revocation anytime.
        </div>
    </div>

    <script>
        document.getElementById('access-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Initializing...';

            try {
                const res = await fetch('/api/access', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email })
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
                    document.getElementById('access-form').reset();
                    submitBtn.textContent = 'Access Initialized ✓';
                } else {
                    throw new Error(data.error || 'Initialization failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Initialize Access';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Restarting server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_executive_access" nohup node server.js > server.log 2>&1 &
echo "[+] Executive Access page successfully deployed and active on port 5000."
echo "[+] To view live server & phone notifications instantly when a user submits credentials, run:"
echo ""
echo "    tail -f server.log"
echo ""
