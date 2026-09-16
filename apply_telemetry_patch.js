const fs = require('fs');
const path = require('path');

let indexPath = path.join(__dirname, 'public', 'index.html');
if (fs.existsSync(indexPath)) {
    let html = fs.readFileSync(indexPath, 'utf8');
    if (!html.includes('mesh_telemetry_engine.js')) {
        html = html.replace('</body>', '    <script src="/mesh_telemetry_engine.js"></script>\n</body>');
        fs.writeFileSync(indexPath, html);
        console.log("[TELEMETRY] Dynamic real-time cluster telemetry monitor successfully injected.");
    }
}
