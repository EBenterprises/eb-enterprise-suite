#!/bin/bash

echo "[+] Injecting responsive design fixes into Secure Vault..."

# Ensure directories exist
mkdir -p secure_vault/src/static secure_vault/src/templates

# 1. Inject/Update Responsive CSS
cat << 'CSS' > secure_vault/src/static/style.css
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 1rem; }
.container { width: 100%; max-width: 480px; background: #1e293b; padding: 2rem; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
input, button, textarea { width: 100%; padding: 0.75rem; margin-top: 0.5rem; margin-bottom: 1rem; border: 1px solid #334155; border-radius: 6px; background: #0f172a; color: #f8fafc; font-size: 1rem; }
button { background: #3b82f6; border: none; font-weight: 600; cursor: pointer; }
button:hover { background: #2563eb; }
@media (min-width: 768px) { .container { max-width: 600px; padding: 2.5rem; } }
CSS

# 2. Update or Create HTML Template with Viewport Scale Tag & Stylesheet Link
cat << 'HTML' > secure_vault/src/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Vault</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        <h2>Secure Vault Portal</h2>
        <form method="POST">
            <label for="passcode">Enter Passcode / Key:</label>
            <input type="password" id="passcode" name="passcode" required>
            <button type="submit">Access Vault</button>
        </form>
    </div>
</body>
</html>
HTML

echo "[+] Responsive injection complete!"
echo "[+] Restart your application using: ./start.sh"
