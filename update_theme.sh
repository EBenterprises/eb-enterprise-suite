#!/usr/bin/env bash
set -e

echo "[+] Refining UI to a proper, ultra-clean professional dark interface..."

# 1. Overwrite style.css with clean, professional dark styling
cat << 'CSS_EOF' > secure_vault/src/static/style.css
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    word-break: break-word;
    overflow-wrap: break-word;
}

html, body {
    width: 100%;
    min-height: 100vh;
    background-color: #121214;
    color: #e4e4e7;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 1.5rem;
    margin: 0;
}

.container {
    width: 100%;
    max-width: 100%;
    background: #18181b;
    padding: 2rem;
    border-radius: 10px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
    border: 1px solid #27272a;
}

@media (min-width: 480px) {
    .container {
        max-width: 420px;
    }
}

form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    width: 100%;
}

input, textarea, button {
    width: 100%;
    padding: 0.85rem 1rem;
    border: 1px solid #3f3f46;
    border-radius: 6px;
    background: #09090b;
    color: #f4f4f5;
    font-size: 0.95rem;
    outline: none;
    font-family: inherit;
    transition: border-color 0.2s ease;
}

input:focus, textarea:focus {
    border-color: #71717a;
}

button {
    background: #f4f4f5;
    color: #09090b;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 44px;
    transition: background 0.2s ease;
}

button:hover {
    background: #e4e4e7;
}

h2 {
    font-size: 1.35rem;
    font-weight: 600;
    text-align: left;
    color: #f4f4f5;
    letter-spacing: -0.01em;
}

label {
    color: #a1a1aa;
    font-size: 0.85rem;
    font-weight: 500;
}
CSS_EOF

# 2. Update dashboard.html with professional enterprise styling
python3 - << 'UPDATE_DASH'
import re

path = "secure_vault/templates/dashboard.html"
with open(path, "r") as f:
    content = f.read()

new_style = """    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; word-break: break-word; overflow-wrap: break-word; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #121214; color: #e4e4e7; padding: 2rem; display: flex; justify-content: center; min-height: 100vh; }
        .container { width: 100%; max-width: 1100px; background: #18181b; padding: 2rem; border: 1px solid #27272a; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #27272a; padding-bottom: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem; }
        h2 { font-size: 1.25rem; font-weight: 600; color: #f4f4f5; margin: 0; }
        h3 { font-size: 1rem; font-weight: 600; color: #f4f4f5; margin-bottom: 0.75rem; }
        textarea { width: 100%; min-height: 100px; padding: 0.85rem; background: #09090b; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 6px; box-sizing: border-box; outline: none; font-family: inherit; font-size: 0.95rem; }
        textarea:focus { border-color: #71717a; }
        button { padding: 0.75rem 1.25rem; background: #f4f4f5; color: #09090b; font-weight: 600; border: none; border-radius: 6px; cursor: pointer; margin-top: 0.75rem; font-size: 0.9rem; transition: background 0.2s; }
        button:hover { background: #e4e4e7; }
        table { width: 100%; border-collapse: collapse; margin-top: 1.5rem; overflow-x: auto; display: block; white-space: nowrap; }
        th, td { padding: 0.85rem 1rem; text-align: left; font-size: 0.85rem; border-bottom: 1px solid #27272a; color: #d4d4d8; }
        th { background: #121214; color: #a1a1aa; text-transform: uppercase; font-weight: 600; letter-spacing: 0.05em; font-size: 0.75rem; }
        .badge { background: #27272a; color: #f4f4f5; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 500; }
        .btn-action { padding: 0.4rem 0.75rem; font-size: 0.75rem; margin-right: 0.4rem; cursor: pointer; border-radius: 4px; font-weight: 600; }
    </style>"""

content = re.sub(r'<style>.*?</style>', new_style, content, flags=re.DOTALL)
with open(path, "w") as f:
    f.write(content)
print("[+] Updated dashboard template style.")
UPDATE_DASH

# 3. Update order_detail.html style
python3 - << 'UPDATE_DETAIL'
import re

path = "secure_vault/templates/order_detail.html"
with open(path, "r") as f:
    content = f.read()

new_style = """    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; word-break: break-word; overflow-wrap: break-word; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #121214; color: #e4e4e7; padding: 2rem; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .container { width: 100%; max-width: 800px; background: #18181b; padding: 2rem; border: 1px solid #27272a; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); }
        h2 { font-size: 1.35rem; font-weight: 600; color: #f4f4f5; margin-bottom: 1.25rem; }
        p { margin-bottom: 0.85rem; font-size: 0.9rem; color: #d4d4d8; }
        pre { background: #09090b; padding: 1rem; border: 1px solid #3f3f46; border-radius: 6px; color: #e4e4e7; white-space: pre-wrap; word-break: break-all; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 0.85rem; margin-top: 0.35rem; margin-bottom: 1rem; }
        a { color: #f4f4f5; text-decoration: underline; font-size: 0.85rem; font-weight: 500; }
        a:hover { color: #d4d4d8; }
    </style>"""

content = re.sub(r'<style>.*?</style>', new_style, content, flags=re.DOTALL)
with open(path, "w") as f:
    f.write(content)
print("[+] Updated order detail template style.")
UPDATE_DETAIL

# 4. Update unauthorized.html style
cat << 'TEMPLATE_UNAUTH' > secure_vault/templates/unauthorized.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Unauthorized</title></head>
<body style="background:#121214; color:#f4f4f5; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding:2rem; text-align:center; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100vh; margin:0;">
    <div style="background:#18181b; padding:2.5rem; border-radius:10px; border:1px solid #27272a; box-shadow:0 4px 20px rgba(0,0,0,0.4); max-width:400px; width:100%;">
        <h2 style="color:#ef4444; margin-top:0; font-size:1.25rem; font-weight:600;">Access Denied</h2>
        <p style="color:#a1a1aa; margin:1rem 0 1.5rem 0; font-size:0.9rem;">You do not have permission to view this record.</p>
        <a href="/" style="color:#f4f4f5; text-decoration:underline; font-size:0.85rem; font-weight:500;">Return to Dashboard</a>
    </div>
</body>
</html>
TEMPLATE_UNAUTH

echo "[+] Restarting Flask server with proper professional theme..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
echo "[+] Done! Clean, minimal, and professional layout applied."
