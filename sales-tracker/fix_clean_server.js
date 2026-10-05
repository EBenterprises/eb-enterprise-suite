const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');

let code = fs.readFileSync(serverPath, 'utf8');

// 1. Remove any previously broken/duplicated timestamp inject blocks
code = code.replace(/<div style="margin-bottom:8px;"><label[^>]*>⏳ Transaction Timestamp<\/label>[\s\S]*?<\/div>/g, '');

// 2. Find where the edit form container ends or where Save Changes button is, and inject the timestamp properly using standard JS template string formatting
const target = '<button';
const injection = '<div style="margin-bottom:8px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Transaction Timestamp</label><input type="datetime-local" id="edit_ts_' + '${t.id}' + '" value="' + '${t.date ? t.date.replace(" ", "T") : ""}' + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div><button';

code = code.replace(target, injection);

fs.writeFileSync(serverPath, code, 'utf8');
console.log("[+] Cleanly fixed and applied timestamp input!");
