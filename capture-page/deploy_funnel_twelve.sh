#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Action Over Shipping Launchpad (V12)
# ==============================================================================
set -e

echo "[+] Initializing twelfth action-oriented launchpad..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_action_launch_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryMakers = [
    { fullName: 'Morgan Vance', email: 'morgan@startdoing.club', coreProject: 'Software / Micro-SaaS', actionGoal: 'Execute & Build Now', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory action store.");
});

const ActionSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    coreProject: { type: String, required: true },
    actionGoal: { type: String, required: true },
    executionNotes: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const ActionMaker = mongoose.models.ActionMaker || mongoose.model('ActionMaker', ActionSchema);

function sendActionAlert(fullName, email, coreProject, actionGoal, executionNotes, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`⚡ [START DOING] NEW BUILDER REGISTRATION! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🛠️ [PROJECT]: ${coreProject}`);
    console.log(`🎯 [GOAL]: ${actionGoal}`);
    console.log(`💡 [NOTES]: ${executionNotes || 'None provided'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`⚡ *New Start Doing Registration!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🛠️ *Project:* \`${coreProject}\`\n🎯 *Goal:* \`${actionGoal}\`\n💡 *Notes:* \`${executionNotes || 'N/A'}\`\n🔢 *Reg #:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram action alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram alert failed:", err.message);
        });
    }
}

app.post('/api/action/register', async (req, res) => {
    try {
        const { fullName, email, coreProject, actionGoal, executionNotes } = req.body;
        if (!fullName || !email || !coreProject || !actionGoal) {
            return res.status(400).json({ error: 'Name, email, project type, and goal are required.' });
        }

        let regCount;

        if (isMongoConnected) {
            const existing = await ActionMaker.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await ActionMaker.countDocuments();
            regCount = count + 1;
            const newMaker = new ActionMaker({ fullName, email, coreProject, actionGoal, executionNotes: executionNotes || '' });
            await newMaker.save();
        } else {
            const existing = memoryMakers.find(m => m.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            regCount = memoryMakers.length + 1;
            memoryMakers.unshift({ fullName, email, coreProject, actionGoal, executionNotes: executionNotes || '', createdAt: new Date() });
        }

        sendActionAlert(fullName, email, coreProject, actionGoal, executionNotes, regCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Execution framework locked. Check your inbox to start doing right now.', 
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
    console.log(`[+] Action server V12 active on port ${PORT}`);
    console.log(`[+] Live telemetry active. Run 'tail -f server.log' to view incoming signups.`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #060810;
    --surface-bg: #0d121f;
    --card-bg: #141b2c;
    --border-color: #212d47;
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

.action-container {
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

.action-container::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--gold), var(--accent-teal));
}

.action-header {
    text-align: center;
    margin-bottom: 2rem;
}

.action-pill {
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

.action-header h1 {
    font-size: 2rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-primary);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.action-header h1 span {
    color: var(--gold);
}

.action-header p {
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
    color: var(--accent-teal);
    margin-bottom: 0.2rem;
}

.phase-card .ph-desc {
    font-size: 0.7rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.action-form {
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

button.btn-action {
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

button.btn-action:hover {
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

.action-footer {
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
    <title>Start Doing &bull; Not Shipping</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="action-container">
        <div class="action-header">
            <div class="action-pill">Action Over Endless Planning</div>
            <h1>Stop Endless Shipping &amp; <span>Start Doing</span></h1>
            <p>Enough overthinking and endless deployment loops. Tell us what you are working on, and get the exact momentum framework to start executing today.</p>
        </div>

        <div class="phases-grid">
            <div class="phase-card">
                <div class="ph-title">1. Focus</div>
                <div class="ph-desc">One Core Goal</div>
            </div>
            <div class="phase-card">
                <div class="ph-title">2. Execute</div>
                <div class="ph-desc">Daily Action</div>
            </div>
            <div class="phase-card">
                <div class="ph-title">3. Build</div>
                <div class="ph-desc">Real Results</div>
            </div>
        </div>

        <form id="action-form" class="action-form">
            <div class="input-group">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Morgan Vance" required autocomplete="name">
            </div>

            <div class="input-group">
                <label for="email">Your Email Address</label>
                <input type="email" id="email" placeholder="morgan@startdoing.club" required autocomplete="email">
            </div>

            <div class="input-group">
                <label for="coreProject">What is your primary project?</label>
                <select id="coreProject" required>
                    <option value="" disabled selected>Choose your project...</option>
                    <option value="Software / Micro-SaaS">Software / Micro-SaaS</option>
                    <option value="Digital Product / Guides">Digital Product / Guides</option>
                    <option value="Services / Freelancing">Services / Freelancing</option>
                    <option value="Content / Media Business">Content / Media Business</option>
                    <option value="Other Business Venture">Other Business Venture</option>
                </select>
            </div>

            <div class="input-group">
                <label for="actionGoal">What is your immediate execution goal?</label>
                <select id="actionGoal" required>
                    <option value="" disabled selected>Choose your immediate goal...</option>
                    <option value="Execute & Build Now">Execute &amp; Build Now</option>
                    <option value="Stop Procrastinating & Launch">Stop Procrastinating &amp; Launch</option>
                    <option value="Secure First Paying Customer">Secure First Paying Customer</option>
                    <option value="Simplify My Operations">Simplify My Operations</option>
                </select>
            </div>

            <div class="input-group">
                <label for="executionNotes">What has been holding you back? (Optional)</label>
                <textarea id="executionNotes" placeholder="Briefly describe your current bottleneck..."></textarea>
            </div>

            <button type="submit" class="btn-action">Lock In Execution Plan</button>
        </form>

        <div id="toast"></div>

        <div class="action-footer">
            EB Enterprises &bull; Start Doing &bull; Zero Fluff
        </div>
    </div>

    <script>
        document.getElementById('action-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const coreProject = document.getElementById('coreProject').value;
            const actionGoal = document.getElementById('actionGoal').value;
            const executionNotes = document.getElementById('executionNotes').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !coreProject || !actionGoal) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Locking In Framework...';

            try {
                const res = await fetch('/api/action/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, coreProject, actionGoal, executionNotes })
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
                    document.getElementById('action-form').reset();
                    submitBtn.textContent = 'Plan Locked ✓';
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
                submitBtn.textContent = 'Lock In Execution Plan';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of start doing launchpad (V12)..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_action_launch_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] Start doing launchpad successfully deployed and active on port 5000."

# Auto-open browser & refresh
TARGET_URL="http://localhost:5000"
if command -v xdg-open &> /dev/null; then
    xdg-open "$TARGET_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$TARGET_URL" 2>/dev/null &
elif command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Start-Process '$TARGET_URL'" 2>/dev/null &
fi

echo "[+] Live server refreshed and browser opened."
