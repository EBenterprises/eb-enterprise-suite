async function fetchNodes() {
    try {
        const res = await fetch('/api/nodes');
        const nodes = await res.json();
        const list = document.getElementById('node-list');
        list.innerHTML = nodes.map(n => `<li>${n.node_id} [${n.latency}]</li>`).join('');
    } catch (err) {
        console.error("Node synchronization failed", err);
    }
}

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        const log = document.getElementById('message-log');
        log.innerHTML = messages.map(m => {
            const decoded = atob(m.payload);
            const timeLeft = Math.max(0, Math.floor(m.expires_at - Date.now() / 1000));
            return `
                <div class="message-item">
                    <div class="message-meta">TO: ${m.recipient} | ID: ${m.id} | DESTruct: ${timeLeft}s</div>
                    <div>${decoded}</div>
                </div>
            `;
        }).join('');
    } catch (err) {
        console.error("Message sync error", err);
    }
}

document.getElementById('transmit-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('recipient-input').value || 'BROADCAST';
    const payload = document.getElementById('payload-input').value;
    const burn_timer = parseInt(document.getElementById('burn-timer').value);

    if (!payload.trim()) return;

    await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload, burn_timer })
    });

    document.getElementById('payload-input').value = '';
    fetchMessages();
});

setInterval(() => {
    fetchMessages();
    fetchNodes();
}, 2000);

fetchNodes();
fetchMessages();
