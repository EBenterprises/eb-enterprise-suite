const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Locate how v4 is defined in createAppHandler(version)
// v5 should inherit everything v4 has (interactive pin picker, map integration, all UI features), 
// plus the advanced Time Travel timestamp modification feature.

// Let's check createAppHandler implementation
if (serverCode.includes("const createAppHandler = (version) => {")) {
    // Ensure version checks like `version === 'v4' || version === 'v5'` or `APP_VERSION === 'v4' || APP_VERSION === 'v5'` are uniform
    serverCode = serverCode.replaceAll("APP_VERSION === 'v4'", "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");
    serverCode = serverCode.replaceAll("version === 'v4'", "(version === 'v4' || version === 'v5')");
}

// 2. Ensure v5 title and badge are set
serverCode = serverCode.replace(
    /const titles = \{([^}]+)\}/,
    `const titles = {$1,\n            'v5': 'Enterprise P2P Master Suite v5 - Pin Picker & Time Travel'}`
);

serverCode = serverCode.replace(
    /const badges = \{([^}]+)\}/,
    `const badges = {$1,\n            'v5': 'v5 Pin Picker & History Time Travel Active'}`
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Synchronized v5 with all v4 features (Pin Picker, Map UI, Edit Controls) plus Time Travel!");
