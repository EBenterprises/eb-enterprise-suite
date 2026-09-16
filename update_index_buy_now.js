const fs = require('fs');
const path = require('path');

let indexHtml = fs.readFileSync(path.join(__dirname, 'public', 'index.html'), 'utf8');

// Replace the reserve button logic with a sleek 'Buy Now' modal checkout workflow
const checkoutModalStyles = `
        /* Modal & Checkout Styles */
        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(5,6,8,0.85); backdrop-filter: blur(8px); display: none; justify-content: center; align-items: center; z-index: 2000; }
        .modal-box { background: var(--surface-panel); border: 1px solid var(--accent-teal); border-radius: 20px; width: 100%; max-width: 440px; padding: 30px; box-shadow: 0 20px 50px rgba(0,0,0,0.9), 0 0 30px var(--accent-teal-glow); }
        .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .modal-title { font-size: 1.2rem; font-weight: 800; color: var(--accent-teal); }
        .close-btn { background: none; border: none; color: var(--text-dim); font-size: 1.2rem; cursor: pointer; }
        .checkout-summary { background: rgba(0,0,0,0.4); border: 1px solid var(--border-subtle); border-radius: 12px; padding: 15px; margin-bottom: 20px; }
        .summary-row { display: flex; justify-content: space-between; font-size: 0.9rem; margin-bottom: 8px; color: var(--text-dim); }
        .summary-row.total { font-weight: 800; color: var(--accent-gold); font-size: 1.1rem; border-top: 1px solid rgba(255,255,255,0.05); padding-top: 8px; margin-top: 8px; }
        .pay-btn { width: 100%; background: linear-gradient(135deg, var(--accent-gold), #d4a017); color: var(--bg-obsidian); border: none; padding: 14px; border-radius: 10px; font-weight: 800; font-size: 1rem; cursor: pointer; box-shadow: 0 0 15px var(--accent-gold-glow); transition: filter 0.2s; }
        .pay-btn:hover { filter: brightness(1.1); }
`;

indexHtml = indexHtml.replace('</style>', checkoutModalStyles + '\n    </style>');

// Inject Modal HTML before closing body
const modalHtml = `
    <div class="modal-overlay" id="checkoutModal">
        <div class="modal-box">
            <div class="modal-header">
                <div class="modal-title" id="modalFarmTitle">⚡ Instant Checkout</div>
                <button class="close-btn" onclick="closeModal()">✕</button>
            </div>
            <div class="checkout-summary">
                <div class="summary-row"><span>Item</span><strong id="modalItemName">Farm-Fresh Eggs (1 doz)</strong></div>
                <div class="summary-row"><span>Unit Price</span><strong id="modalUnitPrice">$0.00</strong></div>
                <div class="summary-row total"><span>Total Due</span><strong id="modalTotal">$0.00</strong></div>
            </div>
            <button class="pay-btn" onclick="executeBuyNow()">🔒 Pay & Lock In Pickup</button>
        </div>
    </div>
`;

indexHtml = indexHtml.replace('</body>', modalHtml + '\n</body>');

// Update JavaScript checkout trigger function
const newScript = `
        let activeCheckoutFarm = null;

        function openBuyNow(farmId, name, price) {
            activeCheckoutFarm = { farmId, name, price };
            document.getElementById('modalFarmTitle').innerText = \`⚡ Buy Now: \${name}\`;
            document.getElementById('modalItemName').innerText = \`\${name} (1 Dozen)\`;
            document.getElementById('modalUnitPrice').innerText = \`$\${price.toFixed(2)}\`;
            document.getElementById('modalTotal').innerText = \`$\${price.toFixed(2)}\`;
            document.getElementById('checkoutModal').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('checkoutModal').style.display = 'none';
            activeCheckoutFarm = null;
        }

        async function executeBuyNow() {
            if (!activeCheckoutFarm) return;
            try {
                const res = await fetch('/api/checkout', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ farmId: activeCheckoutFarm.farmId, qty: 1, paymentMethod: 'mesh_instant' })
                });
                const data = await res.json();
                closeModal();
                if (data.success) {
                    showToast(\`🎉 Purchased! Receipt #\${data.receiptId} | Remaining: \${data.remainingStock} doz\`);
                    loadFarms();
                } else {
                    alert(data.error || 'Checkout failed.');
                }
            } catch (err) {
                alert('Network error connecting to payment gateway.');
            }
        }
`;

indexHtml = indexHtml.replace('async function reserveEggs(farmId, farmName) {', newScript + '\nasync function reserveEggs(farmId, farmName) {');

// Replace button text in card render template
indexHtml = indexHtml.replace(
    'onclick="reserveEggs(${f.id}, \x27${f.name}\x27)"',
    'onclick="openBuyNow(${f.id}, \x27${f.name}\x27, ${f.price})"'
);
indexHtml = indexHtml.replace('⚡ Reserve 1 Dozen for Pickup', '⚡ Buy Now ($' + '${f.price.toFixed(2)})');

fs.writeFileSync(path.join(__dirname, 'public', 'index.html'), indexHtml);
console.log("[CLIENT PATCH] 'Buy Now' modal checkout workflow successfully integrated into consumer radar.");
