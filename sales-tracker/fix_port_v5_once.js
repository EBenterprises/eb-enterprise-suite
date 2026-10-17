const fs = require('fs');
const path = require('path');

const targetFile = path.join(__dirname, 'server_v5.js');
let code = fs.readFileSync(targetFile, 'utf8');

// Strip out ALL existing PORT_V5 declarations or blocks entirely
code = code.replace(/const PORT_V5[\s\S]*?\}\);\n?/g, '');
code = code.replace(/const PORT_V5\s*=\s*\d+;\s*/g, '');

// Append a single clean PORT_V5 listener block at the very end of the file
code += `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log('⏳ Standalone V5 Sales Tracker running at: http://127.0.0.1:' + PORT_V5);
});
`;

fs.writeFileSync(targetFile, code);
console.log("[+] PORT_V5 strictly deduplicated and placed at EOF!");
