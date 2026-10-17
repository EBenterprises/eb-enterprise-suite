const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's locate where the inline edit HTML form is structured inside server.js
// We want to insert the datetime-local input right above the Save Changes button.
// Typically the button looks like: <button ...>Save Changes</button> or similar.

if (code.includes('Save Changes')) {
    console.log("[+] Found 'Save Changes' button in server.js. Injecting timestamp input right above it...");
    
    // Replace right before the Save Changes button or equivalent submit action inside the edit form builder
    code = code.replace(
        /(<button[^>]*>[\s\S]*?Save Changes[\s\S]*?<\/button>)/g,
        `<div style="margin-bottom:8px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Transaction Timestamp</label><input type="datetime-local" id="edit_ts_\${t.id}" value="\${t.date ? t.date.replace(' ', 'T') : ''}" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>$1`
    );
}

// Make sure the client-side updater script grabs 'edit_ts_' + id and sends customTimestamp
if (code.includes('customTimestamp')) {
    console.log("[+] customTimestamp payload mapping already exists.");
} else {
    // Inject customTimestamp into the payload body of the update action
    code = code.replace(
        /amount:\s*parseFloat\s*\([^)]+\)\s*\|\|\s*0,/g,
        (match) => `${match}\n                    customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null,`
    );
}

fs.writeFileSync(serverPath, code, 'utf8');
console.log("[+] Successfully updated server.js with precise timestamp placement right above Save Changes!");
