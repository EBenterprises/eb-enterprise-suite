#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - UI Layout & CSS Polishing Fix
# ==============================================================================
set -e

mkdir -p public

cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Architecture V12 - Secure Platform</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>EB ENTERPRISES</h1>
            <span class="badge">View ID: 2</span>
        </header>

        <div style="text-align: center; margin-bottom: 2rem;">
            <h2 style="color: var(--highlight-gold); font-size: 2rem; margin-bottom: 0.5rem;">EB ARCHITECTURE V12</h2>
            <p style="color: var(--text-muted); font-size: 1rem;">Zero-dependency, high-throughput encrypted messaging protocol.</p>
            <button class="btn-primary" style="max-width: 200px; margin-top: 1rem;" onclick="alert('Mesh Network Initialized')">Get Started</button>
        </div>

        <div class="form-grid">
            <div class="form-group full" style="grid-column: 1 / -1;">
                <h3 style="color: var(--accent-teal); margin-bottom: 0.5rem;">Welcome</h3>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-bottom: 1rem;">Select an action to enter the mesh network.</p>
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <button class="preset-btn" onclick="alert('Create Account Selected')">Create New Account</button>
                    <button class="preset-btn" onclick="alert('Sign In Selected')">Sign In Existing Account</button>
                </div>
            </div>

            <div class="form-group full" style="grid-column: 1 / -1; margin-top: 1rem;">
                <label>OR CONTINUE WITH</label>
                <button class="preset-btn" style="width: 100%; text-align: center; background: var(--bg-obsidian); border-color: var(--accent-teal); color: var(--accent-teal);" onclick="alert('Partner SSO Triggered')">☑ Sign In with Enterprise Partner</button>
            </div>
        </div>

        <div class="form-grid">
            <div class="form-group full" style="grid-column: 1 / -1;">
                <h3 style="color: var(--highlight-gold); margin-bottom: 0.5rem;">Credentials</h3>
                <p style="color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem;">Step 1 of registration sequence.</p>
            </div>
            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" id="email" placeholder="operator@domain.com">
            </div>
            <div class="form-group">
                <label for="password">Master Password</label>
                <input type="password" id="password" placeholder="••••••••••••">
            </div>
            <div class="form-group full" style="grid-column: 1 / -1;">
                <button class="btn-primary" onclick="alert('Credentials Submitted')">Continue to Demographics</button>
            </div>
        </div>

        <div class="form-grid">
            <div class="form-group full" style="grid-column: 1 / -1;">
                <h3 style="color: var(--highlight-gold); margin-bottom: 0.5rem;">Demographics</h3>
                <p style="color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem;">Provide verified profile criteria.</p>
            </div>
            <div class="form-group full" style="grid-column: 1 / -1;">
                <label for="dob">Date of Birth</label>
                <select id="dob">
                    <option value="">Select Date of Birth</option>
                    <option value="verified">Verified Secure Tier (18+)</option>
                </select>
            </div>
        </div>
    </div>
</body>
</html>
HTML_EOF

# Copy to root as well
cp public/index.html ./index.html

echo "[+] Frontend UI layout successfully corrected, styled with Executive Spectrum design tokens, and synchronized."
