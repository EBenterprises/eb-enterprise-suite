#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Cyber-Executive Spectrum "Dope" Overhaul
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Upgrading styles.css with high-end neon accents, glassmorphism, and smooth transitions..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #080a0f;
    --dark-grey: #121824;
    --card-bg: rgba(18, 24, 36, 0.7);
    --border-color: #1e293b;
    --border-glow: rgba(56, 189, 248, 0.4);
    --deep-teal: #0284c7;
    --teal-glow: #38bdf8;
    --champagne-gold: #fbbf24;
    --gold-glow: rgba(251, 191, 36, 0.3);
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --danger: #ef4444;
    --danger-hover: #dc2626;
    --success: #10b981;
    --warning: #f59e0b;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'JetBrains Mono', monospace, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }

body {
    background-color: var(--obsidian);
    background-image: 
        radial-gradient(circle at 10% 20%, rgba(2, 132, 199, 0.08) 0%, transparent 40%),
        radial-gradient(circle at 90% 80%, rgba(251, 191, 36, 0.05) 0%, transparent 40%);
    color: var(--text-main);
    padding: 30px;
    line-height: 1.6;
    min-height: 100vh;
}

.container { max-width: 1350px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 40px; border-bottom: 1px solid var(--border-color); padding-bottom: 25px;
    position: relative;
}

header::after {
    content: ''; position: absolute; bottom: -1px; left: 50%<b>translateX(-50%)</b>; width: 200px; height: 2px;
    background: linear-gradient(90deg, transparent, var(--teal-glow), transparent);
}

.logo {
    display: inline-block; width: 60px; height: 60px; line-height: 60px;
    background: linear-gradient(135deg, var(--deep-teal), #0369a1); color: var(--text-main);
    font-weight: 900; font-size: 1.8rem; border-radius: 12px; margin-bottom: 12px;
    box-shadow: 0 0 20px rgba(56, 189, 248, 0.3);
    border: 1px solid var(--teal-glow);
}

h1 { color: var(--teal-glow); font-size: 2.5rem; letter-spacing: 2px; text-transform: uppercase; text-shadow: 0 0 15px rgba(56, 189, 248, 0.2); }
header p { color: var(--text-muted); font-size: 1.05rem; letter-spacing: 0.5px; }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 25px; margin-bottom: 35px; }
.card { 
    background: var(--card-bg); backdrop-filter: blur(12px);
    padding: 25px; border: 1px solid var(--border-color); border-radius: 12px; 
    border-left: 6px solid var(--deep-teal);
    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    transition: transform 0.2s ease, border-color 0.2s ease;
}
.card:hover { transform: translateY(-3px); border-color: var(--teal-glow); }
.card h3 { color: var(--text-muted); font-size: 0.8rem; text-transform: uppercase; margin-bottom: 10px; letter-spacing: 1px; font-weight: 700; }
.card p { font-size: 2.2rem; font-weight: 800; color: var(--text-main); }

.gold-text { color: var(--champagne-gold) !important; text-shadow: 0 0 10px var(--gold-glow); }
.teal-text { color: var(--teal-glow) !important; text-shadow: 0 0 10px rgba(56, 189, 248, 0.3); }

.form-section, .table-section { 
    background: var(--card-bg); backdrop-filter: blur(12px);
    padding: 30px; border: 1px solid var(--border-color); margin-bottom: 35px; border-radius: 12px; 
    box-shadow: 0 15px 35px rgba(0,0,0,0.6);
}
h2 { color: var(--teal-glow); margin-bottom: 25px; font-size: 1.4rem; text-transform: uppercase; letter-spacing: 1px; border-left: 4px solid var(--champagne-gold); padding-left: 12px; }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 20px; margin-bottom: 25px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.8rem; margin-bottom: 8px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; }
.form-group input, .form-group select { 
    padding: 14px; background: var(--obsidian); border: 1px solid var(--border-color); 
    color: var(--text-main); font-size: 1rem; border-radius: 8px; 
    transition: all 0.2s ease;
}
.form-group input::placeholder { color: #475569; }
.form-group input:focus, .form-group select:focus { 
    outline: none; border-color: var(--teal-glow); 
    box-shadow: 0 0 15px rgba(56, 189, 248, 0.25); 
    background: #0f172a;
}

.btn-submit { 
    width: 100%; padding: 16px; 
    background: linear-gradient(135deg, var(--deep-teal), #0284c7); 
    color: var(--text-main); border: 1px solid var(--teal-glow); 
    font-weight: 800; font-size: 1.1rem; cursor: pointer; border-radius: 8px; 
    text-transform: uppercase; letter-spacing: 1.5px;
    box-shadow: 0 4px 20px rgba(2, 132, 199, 0.4);
    transition: all 0.2s ease; 
}
.btn-submit:hover { 
    background: linear-gradient(135deg, #0369a1, var(--deep-teal));
    box-shadow: 0 6px 25px rgba(56, 189, 248, 0.6);
    transform: translateY(-2px);
}

.table-wrapper { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border-color); }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 16px 14px; border-bottom: 1px solid var(--border-color); }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 1px; background: #0f172a; font-weight: 800; }
td { font-size: 0.95rem; color: var(--text-main); }
tbody tr { transition: background 0.15s ease; }
tbody tr:hover { background: rgba(30, 41, 59, 0.5); }

.badge { padding: 6px 12px; border-radius: 6px; font-size: 0.75rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; display: inline-block; box-shadow: 0 2px 10px rgba(0,0,0,0.3); }
.badge-paid { background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981; }
.badge-unpaid { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid #ef4444; }
.badge-partial { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }

.status-controls { display: flex; flex-direction: column; gap: 8px; }
select.status-select { 
    padding: 6px 10px; background: var(--obsidian); color: var(--text-main); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; font-weight: 600;
    cursor: pointer;
}
input.paid-input { 
    padding: 6px 10px; background: var(--obsidian); color: var(--champagne-gold); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; width: 110px; font-weight: bold;
}

.btn-delete { 
    background: rgba(239, 68, 68, 0.15); border: 1px solid var(--danger); color: #f87171; 
    padding: 8px 14px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.8rem;
    text-transform: uppercase; letter-spacing: 0.5px; transition: all 0.2s ease; 
}
.btn-delete:hover { background: var(--danger); color: white; box-shadow: 0 0 15px rgba(239, 68, 68, 0.4); }
CSS_EOF

echo "[+] Cyber-Executive theme applied. Restarting server..."
node server.js
