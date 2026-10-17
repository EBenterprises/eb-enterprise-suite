const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Fix the malformed response headers / catch block
code = code.replace(/res\.writeHead\([^)]+\)\s*catch\(e\)\s*\{\}\s*\)/g, "res.writeHead(200, { 'Content-Type': 'application/json' })");
code = code.replace(/catch\(e\)\s*\{\}\s*catch\(e\)/g, "catch(e)");
code = code.replace(/catch\(e\)\s*\{\}\s*\)/g, ")");

// Clean up any double catch or syntax artifacts
code = code.replace(/}\s*catch\(e\)\s*{}\s*catch\(e\)\s*{[^}]*}/g, "} catch(e) {}");

fs.writeFileSync(serverPath, code);
console.log("[+] Syntax cleaned successfully.");
