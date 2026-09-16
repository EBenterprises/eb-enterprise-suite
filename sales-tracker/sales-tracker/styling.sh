#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Executive Spectrum Styling Refinement
# ==============================================================================
set -e

echo "[+] Updating public/styles.css with polished padding, margins, and whitespace..."
cat << 'ECSS' > public/styles.css
:root {
    --bg-obsidian: #0b0f12;
    --card-bg: #131920;
    --border-color: #1e293b;
    --teal-accent: #00ffcc;
    --gold-highlight: #d4af37;
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --danger-color: #ef4444;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    background-color: var(--bg-obsidian);
    color: var(--text-main);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.6;
    padding: 2.5rem 1.5rem;
}

.app-container {
    max-width: 1000px;
    margin: 0 auto;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 2.5rem;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
}

header {
    text-align: center;
    margin-bottom: 2.5rem;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1.5rem;
}

header h1 {
    font-size: 2rem;
    letter-spacing: 0.05em;
    color: var(--text-main);
    margin-bottom: 0.3rem;
}

header .subtitle {
    color: var(--text-muted);
    font-size: 0.95rem;
    text-transform: uppercase;
    letter-spacing: 0.15em;
}

#live-totals-bar {
    display: flex;
    justify-content: center;
    gap: 2.5rem;
    margin-top: 1.5rem;
    padding: 1rem 1.5rem;
    background: rgba(0, 255, 204, 0.03);
    border: 1px solid var(--teal-accent);
    border-radius: 8px;
    font-family: monospace;
    font-size: 0.95rem;
}

.tab-nav {
    display: flex;
    gap: 0.75rem;
    margin-bottom: 2.5rem;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1rem;
    overflow-x: auto;
}

.tab-btn {
    background: transparent;
    border: 1px solid var(--border-color);
    color: var(--text-muted);
    padding: 0.65rem 1.25rem;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    transition: all 0.2s ease;
    white-space: nowrap;
}

.tab-btn:hover {
    border-color: var(--teal-accent);
    color: var(--text-main);
}

.tab-btn.active {
    background: var(--teal-accent);
    border-color: var(--teal-accent);
    color: var(--bg-obsidian);
    font-weight: bold;
}

.tab-content {
    display: none;
}

.tab-content.active {
    display: block;
}

.form-section {
    background: rgba(255, 255, 255, 0.01);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 2rem;
    margin-bottom: 2.5rem;
}

.form-section h2 {
    font-size: 1.2rem;
    margin-bottom: 1.25rem;
    color: var(--teal-accent);
    letter-spacing: 0.03em;
}

.preset-buttons {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
}

.preset-btn {
    background: rgba(212, 175, 55, 0.08);
    border: 1px solid var(--gold-highlight);
    color: var(--gold-highlight);
    padding: 0.45rem 0.9rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85rem;
    font-family: monospace;
    transition: all 0.2s ease;
}

.preset-btn:hover {
    background: var(--gold-highlight);
    color: var(--bg-obsidian);
}

.filter-buttons {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
}

.filter-btn {
    background: transparent;
    border: 1px solid var(--border-color);
    color: var(--text-muted);
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
}

.filter-btn:hover, .filter-btn.active {
    border-color: var(--teal-accent);
    color: var(--teal-accent);
    background: rgba(0, 255, 204, 0.05);
}

.input-group {
    margin-bottom: 1.25rem;
}

input, select {
    width: 100%;
    padding: 0.85rem 1rem;
    background: var(--bg-obsidian);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-main);
    font-size: 0.95rem;
    transition: border-color 0.2s ease;
}

input:focus, select:focus {
    outline: none;
    border-color: var(--teal-accent);
}

.btn-submit {
    background: var(--teal-accent);
    color: var(--bg-obsidian);
    border: none;
    padding: 0.85rem 1.5rem;
    border-radius: 6px;
    font-weight: bold;
    cursor: pointer;
    font-size: 0.95rem;
    width: 100%;
    transition: opacity 0.2s ease;
}

.btn-submit:hover {
    opacity: 0.9;
}

.list-section {
    background: rgba(255, 255, 255, 0.01);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 2rem;
}

.list-section h2 {
    font-size: 1.2rem;
    margin-bottom: 1.25rem;
    color: var(--gold-highlight);
    letter-spacing: 0.03em;
}

.table-responsive {
    overflow-x: auto;
}

.data-table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
    font-size: 0.9rem;
}

.data-table th, .data-table td {
    padding: 1rem 1.25rem;
    border-bottom: 1px solid var(--border-color);
}

.data-table th {
    color: var(--text-muted);
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.05em;
}

.timestamp {
    color: var(--text-muted);
    font-size: 0.85rem;
}

.action-link {
    background: none;
    border: none;
    color: var(--teal-accent);
    cursor: pointer;
    font-size: 0.85rem;
    text-decoration: underline;
    padding: 0;
    margin-top: 0.3rem;
    display: inline-block;
}

.btn-delete {
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid var(--danger-color);
    color: var(--danger-color);
    padding: 0.35rem 0.75rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
    transition: all 0.2s ease;
}

.btn-delete:hover {
    background: var(--danger-color);
    color: #fff;
}

.loading {
    color: var(--text-muted);
    text-align: center;
    padding: 2rem 0;
    font-style: italic;
}

.modal {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}

.modal-content {
    background: var(--card-bg);
    border: 1px solid var(--teal-accent);
    border-radius: 10px;
    padding: 2.5rem;
    box-shadow: 0 15px 40px rgba(0,0,0,0.7);
}

.modal-content h3 {
    color: var(--teal-accent);
    margin-bottom: 1rem;
    font-size: 1.25rem;
}

@media (max-width: 768px) {
    body {
        padding: 1rem 0.5rem;
    }
    .app-container {
        padding: 1.25rem;
    }
    #live-totals-bar {
        flex-direction: column;
        gap: 0.75rem;
        align-items: center;
    }
}
ECSS

echo "[+] Restarting server to apply styling updates..."
pkill -f "node server.js" || true
node server.js &
