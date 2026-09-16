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
