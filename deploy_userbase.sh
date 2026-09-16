#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - User-Driven Full-Stack Application
# ==============================================================================
set -e

echo "[+] Initializing userbase application directory structure..."
mkdir -p public server models routes

echo "[+] Generating Userbase Stylesheet (Executive Spectrum)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #070a12;
    --surface-bg: #0b0f19;
    --card-bg: #131b2e;
    --border-color: #22304a;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.2);
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
    flex-direction: column;
    align-items: center;
    padding: 2rem 1rem;
}

.main-container {
    width: 100%;
    max-width: 680px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.6);
}

.brand-header {
    text-align: center;
    margin-bottom: 2rem;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1.25rem;
}

.brand-title {
    font-size: 1.75rem;
    color: var(--gold);
    font-weight: 700;
    letter-spacing: 0.05em;
    margin-bottom: 0.25rem;
}

.brand-subtitle {
    color: var(--text-secondary);
    font-size: 0.9rem;
}

.card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
}

form {
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
    font-size: 0.85rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

input, select {
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 0.85rem 1rem;
    border-radius: 6px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

button.btn-primary {
    background: var(--accent-teal);
    color: var(--bg-app);
    border: none;
    padding: 0.9rem;
    font-weight: 700;
    border-radius: 6px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 0.95rem;
    transition: background 0.2s;
}

button.btn-primary:hover {
    background: #00b3a6;
}

#toast {
    margin-top: 1rem;
    padding: 0.85rem;
    border-radius: 6px;
    display: none;
    text-align: center;
    font-weight: 600;
    font-size: 0.9rem;
}

.userbase-feed {
    margin-top: 2rem;
}

.feed-title {
    font-size: 1.1rem;
    color: var(--gold);
    margin-bottom: 1rem;
    font-weight: 600;
}

.feed-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    max-height: 300px;
    overflow-y: auto;
}

.feed-item {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 1rem;
    border-radius: 6px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.feed-user {
    font-weight: 600;
    color: var(--text-primary);
    font-size: 0.95rem;
}

.feed-meta {
    font-size: 0.8rem;
    color: var(--text-secondary);
}

@media (max-width: 600px) {
    .main-container {
        padding: 1.25rem;
    }
}
CSS_EOF
cp public/style.css ./style.css

echo "[+] Generating Userbase Client Logic (app.js)..."
cat << 'JS_EOF' > public/app.js
document.addEventListener('DOMContentLoaded', () => {
    console.log("EB Userbase Application Initialized.");
    fetchFeed();

    const form = document.getElementById('user-form');
    const toast = document.getElementById('toast');

    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const userTier = document.getElementById('userTier').value;

            try {
                const response = await fetch('/api/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password, userTier })
                });
                const data = await response.json();

                toast.style.display = 'block';
                if (response.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = 'Success: Profile registered to userbase.';
                    form.reset();
                    fetchFeed();
                } else {
                    throw new Error(data.error || 'Registration failed');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = 'Error: ' + err.message;
            }
        });
    }
});

async function fetchFeed() {
    try {
        const res = await fetch('/api/users');
        const users = await res.json();
        const feedList = document.getElementById('feed-list');
        if (!feedList) return;

        feedList.innerHTML = '';
        if (users.length === 0) {
            feedList.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 1rem;">No user entries found in feed.</div>';
            return;
        }

        users.forEach(user => {
            const item = document.createElement('div');
            item.className = 'feed-item';
            item.innerHTML = `
                <div>
                    <div class="feed-user">${escapeHtml(user.email)}</div>
                    <div class="feed-meta">Tier: ${escapeHtml(user.userTier)}</div>
                </div>
                <div class="feed-meta">${new Date(user.createdAt).toLocaleDateString()}</div>
            `;
            feedList.appendChild(item);
        });
    } catch (err) {
        console.error("Failed to fetch userbase feed:", err);
    }
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
JS_EOF
cp public/app.js ./app.js

echo "[+] Generating Userbase HTML View (index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Userbase Fed Application</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="main-container">
        <div class="brand-header">
            <h1 class="brand-title">EB ENTERPRISES</h1>
            <p class="brand-subtitle">Userbase-Fed Application Portal</p>
        </div>

        <div class="card">
            <form id="user-form">
                <div class="form-group">
                    <label for="email">User Email</label>
                    <input type="email" id="email" placeholder="user@domain.com" required>
                </div>
                <div class="form-group">
                    <label for="password">Password / Passkey</label>
                    <input type="password" id="password" placeholder="••••••••••••" required>
                </div>
                <div class="form-group">
                    <label for="userTier">User Tier</label>
                    <select id="userTier" required>
                        <option value="">Select User Tier</option>
                        <option value="verified">Verified Secure Tier (18+)</option>
                        <option value="standard">Standard Member Tier</option>
                    </select>
                </div>
                <button type="submit" class="btn-primary">Register User Profile</button>
            </form>
            <div id="toast"></div>
        </div>

        <div class="userbase-feed">
            <h3 class="feed-title">Live Userbase Feed</h3>
            <div id="feed-list" class="feed-list">
                <!-- Populated dynamically via client JS -->
            </div>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
HTML_EOF
cp public/index.html ./index.html

echo "[+] Generating Server Logic (server.js)..."
cat << 'SRV_EOF' > server.js
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_userbase_root';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(__dirname));

// In-memory fallback storage if MongoDB is offline
let memoryUsers = [];

mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log("[+] Connected to MongoDB successfully.");
}).catch(err => {
    console.warn("[!] MongoDB offline mode active, using memory store:", err.message);
});

const UserSchema = new mongoose.Schema({
    email: { type: String, required: true },
    password: { type: String, required: true },
    userTier: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
});

const UserProfile = mongoose.models.UserProfile || mongoose.model('UserProfile', UserSchema);

app.post('/api/users', async (req, res) => {
    try {
        const { email, password, userTier } = req.body;
        if (!email || !password || !userTier) {
            return res.status(400).json({ error: 'All user parameters are required.' });
        }

        const newUser = { email, password, userTier, createdAt: new Date() };

        try {
            const dbUser = new UserProfile(newUser);
            await dbUser.save();
        } catch (dbErr) {
            memoryUsers.unshift(newUser);
        }

        res.status(200).json({ success: true, message: 'User added to userbase successfully.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/users', async (req, res) => {
    try {
        try {
            const users = await UserProfile.find().sort({ createdAt: -1 }).limit(50);
            return res.json(users);
        } catch (dbErr) {
            return res.json(memoryUsers);
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Userbase application live on port ${PORT}`);
});
SRV_EOF

echo "[+] Triggering live deployment..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_userbase_root" nohup node server.js > server.log 2>&1 &
echo "[+] Userbase-fed application successfully deployed and active on port 5000."
