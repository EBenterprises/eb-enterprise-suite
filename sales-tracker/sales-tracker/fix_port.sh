#!/bin/bash
set -e

echo "[+] Fixing PORT definition in server.js..."
python3 -c "
with open('server.js', 'r') as f:
    code = f.read()

if 'const PORT =' not in code and 'PORT =' not in code:
    # Insert PORT definition right at the top
    code = 'const PORT = 3000;\n' + code
elif 'ReferenceError: PORT is not defined' in '''$1''' or True:
    # Ensure PORT = process.env.PORT || 3000 is explicitly declared at the top
    if 'const PORT' in code:
        code = code.replace('const PORT = process.env.PORT || 3000;', 'const PORT = 3000;')
        if 'const PORT = 3000;' not in code:
            code = 'const PORT = 3000;\n' + code

with open('server.js', 'w') as f:
    f.write(code)
print('[+] PORT variable successfully defined.')
"

echo "[+] Restarting server via run.sh..."
./run.sh
