#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - High Contrast Theme Patch
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Updating styles.css for maximum visibility and contrast..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #0d1117;
    --dark-grey: #161b22;
    --border-color: #30363d;
    --deep-teal: #1f6feb;
    --teal-glow: #58a6ff;
    --champagne-gold: #f0b72c;
    --text-main: #ffffff;
    --text-muted: #8b949e;
    --danger: #f85149;
    --danger-hover: #da3633;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }

body {
    background-color: var(--obsidian);
    color: var(--text-main);
    padding: 20px;
    line-height: 1.5;
}

.container { max-width: 1100px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 30px; border-bottom: 2px solid var(--border-color); padding-bottom: 20px;
}

.logo {
    display: inline-block; width: 50px; height: 50px; line-height: 50px;
    background: var(--deep-teal); color: var(--text-main);
    font-weight: bold; font-size: 1.5rem; border-radius: 6px; margin-bottom: 10px;
}

h1 { color: var(--teal-glow); font-size: 2.2rem; letter-spacing: 1px; }
header p { color: var(--text-muted); font-size: 1rem; }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }
.card { background: var(--dark-grey); padding: 20px; border: 1px solid var(--border-color); border-radius: 8px; border-left: 5px solid var(--deep-teal); }
.card h3 { color: var(--text-muted); font-size: 0.85rem; text-transform: uppercase; margin-bottom: 8px; font-weight: 600; }
.card p { font-size: 1.8rem; font-weight: bold; color: var(--text-main); }

.gold-text { color: var(--champagne-gold) !important; }
.teal-text { color: var(--teal-glow) !important; }

.form-section, .table-section { background: var(--dark-grey); padding: 25px; border: 1px solid var(--border-color); margin-bottom: 30px; border-radius: 8px; }
h2 { color: var(--teal-glow); margin-bottom: 20px; font-size: 1.3rem; }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.85rem; margin-bottom: 6px; color: var(--text-main); font-weight: 600; }
.form-group input { padding: 12px; background: var(--obsidian); border: 1px solid var(--border-color); color: var(--text-main); font-size: 1rem; border-radius: 6px; }
.form-group input::placeholder { color: #484f58; }
.form-group input:focus { outline: none; border-color: var(--teal-glow); box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.3); }

.btn-submit { width: 100%; padding: 14px; background: var(--deep-teal); color: var(--text-main); border: none; font-weight: bold; font-size: 1rem; cursor: pointer; border-radius: 6px; transition: background 0.2s; }
.btn-submit:hover { background: #388bfd; }

.table-wrapper { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 14px 12px; border-bottom: 1px solid var(--border-color); }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.85rem; background: #21262d; }
td { font-size: 1rem; color: var(--text-main); }

.btn-delete { background: var(--danger); border: none; color: var(--text-main); padding: 6px 12px; cursor: pointer; border-radius: 4px; font-weight: 600; transition: background 0.2s; }
.btn-delete:hover { background: var(--danger-hover); }
CSS_EOF

echo "[+] High-contrast theme applied. Restarting server..."
node server.js
