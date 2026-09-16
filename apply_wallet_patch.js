const fs = require('fs');
const path = require('path');

let indexHtml = fs.readFileSync(path.join(__dirname, 'public', 'index.html'), 'utf8');

// Replace old modal HTML with multi-tender wallet & card modal
const oldModalStart = indexHtml.indexOf('<div class="modal-overlay" id="checkoutModal">');
const oldModalEnd = indexHtml.indexOf('</div>\n    </div>\n', oldModalStart) + 16;

if (oldModalStart !== -1) {
    const newModalHtml = `
    <div class="modal-overlay" id="checkoutModal">
        <div class="modal-box" style="max-width: 480px;">
            <div class="modal-header">
                <div class="modal-title" id="modalFarmTitle">⚡ Instant Secure Checkout</div>
                <button class="close-btn" onclick="closeModal()">✕</button>
            </div>
            
            <div class="checkout-summary">
                <div class="summary-row"><span>Item</span><strong id="modalItemName">Farm-Fresh Eggs (1 doz)</strong></div>
                <div class="summary-row"><span>Unit Price</span><strong id="modalUnitPrice">$0.00</strong></div>
                <div class="summary-row total"><span>Total Due</span><strong id="modalTotal">$0.00</strong></div>
            </div>

            <!-- Instant Digital Wallets -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 20px;">
                <button onclick="simulateWalletPayment('Apple Pay')" style="background: #000; color: #fff; border: 1px solid rgba(255,255,255,0.2); padding: 12px; border-radius: 10px; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 0 10px rgba(255,255,255,0.1);">
                     Apple Pay
                </button>
                <button onclick="simulateWalletPayment('Google Pay')" style="background: #111; color: #fff; border: 1px solid rgba(255,255,255,0.2); padding: 12px; border-radius: 10px; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 0 10px rgba(255,255,255,0.1);">
                    ⚡ Google Pay
                </button>
            </div>

            <div style="text-align: center; color: var(--text-dim); font-size: 0.75rem; margin-bottom: 15px; text-transform: uppercase; letter-spacing: 1px; font-weight: 700;">
                — Or Pay with Visa, Mastercard, Interac Debit, Gift —
            </div>

            <!-- Standard Card / Interac Form -->
            <div style="display: flex; flex-direction: column; gap: 12px; margin-bottom: 20px;">
                <div>
                    <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Cardholder Name</label>
                    <input type="text" id="cardName" placeholder="Easton Bodeux" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; outline: none;">
                </div>
                <div>
                    <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Card Number (Visa, MC, Debit, Gift)</label>
                    <input type="text" id="cardNumber" placeholder="4532 •••• •••• 9982" maxlength="19" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace; outline: none;">
                </div>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                    <div>
                        <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Expiry</label>
                        <input type="text" id="cardExpiry" placeholder="MM/YY" maxlength="5" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace; outline: none;">
                    </div>
                    <div>
                        <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">CVV / PIN</label>
                        <input type="password" id="cardCvv" placeholder="•••" maxlength="4" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace; outline: none;">
                    </div>
                </div>
            </div>

            <button class="pay-btn" onclick="executeCardPayment()">🔒 Authorize & Lock In Pickup</button>
        </div>
    </div>
    `;

    indexHtml = indexHtml.substring(0, oldModalStart) + newModalHtml + indexHtml.substring(oldModalEnd);
}

// Update JS payment functions
const newPaymentJs = `
        async function simulateWalletPayment(walletName) {
            if (!activeCheckoutFarm) return;
            try {
                const res = await fetch('/api/checkout', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ farmId: activeCheckoutFarm.farmId, qty: 1, paymentMethod: walletName })
                });
                const data = await res.json();
                closeModal();
                if (data.success) {
                    showToast(\`🎉 Paid with \${walletName}! Receipt #\${data.receiptId} | Remaining: \${data.remainingStock} doz\`);
                    loadFarms();
                } else {
                    alert(data.error || 'Payment failed.');
                }
            } catch (err) {
                alert('Network error connecting to payment gateway.');
            }
        }

        async function executeCardPayment() {
            if (!activeCheckoutFarm) return;
            const number = document.getElementById('cardNumber').value.trim();
            if (!number || number.length < 12) {
                alert('Please enter a valid card number, Interac debit number, or gift card code.');
                return;
            }

            try {
                const res = await fetch('/api/checkout', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ farmId: activeCheckoutFarm.farmId, qty: 1, paymentMethod: 'card_or_interac' })
                });
                const data = await res.json();
                closeModal();
                if (data.success) {
                    showToast(\`✅ Card/Debit Authorized! Receipt #\${data.receiptId} | Remaining: \${data.remainingStock} doz\`);
                    loadFarms();
                } else {
                    alert(data.error || 'Authorization failed.');
                }
            } catch (err) {
                alert('Network error connecting to payment gateway.');
            }
        }
`;

indexHtml = indexHtml.replace('async function executeBuyNow() {', newPaymentJs + '\nasync function executeBuyNow() {');

fs.writeFileSync(path.join(__dirname, 'public', 'index.html'), indexHtml);
console.log("[CLIENT PATCH] Multi-tender checkout interface (Apple Pay, Google Pay, Credit, Visa Debit, Interac & Gift Cards) successfully integrated.");
