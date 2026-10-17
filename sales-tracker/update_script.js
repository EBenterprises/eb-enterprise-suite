const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Force-patch the edit form generation wherever the edit HTML is built
// Let's look for where the edit form container or inputs are rendered
if (code.includes('id="edit_amt_')) {
    console.log("[+] Found inline edit input in server.js");
    
    // Replace the amount input line with timestamp + amount input
    code = code.replace(
        /<input type="number" id="edit_amt_\$\{t\.id\}"/g,
        '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Timestamp</label><input type="datetime-local" id="edit_ts_${t.id}" value="${t.date ? t.date.replace(\' \', \'T\') : \'\'}" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div><input type="number" id="edit_amt_${t.id}"'
    );
}

// Ensure the save action payload includes the customTimestamp value
if (code.includes('amount: parseFloat(document.getElementById(\'edit_amt_\' + id).value)')) {
    code = code.replace(
        /amount: parseFloat\(document\.getElementById\('edit_amt_' \+ id\)\.value\) \|\| 0,/g,
        `amount: parseFloat(document.getElementById('edit_amt_' + id).value) || 0,\n                    customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null,`
    );
}

// Ensure backend handles customTimestamp
if (code.includes('t.customer = payload.customer !== undefined ? payload.customer : t.customer;')) {
    code = code.replace(
        't.customer = payload.customer !== undefined ? payload.customer : t.customer;',
        't.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    if (!isNaN(customTs)) {\n                                        t.timestamp = customTs;\n                                        t.date = payload.customTimestamp.replace(\'T\', \' \');\n                                    }\n                                }'
    );
}

fs.writeFileSync(serverPath, code, 'utf8');
console.log("[+] Successfully updated server.js with editable timestamp field!");
