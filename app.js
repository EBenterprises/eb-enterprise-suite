document.addEventListener('DOMContentLoaded', () => {
    console.log("EB Userbase Application Initialized.");
    fetchFeed();

    const form = document.getElementById('user-form');
    const toast = document.getElementById('toast');

    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const userTier = document.getElementById('userTier').value;

            try {
                const response = await fetch('/api/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password, userTier })
                });
                const data = await response.json();

                toast.style.display = 'block';
                if (response.ok) {
                    toast.style.background = 'rgba(34, 197, 94, 0.15)';
                    toast.style.color = 'var(--success)';
                    toast.style.border = '1px solid var(--success)';
                    toast.textContent = 'Success: Profile registered to userbase.';
                    form.reset();
                    fetchFeed();
                } else {
                    throw new Error(data.error || 'Registration failed');
                }
            } catch (err) {
                toast.style.display = 'block';
                toast.style.background = 'rgba(239, 68, 68, 0.15)';
                toast.style.color = 'var(--danger)';
                toast.style.border = '1px solid var(--danger)';
                toast.textContent = 'Error: ' + err.message;
            }
        });
    }
});

async function fetchFeed() {
    try {
        const res = await fetch('/api/users');
        const users = await res.json();
        const feedList = document.getElementById('feed-list');
        if (!feedList) return;

        feedList.innerHTML = '';
        if (users.length === 0) {
            feedList.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 1rem;">No user entries found in feed.</div>';
            return;
        }

        users.forEach(user => {
            const item = document.createElement('div');
            item.className = 'feed-item';
            item.innerHTML = `
                <div>
                    <div class="feed-user">${escapeHtml(user.email)}</div>
                    <div class="feed-meta">Tier: ${escapeHtml(user.userTier)}</div>
                </div>
                <div class="feed-meta">${new Date(user.createdAt).toLocaleDateString()}</div>
            `;
            feedList.appendChild(item);
        });
    } catch (err) {
        console.error("Failed to fetch userbase feed:", err);
    }
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
