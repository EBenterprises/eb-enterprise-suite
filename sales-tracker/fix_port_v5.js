const fs = require('fs');
const path = require('path');

let code = fs.readFileSync(path.join(__dirname, 'server_v5.js'), 'utf8');

// Remove all occurrences of PORT_V5 declarations
code = code.replace(/const PORT_V5\s*=\s*\d+;/g, '');

// Insert a single clean PORT_V5 declaration right before the listen call
code = code.replace(
    /http\.createServer\(createAppHandler\('v5'\)\)\.listen\(PORT_V5/g,
    '// handled'
);

code = code.replace(
    /http\.createServer\(createAppHandler\('v4'\)\)\.listen\(PORT_V4/g,
    `const PORT_V5 = 51205;\nhttp.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {\n    console.log('⏳ Version 5 Standalone running at: http://127.0.0.1:' + PORT_V5);\n});\n\nhttp.createServer(createAppHandler('v4')).listen(PORT_V4`
);

fs.writeFileSync(path.join(__dirname, 'server_v5.js'), code);
console.log("[+] server_v5.js port declaration fixed!");
