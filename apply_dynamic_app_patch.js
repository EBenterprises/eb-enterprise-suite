const fs = require('fs');
const path = require('path');

let indexPath = path.join(__dirname, 'public', 'index.html');
if (fs.existsSync(indexPath)) {
    let html = fs.readFileSync(indexPath, 'utf8');
    
    // Inject dynamic filter toolbar above farms grid if not present
    if (!html.includes('id="searchInput"')) {
        const toolbarHtml = `
        <!-- Dynamic Filter & Telemetry Control Bar -->
        <div style="background: var(--surface-glass); backdrop-filter: blur(12px); border: 1px solid var(--border-subtle); padding: 20px; border-radius: var(--radius-lg); margin-bottom: 30px; display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 20px; align-items: center; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
            <div>
                <label style="font-size: 0.75rem; color: var(--text-dim); display: block; margin-bottom: 6px; font-weight: 700; text-transform: uppercase;">Search Producer or Strain</label>
                <input type="text" id="searchInput" placeholder="Search Okanagan Valley Acres..." style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 12px 16px; border-radius: var(--radius-sm); font-size: 0.9rem; outline: none;">
            </div>
            <div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
                    <label style="font-size: 0.75rem; color: var(--text-dim); font-weight: 700; text-transform: uppercase;">Proximity Radius</label>
                    <span id="distanceLabel" style="font-size: 0.75rem; color: var(--accent-teal); font-weight: 800;">100 km</span>
                </div>
                <input type="range" id="distanceSlider" min="5" max="500" value="100" style="width: 100%; accent-color: var(--accent-teal); cursor: pointer;">
            </div>
            <div style="display: flex; justify-content: flex-end; gap: 15px; align-items: center;">
                <div style="text-align: right;">
                    <div style="font-size: 0.7rem; color: var(--text-dim); text-transform: uppercase;">Mesh Telemetry</div>
                    <strong id="telemetryNodesCount" style="font-size: 0.9rem; color: var(--success);">5 Edge Nodes</strong>
                </div>
            </div>
        </div>
        `;
        
        html = html.replace('<div class="farms-grid" id="farmsGrid">', toolbarHtml + '\n        <div class="farms-grid" id="farmsGrid">');
    }

    if (!html.includes('app_dynamic_engine.js')) {
        html = html.replace('</body>', '    <script src="/app_dynamic_engine.js"></script>\n</body>');
    }

    fs.writeFileSync(indexPath, html);
    console.log("[DYNAMIC APP] Fully reactive dynamic frontend application engine injected successfully.");
}
