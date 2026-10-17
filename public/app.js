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

// --- INJECTED UPDATE: Dynamic Item Rows & Total Calculation ---
const itemsContainer = document.getElementById('items-container');
const addItemBtn = document.getElementById('add-item-btn');
const calculatedTotal = document.getElementById('calculated-total');

function calculateTotal() {
    let total = 0;
    document.querySelectorAll('.item-row').forEach(row => {
        const qty = parseFloat(row.querySelector('.item-qty').value) || 0;
        const price = parseFloat(row.querySelector('.item-price').value) || 0;
        total += qty * price;
    });
    if (calculatedTotal) calculatedTotal.textContent = `$${total.toFixed(2)}`;
    return total;
}

if (addItemBtn) {
    addItemBtn.addEventListener('click', () => {
        const row = document.createElement('div');
        row.className = 'item-row';
        row.innerHTML = `
            <input type="text" placeholder="Item Name" class="item-name" required>
            <input type="number" placeholder="Qty" class="item-qty" value="1" min="1" required>
            <input type="number" placeholder="Price ($)" class="item-price" step="0.01" required>
            <button type="button" class="remove-item-btn">×</button>
        `;
        itemsContainer.appendChild(row);
        attachRowListeners(row);
    });
}

function attachRowListeners(row) {
    const removeBtn = row.querySelector('.remove-item-btn');
    if (removeBtn) {
        removeBtn.addEventListener('click', () => {
            if (document.querySelectorAll('.item-row').length > 1) {
                row.remove();
                calculateTotal();
            } else {
                alert('You must have at least one item.');
            }
        });
    }
    row.querySelectorAll('input').forEach(input => {
        input.addEventListener('input', calculateTotal);
    });
}

document.querySelectorAll('.item-row').forEach(attachRowListeners);
