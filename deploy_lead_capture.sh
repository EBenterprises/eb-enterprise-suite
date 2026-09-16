#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - High-Converting Lead Capture Engine
# ==============================================================================
set -e

echo "[+] Initializing lead capture directory structure..."
mkdir -p public server

echo "[+] Writing Lead Capture Server (server.js)..."
cat << 'SRV_EOF' > server.js
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_lead_capture';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

let memoryLeads = [
    { email: 'operator@eb.enterprise', source: 'Direct System Injection', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory lead store.");
});

const LeadSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    source: { type: String, default: 'Direct Opt-In' },
    createdAt: { type: Date, default: Date.now }
});

const Lead = mongoose.models.Lead || mongoose.model('Lead', LeadSchema);

// Lead Capture API Endpoint
app.post('/api/capture', async (req, res) => {
    try {
        const { email, source } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email address is required for capture.' });
        }

        const leadSource = source || 'Direct Opt-In';

        if (isMongoConnected) {
            const existing = await Lead.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            const newLead = new Lead({ email, source: leadSource });
            await newLead.save();
            const totalLeads = await Lead.countDocuments();
            return res.status(200).json({ success: true, message: 'Access successfully secured.', totalLeads });
        } else {
            const existing = memoryLeads.find(l => l.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered.' });
            }
            memoryLeads.unshift({ email, source: leadSource, createdAt: new Date() });
            return res.status(200).json({ success: true, message: 'Access successfully secured.', totalLeads: memoryLeads.length });
        }
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
});

app.get('/api/stats', async (req, res) => {
    try {
        if (isMongoConnected) {
            const count = await Lead.countDocuments();
            return res.json({ totalLeads: count });
        } else {
            return res.json({ totalLeads: memoryLeads.length });
        }
    } catch (err) {
        return res.json({ totalLeads: 1 });
    }
});

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Lead capture server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Executive Spectrum Stylesheet (public/style.css)..."
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
    max-width: 500px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 14px;
    padding: 2.5rem 2rem;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.7);
    text-align: center;
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
    line-height: 1.25;
    margin-bottom: 0.75rem;
    letter-spacing: -0.02em;
}

.headline span {
    color: var(--accent-teal);
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
    gap: 1rem;
}

.input-group {
    position: relative;
}

input[type="email"] {
    width: 100%;
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 1rem 1.15rem;
    border-radius: 8px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input[type="email"]:focus {
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
}

.footer-note {
    margin-top: 1.75rem;
    font-size: 0.75rem;
    color: var(--text-secondary);
    letter-spacing: 0.03em;
}
CSS_EOF

echo "[+] Writing Lead Capture View (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Secure Access Portal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="capture-container">
        <div class="badge">Restricted Access Portal</div>
        <h1 class="headline">Secure Your Spot in the <span>Executive Network</span></h1>
        <p class="subheadline">Enter your primary email address below to unlock instant deployment keys and sovereign utility access.</p>

        <form id="capture-form" class="capture-form">
            <div class="input-group">
                <input type="email" id="email" placeholder="Enter your email address..." required autocomplete="email">
            </div>
            <button type="submit" class="btn-capture">Unlock Access Now</button>
        </form>

        <div id="toast"></div>

        <div class="footer-note">
            EB Enterprises &bull; Zero Spam &bull; Sovereign Infrastructure
        </div>
    </div>

    <script>
        document.getElementById('capture-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Securing Access...';

            try {
                const res = await fetch('/api/capture', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, source: 'Direct Lead Capture' })
                });
                const data = await res.json();

                toast.style.display = 'block';
                if (res.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = data.message;
                    document.getElementById('capture-form').reset();
                    submitBtn.textContent = 'Access Secured ✓';
                } else {
                    throw new Error(data.error || 'Capture failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Unlock Access Now';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of lead capture page..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_lead_capture" nohup node server.js > server.log 2>&1 &
echo "[+] Lead capture page successfully deployed and active on port 5000."
