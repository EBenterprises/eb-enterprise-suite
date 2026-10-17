const fs = require('fs');
const { execSync } = require('child_process');

console.log("[+] Upgrading server.js UI header from 'v1' to 'v5' while keeping your exact layout...");

if (fs.existsSync('server.js')) {
    let content = fs.readFileSync('server.js', 'utf8');
    
    // Replace Enterprise P2P Master Suite v1 with v5
    content = content.replace(/Enterprise P2P Master Suite v1/g, 'Enterprise P2P Master Suite v5');
    content = content.replace(/v1 Master Suite/g, 'v5 P2P Master Suite');
    
    // Ensure manifest / PWA support so Chrome allows PWA installation instead of "This app cannot be installed"
    const manifestLink = `<link rel="manifest" href="/manifest.json">`;
    if (!content.includes('manifest.json')) {
        content = content.replace('</head>', `${manifestLink}\n</head>`);
    }

    fs.writeFileSync('server.js', content);
}

// Create manifest.json for full PWA installation support
const manifestJson = {
    "name": "EB Enterprises P2P Master Suite v5",
    "short_name": "EB Sales v5",
    "start_url": "/",
    "display": "standalone",
    "background_color": "#0b0f19",
    "theme_color": "#38bdf8",
    "icons": [
        {
            "src": "https://cdn-icons-png.flaticon.com/512/3177/3177440.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
};

fs.writeFileSync('manifest.json', JSON.stringify(manifestJson, null, 2));

console.log("[+] Terminating existing node processes...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Restarting server.js with v5 branding and PWA installation support on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
