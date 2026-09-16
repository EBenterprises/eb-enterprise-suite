const fs = require('fs');
const path = require('path');

// Modernized Design System Injection (OLED Dark, Cyber-Minimal Glassmorphism, Neon Accents)
const modernDesignSystem = `
        :root {
            --bg-obsidian: #030406;
            --surface-panel: #0a0d14;
            --surface-glass: rgba(13, 17, 23, 0.7);
            --accent-teal: #00ffea;
            --accent-teal-glow: rgba(0, 255, 234, 0.25);
            --accent-gold: #f4c430;
            --accent-gold-glow: rgba(244, 196, 48, 0.3);
            --text-main: #f1f5f9;
            --text-dim: #64748b;
            --border-subtle: rgba(0, 255, 234, 0.12);
            --border-glow: rgba(0, 255, 234, 0.4);
            --success: #00ff66;
            --danger: #ff3366;
            --radius-lg: 20px;
            --radius-md: 14px;
            --radius-sm: 10px;
            --transition-smooth: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        body { 
            background: var(--bg-obsidian); 
            background-image: radial-gradient(circle at 10% 10%, rgba(0,255,234,0.03) 0%, transparent 40%), radial-gradient(circle at 90% 90%, rgba(244,196,48,0.02) 0%, transparent 40%);
            color: var(--text-main); 
            padding: 40px 20px; 
            display: flex; 
            justify-content: center; 
            min-height: 100vh; 
        }
        .container { width: 100%; max-width: 1280px; }

        header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            background: var(--surface-glass); 
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border-subtle); 
            padding: 30px; 
            border-radius: var(--radius-lg); 
            margin-bottom: 30px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.7), 0 0 30px rgba(0,255,234,0.05); 
        }
        .logo h1 { color: var(--accent-teal); font-size: 1.8rem; font-weight: 800; letter-spacing: -0.5px; text-shadow: 0 0 15px var(--accent-teal-glow); display: flex; align-items: center; gap: 14px; }
        .logo p { color: var(--text-dim); font-size: 0.95rem; margin-top: 6px; font-weight: 400; }

        .nav-links { display: flex; gap: 14px; }
        .nav-btn { 
            background: rgba(0,255,234,0.04); 
            border: 1px solid var(--border-subtle); 
            color: var(--accent-teal); 
            padding: 12px 20px; 
            border-radius: var(--radius-sm); 
            text-decoration: none; 
            font-weight: 700; 
            font-size: 0.85rem; 
            transition: var(--transition-smooth); 
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .nav-btn.gold { border-color: rgba(244,196,48,0.3); color: var(--accent-gold); background: rgba(244,196,48,0.04); }
        .nav-btn:hover { background: rgba(0,255,234,0.1); border-color: var(--border-glow); transform: translateY(-2px); box-shadow: 0 5px 15px var(--accent-teal-glow); }

        .card { 
            background: var(--surface-panel); 
            border: 1px solid var(--border-subtle); 
            border-radius: var(--radius-lg); 
            overflow: hidden; 
            box-shadow: 0 15px 35px rgba(0,0,0,0.5); 
            display: flex; 
            flex-direction: column; 
            transition: var(--transition-smooth);
        }
        .card:hover { border-color: var(--border-glow); transform: translateY(-4px); box-shadow: 0 20px 40px rgba(0,0,0,0.8), 0 0 20px var(--accent-teal-glow); }
        .card-img { width: 100%; height: 220px; object-fit: cover; border-bottom: 1px solid var(--border-subtle); transition: transform 0.5s ease; }
        .card:hover .card-img { transform: scale(1.03); }

        .card-body { padding: 30px; flex: 1; display: flex; flex-direction: column; justify-content: space-between; }
        .farm-title { font-size: 1.4rem; font-weight: 800; color: var(--text-main); margin-bottom: 8px; letter-spacing: -0.3px; }
        .farm-desc { font-size: 0.95rem; color: var(--text-dim); margin-bottom: 20px; line-height: 1.5; }

        .meta-row { display: flex; justify-content: space-between; align-items: center; background: rgba(0,0,0,0.4); padding: 14px 18px; border-radius: var(--radius-sm); border: 1px solid rgba(255,255,255,0.03); margin-bottom: 24px; }
        .stock-badge { font-weight: 800; font-size: 1rem; color: var(--success); display: flex; align-items: center; gap: 8px; }
        .stock-badge.low { color: var(--danger); }
        .price-tag { font-weight: 800; font-size: 1.2rem; color: var(--accent-gold); text-shadow: 0 0 10px var(--accent-gold-glow); }

        .reserve-btn { 
            width: 100%; 
            background: linear-gradient(135deg, var(--accent-teal), #00b3a4); 
            color: var(--bg-obsidian); 
            border: none; 
            padding: 16px; 
            border-radius: var(--radius-sm); 
            font-weight: 800; 
            font-size: 0.95rem; 
            cursor: pointer; 
            box-shadow: 0 0 20px var(--accent-teal-glow); 
            transition: var(--transition-smooth); 
        }
        .reserve-btn:hover { filter: brightness(1.15); transform: translateY(-1px); box-shadow: 0 0 25px var(--accent-teal-glow); }
        .reserve-btn:disabled { background: #1e293b; color: #475569; cursor: not-allowed; box-shadow: none; transform: none; }

        .modal-overlay { 
            position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
            background: rgba(3, 4, 6, 0.85); 
            backdrop-filter: blur(12px); 
            -webkit-backdrop-filter: blur(12px); 
            display: none; justify-content: center; align-items: center; z-index: 2000; 
            animation: fadeIn 0.2s ease forwards;
        }
        .modal-box { 
            background: var(--surface-panel); 
            border: 1px solid var(--border-glow); 
            border-radius: var(--radius-lg); 
            width: 100%; max-width: 480px; padding: 35px; 
            box-shadow: 0 25px 60px rgba(0,0,0,0.95), 0 0 40px var(--accent-teal-glow); 
            animation: scaleUp 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes scaleUp { from { transform: scale(0.95); opacity: 0; } to { transform: scale(1); opacity: 1; } }

        .toast { 
            position: fixed; bottom: 35px; right: 35px; 
            background: var(--surface-panel); 
            border: 1px solid var(--accent-teal); 
            color: var(--text-main); 
            padding: 18px 28px; 
            border-radius: var(--radius-md); 
            box-shadow: 0 15px 40px rgba(0,0,0,0.9), 0 0 25px var(--accent-teal-glow); 
            display: none; z-index: 3000; font-weight: 700; font-size: 0.95rem; 
        }
`;

const indexPath = path.join(__dirname, 'public', 'index.html');
if (fs.existsSync(indexPath)) {
    let html = fs.readFileSync(indexPath, 'utf8');
    // Replace old style block with modern design system
    const styleStart = html.indexOf('<style>');
    const styleEnd = html.indexOf('</style>') + 8;
    if (styleStart !== -1 && styleEnd !== -1) {
        html = html.substring(0, styleStart) + '<style>\n' + modernDesignSystem + '\n    </style>' + html.substring(styleEnd);
        fs.writeFileSync(indexPath, html);
        console.log("[THEME] Consumer radar successfully upgraded to ultra-modern OLED Glassmorphism.");
    }
}
