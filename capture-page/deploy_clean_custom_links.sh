#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Clean Domain & Custom Redirect Hub
# ==============================================================================
set -e

PORT=5000

echo "[+] Initializing clean custom link portal..."
mkdir -p public server

echo "[+] Writing Backend Server (server.js)..."
cat << 'SRV_EOF' > server.js
const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const LINKS_FILE = path.join(__dirname, 'links.json');

// Default custom links configuration
let customLinks = {
    "welcome": {
        title: "Welcome Portal",
        destinationUrl: "https://example.com",
        headline: "Redirecting to Your Destination",
        subheadline: "Please wait while we route you securely...",
        buttonText: "Proceed Now",
        autoRedirect: true,
        delaySeconds: 2
    },
    "portfolio": {
        title: "EB Enterprises Portfolio",
        destinationUrl: "https://github.com",
        headline: "Professional Systems Portfolio",
        subheadline: "Accessing core architecture repositories and deployments.",
        buttonText: "Open Portfolio",
        autoRedirect: false,
        delaySeconds: 0
    }
};

if (fs.existsSync(LINKS_FILE)) {
    try {
        customLinks = JSON.parse(fs.readFileSync(LINKS_FILE, 'utf8'));
    } catch (e) {
        console.warn("[!] Failed to parse links.json, using defaults.");
    }
}

app.get('/api/links', (req, res) => {
    res.json(customLinks);
});

