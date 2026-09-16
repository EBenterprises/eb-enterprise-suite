// Enhanced payment modal script supporting digital wallets and card brands
const enhancedCheckoutModal = `
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
                <button onclick="simulateWalletPayment('Apple Pay')" style="background: #000; color: #fff; border: 1px solid rgba(255,255,255,0.2); padding: 12px; border-radius: 10px; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px;">
                     Apple Pay
                </button>
                <button onclick="simulateWalletPayment('Google Pay')" style="background: #111; color: #fff; border: 1px solid rgba(255,255,255,0.2); padding: 12px; border-radius: 10px; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px;">
                    ⚡ Google Pay
                </button>
            </div>

            <div style="text-align: center; color: var(--text-dim); font-size: 0.75rem; margin-bottom: 15px; text-transform: uppercase; letter-spacing: 1px;">
                — Or Pay with Card / Interac Debit —
            </div>

            <!-- Standard Card / Interac Form -->
            <div style="display: flex; flex-direction: column; gap: 12px; margin-bottom: 20px;">
                <div>
                    <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Cardholder Name</label>
                    <input type="text" id="cardName" placeholder="Easton Bodeux" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem;">
                </div>
                <div>
                    <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Card Number (Visa, MC, Amex, Interac Debit, Gift)</label>
                    <input type="text" id="cardNumber" placeholder="4532 •••• •••• 9982" maxlength="19" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace;">
                </div>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                    <div>
                        <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">Expiry</label>
                        <input type="text" id="cardExpiry" placeholder="MM/YY" maxlength="5" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace;">
                    </div>
                    <div>
                        <label style="font-size: 0.75rem; color: var(--text-dim); margin-bottom: 4px; display: block;">CVV / PIN</label>
                        <input type="password" id="cardCvv" placeholder="•••" maxlength="4" style="width: 100%; background: var(--bg-obsidian); border: 1px solid var(--border-subtle); color: var(--text-main); padding: 10px; border-radius: 8px; font-size: 0.85rem; font-family: monospace;">
                    </div>
                </div>
            </div>

            <button class="pay-btn" onclick="executeCardPayment()">🔒 Authorize & Lock In Pickup</button>
        </div>
    </div>
`;
