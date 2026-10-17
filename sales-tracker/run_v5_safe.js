const fs = require('fs');
const path = require('path');

const targetFile = path.join(__dirname, 'server_v5.js');
let code = fs.readFileSync(targetFile, 'utf8');

// Strip out any existing PORT_V5 declarations or blocks completely to avoid duplicates
code = code.replace(/const PORT_V5[\s\S]*?\}\);\n?/g, '');
code = code.replace(/const PORT_V5\s*=\s*\d+;\s*/g, '');

// Insert a single clean PORT_V5 listener block right before PORT_V4 listen call
const v5ListenerBlock = `const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log('⏳ Standalone V5 Sales Tracker running at: http://127.0.0.1:' + PORT_V5);
});

`;

code = code.replace(
    "http.createServer(createAppHandler('v4')).listen(PORT_V4",
    v5ListenerBlock + "http.createServer(createAppHandler('v4')).listen(PORT_V4"
);

fs.writeFileSync(targetFile, code);
console.log("[+] server_v5.js cleaned of duplicate declarations and ready!");
