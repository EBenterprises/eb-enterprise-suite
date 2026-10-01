const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure the top cluster banner HTML includes the v5 link right after v4 in all versions' HTML generator
const oldBannerHTML = `
<div style="background:#1e293b; padding:8px 12px; border-bottom:1px solid #334155; display:flex; gap:12px; align-items:center; font-size:12px; flex-wrap:wrap;">
    <span style="font-weight:bold; color:#38bdf8;">EB Cluster:</span>
    <a href="http://127.0.0.1:51201" style="color:\${APP_VERSION==='v1'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v1 Base</a>
    <a href="http://127.0.0.1:51202" style="color:\${APP_VERSION==='v2'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v2 Time</a>
    <a href="http://127.0.0.1:51203" style="color:\${APP_VERSION==='v3'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v3 Map</a>
    <a href="http://127.0.0.1:51204" style="color:\${APP_VERSION==='v4'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v4 Pin</a>
</div>
`;

const newBannerHTML = `
<div style="background:#1e293b; padding:8px 12px; border-bottom:1px solid #334155; display:flex; gap:12px; align-items:center; font-size:12px; flex-wrap:wrap;">
    <span style="font-weight:bold; color:#38bdf8;">EB Cluster:</span>
    <a href="http://127.0.0.1:51201" style="color:\${APP_VERSION==='v1'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v1 Base</a>
    <a href="http://127.0.0.1:51202" style="color:\${APP_VERSION==='v2'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v2 Time</a>
    <a href="http://127.0.0.1:51203" style="color:\${APP_VERSION==='v3'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v3 Map</a>
    <a href="http://127.0.0.1:51204" style="color:\${APP_VERSION==='v4'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v4 Pin</a>
    <a href="http://127.0.0.1:51205" style="color:\${APP_VERSION==='v5'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v5 History Time Travel</a>
</div>
`;

if (serverCode.includes('v4 Pin')) {
    serverCode = serverCode.replace(/<div style="background:\#1e293b; padding:8px 12px; border-bottom:1px solid \#334155; display:flex; gap:12px; align-items:center; font-size:12px; flex-wrap:wrap;">[\s\S]*?<\/div>/g, newBannerHTML.trim());
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully added Version 5 link to the cluster navigation bar!");
} else {
    console.log("[-] Banner HTML pattern not matched exactly, checking alternative insertion...");
}
