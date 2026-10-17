const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The user wants the input fields (like the new Item Name input) to look normal, matching the standard styling of the other form inputs (e.g., custInput, amountInput, cashInput) rather than heavily styled or misaligned.
// Let's replace the inline heavy/custom styling of itemInput with standard styling that matches amountInput/custInput.

const standardItemInputHtml = `
<div style="margin-bottom:8px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:4px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="Item Name (optional)" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
`;

// Replace any existing itemInput HTML blocks with the clean standard one
code = code.replace(
    /<div style="margin-bottom:8px;">[\s\S]*?id="itemInput"[\s\S]*?<\/div>/g,
    standardItemInputHtml.trim()
);

// Also check if there's any other variant of itemInput and clean it up
code = code.replace(
    /<div style="margin-bottom:6px;">[\s\S]*?id="itemInput"[\s\S]*?<\/div>/g,
    standardItemInputHtml.trim()
);

fs.writeFileSync(serverPath, code);
console.log("[+] Standardized Item Name input styling to match existing form fields.");
