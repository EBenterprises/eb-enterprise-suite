async function fetchNodes() {
    try {
        const res = await fetch('/api/nodes');
        const nodes = await res.json();
        const list = document.getElementById('node-list');
        list.innerHTML = nodes.map(n => `<li>${n.node_id || n.peer_id} [${n.latency || n.ping}]<br><small>${n.fingerprint || ''}</small></li>`).join('');
    } catch (err) {
        console.error("Node sync error", err);
    }
}

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        const log = document.getElementById('message-log');
        log.innerHTML = messages.map(m => {
            const timeLeft = Math.max(0, Math.floor(m.expires_at - Date.now() / 1000));
            let displayVal = m.payload;
            if (m.payload && m.payload.includes('#payload:')) {
                const parts = m.payload.split('#payload:');
                try { displayVal = `[STEGANO CLOAKED] -> ${atob(parts[1])}`; } catch(e) {}
            }
            return `
                <div class="message-item">
                    <div class="message-meta">TO: ${m.recipient} | ID: ${m.id} | DESTruct: ${timeLeft}s</div>
                    <div>${displayVal}</div>
                </div>
            `;
        }).join('');
    } catch (err) {
        console.error("Message sync error", err);
    }
}

async function fetchDeadDrops() {
    try {
        const res = await fetch('/api/deaddrop/list');
        const drops = await res.json();
        const log = document.getElementById('drop-log');
        log.innerHTML = drops.map(d => `<div>DROP: ${d.drop_id} (${d.recipient})</div>`).join('');
    } catch (err) {
        console.error("Dead drop sync error", err);
    }
}

async function fetchZKList() {
    try {
        const res = await fetch('/api/zk/list');
        const zkDrops = await res.json();
        const log = document.getElementById('zk-log');
        log.innerHTML = zkDrops.map(d => `<div>ZK: ${d.drop_id} [Locked: ${d.locked}]</div>`).join('');
    } catch (err) {
        console.error("ZK sync error", err);
    }
}

async function fetchCRIEStatus() {
    try {
        const res = await fetch('/api/crie/status');
        const status = await res.json();
        document.getElementById('crie-status').innerText = `CRIE: ${status.crie_status} (${status.self_healing})`;
    } catch (err) {
        console.error("CRIE sync error", err);
    }
}

document.getElementById('transmit-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('recipient-input').value || 'BROADCAST';
    const payload = document.getElementById('payload-input').value;
    const steg_mode = document.getElementById('steg-mode').value;
    const burn_timer = parseInt(document.getElementById('burn-timer').value);

    if (!payload.trim()) return;

    await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload, steg_mode, burn_timer })
    });

    document.getElementById('payload-input').value = '';
    fetchMessages();
});

document.getElementById('rotate-circuit-btn').addEventListener('click', async () => {
    await fetch('/api/circuit/rotate', { method: 'POST' });
    fetchNodes();
});

document.getElementById('drop-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('drop-recipient').value || 'SECURE_DROP';
    const payload = document.getElementById('drop-payload').value;

    if (!payload.trim()) return;

    await fetch('/api/deaddrop/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload })
    });

    document.getElementById('drop-payload').value = '';
    fetchDeadDrops();
});

document.getElementById('zk-arm-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('zk-recipient').value || 'SECURE_ZK';
    const passphrase = document.getElementById('zk-pass').value;
    const ciphertext = document.getElementById('zk-payload').value;

    if (!ciphertext.trim()) return;

    await fetch('/api/zk/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, passphrase, ciphertext })
    });

    document.getElementById('zk-payload').value = '';
    document.getElementById('zk-pass').value = '';
    fetchZKList();
});

setInterval(() => {
    fetchMessages();
    fetchNodes();
    fetchDeadDrops();
    fetchZKList();
    fetchCRIEStatus();
}, 2000);

fetchNodes();
fetchMessages();
fetchDeadDrops();
fetchZKList();
fetchCRIEStatus();
