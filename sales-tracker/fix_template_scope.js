const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');

let code = fs.readFileSync(serverPath, 'utf8');

// The error happens because the injected string uses backtick interpolation (${t.id}) 
// inside a standard string or a context where `t` is not scoped as a template variable.
// Let's replace those raw template variables with safe string concatenation: ' + t.id + '

code = code.replace(
    /<div style="margin-bottom:8px;"><label[^>]*>⏳ Transaction Timestamp<\/label><input type="datetime-local" id="edit_ts_\$\{t\.id\}" value="\$\{t\.date \? t\.date\.replace\(" ", "T"\) : ""\}"[^>]*><\/div>/g,
    ''
);

// Now let's inject it correctly using direct string concatenation inside the template
const target = '<button';
const injection = '<div style="margin-bottom:8px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Transaction Timestamp</label><input type="datetime-local" id="edit_ts_\' + t.id + \'" value="\' + (t.date ? t.date.replace(\' \', \'T\') : \'\') + \'" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div><button';

code = code.replace(target, injection);

fs.writeFileSync(serverPath, code, 'utf8');
console.log("[+] Fixed template scope error cleanly!");
