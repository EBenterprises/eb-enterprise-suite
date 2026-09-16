#!/bin/bash
set -e

echo "[+] Updating v2 application (releases/v2) with customized title and quick presets..."

# 1. Update index.html title and presets in releases/v2
python3 -c "
with open('releases/v2/public/index.html', 'r') as f:
    html = f.read()

# Update header title if needed
html = html.replace('EB Sales Tracker', 'EB Sales & Payments Tracker')

# Update quick presets markup if necessary or ensure presets reflect the custom labels
old_presets = '''            <div class=\"preset-buttons\" style=\"margin-bottom: 1rem;\">
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(0.87, 20)\">0.87g - $20</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(1.75, 40)\">1.75g - $40</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(3.5, 80)\">3.5g - $80</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(7, 160)\">7g - $160</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(14, 320)\">14g - $320</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(28, 640)\">28g - $640</button>
            </div>'''

new_presets = '''            <div class=\"preset-buttons\" style=\"margin-bottom: 1rem; display: flex; flex-wrap: wrap; gap: 0.5rem;\">
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(0.87, 20, 'Syde (0.87g)')\">Syde (0.87g)</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(1.75, 40, 'Syde (1.75g)')\">Syde (1.75g)</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(3.5, 80, 'Syde (3.5g)')\">Syde (3.5g)</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(7, 160, 'Syde (7g)')\">Syde (7g)</button>
                <button type=\"button\" class=\"btn-preset\" onclick=\"setPreset(14, 320, 'Syde (14g)')\">Syde (14g)</button>
            </div>'''

if 'btn-preset' in html:
    # replace section containing presets
    import re
    html = re.sub(r'<div class=\"preset-buttons\"[^>]*>.*?</div>', new_presets, html, flags=re.DOTALL)

with open('releases/v2/public/index.html', 'w') as f:
    f.write(html)
print('[+] v2 index.html updated.')
"

# 2. Update app.js in releases/v2 to handle preset item descriptions
python3 -c "
with open('releases/v2/public/app.js', 'r') as f:
    js = f.read()

old_set_preset = '''function setPreset(qty, price) {
    document.getElementById('item-qty').value = qty;
    document.getElementById('item-price').value = price;
    document.getElementById('item-desc').value = qty + 'g Unit';
}'''

new_set_preset = '''function setPreset(qty, price, label) {
    document.getElementById('item-qty').value = qty;
    document.getElementById('item-price').value = price;
    document.getElementById('item-desc').value = label || (qty + 'g Unit');
}'''

if old_set_preset in js:
    js = js.replace(old_set_preset, new_set_preset)
elif 'function setPreset' in js:
    import re
    js = re.sub(r'function setPreset\([^)]*\)\s*\{[^}]*\}', new_set_preset, js, flags=re.DOTALL)

with open('releases/v2/public/app.js', 'w') as f:
    f.write(js)
print('[+] v2 app.js updated.')
"

echo "[+] Restarting v2 on port 3002..."
pkill -f "node.*releases/v2/server.js" || true
cd releases/v2
PORT=3002 nohup node server.js > server.log 2>&1 &
cd - > /dev/null

echo "[+] v2 successfully updated and running on http://localhost:3002"
