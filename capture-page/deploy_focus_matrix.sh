#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Focus Matrix & Execution Engine
# ==============================================================================
set -e

echo "[+] Initializing Focus Matrix execution engine..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/focus_matrix_engine';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryStore = [
    { fullName: 'Sam Vance', email: 'sam@focusmatrix.app', coreObjective: 'Single high-impact build', priorityLevel: 'Absolute Priority', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on resilient in-memory store.");
});

const MatrixSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    coreObjective: { type: String, required: true },
    priorityLevel: { type: String, required: true },
    executionNotes: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const MatrixEntry = mongoose.models.MatrixEntry || mongoose.model('MatrixEntry', MatrixSchema);

function sendTelegramNotification(fullName, email, coreObjective, priorityLevel, executionNotes, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🎯 [FOCUS MATRIX] NEW ENTRY! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`🎯 [OBJECTIVE]: ${coreObjective}`);
    console.log(`⚡ [PRIORITY]: ${priorityLevel}`);
    console.log(`💡 [NOTES]: ${executionNotes || 'None'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🎯 *Focus Matrix Entry!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n🎯 *Objective:* \`${coreObjective}\`\n⚡ *Priority:* \`${priorityLevel}\`\n💡 *Notes:* \`${executionNotes || 'N/A'}\`\n🔢 *Count:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
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

app.post('/api/matrix', async (req, res) => {
    try {
        const { fullName, email, coreObjective, priorityLevel, executionNotes } = req.body;
        if (!fullName || !email || !coreObjective || !priorityLevel) {
            return res.status(400).json({ error: 'All mandatory fields must be completed.' });
        }

        let totalCount;

        if (isMongoConnected) {
            const existing = await MatrixEntry.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const count = await MatrixEntry.countDocuments();
            totalCount = count + 1;
            const newEntry = new MatrixEntry({ fullName, email, coreObjective, priorityLevel, executionNotes: executionNotes || '' });
            await newEntry.save();
        } else {
            const existing = memoryStore.find(s => s.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            totalCount = memoryStore.length + 1;
            memoryStore.unshift({ fullName, email, coreObjective, priorityLevel, executionNotes: executionNotes || '', createdAt: new Date() });
        }

        sendTelegramNotification(fullName, email, coreObjective, priorityLevel, executionNotes, totalCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Focus locked. Zero distractions, absolute execution.', 
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
    console.log(`[+] Focus Matrix server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-base: #05070c;
    --surface: #0d121f;
    --card: #151c2e;
    --border: #232d47;
    --text-main: #ffffff;
    --text-muted: #94a3b8;
    --violet: #8b5cf6;
    --violet-glow: rgba(139, 92, 246, 0.25);
    --gold: #fde047;
    --success: #22c55e;
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
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.9);
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
    background: linear-gradient(90deg, var(--violet), var(--gold));
}

.header {
    text-align: center;
    margin-bottom: 2.2rem;
}

.badge {
    display: inline-block;
    background: rgba(139, 92, 246, 0.12);
    border: 1px solid rgba(139, 92, 246, 0.35);
    color: var(--violet);
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
    color: var(--violet);
}

.header p {
    color: var(--text-muted);
    font-size: 0.95rem;
    line-height: 1.5;
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
    border-color: var(--violet);
    box-shadow: 0 0 0 3px var(--violet-glow);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 90px;
}

button.submit-btn {
    background: linear-gradient(135deg, var(--violet), #7c3aed);
    color: var(--text-main);
    border: none;
    padding: 1.15rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    font-size: 0.95rem;
    transition: all 0.2s;
    box-shadow: 0 6px 20px rgba(139, 92, 246, 0.3);
    margin-top: 0.5rem;
}

button.submit-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(139, 92, 246, 0.45);
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
    <title>Focus Matrix &bull; Absolute Execution</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <div class="badge">Pure Focus Engine</div>
            <h1>The Focus <span>Matrix</span></h1>
            <p>Eliminate distractions, lock onto your single primary objective, and execute without hesitation or template noise.</p>
        </div>

        <form id="matrix-form" class="form">
            <div class="field">
                <label for="fullName">Your Name</label>
                <input type="text" id="fullName" placeholder="Sam Vance" required autocomplete="name">
            </div>

            <div class="field">
                <label for="email">Email Address</label>
                <input type="email" id="email" placeholder="sam@focusmatrix.app" required autocomplete="email">
            </div>

            <div class="field">
                <label for="coreObjective">What is your single core objective?</label>
                <input type="text" id="coreObjective" placeholder="E.g., Finish full-stack build and verify core logic..." required>
            </div>

            <div class="field">
                <label for="priorityLevel">Priority Level</label>
                <select id="priorityLevel" required>
                    <option value="" disabled selected>Select priority...</option>
                    <option value="Absolute Priority">Absolute Priority</option>
                    <option value="High Concentration">High Concentration</option>
                    <option value="Deep Work Mode">Deep Work Mode</option>
                </select>
            </div>

            <div class="field">
                <label for="executionNotes">Execution Parameters (Optional)</label>
                <textarea id="executionNotes" placeholder="Any specific details on how you plan to execute..."></textarea>
            </div>

            <button type="submit" class="submit-btn">Initialize Focus Matrix</button>
        </form>

        <div id="feedback"></div>

        <div class="footer">
            EB Enterprises &bull; Focus Matrix &bull; Zero Noise
        </div>
    </div>

    <script>
        document.getElementById('matrix-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const coreObjective = document.getElementById('coreObjective').value.trim();
            const priorityLevel = document.getElementById('priorityLevel').value;
            const executionNotes = document.getElementById('executionNotes').value.trim();
            const feedback = document.getElementById('feedback');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email || !coreObjective || !priorityLevel) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Locking Focus...';

            try {
                const res = await fetch('/api/matrix', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, coreObjective, priorityLevel, executionNotes })
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
                    document.getElementById('matrix-form').reset();
                    submitBtn.textContent = 'Locked ✓';
                } else {
                    throw new Error(data.error || 'Submission failed.');
                }
            } catch (err) {
                feedback.style.display = 'block';
                feedback.style.background = 'rgba(239, 68, 68, 0.15)';
                feedback.style.color = '#ef4444';
                feedback.style.border = '1px solid #ef4444';
                feedback.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Initialize Focus Matrix';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Launching Focus Matrix application..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/focus_matrix_engine" nohup node server.js > server.log 2>&1 &
echo "[+] Application successfully deployed and active on port 5000."

# Auto-open browser
TARGET_URL="http://localhost:5000"
if command -v xdg-open &> /dev/null; then
    xdg-open "$TARGET_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$TARGET_URL" 2>/dev/null &
elif command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Start-Process '$TARGET_URL'" 2>/dev/null &
fi

echo "[+] Done."
