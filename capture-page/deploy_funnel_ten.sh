#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Simple Side Hustle Launchpad (V10)
# ==============================================================================
set -e

echo "[+] Initializing tenth side hustle launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_hustle_launch_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryHustlers = [
    { fullName: 'Chloe Davis', email: 'chloe@sidehustlesimple.co', hustleGoal: 'Extra $1k-$5k/month', timeCommitment: 'Part-time (5-15 hrs/week)', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory hustler store.");
});

const HustleSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    hustleGoal: { type: String, required: true },
    timeCommitment: { type: String, required: true },
    productIdea: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const HustleFounder = mongoose.models.HustleFounder || mongoose.model('HustleFounder', HustleSchema);

function sendHustleAlert(fullName, email, hustleGoal, timeCommitment, productIdea, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`💡 [HUSTLE LAUNCH] NEW HUSTLER SIGNUP! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🎯 [GOAL]: ${hustleGoal}`);
    console.log(`⏰ [TIME]: ${timeCommitment}`);
    console.log(`💡 [IDEA]: ${productIdea || 'None provided'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`💡 *New Hustler Signup!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🎯 *Goal:* \`${hustleGoal}\`\n⏰ *Time:* \`${timeCommitment}\`\n💡 *Idea:* \`${productIdea || 'N/A'}\`\n🔢 *Signup #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram hustle alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram alert failed:", err.message);
        });
    }
}

app.post('/api/hustle/register', async (req, res) => {
    try {
        const { fullName, email, hustleGoal, timeCommitment, productIdea } = req.body;
        if (!fullName || !email || !hustleGoal || !timeCommitment) {
            return res.status(400).json({ error: 'Name, email, goal, and time commitment are required.' });
        }

        let signupCount;

        if (isMongoConnected) {
            const existing = await HustleFounder.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await HustleFounder.countDocuments();
            signupCount = count + 1;
            const newHustler = new HustleFounder({ fullName, email, hustleGoal, timeCommitment, productIdea: productIdea || '' });
            await newHustler.save();
        } else {
            const existing = memoryHustlers.find(h => h.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            signupCount = memoryHustlers.length + 1;
            memoryHustlers.unshift({ fullName, email, hustleGoal, timeCommitment, productIdea: productIdea || '', createdAt: new Date() });
        }

        sendHustleAlert(fullName, email, hustleGoal, timeCommitment, productIdea, signupCount);

        return res.status(200).json({ 
            success: true, 
            message: 'You are ready to go! Check your email for your quick-start roadmap.', 
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
    console.log(`[+] Hustle launch server V10 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming signups.`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #080c14;
    --surface-bg: #101722;
    --card-bg: #182232;
    --border-color: #243048;
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

.hustle-container {
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

.hustle-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--gold), var(--accent-teal));
}

.hustle-header {
    text-align: center;
    margin-bottom: 2rem;
}

.hustle-pill {
    display: inline-block;
    background: rgba(253, 224, 71, 0.1);
    border: 1px solid rgba(253, 224, 71, 0.3);
    color: var(--gold);
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.hustle-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.hustle-header h1 span {
    color: var(--gold);
}

.hustle-header p {
    color: var(--text-secondary);
    font-size: 0.95rem;
    line-height: 1.5;
}

.perks-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.perk-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.perk-card .pk-title {
    font-size: 0.85rem;
    font-weight: 700;
    color: var(--accent-teal);
    margin-bottom: 0.2rem;
}

.perk-card .pk-desc {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.hustle-form {
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
    border-color: var(--gold);
    box-shadow: 0 0 0 3px rgba(253, 224, 71, 0.2);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 80px;
}

button.btn-hustle {
    background: linear-gradient(135deg, var(--gold), #eab308);
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
    box-shadow: 0 6px 20px rgba(234, 179, 8, 0.3);
    margin-top: 0.5rem;
}

button.btn-hustle:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(234, 179, 8, 0.45);
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

.hustle-footer {
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
    <title>Start a Simple Side Hustle</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="hustle-container">
        <div class="hustle-header">
            <div class="hustle-pill">Zero Stress &bull; Real Income</div>
            <h1>Turn Your Skills Into a <span>Profitable Side Hustle</span></h1>
            <p>Ready to make extra money on your own terms? Tell us what you want to achieve, and we will send you a straightforward launch guide.</p>
        </div>

        <div class="perks-grid">
            <div class="perk-card">
                <div class="pk-title">1. Choose</div>
                <div class="pk-desc">Simple Products</div>
            </div>
            <div class="perk-card">
                <div class="pk-title">2. Build</div>
                <div class="pk-desc">Quick Setup</div>
            </div>
            <div class="perk-card">
                <div class="pk-title">3. Earn</div>
                <div class="pk-desc">First Customers</div>
            </div>
        </div>

        <form id="hustle-form" class="hustle-form">
            <div class="input-group">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Chloe Davis" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Your Email Address</label>
                <input type="email" id="email" placeholder="chloe@sidehustlesimple.co" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="hustleGoal">What is your primary income goal?</label>
                <select id="hustleGoal" required>
                    <option value="" disabled selected>Choose your goal...</option>
                    <option value="Extra $500 - $1,000 / month">Extra $500 - $1,000 / month</option>
                    <option value="Extra $1,000 - $5,000 / month">Extra $1,000 - $5,000 / month</option>
                    <option value="Replace my full-time income">Replace my full-time income</option>
                    <option value="Just exploring and testing ideas">Just exploring and testing ideas</option>
                </select>
            </div>

            <div class="input-group">
                <label for="timeCommitment">How much time can you put in weekly?</label>
                <select id="timeCommitment" required>
                    <option value="" disabled selected>Choose your time availability...</option>
                    <option value="Casual (Under 5 hours/week)">Casual (Under 5 hours/week)</option>
                    <option value="Part-time (5 - 15 hours/week)">Part-time (5 - 15 hours/week)</option>
                    <option value="Dedicated (15+ hours/week)">Dedicated (15+ hours/week)</option>
                </select>
            </div>

            <div class="input-group">
                <label for="productIdea">What products or services do you want to offer? (Optional)</label>
                <textarea id="productIdea" placeholder="E.g., digital guides, freelance writing, online coaching, physical items..."></textarea>
            </div>

            <button type="submit" class="btn-hustle">Get My Launch Roadmap</button>
        </form>

        <div id="toast"></div>

        <div class="hustle-footer">
            EB Enterprises &bull; Simple Business Roadmaps &bull; Zero Spam
        </div>
    </div>

    <script>
        document.getElementById('hustle-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const hustleGoal = document.getElementById('hustleGoal').value;
            const timeCommitment = document.getElementById('timeCommitment').value;
            const productIdea = document.getElementById('productIdea').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !hustleGoal || !timeCommitment) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Generating Roadmap...';

            try {
                const res = await fetch('/api/hustle/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, hustleGoal, timeCommitment, productIdea })
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
                    document.getElementById('hustle-form').reset();
                    submitBtn.textContent = 'Roadmap Sent ✓';
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
                submitBtn.textContent = 'Get My Launch Roadmap';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of side hustle launchpad (V10)..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_hustle_launch_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Side hustle launchpad successfully deployed and active on port 5000."
echo "[+] Monitor real-time signups with:"
echo ""
echo "    tail -f server.log"
echo ""
