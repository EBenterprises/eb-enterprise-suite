const fs = require('fs');
const path = require('path');

let indexPath = path.join(__dirname, 'public', 'index.html');
if (fs.existsSync(indexPath)) {
    let html = fs.readFileSync(indexPath, 'utf8');
    if (!html.includes('cluster_sync.js')) {
        html = html.replace('</body>', '    <script src="/cluster_sync.js"></script>\n</body>');
        fs.writeFileSync(indexPath, html);
        console.log("[DYNAMIC PATCH] Real-time SSE WebSocket mesh synchronization injected into consumer portal.");
    }
}
