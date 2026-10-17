const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// We want to target the inline edit form template generation inside server.js
// Let's see how the edit form inputs are generated in server.js and inject the datetime-local input right there.

// Let's replace the inline edit card innerHTML structure to explicitly include the timestamp field
const targetString = 'input type="number" id="edit_amt_';
if (code.includes(targetString)) {
    console.log("[+] Found inline edit fields in server.js. Patching template...");
}

// Let's write a robust patch that injects the timestamp input right above the amount/cash inputs in the inline editing form
const oldEditFormSnippet = `const editFormHTML = \`<div id="edit_form_\${t.id}"`;

// Alternatively, let's inspect and replace the HTML template part for the inline editor
// Let's do a direct replacement on the inline edit form's input fields block
code = code.replace(
    /(\<input type="number" id="edit_amt_\$\{t\.id\}"[^>]*\>)/g,
    `<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Timestamp</label><input type="datetime-local" id="edit_ts_\${t.id}" value="\${t.date ? t.date.replace(' ', 'T') : ''}" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>$1`
);

// Also make sure the client-side JavaScript that collects payload for update_tx includes customTimestamp
code = code.replace(
    /amount: parseFloat\(document\.getElementById\('edit_amt_' \+ id\)\.value\) \|\| 0,/g,
    `amount: parseFloat(document.getElementById('edit_amt_' + id).value) || 0,\n                    customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null,`
);

fs.writeFileSync(serverPath, code);
console.log("[+] Inline edit timestamp field injected successfully into server.js!");
