#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Dignity & Community Support Platform
# ==============================================================================
set -e

echo "[+] Initializing dignity and community support platform..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_homeless_support_platform';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryStore = [
    { fullName: 'Community Advocate', contactInfo: 'support@communitydignity.org', resourceNeeded: 'Emergency Shelter & Meals', locationNotes: 'Downtown Core', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on resilient in-memory store.");
});

const SupportSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    contactInfo: { type: String, required: true, trim: true },
    resourceNeeded: { type: String, required: true },
    locationNotes: { type: String, required: true },
    additionalDetails: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now }
});

const SupportEntry = mongoose.models.SupportEntry || mongoose.model('SupportEntry', SupportSchema);

function sendTelegramNotification(fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails, count) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🤝 [DIGNITY SUPPORT] NEW ASSISTANCE REQUEST! [#${count}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME/ALIAS]: ${fullName}`);
    console.log(`📞 [CONTACT]: ${contactInfo}`);
    console.log(`🆘 [RESOURCE]: ${resourceNeeded}`);
    console.log(`📍 [LOCATION]: ${locationNotes}`);
    console.log(`💡 [DETAILS]: ${additionalDetails || 'None'}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🤝 *New Community Support Request!*\n\n👤 *Name:* \`${fullName}\`\n📞 *Contact:* \`${contactInfo}\`\n🆘 *Resource:* \`${resourceNeeded}\`\n📍 *Location:* \`${locationNotes}\`\n💡 *Details:* \`${additionalDetails || 'N/A'}\`\n🔢 *Count:* \`${count}\`\n⏱️ *Time:* ${timestamp}`);
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

app.post('/api/support', async (req, res) => {
    try {
        const { fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails } = req.body;
        if (!fullName || !contactInfo || !resourceNeeded || !locationNotes) {
            return res.status(400).json({ error: 'All mandatory fields must be completed.' });
        }

        let totalCount;

        if (isMongoConnected) {
            const count = await SupportEntry.countDocuments();
            totalCount = count + 1;
            const newEntry = new SupportEntry({ fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails: additionalDetails || '' });
            await newEntry.save();
        } else {
            totalCount = memoryStore.length + 1;
            memoryStore.unshift({ fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails: additionalDetails || '', createdAt: new Date() });
        }

        sendTelegramNotification(fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails, totalCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Request submitted. Local support networks have been notified to assist you.', 
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
    console.log(`[+] Support platform active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-base: #0f172a;
    --surface: #1e293b;
    --card: #334155;
    --border: #475569;
    --text-main: #f8fafc;
    --text-muted: #cbd5e1;
    --accent-blue: #38bdf8;
    --accent-blue-glow: rgba(56, 189, 248, 0.25);
    --gold: #facc15;
    --success: #4ade80;
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
    box-shadow: 0 30px 70px rgba(0, 0, 0, 0.7);
    position: relative;
    overflow: hidden;
}

.wrapper::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 5px;
    background: linear-gradient(90deg, var(--accent-blue), var(--gold));
}

.header {
    text-align: center;
    margin-bottom: 2.2rem;
}

.badge {
    display: inline-block;
    background: rgba(56, 189, 248, 0.15);
    border: 1px solid rgba(56, 189, 248, 0.4);
    color: var(--accent-blue);
    font-size: 0.8rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    padding: 0.4rem 1.1rem;
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
    color: var(--accent-blue);
}

.header p {
    color: var(--text-muted);
    font-size: 1rem;
    line-height: 1.6;
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
    font-size: 0.8rem;
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
    padding: 1rem 1.1rem;
    border-radius: 8px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus, textarea:focus {
    border-color: var(--accent-blue);
    box-shadow: 0 0 0 3px var(--accent-blue-glow);
}

select {
    cursor: pointer;
}

textarea {
    resize: vertical;
    min-height: 90px;
}

button.submit-btn {
    background: linear-gradient(135deg, var(--accent-blue), #0284c7);
    color: #ffffff;
    border: none;
    padding: 1.15rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    font-size: 1rem;
    transition: all 0.2s;
    box-shadow: 0 6px 20px rgba(56, 189, 248, 0.3);
    margin-top: 0.5rem;
}

button.submit-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(56, 189, 248, 0.45);
}

#feedback {
    margin-top: 1.25rem;
    padding: 1rem;
    border-radius: 8px;
    display: none;
    font-weight: 600;
    font-size: 0.9rem;
    text-align: center;
}

.footer {
    margin-top: 1.75rem;
    text-align: center;
    font-size: 0.8rem;
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
    <title>Community Support &bull; Access Resources</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <div class="badge">Community Aid Network</div>
            <h1>Find Shelter &amp; <span>Support Services</span></h1>
            <p>Connect quickly with local emergency housing, warm meals, healthcare services, and community advocates.</p>
        </div>

        <form id="support-form" class="form">
            <div class="field">
                <label for="fullName">Your Name or Alias</label>
                <input type="text" id="fullName" placeholder="First name or preferred identifier" required autocomplete="name">
            </div>

            <div class="field">
                <label for="contactInfo">Contact Information (Phone, Email, or Shelter Name)</label>
                <input type="text" id="contactInfo" placeholder="How can support reach you?" required>
            </div>

            <div class="field">
                <label for="resourceNeeded">Primary Resource Needed</label>
                <select id="resourceNeeded" required>
                    <option value="" disabled selected>Select immediate need...</option>
                    <option value="Emergency Shelter / Housing">Emergency Shelter / Housing</option>
                    <option value="Warm Meals / Food Bank">Warm Meals / Food Bank</option>
                    <option value="Medical or Mental Health Care">Medical or Mental Health Care</option>
                    <option value="Clothing & Hygiene Supplies">Clothing &amp; Hygiene Supplies</option>
                    <option value="General Support / Navigation">General Support / Navigation</option>
                </select>
            </div>

            <div class="field">
                <label for="locationNotes">Current Location / Area</label>
                <input type="text" id="locationNotes" placeholder="E.g., Downtown library, specific street or landmark..." required>
            </div>

            <div class="field">
                <label for="additionalDetails">Additional Details (Optional)</label>
                <textarea id="additionalDetails" placeholder="Any specific needs, immediate safety notes, or urgency..."></textarea>
            </div>

            <button type="submit" class="submit-btn">Request Assistance Now</button>
        </form>

        <div id="feedback"></div>

        <div class="footer">
            Community Dignity Network &bull; Confidential &amp; Accessible
        </div>
    </div>

    <script>
        document.getElementById('support-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const contactInfo = document.getElementById('contactInfo').value.trim();
            const resourceNeeded = document.getElementById('resourceNeeded').value;
            const locationNotes = document.getElementById('locationNotes').value.trim();
            const additionalDetails = document.getElementById('additionalDetails').value.trim();
            const feedback = document.getElementById('feedback');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !contactInfo || !resourceNeeded || !locationNotes) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting Request...';

            try {
                const res = await fetch('/api/support', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, contactInfo, resourceNeeded, locationNotes, additionalDetails })
                });

                const contentType = res.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new Error("Invalid server response format.");
                }

                const data = await res.json();

                feedback.style.display = 'block';
                if (res.ok) {
                    feedback.style.background = 'rgba(74, 222, 128, 0.15)';
                    feedback.style.color = 'var(--success)';
                    feedback.style.border = '1px solid var(--success)';
                    feedback.textContent = data.message;
                    document.getElementById('support-form').reset();
                    submitBtn.textContent = 'Request Sent ✓';
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
                submitBtn.textContent = 'Request Assistance Now';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Launching Community Support application..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_homeless_support_platform" nohup node server.js > server.log 2>&1 &
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
