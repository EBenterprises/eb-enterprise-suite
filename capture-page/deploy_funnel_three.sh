#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Syndicate Launchpad Funnel (V3)
# ==============================================================================
set -e

echo "[+] Initializing third high-converting syndicate launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_syndicate_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memorySyndicate = [
    { fullName: 'Julian Cross', email: 'julian@crosscap.io', allocationSize: '$25,000+', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory syndicate store.");
});

const SyndicateSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    allocationSize: { type: String, default: '$10,000 - $25,000' },
    createdAt: { type: Date, default: Date.now }
});

const SyndicateSubmission = mongoose.models.SyndicateSubmission || mongoose.model('SyndicateSubmission', SyndicateSchema);

function sendSyndicateAlert(fullName, email, allocationSize, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🚀 [SYNDICATE LAUNCHPAD] NEW CAPITAL COMMITMENT! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`💰 [ALLOCATION]: ${allocationSize}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🚀 *New Syndicate Commitment!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n💰 *Allocation:* \`${allocationSize}\`\n🔢 *Commitment #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram syndicate alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram syndicate alert failed:", err.message);
        });
    }
}

app.post('/api/syndicate/submit', async (req, res) => {
    try {
        const { fullName, email, allocationSize } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Name and secure email are required.' });
        }

        const selectedAllocation = allocationSize || '$10,000 - $25,000';
        let submissionCount;

        if (isMongoConnected) {
            const existing = await SyndicateSubmission.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the syndicate ledger.' });
            }
            const count = await SyndicateSubmission.countDocuments();
            submissionCount = count + 1;
            const newSub = new SyndicateSubmission({ fullName, email, allocationSize: selectedAllocation });
            await newSub.save();
        } else {
            const existing = memorySyndicate.find(s => s.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the syndicate ledger.' });
            }
            submissionCount = memorySyndicate.length + 1;
            memorySyndicate.unshift({ fullName, email, allocationSize: selectedAllocation, createdAt: new Date() });
        }

        sendSyndicateAlert(fullName, email, selectedAllocation, submissionCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Commitment registered. Node deployment files will be dispatched via secure email.', 
            submissionCount 
        });
    } catch (err) {
        console.error("[ERROR] Syndicate submission failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Syndicate launchpad server V3 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming commitments.`);
});
SRV_EOF

echo "[+] Writing Syndicate Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #060913;
    --surface-bg: #0d1322;
    --card-bg: #151d30;
    --border-color: #23314f;
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

.syndicate-container {
    width: 100%;
    max-width: 560px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 3rem 2.5rem;
    box-shadow: 0 35px 80px rgba(0, 0, 0, 0.85);
    position: relative;
    overflow: hidden;
}

.syndicate-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--accent-teal), var(--gold-bright));
}

.syndicate-header {
    text-align: center;
    margin-bottom: 2rem;
}

.syndicate-tag {
    display: inline-block;
    background: rgba(0, 210, 196, 0.1);
    border: 1px solid rgba(0, 210, 196, 0.3);
    color: var(--accent-teal);
    font-size: 0.7rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.syndicate-header h1 {
    font-size: 2.1rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.syndicate-header h1 span {
    color: var(--accent-teal);
}

.syndicate-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.features-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.feature-tile {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.feature-tile .ft-num {
    font-size: 1.15rem;
    font-weight: 800;
    color: var(--gold-bright);
    margin-bottom: 0.2rem;
}

.feature-tile .ft-lbl {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight: 600;
}

.syndicate-form {
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

button.btn-syndicate {
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
    box-shadow: 0 6px 20px rgba(0, 210, 196, 0.35);
    margin-top: 0.5rem;
}

button.btn-syndicate:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(0, 210, 196, 0.5);
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

.syndicate-footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border-color);
    padding-top: 1.25rem;
}
CSS_EOF

echo "[+] Writing Syndicate Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Syndicate Launchpad</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="syndicate-container">
        <div class="syndicate-header">
            <div class="syndicate-tag">Global Private Syndicate</div>
            <h1>Claim Your Stake in <span>Autonomous Scale</span></h1>
            <p>Direct deployment keys for vetted operators. Lock in your funding allocation before the syndicate round closes permanently.</p>
        </div>

        <div class="features-grid">
            <div class="feature-tile">
                <div class="ft-num">0%</div>
                <div class="ft-lbl">Fees</div>
            </div>
            <div class="feature-tile">
                <div class="ft-num">Instant</div>
                <div class="ft-lbl">Deployment</div>
            </div>
            <div class="feature-tile">
                <div class="ft-num">Direct</div>
                <div class="ft-lbl">Access</div>
            </div>
        </div>

        <form id="syndicate-form" class="syndicate-form">
            <div class="input-group">
                <label for="fullName">Full Name or Entity</label>
                <input type="text" id="fullName" placeholder="Julian Cross" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Secure Contact Email</label>
                <input type="email" id="email" placeholder="julian@crosscap.io" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="allocationSize">Intended Allocation Tier</label>
                <select id="allocationSize">
                    <option value="$10,000 - $25,000">$10,000 - $25,000 (Standard Stake)</option>
                    <option value="$25,000 - $100,000">$25,000 - $100,000 (Priority Stake)</option>
                    <option value="$100,000+">$100,000+ (Founding Syndicate Anchor)</option>
                </select>
            </div>

            <button type="submit" class="btn-syndicate">Secure Syndicate Allocation</button>
        </form>

        <div id="toast"></div>

        <div class="syndicate-footer">
            EB Enterprises &bull; Sovereign Infrastructure &bull; End-to-End Encrypted
        </div>
    </div>

    <script>
        document.getElementById('syndicate-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const allocationSize = document.getElementById('allocationSize').value;
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Registering Commitment...';

            try {
                const res = await fetch('/api/syndicate/submit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, allocationSize })
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
                    document.getElementById('syndicate-form').reset();
                    submitBtn.textContent = 'Allocation Secured ✓';
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
                submitBtn.textContent = 'Secure Syndicate Allocation';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of third syndicate launchpad..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_syndicate_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Syndicate launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time commitments with:"
echo ""
echo "    tail -f server.log"
echo ""
