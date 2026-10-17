const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Looking at the screenshot, Weight (g), Item / Product Name, and Amount ($) are currently side-by-side in a split grid layout.
// The user wants them fully stacked vertically in a clean order:
// 1. Customer Name
// 2. Weight Presets & Weight (g)
// 3. Item / Product Name
// 4. Amount / Cost ($)
// 5. Cash Collected ($)
// 6. Landmark / Location
// 7. GPS Coordinates

// Let's locate where the form inputs are defined in the HTML template and replace the split grid with a clean vertical stack.
// Let's search for the form structure in server.js

console.log("[+] Analyzing server.js form structure for vertical stacking...");
