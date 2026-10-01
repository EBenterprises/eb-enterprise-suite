const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Add PORT_V5 listener explicitly if not present
if (!serverCode.includes('PORT_V5')) {
    const targetListen = `http.createServer(createAppHandler('v4')).listen(PORT_V4, '127.0.0.1', () => {
    console.log(\`📍 Version 4 (Interactive Pin Picker) running at: http://127.0.0.1:\${PORT_V4}\`);
});`;

    const replacement = targetListen + `

const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});`;

    serverCode = serverCode.replace(targetListen, replacement);
}

// 2. Add v5 to titles & badges
if (!serverCode.includes("'v5':")) {
    serverCode = serverCode.replace(
        "const titles = {",
        "const titles = {\n            'v5': 'Enterprise P2P Master Suite v5 - History Time Travel',"
    );
    serverCode = serverCode.replace(
        "const badges = {",
        "const badges = {\n            'v5': 'v5 History Time Travel & Edit Active',"
    );
}

// 3. Ensure banner includes v5 link right after v4
const targetBanner = `<a href="http://127.0.0.1:51204" style="color:\${APP_VERSION==='v4'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v4 Pin</a>`;
const v5Link = `\n    <a href="http://127.0.0.1:51205" style="color:\${APP_VERSION==='v5'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v5 History Time Travel</a>`;

if (!serverCode.includes('v5 History Time Travel')) {
    serverCode = serverCode.replaceAll(targetBanner, targetBanner + v5Link);
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] force_add_v5 complete!");
