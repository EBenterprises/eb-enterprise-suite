const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Clean up malformed or duplicated catch blocks
code = code.replace(/catch\s*\([^)]*\)\s*\{\}\s*\}\s*catch\s*\([^)]*\)\s*\{\}/g, '} catch(e) {}');
code = code.replace(/catch\s*\([^)]*\)\s*\{\}\s*catch\s*\([^)]*\)\s*\{\}/g, 'catch(e) {}');
code = code.replace(/catch\s*\([^)]*\)\s*\{[^}]*\}\s*catch\s*\([^)]*\)\s*\{[^}]*\}/g, 'catch(e) {}');
code = code.replace(/catch\s*\([^)]*\)\s*\{\}\s*\)\s*catch\s*\([^)]*\)/g, 'catch(e)');

fs.writeFileSync(serverPath, code);
console.log("[+] Malformed catch blocks cleaned up!");
