const fs = require('fs');

console.log("[+] Configuring server.js for v5 on port 51205...");
if (fs.existsSync('server.js')) {
    let code = fs.readFileSync('server.js', 'utf8');
    // Replace port 3000 or any existing port with 51205 for v5
    code = code.replace(/3000/g, '51205');
    code = code.replace(/51201/g, '51205');
    fs.writeFileSync('server.js', code);
}

console.log("[+] Launching v5 Master Suite on port 51205...");
require('./server.js');
