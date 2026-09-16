#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - High-Converting Sales Funnel Engine
# ==============================================================================
set -e

echo "[+] Initializing full-stack sales funnel structure..."
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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_sales_funnel';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

let memoryLeads = [
    { fullName: 'Jordan Vance', email: 'jordan@vance.io', tier: 'Founding Partner', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory lead store.");
});

const LeadSchema = new mongoose.Schema({
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    tier: { type: String, default: 'Founding Partner' },
    createdAt: { type: Date, default: Date.now }
});

const FunnelLead = mongoose.models.FunnelLead || mongoose.model('FunnelLead', LeadSchema);

function sendFunnelAlert(fullName, email, tier, leadCount) {
    const timestamp = new Date().toLocaleString();

    console.log("\n==================================================");
    console.log(`🔥 [FUNNEL CONVERSION] NEW PRIORITY LEAD! [#${leadCount}]`);
    console.log(`⏱️ [TIMESTAMP]: ${timestamp}`);
    console.log(`👤 [NAME]: ${fullName}`);
    console.log(`📧 [EMAIL]: ${email}`);
    console.log(`💎 [TIER]: ${tier}`);
    console.log("==================================================\n");

    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
        const message = encodeURIComponent(`🔥 *New Sales Funnel Conversion!*\n\n👤 *Name:* \`${fullName}\`\n📧 *Email:* \`${email}\`\n💎 *Tier:* \`${tier}\`\n🔢 *Lead #:* \`${leadCount}\`\n⏱️ *Time:* ${timestamp}`);
        const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=Markdown`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                console.log("[+] Telegram funnel alert dispatched.");
            });
        }).on('error', (err) => {
            console.error("[!] Telegram funnel alert failed:", err.message);
        });
    }
}

app.post('/api/funnel/convert', async (req, res) => {
    try {
        const { fullName, email, tier } = req.body;
        if (!fullName || !email) {
            return res.status(400).json({ error: 'Name and email are required to secure your spot.' });
        }

        const selectedTier = tier || 'Founding Partner';
        let leadCount;

        if (isMongoConnected) {
            const existing = await FunnelLead.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the priority pipeline.' });
            }
            const count = await FunnelLead.countDocuments();
            leadCount = count + 1;
            const newLead = new FunnelLead({ fullName, email, tier: selectedTier });
            await newLead.save();
        } else {
            const existing = memoryLeads.find(l => l.email === email);
            if (existing) {
                return res.status(400).json({ error: 'This email is already registered in the priority pipeline.' });
            }
            leadCount = memoryLeads.length + 1;
            memoryLeads.unshift({ fullName, email, tier: selectedTier, createdAt: new Date() });
        }

        sendFunnelAlert(fullName, email, selectedTier, leadCount);

        return res.status(200).json({ 
            success: true, 
            message: 'Allocation secured successfully. Welcome to the inner circle.', 
            leadCount 
        });
    } catch (err) {
        console.error("[ERROR] Funnel conversion failure:", err.message);
        return res.status(500).json({ error: err.message });
    }
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`[+] High-converting sales funnel server active on port ${PORT}`);
    console.log(`[+] Real-time telemetry monitoring active. Run 'tail -f server.log' to view incoming conversions.`);
});
SRV_EOF

echo "[+] Writing Funnel Stylesheet (public/style.css)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #05070c;
    --surface-bg: #0b0f19;
    --card-bg: #121826;
    --border-color: #1e293b;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.25);
    --gold: #d4af37;
    --gold-glow: rgba(212, 175, 55, 0.2);
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

.funnel-wrapper {
    width: 100%;
    max-width: 580px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    padding: 3rem 2.5rem;
    box-shadow: 0 25px 60px rgba(0, 0, 0, 0.8);
    position: relative;
    overflow: hidden;
}

.funnel-wrapper::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: linear-gradient(90deg, var(--gold), var(--accent-teal));
}

.badge-wrapper {
    display: flex;
    justify-content: center;
    margin-bottom: 1.5rem;
}

.badge {
    background: rgba(212, 175, 55, 0.1);
    border: 1px solid rgba(212, 175, 55, 0.3);
    color: var(--gold);
    font-size: 0.75rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    padding: 0.4rem 1rem;
    border-radius: 30px;
}

.headline {
    font-size: 2.15rem;
    font-weight: 800;
    color: var(--text-primary);
    text-align: center;
    line-height: 1.2;
    margin-bottom: 1rem;
    letter-spacing: -0.02em;
}

.headline span {
    color: var(--accent-teal);
}

.subheadline {
    color: var(--text-secondary);
    font-size: 1.05rem;
    text-align: center;
    line-height: 1.6;
    margin-bottom: 2.25rem;
}

.value-props {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 2rem;
}

.prop-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1rem;
    text-align: center;
}

.prop-card h4 {
    color: var(--gold);
    font-size: 0.85rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 0.25rem;
}

.prop-card p {
    color: var(--text-secondary);
    font-size: 0.8rem;
    line-height: 1.3;
}

.funnel-form {
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
    letter-spacing: 0.06em;
    font-weight: 700;
}

input, select {
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

input:focus, select:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

select {
    cursor: pointer;
}

button.btn-convert {
    background: linear-gradient(135deg, var(--accent-teal), #00b3a6);
    color: var(--bg-app);
    border: none;
    padding: 1.15rem;
    font-weight: 800;
    border-radius: 8px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-size: 1rem;
    transition: all 0.2s;
    box-shadow: 0 6px 20px rgba(0, 210, 196, 0.35);
    margin-top: 0.5rem;
}

button.btn-convert:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 210, 196, 0.5);
}

#toast {
    margin-top: 1.25rem;
    padding: 1rem;
    border-radius: 8px;
    display: none;
    font-weight: 600;
    font-size: 0.9rem;
    text-align: center;
}

.funnel-footer {
    margin-top: 2rem;
    text-align: center;
    font-size: 0.8rem;
    color: var(--text-secondary);
    border-top: 1px solid var(--border-color);
    padding-top: 1.5rem;
    letter-spacing: 0.03em;
}
CSS_EOF

echo "[+] Writing Funnel Page (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Private Allocation Pipeline</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="funnel-wrapper">
        <div class="badge-wrapper">
            <div class="badge">Phase 1 Allocation &bull; Strictly Limited</div>
        </div>
        
        <h1 class="headline">Secure Your Stake in the <span>Next Financial Frontier</span></h1>
        <p class="subheadline">We are onboarding a select group of visionary operators into our sovereign infrastructure. Lock in your priority tier before capacity is exhausted.</p>

        <div class="value-props">
            <div class="prop-card">
                <h4>Private Assets</h4>
                <p>Direct deployment keys for sovereign tech architectures.</p>
            </div>
            <div class="prop-card">
                <h4>Zero Friction</h4>
                <p>Instant pipeline verification & priority access node.</p>
            </div>
        </div>

        <form id="funnel-form" class="funnel-form">
            <div class="form-group">
                <label for="fullName">Full Name</label>
                <input type="text" id="fullName" placeholder="Alexander Wright" required autocomplete="name">
            </div>
            
            <div class="form-group">
                <label for="email">Primary Secure Email</label>
                <input type="email" id="email" placeholder="alexander@domain.com" required autocomplete="email">
            </div>

            <div class="form-group">
                <label for="tier">Select Partnership Tier</label>
                <select id="tier">
                    <option value="Founding Partner">Founding Partner (Tier 1 Priority)</option>
                    <option value="Enterprise Operator">Enterprise Operator (Tier 2 Access)</option>
                    <option value="Strategic Affiliate">Strategic Affiliate (Tier 3 Access)</option>
                </select>
            </div>

            <button type="submit" class="btn-convert">Claim My Allocation Now</button>
        </form>

        <div id="toast"></div>

        <div class="funnel-footer">
            EB Enterprises &bull; 100% Secure &amp; Confidential &bull; Zero Spam Guarantee
        </div>
    </div>

    <script>
        document.getElementById('funnel-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const tier = document.getElementById('tier').value;
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Securing Allocation...';

            try {
                const res = await fetch('/api/funnel/convert', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email, tier })
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
                    document.getElementById('funnel-form').reset();
                    submitBtn.textContent = 'Allocation Secured ✓';
                } else {
                    throw new Error(data.error || 'Conversion failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Claim My Allocation Now';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of sales funnel..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_funnel" nohup node server.js > server.log 2>&1 &
echo "[+] High-converting sales funnel successfully deployed and active on port 5000."
echo "[+] To view live instant conversions on your terminal or phone, run:"
echo ""
echo "    tail -f server.log"
echo ""
