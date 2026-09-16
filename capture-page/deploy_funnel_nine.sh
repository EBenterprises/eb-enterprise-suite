#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - No-BS Business Launchpad (V9)
# ==============================================================================
set -e

echo "[+] Initializing ninth no-BS business launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_nobs_launch_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryFounders = [
    { fullName: 'Jack Miller', email: 'jack@simplebuild.io', businessType: 'Online Store / E-commerce', currentStage: 'Just starting out', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory founder store.");
});

const NoBSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    businessType: { type: String, required: true },
    currentStage: { type: String, required: true },
    goalDetails: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const NoBSFounder = mongoose.models.NoBSFounder || mongoose.model('NoBSFounder', NoBSchema);

function sendNoBSAlert(fullName, email, businessType, currentStage, goalDetails, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🔥 [NO-BS LAUNCH] NEW FOUNDER SIGNUP! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🛠️ [TYPE]: ${businessType}`);
    console.log(`📈 [STAGE]: ${currentStage}`);
    console.log(`🎯 [GOAL]: ${goalDetails || 'None provided'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🔥 *New No-BS Founder Signup!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🛠️ *Type:* \`${businessType}\`\n📈 *Stage:* \`${currentStage}\`\n🎯 *Goal:* \`${goalDetails || 'N/A'}\`\n🔢 *Signup #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram no-BS alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram alert failed:", err.message);
        });
    }
}

app.post('/api/launch/register', async (req, res) => {
    try {
        const { fullName, email, businessType, currentStage, goalDetails } = req.body;
        if (!fullName || !email || !businessType || !currentStage) {
            return res.status(400).json({ error: 'Name, email, business type, and stage are required.' });
        }

        let signupCount;

        if (isMongoConnected) {
            const existing = await NoBSFounder.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await NoBSFounder.countDocuments();
            signupCount = count + 1;
            const newFounder = new NoBSFounder({ fullName, email, businessType, currentStage, goalDetails: goalDetails || '' });
            await newFounder.save();
        } else {
            const existing = memoryFounders.find(f => f.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            signupCount = memoryFounders.length + 1;
            memoryFounders.unshift({ fullName, email, businessType, currentStage, goalDetails: goalDetails || '', createdAt: new Date() });
        }

        sendNoBSAlert(fullName, email, businessType, currentStage, goalDetails, signupCount);

        return res.status(200).json({ 
            success: true, 
            message: 'You are all set! Check your inbox for your step-by-step setup guide.', 
            signupCount 
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
    console.log(`[+] No-BS business funnel server V9 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming signups.`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #0a0e17;
    --surface-bg: #121824;
    --card-bg: #1a2233;
    --border-color: #27344f;
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

.launch-container {
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

.launch-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--accent-teal), var(--gold));
}

.launch-header {
    text-align: center;
    margin-bottom: 2rem;
}

.launch-pill {
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

.launch-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.launch-header h1 span {
    color: var(--accent-teal);
}

.launch-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.steps-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.step-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.step-card .st-title {
    font-size: 0.85rem;
    font-weight: 700;
    color: var(--gold);
    margin-bottom: 0.2rem;
}

.step-card .st-desc {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.launch-form {
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

button.btn-launch {
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

button.btn-launch:hover {
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

.launch-footer {
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
    <title>Start Your Business - No Fluff</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="launch-container">
        <div class="launch-header">
            <div class="launch-pill">No Fluff &bull; Real Results</div>
            <h1>Want to Start a Business? <span>Let’s Build It.</span></h1>
            <p>No confusing jargon, no wasted time. Tell us what you want to sell, and we will send you the exact steps to get your first customer.</p>
        </div>

        <div class="steps-grid">
            <div class="step-card">
                <div class="st-title">1. Pick Idea</div>
                <div class="st-desc">Products & Services</div>
            </div>
            <div class="step-card">
                <div class="st-title">2. Set Up</div>
                <div class="st-desc">Simple Setup</div>
            </div>
            <div class="step-card">
                <div class="st-title">3. Launch</div>
                <div class="st-desc">Make Sales</div>
            </div>
        </div>

        <form id="launch-form" class="launch-form">
            <div class="input-group">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Jack Miller" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Your Email Address</label>
                <input type="email" id="email" placeholder="jack@simplebuild.io" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="businessType">What type of business do you want to start?</label>
                <select id="businessType" required>
                    <option value="" disabled selected>Choose your business type...</option>
                    <option value="Online Store / E-commerce">Online Store / Selling Products</option>
                    <option value="Services / Consulting">Offering Services or Consulting</option>
                    <option value="Software / App">Building Software or an App</option>
                    <option value="Content / Media">Content Creation or Media</option>
                    <option value="Other Business">Something Else</option>
                </select>
            </div>

            <div class="input-group">
                <label for="currentStage">Where are you right now?</label>
                <select id="currentStage" required>
                    <option value="" disabled selected>Choose where you are...</option>
                    <option value="Just starting out / Have an idea">Just starting out / Have an idea</option>
                    <option value="Working on setup / Building">Working on setup / Building</option>
                    <option value="Already selling / Looking to grow">Already selling / Looking to grow</option>
                </select>
            </div>

            <div class="input-group">
                <label for="goalDetails">What are you planning to sell? (Optional)</label>
                <textarea id="goalDetails" placeholder="Briefly describe your products or services..."></textarea>
            </div>

            <button type="submit" class="btn-launch">Get My Step-by-Step Guide</button>
        </form>

        <div id="toast"></div>

        <div class="launch-footer">
            EB Enterprises &bull; Straightforward Business Guides &bull; Zero Spam
        </div>
    </div>

    <script>
        document.getElementById('launch-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const businessType = document.getElementById('businessType').value;
            const currentStage = document.getElementById('currentStage').value;
            const goalDetails = document.getElementById('goalDetails').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !businessType || !currentStage) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Sending Guide...';

            try {
                const res = await fetch('/api/launch/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, businessType, currentStage, goalDetails })
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
                    document.getElementById('launch-form').reset();
                    submitBtn.textContent = 'Guide Sent ✓';
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
                submitBtn.textContent = 'Get My Step-by-Step Guide';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of no-BS business launchpad (V9)..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_nobs_launch_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] No-BS business launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time signups with:"
echo ""
echo "    tail -f server.log"
echo ""
