#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Start Doing Not Shipping Platform
# ==============================================================================
set -e

echo "[+] Initializing 'Start Doing Not Shipping' application structure..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/start_doing_not_shipping';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryStore = [
    { fullName: 'Jordan Vance', email: 'jordan@startdoingnotshipping.com', projectType: 'Full-Stack Application', mainBlocker: 'Endless planning / refactoring', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on resilient in-memory store.");
});

const SubmissionSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    projectType: { type: String, required: true },
    mainBlocker: { type: String, required: true },
    customNotes: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const Submission = mongoose.models.Submission || mongoose.model('Submission', SubmissionSchema);

function sendTelegramNotification(fullName, email, projectType, mainBlocker, customNotes, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`⚡ [START DOING NOT SHIPPING] NEW ENTRY! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🛠️ [PROJECT]: ${projectType}`);
    console.log(`🛑 [BLOCKER]: ${mainBlocker}`);
    console.log(`💡 [NOTES]: ${customNotes || 'None'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`⚡ *Start Doing Not Shipping Entry!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🛠️ *Project:* \`${projectType}\`\n🛑 *Blocker:* \`${mainBlocker}\`\n💡 *Notes:* \`${customNotes || 'N/A'}\`\n🔢 *Count:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram notification sent successfully.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram notification failed:", err.message);
        });
    }
}

app.post('/api/submit', async (req, res) => {
    try {
        const { fullName, email, projectType, mainBlocker, customNotes } = req.body;
        if (!fullName || !email || !projectType || !mainBlocker) {
            return res.status(400).json({ error: 'All mandatory fields must be completed.' });
        }

        let totalCount;

        if (isMongoConnected) {
            const existing = await Submission.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await Submission.countDocuments();
            totalCount = count + 1;
            const newSub = new Submission({ fullName, email, projectType, mainBlocker, customNotes: customNotes || '' });
            await newSub.save();
        } else {
            const existing = memoryStore.find(s => s.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            totalCount = memoryStore.length + 1;
            memoryStore.unshift({ fullName, email, projectType, mainBlocker, customNotes: customNotes || '', createdAt: new Date() });
        }

        sendTelegramNotification(fullName, email, projectType, mainBlocker, customNotes, totalCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Commitment recorded. Start doing, not shipping.', 
            totalCount 
        });
    } catch (err) {
        console.error("[ERROR] Submission failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] Start Doing Not Shipping server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-base: #060810;
    --surface: #0d121f;
    --card: #141b2c;
    --border: #212d47;
    --text-main: #ffffff;
    --text-muted: #94a3b8;
    --teal: #00d2c4;
    --teal-glow: rgba(0, 210, 196, 0.25);
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
    background-color: var(--bg-base);
    color: var(--text-main);
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 2rem 1rem;
}

.wrapper {
    width: 100%;
    max-width: 600px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 3rem 2.5rem;
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.85);
    position: relative;
    overflow: hidden;
}

.wrapper::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--teal), var(--gold));
}

.header {
    text-align: center;
    margin-bottom: 2.2rem;
}

.badge {
    display: inline-block;
    background: rgba(0, 210, 196, 0.1);
    border: 1px solid rgba(0, 210, 196, 0.3);
    color: var(--teal);
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.35rem 1rem;
    border-radius: 20px;
    margin-bottom: 1rem;
}

.header h1 {
    font-size: 2.1rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--text-main);
    margin-bottom: 0.6rem;
    line-height: 1.2;
}

.header h1 span {
    color: var(--teal);
}

.header p {
    color: var(--text-muted);
    font-size: 0.95rem;
    line-height: 1.5;
}

.principles {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
    margin-bottom: 2rem;
}

.principle-box {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 1rem 0.5rem;
    text-align: center;
}

.principle-box .p-title {
    font-size: 0.85rem;
    font-weight: 700;
    color: var(--gold);
    margin-bottom: 0.2rem;
}

.principle-box .p-desc {
    font-size: 0.7rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.field {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

label {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-weight: 700;
}

input, select, textarea {
    width: 100%;
    background: var(--bg-base);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 0.95rem 1.1rem;
    border-radius: 8px;
    font-size: 0.95rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus, textarea:focus {
    border-color: var(--teal);
    box-shadow: 0 0 0 3px var(--teal-glow);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 80px;
}

button.submit-btn {
    background: linear-gradient(135deg, var(--teal), #00a89d);
    color: var(--bg-base);
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

button.submit-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(0, 210, 196, 0.45);
}

#feedback {
    margin-top: 1.25rem;
    padding: 0.95rem;
    border-radius: 8px;
    display: none;
    font-weight: 600;
    font-size: 0.85rem;
    text-align: center;
}

.footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.75rem;
    color: var(--text-muted);
    letter-spacing: 0.04em;
    border-top: 1px solid var(--border);
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
    <title>Start Doing Not Shipping</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <div class="badge">Execution Framework</div>
            <h1>Start Doing <span>Not Shipping</span></h1>
            <p>Cut out the endless deployment loops, over-engineering, and planning theater. Focus entirely on pure execution and building what matters.</p>
        </div>

        <div class="principles">
            <div class="principle-box">
                <div class="p-title">Focus</div>
                <div class="p-desc">Zero Distraction</div>
            </div>
            <div class="principle-box">
                <div class="p-title">Action</div>
                <div class="p-desc">Build Daily</div>
            </div>
            <div class="principle-box">
                <div class="p-title">Execution</div>
                <div class="p-desc">Real Progress</div>
            </div>
        </div>

        <form id="action-form" class="form">
            <div class="field">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Jordan Vance" required autocomplete="name">
            </div>

            <div class="field">
                <label for="email">Email Address</label>
                <input type="email" id="email" placeholder="jordan@startdoingnotshipping.com" required autocomplete="email">
            </div>

            <div class="field">
                <label for="projectType">Core Project Type</label>
                <select id="projectType" required>
                    <option value="" disabled selected>Select project type...</option>
                    <option value="Full-Stack Application">Full-Stack Application</option>
                    <option value="Micro-SaaS Product">Micro-SaaS Product</option>
                    <option value="Automation Script / Tool">Automation Script / Tool</option>
                    <option value="Digital Venture / Business">Digital Venture / Business</option>
                    <option value="Other Deep Build">Other Deep Build</option>
                </select>
            </div>

            <div class="field">
                <label for="mainBlocker">Primary Bottleneck</label>
                <select id="mainBlocker" required>
                    <option value="" disabled selected>Select main obstacle...</option>
                    <option value="Endless planning / refactoring">Endless planning / refactoring</option>
                    <option value="Perfectionism & over-polishing">Perfectionism &amp; over-polishing</option>
                    <option value="Distractions & context switching">Distractions &amp; context switching</option>
                    <option value="Lack of consistent daily execution">Lack of consistent daily execution</option>
                </select>
            </div>

            <div class="field">
                <label for="customNotes">Execution Notes (Optional)</label>
                <textarea id="customNotes" placeholder="What are you committing to build today?"></textarea>
            </div>

            <button type="submit" class="submit-btn">Lock In Commitment</button>
        </form>

        <div id="feedback"></div>

        <div class="footer">
            EB Enterprises &bull; Start Doing Not Shipping &bull; All Rights Reserved
        </div>
    </div>

    <script>
        document.getElementById('action-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const projectType = document.getElementById('projectType').value;
            const mainBlocker = document.getElementById('mainBlocker').value;
            const customNotes = document.getElementById('customNotes').value.trim();
            const feedback = document.getElementById('feedback');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !projectType || !mainBlocker) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Locking In...';

            try {
                const res = await fetch('/api/submit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, projectType, mainBlocker, customNotes })
                });

                const contentType = res.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new Error("Invalid server response format.");
                }

                const data = await res.json();

                feedback.style.display = 'block';
                if (res.ok) {
                    feedback.style.background = 'rgba(34, 197, 94, 0.15)';
                    feedback.style.color = 'var(--success)';
                    feedback.style.border = '1px solid var(--success)';
                    feedback.textContent = data.message;
                    document.getElementById('action-form').reset();
                    submitBtn.textContent = 'Committed ✓';
                } else {
                    throw new Error(data.error || 'Submission failed.');
                }
            } catch (err) {
                feedback.style.display = 'block';
                feedback.style.background = 'rgba(239, 68, 68, 0.15)';
                feedback.style.color = 'var(--danger)';
                feedback.style.border = '1px solid var(--danger)';
                feedback.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Lock In Commitment';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Launching new Start Doing Not Shipping application..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/start_doing_not_shipping" nohup node server.js > server.log 2>&1 &
echo "[+] Application successfully deployed and active on port 5000."

# Open browser automatically
TARGET_URL="http://localhost:5000"
if command -v xdg-open &> /dev/null; then
    xdg-open "$TARGET_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$TARGET_URL" 2>/dev/null &
elif command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Start-Process '$TARGET_URL'" 2>/dev/null &
fi

echo "[+] Done."
