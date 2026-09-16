#!/usr/bin/env bash
set -e

echo "[+] Adjusting layout for seamless mobile and desktop responsiveness..."

# 1. Update style.css with fluid mobile-first spacing (no weird vertical center constraints)
cat << 'CSS_EOF' > secure_vault/src/static/style.css
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    word-break: break-word;
    overflow-wrap: break-word;
}

html {
    width: 100%;
    height: 100%;
    background-color: #121214;
}

body {
    width: 100%;
    min-height: 100vh;
    background-color: #121214;
    color: #e4e4e7;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 1rem;
    margin: 0;
}

.container {
    width: 100%;
    max-width: 420px;
    background: #18181b;
    padding: 1.5rem;
    border-radius: 10px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
    border: 1px solid #27272a;
    margin-top: 1rem;
    margin-bottom: 2rem;
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

# 2. Update dashboard.html layout for fluid full-width viewing on all screens
python3 - << 'UPDATE_DASH'
import re

path = "secure_vault/templates/dashboard.html"
with open(path, "r") as f:
    content = f.read()

new_style = """    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; word-break: break-word; overflow-wrap: break-word; }
        html { width: 100%; background: #121214; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #121214; color: #e4e4e7; padding: 1rem; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        .container { width: 100%; max-width: 1200px; background: #18181b; padding: 1.5rem; border: 1px solid #27272a; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); margin-top: 0.5rem; margin-bottom: 2rem; }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #27272a; padding-bottom: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem; }
        h2 { font-size: 1.25rem; font-weight: 600; color: #f4f4f5; margin: 0; }
        h3 { font-size: 1rem; font-weight: 600; color: #f4f4f5; margin-bottom: 0.75rem; }
        textarea { width: 100%; min-height: 100px; padding: 0.85rem; background: #09090b; color: #f4f4f5; border: 1px solid #3f3f46; border-radius: 6px; box-sizing: border-box; outline: none; font-family: inherit; font-size: 0.95rem; }
        textarea:focus { border-color: #71717a; }
        button { padding: 0.75rem 1.25rem; background: #f4f4f5; color: #09090b; font-weight: 600; border: none; border-radius: 6px; cursor: pointer; margin-top: 0.75rem; font-size: 0.9rem; transition: background 0.2s; }
        button:hover { background: #e4e4e7; }
        .table-wrapper { width: 100%; overflow-x: auto; margin-top: 1.5rem; border: 1px solid #27272a; border-radius: 6px; }
        table { width: 100%; border-collapse: collapse; white-space: nowrap; }
        th, td { padding: 0.85rem 1rem; text-align: left; font-size: 0.85rem; border-bottom: 1px solid #27272a; color: #d4d4d8; }
        th { background: #121214; color: #a1a1aa; text-transform: uppercase; font-weight: 600; letter-spacing: 0.05em; font-size: 0.75rem; }
        tr:last-child td { border-bottom: none; }
        .badge { background: #27272a; color: #f4f4f5; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 500; }
        .btn-action { padding: 0.4rem 0.75rem; font-size: 0.75rem; margin-right: 0.4rem; cursor: pointer; border-radius: 4px; font-weight: 600; display: inline-block; margin-top: 0; }
    </style>"""

content = re.sub(r'<style>.*?</style>', new_style, content, flags=re.DOTALL)

# Wrap table in responsive scroll container for clean mobile rendering
table_block_old = """        <table>"""
table_block_new = """        <div class="table-wrapper">\n        <table>"""
content = content.replace(table_block_old, table_block_new, 1)

table_end_old = """            </tbody>\n        </table>"""
table_end_new = """            </tbody>\n        </table>\n        </div>"""
content = content.replace(table_end_old, table_end_new, 1)

with open(path, "w") as f:
    f.write(content)
print("[+] Updated dashboard layout responsiveness.")
UPDATE_DASH

# 3. Update order_detail.html for clean top-aligned layout
python3 - << 'UPDATE_DETAIL'
import re

path = "secure_vault/templates/order_detail.html"
with open(path, "r") as f:
    content = f.read()

new_style = """    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; word-break: break-word; overflow-wrap: break-word; }
        html { width: 100%; background: #121214; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #121214; color: #e4e4e7; padding: 1rem; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        .container { width: 100%; max-width: 800px; background: #18181b; padding: 1.5rem; border: 1px solid #27272a; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); margin-top: 0.5rem; margin-bottom: 2rem; }
        h2 { font-size: 1.35rem; font-weight: 600; color: #f4f4f5; margin-bottom: 1.25rem; }
        p { margin-bottom: 0.85rem; font-size: 0.9rem; color: #d4d4d8; }
        pre { background: #09090b; padding: 1rem; border: 1px solid #3f3f46; border-radius: 6px; color: #e4e4e7; white-space: pre-wrap; word-break: break-all; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 0.85rem; margin-top: 0.35rem; margin-bottom: 1rem; }
        a { color: #f4f4f5; text-decoration: underline; font-size: 0.85rem; font-weight: 500; }
        a:hover { color: #d4d4d8; }
    </style>"""

content = re.sub(r'<style>.*?</style>', new_style, content, flags=re.DOTALL)
with open(path, "w") as f:
    f.write(content)
print("[+] Updated order detail layout.")
UPDATE_DETAIL

# 4. Update unauthorized.html layout
cat << 'TEMPLATE_UNAUTH' > secure_vault/templates/unauthorized.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Unauthorized</title></head>
<body style="background:#121214; color:#f4f4f5; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding:1rem; display:flex; flex-direction:column; align-items:center; min-height:100vh; margin:0;">
    <div style="background:#18181b; padding:2rem; border-radius:10px; border:1px solid #27272a; box-shadow:0 4px 20px rgba(0,0,0,0.4); max-width:400px; width:100%; margin-top:2rem; text-align:center;">
        <h2 style="color:#ef4444; margin-top:0; font-size:1.25rem; font-weight:600;">Access Denied</h2>
        <p style="color:#a1a1aa; margin:1rem 0 1.5rem 0; font-size:0.9rem;">You do not have permission to view this record.</p>
        <a href="/" style="color:#f4f4f5; text-decoration:underline; font-size:0.85rem; font-weight:500;">Return to Dashboard</a>
    </div>
</body>
</html>
TEMPLATE_UNAUTH

echo "[+] Restarting Flask server with responsive mobile-first flow layout..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
echo "[+] Done! Layout adjusted: cards flow naturally from the top without awkward vertical centering traps on mobile."
