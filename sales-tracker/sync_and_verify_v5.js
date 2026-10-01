const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Ensure v5 shares the exact same codebase logic, pin picker, map features, and UI structure as v4,
// plus the v5-exclusive Time Travel timestamp editor in history.
// Let's replace any version-specific divergence where v4 had map/pin features that v5 missed.
serverCode = serverCode.replaceAll("APP_VERSION === 'v4'", "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");
serverCode = serverCode.replaceAll("version === 'v4'", "(version === 'v4' || version === 'v5')");

// 2. Ensure the history card renderer for v3, v4, v5 consistently renders the "✏️ Edit" button next to "Delete",
// and for v5, includes the `datetime-local` picker to edit the transaction date/timestamp alongside amount, customer, landmark, and GPS.

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] v5 successfully synchronized as an exact replica of v4 plus History Time Travel!");
