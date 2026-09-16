#!/bin/bash

echo "[+] Updating full-screen responsive layout..."

mkdir -p secure_vault/src/static secure_vault/src/templates

# 1. Update CSS with fluid full-width mobile padding, wrapping, and spacing
cat << 'CSS' > secure_vault/src/static/style.css
/* Global Reset & Box Sizing */
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
    background-color: #0f172a;
    color: #f8fafc;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: center;
    padding: 0.75rem;
}

/* Fluid Container that fills mobile screens safely with breathing room */
.container {
    width: 100%;
    max-width: 600px;
    background: #1e293b;
    padding: 1.25rem;
    border-radius: 14px;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.35);
    margin-top: 1rem;
    margin-bottom: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* Typography and Spacing */
h1, h2, h3 {
    color: #f1f5f9;
    line-height: 1.3;
    text-align: center;
    margin-bottom: 0.5rem;
}

p, label {
    color: #cbd5e1;
    font-size: 0.95rem;
    line-height: 1.5;
}

/* Form Elements & Touch Targets */
form {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    width: 100%;
}

input, select, textarea, button {
    width: 100%;
    padding: 0.85rem 1rem;
    border: 1px solid #334155;
    border-radius: 8px;
    background: #0f172a;
    color: #f8fafc;
    font-size: 1rem; /* Prevents auto-zoom on mobile safari/chrome */
    outline: none;
    transition: border-color 0.2s;
}

input:focus, textarea:focus {
    border-color: #3b82f6;
}

button {
    background: #3b82f6;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 48px; /* Ideal mobile touch target */
    margin-top: 0.5rem;
}

button:active {
    background: #2563eb;
}

/* Tablet & Desktop Adjustments */
@media (min-width: 768px) {
    html, body {
        padding: 2rem;
        justify-content: center;
    }
    .container {
        max-width: 650px;
        padding: 2.5rem;
        margin-top: 0;
    }
}
CSS

# 2. Ensure HTML Template handles Viewport Scale Correctly
cat << 'HTML' > secure_vault/src/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Secure Vault</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        <h2>Secure Vault Portal</h2>
        <form method="POST">
            <label for="passcode">Enter Passcode / Key:</label>
            <input type="password" id="passcode" name="passcode" required placeholder="Enter key...">
            <button type="submit">Access Vault</button>
        </form>
    </div>
</body>
</html>
HTML

echo "[+] Full-screen responsive layout applied!"
