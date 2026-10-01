const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure Version 5 port & listener is present right after Version 4
if (!serverCode.includes('PORT_V5')) {
    const v5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;
    serverCode = serverCode.replace(
        /http\.createServer\(createAppHandler\('v4'\)\)\.listen\(PORT_V4[^}]+\}\);/,
        match => match + '\n' + v5Block
    );
}

// Ensure every banner includes v5 right after v4
const targetBannerSnippet = `<a href="http://127.0.0.1:51204" style="color:\${APP_VERSION==='v4'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v4 Pin</a>`;
const v5BannerLink = `\n    <a href="http://127.0.0.1:51205" style="color:\${APP_VERSION==='v5'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v5 History Time Travel</a>`;

if (!serverCode.includes('v5 History Time Travel')) {
    serverCode = serverCode.replaceAll(targetBannerSnippet, targetBannerSnippet + v5BannerLink);
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] server.js updated with Version 5 listener and navigation links in correct order!");
