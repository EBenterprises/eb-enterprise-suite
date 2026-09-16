#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Multi-Page Full-Stack Userbase Platform
# ==============================================================================
set -e

echo "[+] Initializing multi-page application structure..."
mkdir -p public

echo "[+] Writing Multi-Page Server (server.js)..."
cat << 'SRV_EOF' > server.js
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/eb_multipage_root';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

let memoryStore = [
    { email: 'operator@eb.enterprise', userTier: 'Verified Secure Tier (18+)', bio: 'Principal system architect & operator.', createdAt: new Date() }
];

let isMongoConnected = false;
mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    isMongoConnected = true;
    console.log("[+] Connected to MongoDB instance.");
}).catch(err => {
    console.warn("[!] MongoDB offline. Operating on robust in-memory store.");
});

const UserSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    password: { type: String, required: true },
    userTier: { type: String, required: true },
    bio: { type: String, default: 'Enterprise user node.' },
    createdAt: { type: Date, default: Date.now }
});

const User = mongoose.models.User || mongoose.model('User', UserSchema);

// API Endpoints
app.post('/api/users', async (req, res) => {
    try {
        const { email, password, userTier, bio } = req.body;
        if (!email || !password || !userTier) {
            return res.status(400).json({ error: 'Required parameters missing.' });
        }

        if (isMongoConnected) {
            const existing = await User.findOne({ email });
            if (existing) {
                return res.status(400).json({ error: 'User email already registered.' });
            }
            const newUser = new User({ email, password, userTier, bio: bio || 'Enterprise member node.' });
            await newUser.save();
            const allUsers = await User.find().sort({ createdAt: -1 }).limit(50);
            return res.status(200).json({ success: true, message: 'Registration complete.', users: allUsers });
        } else {
            const existing = memoryStore.find(u => u.email === email);
            if (existing) {
                return res.status(400).json({ error: 'User email already registered.' });
            }
            memoryStore.unshift({ email, userTier, bio: bio || 'Enterprise member node.', createdAt: new Date() });
            return res.status(200).json({ success: true, message: 'Registration complete.', users: memoryStore });
        }
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
});

app.get('/api/users', async (req, res) => {
    try {
        if (isMongoConnected) {
            const users = await User.find().sort({ createdAt: -1 }).limit(50);
            return res.json(users);
        } else {
            return res.json(memoryStore);
        }
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
});

// Explicit Page Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/feed', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'feed.html'));
});

app.get('/directory', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'directory.html'));
});

app.get('/about', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'about.html'));
});

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Multi-page production server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Shared Executive Spectrum Stylesheet (public/style.css)..."
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
    max-width: 720px;
    background: var(--surface-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.6);
}

.nav-bar {
    display: flex;
    justify-content: center;
    gap: 1rem;
    margin-bottom: 2rem;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1rem;
    flex-wrap: wrap;
}

.nav-link {
    color: var(--text-secondary);
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 600;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    transition: all 0.2s;
}

.nav-link:hover, .nav-link.active {
    color: var(--accent-teal);
    border-color: var(--accent-teal);
}