app.post('/api/links', (req, res) => {
    try {
        customLinks = req.body;
        fs.writeFileSync(LINKS_FILE, JSON.stringify(customLinks, null, 2));
        res.json({ success: true, message: 'Custom links updated successfully.' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Route for custom vanity links: e.g. /l/welcome or /l/portfolio
app.get('/l/:slug', (req, res) => {
    const slug = req.params.slug;
    const link = customLinks[slug];

    if (!link) {
        return res.status(404).sendFile(path.join(__dirname, 'public', '404.html'));
    }

    // Serve a clean redirect/gateway page configured specifically for this slug
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${link.title}</title>
    <style>
        :root { background: #060810; color: #fff; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 1rem; }
        .box { max-width: 480px; width: 100%; background: #0d121f; border: 1px solid #212d47; border-radius: 12px; padding: 2.5rem 2rem; text-align: center; box-shadow: 0 20px 50px rgba(0,0,0,0.8); }
        h1 { font-size: 1.6rem; margin-bottom: 0.5rem; color: #fff; }
        p { color: #94a3b8; font-size: 0.95rem; margin-bottom: 1.5rem; line-height: 1.5; }
        .btn { display: inline-block; background: #00d2c4; color: #060810; padding: 0.9rem 1.75rem; border-radius: 8px; font-weight: 700; text-decoration: none; text-transform: uppercase; letter-spacing: 0.08em; font-size: 0.85rem; transition: transform 0.2s; }
        .btn:hover { transform: translateY(-1px); }
        .spinner { width: 24px; height: 24px; border: 3px solid rgba(0,210,196,0.3); border-top-color: #00d2c4; border-radius: 50%; animation: spin 0.8s linear infinite; margin: 0 auto 1rem; }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
    ${link.autoRedirect ? `<meta http-equiv="refresh" content="${link.delaySeconds};url=${link.destinationUrl}">` : ''}
</head>
<body>
    <div class="box">
        ${link.autoRedirect ? '<div class="spinner"></div>' : ''}
        <h1>${link.headline}</h1>
        <p>${link.subheadline}</p>
        <a href="${link.destinationUrl}" class="btn">${link.buttonText}</a>
    </div>
    <script>
        // Fallback programmatic redirect if needed
        const dest = "${link.destinationUrl}";
        const auto = ${link.autoRedirect};
        const delay = ${link.delaySeconds} * 1000;
        if (auto && dest) {
            setTimeout(() => {
                window.location.href = dest;
            }, delay);
        }
    </script>
</body>
</html>`);
});

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
    console.log(`[+] Clean Custom Links server active on port ${PORT}`);
});
SRV_EOF

echo "[+] Writing Stylesheet & Admin Panel (public/index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom Links Manager</title>
    <style>
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
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: var(--bg-base); color: var(--text-main); min-height: 100vh; padding: 2rem 1rem; display: flex; justify-content: center; }
        .wrapper { width: 100%; max-width: 720px; }
        .header { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 2rem; margin-bottom: 1.5rem; text-align: center; }
        h1 { font-size: 1.8rem; font-weight: 800; margin-bottom: 0.5rem; }
        h1 span { color: var(--teal); }
        p { color: var(--text-muted); font-size: 0.9rem; }
        .card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 2rem; margin-bottom: 1.5rem; }
        h2 { font-size: 1.1rem; color: var(--gold); margin-bottom: 1.25rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .form-group { margin-bottom: 1rem; }
        label { display: block; font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.08em; font-weight: 700; margin-bottom: 0.4rem; }
        input, textarea, select { width: 100%; background: var(--bg-base); border: 1px solid var(--border); color: var(--text-main); padding: 0.85rem 1rem; border-radius: 8px; font-size: 0.9rem; outline: none; }
        input:focus, textarea:focus { border-color: var(--teal); box-shadow: 0 0 0 3px var(--teal-glow); }
        .row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        button { background: linear-gradient(135deg, var(--teal), #00a89d); color: var(--bg-base); border: none; padding: 1rem; font-weight: 800; border-radius: 8px; cursor: pointer; text-transform: uppercase; letter-spacing: 0.1em; width: 100%; font-size: 0.9rem; margin-top: 0.5rem; }
        button:hover { opacity: 0.95; }
        .link-list { display: flex; flex-direction: column; gap: 0.75rem; margin-top: 1rem; }
        .link-item { background: var(--card); border: 1px solid var(--border); padding: 1rem; border-radius: 8px; display: flex; justify-content: space-between; align-items: center; }
        .link-info h3 { font-size: 0.95rem; color: var(--teal); margin-bottom: 0.2rem; }
        .link-info p { font-size: 0.8rem; word-break: break-all; }
        .link-actions a { color: var(--gold); font-size: 0.85rem; text-decoration: none; font-weight: 700; background: rgba(253,224,71,0.1); padding: 0.4rem 0.8rem; border-radius: 6px; border: 1px solid rgba(253,224,71,0.3); }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <h1>Custom Clean <span>Links Manager</span></h1>
            <p>Generate clean vanity links (e.g., /l/yourname) that route smoothly without warning screens or IP prompts.</p>
        </div>

        <div class="card">
            <h2>Active Custom Links</h2>
            <div id="linkList" class="link-list"></div>
        </div>

        <div class="card">
            <h2>Add or Edit Link Slug</h2>
            <form id="linkForm">
                <div class="row">
                    <div class="form-group">
                        <label>Slug Key (e.g. vip, offer, app)</label>
                        <input type="text" id="slugKey" placeholder="vip" required>
                    </div>
                    <div class="form-group">
                        <label>Portal Title</label>
                        <input type="text" id="title" placeholder="VIP Access" required>
                    </div>
                </div>
                <div class="form-group">
                    <label>Destination URL (Where people go)</label>
                    <input type="url" id="destinationUrl" placeholder="https://yourwebsite.com" required>
                </div>
                <div class="row">
                    <div class="form-group">
                        <label>Headline Text</label>
                        <input type="text" id="headline" placeholder="Welcome to VIP Access" required>
                    </div>
                    <div class="form-group">
                        <label>Button Text</label>
                        <input type="text" id="buttonText" placeholder="Continue" required>
                    </div>
                </div>
                <div class="form-group">
                    <label>Subheadline / Description</label>
                    <textarea id="subheadline" placeholder="Click below or redirecting automatically..." rows="2" required></textarea>
                </div>
                <div class="row">
                    <div class="form-group">
                        <label>Auto-Redirect (true / false)</label>
                        <select id="autoRedirect">
                            <option value="true">True (Redirect Automatically)</option>
                            <option value="false">False (Require Button Click)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Redirect Delay (Seconds)</label>
                        <input type="number" id="delaySeconds" value="1" min="0" max="10" required>
                    </div>
                </div>
                <button type="submit">Save &amp; Generate Link</button>
            </form>
        </div>
    </div>

    <script>
        let currentLinks = {};
        let currentTunnelBase = window.location.origin;

        async function loadLinks() {
            const res = await fetch('/api/links');
            currentLinks = await res.json();
            renderLinks();
        }

        function renderLinks() {
            const container = document.getElementById('linkList');
            container.innerHTML = '';

            for (const [slug, l] of Object.entries(currentLinks)) {
                const fullLink = `${currentTunnelBase}/l/${slug}`;
                const div = document.createElement('div');
                div.className = 'link-item';
                div.innerHTML = `
                    <div class="link-info">
                        <h3>/${slug} &bull; ${l.title}</h3>
                        <p>Target: ${l.destinationUrl}</p>
                    </div>
                    <div class="link-actions">
                        <a href="${fullLink}" target="_blank">Test Link ↗</a>
                    </div>
                `;
                container.appendChild(div);
            }
        }

        document.getElementById('linkForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const slug = document.getElementById('slugKey').value.trim().toLowerCase();
            
            currentLinks[slug] = {
                title: document.getElementById('title').value.trim(),
                destinationUrl: document.getElementById('destinationUrl').value.trim(),
                headline: document.getElementById('headline').value.trim(),
                subheadline: document.getElementById('subheadline').value.trim(),
                buttonText: document.getElementById('buttonText').value.trim(),
                autoRedirect: document.getElementById('autoRedirect').value === 'true',
                delaySeconds: parseInt(document.getElementById('delaySeconds').value) || 1
            };

            const res = await fetch('/api/links', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(currentLinks)
            });

            if (res.ok) {
                renderLinks();
                alert(`Link /l/${slug} saved successfully!`);
                document.getElementById('linkForm').reset();
            } else {
                alert('Failed to save link.');
            }
        });

        loadLinks();
    </script>
</body>
</html>
HTML_EOF

echo "[+] Writing 404 page (public/404.html)..."
cat << '404_EOF' > public/404.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Link Not Found</title>
    <style>
        body { background: #060810; color: #fff; font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; text-align: center; }
        h1 { color: #ef4444; margin-bottom: 0.5rem; }
        p { color: #94a3b8; }
    </style>
</head>
<body>
    <div>
        <h1>404 &bull; Link Not Found</h1>
        <p>The requested custom link slug does not exist or has been removed.</p>
    </div>
</body>
</html>
404_EOF

echo "[+] Starting server..."
pkill -f "node" 2>/dev/null || true
sleep 1
PORT=$PORT nohup node server.js > server.log 2>&1 &
sleep 2

echo "[+] Launching LocalTunnel..."
rm -f public_url.log
npx -y localtunnel --port $PORT > public_url.log 2>&1 &

PUBLIC_URL=""
for i in {1..10}; do
    sleep 1
    if [ -f public_url.log ]; then
        PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+(\.loca\.lt|\.localtunnel\.me)' public_url.log || true)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] CLEAN LINK MANAGER READY:"
    echo "    Dashboard: $PUBLIC_URL"
    echo "    Custom Links: $PUBLIC_URL/l/welcome"
    echo ""
    echo "    (No IP prompts. Configure clean vanity paths instantly!)"
else
    echo "[!] Tunnel lookup pending. Run manually: npx localtunnel --port $PORT"
    echo "    Local URL: http://localhost:$PORT"
fi
echo "=================================================="
echo ""
