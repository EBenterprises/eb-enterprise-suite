const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');

if (!fs.existsSync(serverPath)) {
    console.error("[-] server.js not found in current directory!");
    process.exit(1);
}

let code = fs.readFileSync(serverPath, 'utf8');

// 1. Remove any broken timestamp inject attempts
code = code.replace(/<div style="margin-bottom:8px;"><label[^>]*>⏳ Transaction Timestamp<\/label>[\s\S]*?<\/div>/g, '');

// 2. Locate the edit form button/container and correctly insert the editable timestamp field
// In the classic V1-V4 UI templates, templates are built using string concatenation where transaction objects are mapped.
// We insert the datetime-local input using safe string concatenation matching the surrounding template.
const target = '<button';
const timestampInput = '<div style="margin-bottom:8px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Transaction Timestamp</label><input type="datetime-local" id="edit_ts_\' + t.id + \'" value="\' + (t.date ? t.date.replace(\' \', \'T\') : \'\') + \'" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div><button';

if (code.includes(target)) {
    // Replace the first occurrence in the edit modal template
    code = code.replace(target, timestampInput);
    fs.writeFileSync(serverPath, code, 'utf8');
    console.log("[+] Successfully added editable transaction timestamp to the V1-V4 UI edit modal!");
} else {
    console.log("[-] Target element not found for injection.");
}
