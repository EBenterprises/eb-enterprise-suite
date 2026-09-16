#!/bin/bash

# Ensure directories exist
mkdir -p secure_vault/src/static secure_vault/src/templates

# Write Responsive CSS
cat << 'CSS' > secure_vault/src/static/style.css
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: sans-serif; background-color: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 1rem; }
.container { width: 100%; max-width: 480px; background: #1e293b; padding: 2rem; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
input, button { width: 100%; padding: 0.75rem; margin-top: 0.5rem; margin-bottom: 1rem; border: 1px solid #334155; border-radius: 6px; background: #0f172a; color: #f8fafc; font-size: 1rem; }
button { background: #3b82f6; border: none; font-weight: 600; cursor: pointer; }
button:hover { background: #2563eb; }
@media (min-width: 768px) { .container { max-width: 600px; padding: 2.5rem; } }
CSS

echo "[+] Responsive CSS updated successfully!"
