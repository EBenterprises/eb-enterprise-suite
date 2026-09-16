#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Custom Copy Portal Engine
# ==============================================================================
set -e

echo "[+] Writing custom copy and live deployment files..."

cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="capture-container">
        <div class="badge">Restricted Portal</div>
        <h1 class="headline">Executive Access</h1>
        <p class="subheadline">Secure Your Advantage<br>Enter your credentials below to initialize direct access to proprietary architectures and market launch assets.</p>

        <form id="access-form" class="capture-form">
            <div class="form-group">
                <label for="fullName">Full Name</label>
                <input type="text" id="fullName" placeholder="Alexander Wright" required autocomplete="name">
            </div>
            <div class="form-group">
                <label for="email">Secure Email</label>
                <input type="email" id="email" placeholder="alexander@domain.com" required autocomplete="email">
            </div>
            <button type="submit" class="btn-capture">Initialize Access</button>
        </form>

        <div id="toast"></div>

        <div class="footer-note">
            Zero spam guarantee. Immediate cryptographic revocation anytime.
        </div>
    </div>

    <script>
        document.getElementById('access-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullName = document.getElementById('fullName').value.trim();
            const email = document.getElementById('email').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!fullName || !email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Initializing...';

            try {
                const res = await fetch('/api/access', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ fullName, email })
                });

                const contentType = res.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new Error("Received non-JSON response from server.");
                }

                const data = await res.json();

                toast.style.display = 'block';
                if (res.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = data.message;
                    document.getElementById('access-form').reset();
                    submitBtn.textContent = 'Access Initialized ✓';
                } else {
                    throw new Error(data.error || 'Initialization failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Initialize Access';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Restarting server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_executive_access" nohup node server.js > server.log 2>&1 &
echo "[+] Portal updated with custom copy and active on port 5000."
echo "[+] Monitor live submissions with: tail -f server.log"
