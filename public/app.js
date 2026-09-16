document.addEventListener('DOMContentLoaded', () => {
    console.log("EB Userbase Platform Initialized.");
    loadFeed();

    const form = document.getElementById('user-form');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value.trim();
            const userTier = document.getElementById('userTier').value;

            if (!email || !password || !userTier) {
                showToast('Please complete all form fields.', false);
                return;
            }

            try {
                const response = await fetch('/api/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password, userTier })
                });
                const data = await response.json();

                if (response.ok) {
                    showToast('Success: ' + data.message, true);
                    form.reset();
                    renderFeed(data.users);
                } else {
                    throw new Error(data.error || 'Registration failed.');
                }
            } catch (err) {
                showToast('Error: ' + err.message, false);
            }
        });
    }
});

async function loadFeed() {
    try {
        const res = await fetch('/api/users');
        const users = await res.json();
        renderFeed(users);
    } catch (err) {
        console.error("Failed to load userbase feed:", err);
    }
}

function renderFeed(users) {
    const feedList = document.getElementById('feed-list');
    const userCount = document.getElementById('user-count');
    if (!feedList) return;

    feedList.innerHTML = '';
    if (userCount) {
        userCount.textContent = (users ? users.length : 0) + ' Registered';
    }

    if (!users || users.length === 0) {
        feedList.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 1.5rem;">No user profiles registered yet.</div>';
        return;
    }

    users.forEach(user => {
        const item = document.createElement('div');
        item.className = 'feed-item';
        
        const dateStr = user.createdAt ? new Date(user.createdAt).toLocaleDateString() : 'Just now';

        item.innerHTML = `
            <div>
                <div class="feed-user">${escapeHtml(user.email)}</div>
                <div class="feed-meta">Tier: ${escapeHtml(user.userTier)}</div>
            </div>
            <div class="feed-meta">${dateStr}</div>
        `;
        feedList.appendChild(item);
    });
}

function showToast(message, isSuccess) {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.style.display = 'block';
    toast.style.background = isSuccess ? 'rgba(34, 197, 94, 0.15)' : 'rgba(239, 68, 68, 0.15)';
    toast.style.color = isSuccess ? 'var(--success)' : 'var(--danger)';
    toast.style.border = isSuccess ? '1px solid var(--success)' : '1px solid var(--danger)';
    toast.textContent = message;

    setTimeout(() => {
        toast.style.display = 'none';
    }, 4000);
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
