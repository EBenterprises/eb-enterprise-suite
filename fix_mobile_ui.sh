#!/bin/bash

echo "[+] Applying mobile-friendly UI constraints to Secure Vault..."

mkdir -p secure_vault/src/static

cat << 'CSS' > secure_vault/src/static/style.css
/* Mobile-First Fluid Resizing */
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background-color: #0f172a;
    color: #f8fafc;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    padding: 1rem;
    width: 100vw;
    overflow-x: hidden;
}

/* Fluid Container that Adapts to Small Screens */
.container {
    width: 100%;
    max-width: 420px;
    background: #1e293b;
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    margin: 0 auto;
}

/* Touch-Friendly Form Elements */
input, select, textarea, button {
    width: 100%;
    max-width: 100%;
    padding: 0.875rem;
    margin-top: 0.5rem;
    margin-bottom: 1rem;
    border: 1px solid #334155;
    border-radius: 8px;
    background: #0f172a;
    color: #f8fafc;
    font-size: 1rem; /* Prevents auto-zoom on iOS */
}

button {
    background: #3b82f6;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 48px; /* Ideal mobile touch target size */
    transition: background 0.2s;
}

button:active {
    background: #1d4ed8;
}

/* Responsive Headings & Text */
h2 {
    font-size: 1.5rem;
    margin-bottom: 1rem;
    text-align: center;
}

label {
    font-size: 0.875rem;
    color: #94a3b8;
}

/* Tablet & Desktop Expansion */
@media (min-width: 768px) {
    .container {
        max-width: 500px;
        padding: 2.5rem;
    }
    h2 {
        font-size: 1.75rem;
    }
}
CSS

echo "[+] Mobile UI styling applied successfully!"
