const http = require('http');
const fs = require('fs');
const path = require('path');

function fetchJson(url) {
    return new Promise((resolve, reject) => {
        http.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
            });
        }).on('error', reject);
    });
}

async function manageTabs() {
    const configPath = path.join(__dirname, '../config/config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const port = config.browser.debuggingPort;

    try {
        console.log(`[Browser] Connecting to Chrome debugging interface on port ${port}...`);
        const targets = await fetchJson(`http://127.0.0.1:${port}/json`);

        for (const targetUrl of config.browser.defaultTargets) {
            const existing = targets.find(t => t.url && t.url.includes(targetUrl));
            if (existing) {
                console.log(`[Tabs] Refreshing existing target: ${targetUrl} (ID: ${existing.id})`);
                await fetchJson(`http://127.0.0.1:${port}/json/activate/${existing.id}`);
            } else {
                console.log(`[Tabs] Opening new target: ${targetUrl}`);
                await fetchJson(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(targetUrl)}`);
            }
        }
    } catch (error) {
        console.error(`[Browser] Failed to connect to debugging port ${port}. Ensure Chrome is running with --remote-debugging-port=${port}`, error.message);
    }
}

if (require.main === module) {
    manageTabs();
}

module.exports = { manageTabs };
