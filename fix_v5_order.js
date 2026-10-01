const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Remove v5 block from its current incorrect position
const portV5BlockRegex = /\nconst PORT_V5 = 51205;\nhttp\.createServer\(createAppHandler\('v5'\)\)\.listen\(PORT_V5, '127\.0\.0\.1', \(\) => \{\n    console\.log\(`⏳ Version 5 \(History Time Travel\) running at: http:\/\/127\.0.0\.1:\$\{PORT_V5\}`\);\n\}\);/g;

serverCode = serverCode.replace(portV5BlockRegex, '');

// Also clean up navigation header / links rendering if v5 was out of order in the UI cluster banner
// Let's ensure the dashboard header links array/HTML renders v1, v2, v3, v4, v5 in correct order
const correctV5Insertion = `
http.createServer(createAppHandler('v4')).listen(PORT_V4, '127.0.0.1', () => {
    console.log(\`📍 Version 4 (Interactive Pin Picker) running at: http://127.0.0.1:\${PORT_V4}\`);
});

const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

serverCode = serverCode.replace(
    /http\.createServer\(createAppHandler\('v4'\)\)\.listen\(PORT_V4[^}]+\}\);/,
    correctV5Insertion.trim()
);

// Also fix the HTML cluster switcher links order in createAppHandler dashboard banner
serverCode = serverCode.replace(
    /href="http:\/\/127\.0\.0\.1:51205"[\s\S]*?href="http:\/\/127\.0\.0.1:51204"/g,
    `href="http://127.0.0.1:51204" ... href="http://127.0.0.1:51205"`
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully reordered Version 5 to follow Version 4!");