.brand-header {
    text-align: center;
    margin-bottom: 2rem;
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

input, select, textarea {
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 0.85rem 1rem;
    border-radius: 6px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus, textarea:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

textarea {
    resize: vertical;
    min-height: 80px;
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

.feed-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.feed-item {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 1.25rem;
    border-radius: 8px;
}

.feed-user {
    font-weight: 700;
    color: var(--text-primary);
    font-size: 1rem;
    margin-bottom: 0.25rem;
}

.feed-bio {
    color: var(--text-secondary);
    font-size: 0.9rem;
    margin-bottom: 0.5rem;
}

.feed-meta {
    font-size: 0.8rem;
    color: var(--gold);
}

.content-section p {
    color: var(--text-secondary);
    line-height: 1.6;
    margin-bottom: 1rem;
}
CSS_EOF

echo "[+] Writing Page 1: Registration (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Registration Portal</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="main-container">
        <nav class="nav-bar">
            <a href="/" class="nav-link active">Register</a>
            <a href="/feed" class="nav-link">Live Feed</a>
            <a href="/directory" class="nav-link">Directory</a>
            <a href="/about" class="nav-link">About</a>
        </nav>

        <div class="brand-header">
            <h1 class="brand-title">EB ENTERPRISES</h1>
            <p class="brand-subtitle">Userbase Registration Portal</p>
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
                        <option value="Verified Secure Tier (18+)">Verified Secure Tier (18+)</option>
                        <option value="Standard Member Tier">Standard Member Tier</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="bio">Operator Bio / Note</label>
                    <textarea id="bio" placeholder="Describe your operator node..."></textarea>
                </div>
                <button type="submit" class="btn-primary">Register User Profile</button>
            </form>
            <div id="toast"></div>
        </div>
    </div>

    <script>
        document.getElementById('user-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value.trim();
            const userTier = document.getElementById('userTier').value;
            const bio = document.getElementById('bio').value.trim();
            const toast = document.getElementById('toast');

            try {
                const res = await fetch('/api/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password, userTier, bio })
                });
                const data = await res.json();
                toast.style.display = 'block';
                if (res.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = 'Success: Registered! Redirecting to feed...';
                    setTimeout(() => { window.location.href = '/feed'; }, 1500);
                } else {
                    throw new Error(data.error || 'Registration failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = 'Error: ' + err.message;
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Writing Page 2: Live Feed (public/feed.html)..."
cat << 'HTML_EOF' > public/feed.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Live Userbase Feed</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="main-container">
        <nav class="nav-bar">
            <a href="/" class="nav-link">Register</a>
            <a href="/feed" class="nav-link active">Live Feed</a>
            <a href="/directory" class="nav-link">Directory</a>
            <a href="/about" class="nav-link">About</a>
        </nav>

        <div class="brand-header">
            <h1 class="brand-title">EB ENTERPRISES</h1>
            <p class="brand-subtitle">Live Userbase Activity Stream</p>
        </div>

        <div id="feed-list" class="feed-list">
            <div style="color: var(--text-secondary); text-align: center; padding: 2rem;">Loading live feed...</div>
        </div>
    </div>

    <script>
        async function loadFeed() {
            try {
                const res = await fetch('/api/users');
                const users = await res.json();
                const feedList = document.getElementById('feed-list');
                feedList.innerHTML = '';

                if (!users || users.length === 0) {
                    feedList.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 2rem;">No registered profiles found.</div>';
                    return;
                }

                users.forEach(user => {
                    const item = document.createElement('div');
                    item.className = 'feed-item';
                    item.innerHTML = `
                        <div class="feed-user">${escapeHtml(user.email)}</div>
                        <div class="feed-bio">${escapeHtml(user.bio || 'No bio provided.')}</div>
                        <div class="feed-meta">Tier: ${escapeHtml(user.userTier)} | Joined: ${new Date(user.createdAt).toLocaleDateString()}</div>
                    `;
                    feedList.appendChild(item);
                });
            } catch (err) {
                console.error("Feed load error:", err);
            }
        }
        function escapeHtml(str) {
            return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }
        loadFeed();
    </script>
</body>
</html>
HTML_EOF

echo "[+] Writing Page 3: Directory (public/directory.html)..."
cat << 'HTML_EOF' > public/directory.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Member Directory</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="main-container">
        <nav class="nav-bar">
            <a href="/" class="nav-link">Register</a>
            <a href="/feed" class="nav-link">Live Feed</a>
            <a href="/directory" class="nav-link active">Directory</a>
            <a href="/about" class="nav-link">About</a>
        </nav>

        <div class="brand-header">
            <h1 class="brand-title">EB ENTERPRISES</h1>
            <p class="brand-subtitle">Verified Operator Directory</p>
        </div>

        <div class="card content-section">
            <h3 style="color: var(--gold); margin-bottom: 0.75rem;">Directory Overview</h3>
            <p>This directory indexes all active participant nodes registered within the EB Enterprises infrastructure. Use the search filter below to query specific operator nodes.</p>
            <input type="text" id="search-input" placeholder="Filter by email or tier..." style="margin-top: 0.5rem; margin-bottom: 1rem;">
        </div>

        <div id="directory-list" class="feed-list"></div>
    </div>

    <script>
        let allMembers = [];
        async function loadDirectory() {
            try {
                const res = await fetch('/api/users');
                allMembers = await res.json();
                renderDirectory(allMembers);
            } catch (err) {
                console.error("Directory load error:", err);
            }
        }

        function renderDirectory(members) {
            const list = document.getElementById('directory-list');
            list.innerHTML = '';
            if (!members || members.length === 0) {
                list.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 2rem;">No entries found.</div>';
                return;
            }
            members.forEach(m => {
                const item = document.createElement('div');
                item.className = 'feed-item';
                item.innerHTML = `
                    <div class="feed-user">${escapeHtml(m.email)}</div>
                    <div class="feed-meta">Access Level: ${escapeHtml(m.userTier)}</div>
                `;
                list.appendChild(item);
            });
        }

        document.getElementById('search-input').addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            const filtered = allMembers.filter(m => m.email.toLowerCase().includes(query) || m.userTier.toLowerCase().includes(query));
            renderDirectory(filtered);
        });

        function escapeHtml(str) {
            return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }

        loadDirectory();
    </script>
</body>
</html>
HTML_EOF

echo "[+] Writing Page 4: About (public/about.html)..."
cat << 'HTML_EOF' > public/about.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - About Platform</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="main-container">
        <nav class="nav-bar">
            <a href="/" class="nav-link">Register</a>
            <a href="/feed" class="nav-link">Live Feed</a>
            <a href="/directory" class="nav-link">Directory</a>
            <a href="/about" class="nav-link.active" style="color: var(--accent-teal); border-color: var(--accent-teal);">About</a>
        </nav>

        <div class="brand-header">
            <h1 class="brand-title">EB ENTERPRISES</h1>
            <p class="brand-subtitle">Platform Architecture & Mission</p>
        </div>

        <div class="card content-section">
            <h3 style="color: var(--gold); margin-bottom: 0.75rem;">Sovereign Architecture</h3>
            <p>EB Enterprises operates on sovereign, self-contained full-stack application models designed for lightning-fast execution across mobile and desktop environments.</p>
            <p>All user entries, node registrations, and activity logs are processed through robust client-server pipelines ensuring absolute stability and zero registration failures.</p>
            <div style="margin-top: 1.5rem; text-align: center; color: var(--gold); font-weight: 600; font-size: 0.9rem;">
                Executive Spectrum Design Standard — Version 12.4
            </div>
        </div>
    </div>
</body>
</html>
HTML_EOF

echo "[+] Triggering live deployment of multi-page application..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_multipage_root" nohup node server.js > server.log 2>&1 &
echo "[+] Multi-page application successfully deployed and active on port 5000."
