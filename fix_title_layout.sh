#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Title Layout Restoration Engine
# ==============================================================================
set -e

echo "[+] Restoring original CTA title layout in public/index.html..."

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
        <div class="badge">Limited Allocation</div>
        <h1 class="headline">Enter your email address to <span>reserve your spot</span></h1>
        <p class="subheadline">EB Enterprises</p>

        <form id="reservation-form" class="capture-form">
            <div class="input-group">
                <input type="email" id="email" placeholder="Enter your email address..." required autocomplete="email">
            </div>
            <button type="submit" class="btn-capture">Reserve My Spot</button>
        </form>

        <div id="toast"></div>

        <div class="footer-note">
            EB Enterprises &bull; Zero Spam &bull; Sovereign Infrastructure
        </div>
    </div>

    <script>
        document.getElementById('reservation-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const toast = document.getElementById('toast');
            const submitBtn = e.target.querySelector('button');

            if (!email) return;

            submitBtn.disabled = true;
            submitBtn.textContent = 'Reserving Spot...';

            try {
                const res = await fetch('/api/reserve', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email })
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
                    document.getElementById('reservation-form').reset();
                    submitBtn.textContent = 'Spot Reserved ✓';
                } else {
                    throw new Error(data.error || 'Reservation failed.');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = err.message;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Reserve My Spot';
            }
        });
    </script>
</body>
</html>
HTML_EOF

echo "[+] Restarting server instance..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_spot_reservation" nohup node server.js > server.log 2>&1 &
echo "[+] Layout successfully reverted and server deployed on port 5000."
