#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Executive Spectrum CSS Injection
# ==============================================================================
set -e

mkdir -p public

cat << 'CSS_EOF' > public/style.css
/* ==============================================================================
   EXECUTIVE SPECTRUM DESIGN SYSTEM (EB Enterprises)
   Obsidian (#0b0f19) | Deep Teal (#00d2c4) | Champagne Gold (#d4af37)
   ============================================================================== */

:root {
    --bg-obsidian: #0b0f19;
    --surface-dark: #131b2e;
    --surface-card: #182239;
    --border-color: #27354f;
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-hover: #00b3a6;
    --highlight-gold: #d4af37;
    --highlight-gold-hover: #b89728;
    --danger: #ef4444;
    --success: #22c55e;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

body {
    background-color: var(--bg-obsidian);
    color: var(--text-main);
    min-height: 100vh;
    padding: 2rem;
    display: flex;
    flex-direction: column;
    align-items: center;
}

.container {
    width: 100%;
    max-width: 1200px;
    background: var(--surface-dark);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}

header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid var(--border-color);
    padding-bottom: 1rem;
    margin-bottom: 2rem;
}

h1 {
    font-size: 1.75rem;
    color: var(--highlight-gold);
    letter-spacing: 0.05em;
}

.badge {
    background: rgba(0, 210, 196, 0.15);
    color: var(--accent-teal);
    padding: 0.35rem 0.75rem;
    border-radius: 20px;
    font-size: 0.85rem;
    font-weight: 600;
    border: 1px solid var(--accent-teal);
}

.form-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 1rem;
    margin-bottom: 1.5rem;
    background: var(--surface-card);
    padding: 1.5rem;
    border-radius: 8px;
    border: 1px solid var(--border-color);
}

.form-group {
    display: flex;
    flex-direction: column;
}

label {
    font-size: 0.85rem;
    color: var(--text-muted);
    margin-bottom: 0.5rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

input, select {
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    padding: 0.75rem;
    border-radius: 6px;
    font-size: 1rem;
    outline: none;
    transition: border-color 0.2s;
}

input:focus, select:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px rgba(0, 210, 196, 0.15);
}

.presets-container {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
}

.preset-btn {
    background: var(--surface-card);
    border: 1px solid var(--highlight-gold);
    color: var(--highlight-gold);
    padding: 0.5rem 1rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    transition: all 0.2s;
}

.preset-btn:hover {
    background: var(--highlight-gold);
    color: var(--bg-obsidian);
}

.btn-primary {
    background: var(--accent-teal);
    color: var(--bg-obsidian);
    border: none;
    padding: 0.75rem 1.5rem;
    font-weight: bold;
    border-radius: 6px;
    cursor: pointer;
    transition: background 0.2s;
    width: 100%;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.btn-primary:hover {
    background: var(--accent-teal-hover);
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 1.5rem;
    background: var(--surface-card);
    border-radius: 8px;
    overflow: hidden;
    border: 1px solid var(--border-color);
}

th, td {
    padding: 1rem;
    text-align: left;
    border-bottom: 1px solid var(--border-color);
}

th {
    background: #111827;
    color: var(--highlight-gold);
    font-size: 0.85rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

tr:hover {
    background: rgba(255, 255, 255, 0.02);
}

.action-toggle {
    cursor: pointer;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-size: 0.85rem;
    font-weight: 600;
    border: none;
}

.action-toggle.active {
    background: rgba(34, 197, 94, 0.2);
    color: var(--success);
    border: 1px solid var(--success);
}

.action-toggle.inactive {
    background: rgba(239, 68, 68, 0.2);
    color: var(--danger);
    border: 1px solid var(--danger);
}
CSS_EOF

# Also copy or symlink style.css to root so static middleware picks it up immediately
cp public/style.css ./style.css

echo "[+] Executive Spectrum CSS successfully deployed to public/style.css and root."
