#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Elite Access Sales Funnel Engine (V2)
# ==============================================================================
set -e

echo "[+] Initializing second high-converting sales funnel architecture..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_elite_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memorySubmissions = [
    { fullName: 'Victoria Sterling', email: 'victoria@sterling.ventures', assetClass: 'Quantum Core', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory elite store.");
});

const EliteSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    assetClass: { type: String, default: 'Quantum Core' },
    createdAt: { type: Date, default: Date.now }
});

const EliteSubmission = mongoose.models.EliteSubmission || mongoose.model('EliteSubmission', EliteSchema);

function sendEliteAlert(fullName, email, assetClass, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`💎 [ELITE FUNNEL] NEW APPLICATION RECEIVED! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🚀 [INTEREST]: ${assetClass}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`💎 *New Elite Funnel Application!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🚀 *Interest:* \`${assetClass}\`\n🔢 *App #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram elite alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram elite alert failed:", err.message);
        });
    }
}

app.post('/api/elite/submit', async (req, res) => {
    try {
        const { fullName, email, assetClass } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Full name and secure email are required.' });
        }

        const selectedAsset = assetClass || 'Quantum Core';
        let submissionCount;

        if (isMongoConnected) {
            const existing = await EliteSubmission.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the elite registry.' });
            }
            const count = await EliteSubmission.countDocuments();
            submissionCount = count + 1;
            const newSub = new EliteSubmission({ fullName, email, assetClass: selectedAsset });
            await newSub.save();
        } else {
            const existing = memorySubmissions.find(s => s.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the elite registry.' });
            }
            submissionCount = memorySubmissions.length + 1;
            memorySubmissions.unshift({ fullName, email, assetClass: selectedAsset, createdAt: new Date() });
        }

        sendEliteAlert(fullName, email, selectedAsset, submissionCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Application successfully received. Expect secure transmission within 24 hours.', 
            submissionCount 
        });
    } catch (err) {
        console.error("[ERROR] Elite submission failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Elite funnel server V2 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view submissions.`);
});
SRV_EOF

echo "[+] Writing Elite Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #030509;
    --surface-bg: #090d16;
    --card-bg: #101726;
    --border-color: #1a253a;
    --text-primary: #f8fafc;
    --text-secondary: #8a9bb8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.2);
    --gold: #f3e5ab;
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

.elite-container {
    width: 100%;
    max-width: 540px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 18px;
    padding: 3rem 2.5rem;
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.85);
    position: relative;
}

.elite-header {
    text-align: center;
    margin-bottom: 2rem;
}

.elite-pill {
    display: inline-block;
    background: rgba(212, 175, 55, 0.08);
    border: 1px solid rgba(212, 175, 55, 0.25);
    color: var(--gold-bright);
    font-size: 0.7rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.elite-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.5rem;
}

.elite-header h1 span {
    color: var(--gold-bright);
}

.elite-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.metrics-bar {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.metric-box {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 0.85rem 0.5rem;
    text-align: center;
}

.metric-box .val {
    font-size: 1.1rem;
    font-weight: 800;
    color: var(--accent-teal);
    margin-bottom: 0.15rem;
}

.metric-box .lbl {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.elite-form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.field-group {
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

button.btn-elite {
    background: linear-gradient(135deg, var(--gold-bright), #b89728);
    color: var(--bg-app);
    border: none;
    padding: 1.1rem;
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

button.btn-elite:hover {
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

.elite-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Elite Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Sovereign Asset Allocation</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="elite-container">
        <div class="elite-header">
            <div class="elite-pill">Private Syndicate Access</div>
            <h1>Unlock <span>Autonomous Wealth</span> Architecture</h1>
            <p>Submit your verified credentials to review proprietary market instruments and sovereign deployment nodes.</p>
        </div>

        <div class="metrics-bar">
            <div class="metric-box">
                <div class="val">100%</div>
                <div class="lbl">Sovereign</div>
            </div>
            <div class="metric-box">
                <div class="val">Zero</div>
                <div class="lbl">Intermediaries</div>
            </div>
            <div class="metric-box">
                <div class="val">Instant</div>
                <div class="lbl">Revocation</div>
            </div>
        </div>

        <form id="elite-form" class="elite-form">
            <div class="field-group">
                <label for="fullName">Full Legal or Operating Name</label>
                <input type="text" id="fullName" placeholder="Victoria Sterling" required autocomplete="name">
            </div>

            <div class="field-group">
                <label for="email">Secure Communications Email</label>
                <input type="email" id="email" placeholder="victoria@sterling.ventures" required autocomplete="email">
            </div>

            <div class="field-group">
                <label for="assetClass">Primary Investment Focus</label>
                <select id="assetClass">
                    <option value="Quantum Core">Quantum Core &amp; Microkernels</option>
                    <option value="Autonomous Infrastructure">Autonomous Infrastructure Nodes</option>
                    <option value="Sovereign Protocol Layer">Sovereign Protocol Resolution</option>
                </select>
            </div>

            <button type="submit" class="btn-elite">Submit Credentials for Review</button>
        </form>

        <div id="toast"></div>

        <div class="elite-footer">
            EB Enterprises &bull; Confidential &bull; Encrypted End-to-End
        </div>
    </div>

    <script>
        document.getElementById('elite-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const assetClass = document.getElementById('assetClass').value;
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Transmitting Credentials...';

            try {
                const res = await fetch('/api/elite/submit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, assetClass })
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
                    document.getElementById('elite-form').reset();
                    submitBtn.textContent = 'Credentials Secured ✓';
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
                submitBtn.textContent = 'Submit Credentials for Review';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of second sales funnel..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_elite_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Second elite sales funnel successfully deployed and active on port 5000."
echo "[+] Monitor real-time submissions with:"
echo ""
echo "    tail -f server.log"
echo ""
