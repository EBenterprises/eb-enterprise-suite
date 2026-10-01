document.addEventListener('DOMContentLoaded', async () => {
  await loadVersionInfo();
  loadTransactionHistory();
});

async function loadVersionInfo() {
  try {
    const res = await fetch('/api/version');
    const data = await res.json();
    document.getElementById('version-badge').textContent = `${data.version.toUpperCase()} (Port: ${data.port})`;
  } catch (e) {
    console.error('Could not load version metadata');
  }
}

async function loadTransactionHistory() {
  const response = await fetch('/api/transactions');
  const transactions = await response.json();
  const listContainer = document.getElementById('transaction-list');
  
  if (transactions.length === 0) {
    listContainer.innerHTML = '<p>No transactions found.</p>';
    return;
  }

  listContainer.innerHTML = transactions.map(tx => `
    <div class="transaction-item" data-id="${tx.id}">
      <div class="tx-info">
        <strong>${tx.customer || 'Guest'}</strong> - $${tx.amount} <br>
        <small>Timestamp: ${new Date(tx.timestamp).toLocaleString()}</small>
      </div>
      <button onclick="toggleEditModal('${tx.id}')">Edit / Time Travel</button>

      <div id="edit-modal-${tx.id}" class="edit-popup-menu" style="display: none;">
        <h4>Edit Transaction & Time Travel</h4>
        <label>Timestamp:</label><br>
        <input type="datetime-local" id="edit-time-${tx.id}" value="${formatForDateTimeLocal(tx.timestamp)}"><br>
        
        <label>Customer:</label><br>
        <input type="text" id="edit-customer-${tx.id}" value="${tx.customer || ''}"><br>
        
        <label>Amount:</label><br>
        <input type="number" id="edit-amount-${tx.id}" value="${tx.amount}"><br>
        
        <button onclick="submitTransactionEdit('${tx.id}')">Save Changes</button>
        <button onclick="toggleEditModal('${tx.id}')" style="background:#555;">Cancel</button>
      </div>
    </div>
  `).join('');
}

function formatForDateTimeLocal(isoString) {
  const date = new Date(isoString);
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function toggleEditModal(id) {
  const modal = document.getElementById(`edit-modal-${id}`);
  if (modal) {
    modal.style.display = modal.style.display === 'none' ? 'block' : 'none';
  }
}

async function submitTransactionEdit(id) {
  const customTimestamp = document.getElementById(`edit-time-${id}`).value;
  const customer = document.getElementById(`edit-customer-${id}`).value;
  const amount = parseFloat(document.getElementById(`edit-amount-${id}`).value);

  const response = await fetch(`/api/transactions/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      timestamp: customTimestamp ? new Date(customTimestamp).toISOString() : undefined,
      customer, 
      amount 
    })
  });

  if (response.ok) {
    loadTransactionHistory();
  } else {
    alert('Failed to update transaction record.');
  }
}
