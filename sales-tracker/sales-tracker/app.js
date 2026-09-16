let sales = JSON.parse(localStorage.getItem('salesData')) || [];

const salesForm = document.getElementById('salesForm');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const salesTableBody = document.getElementById('salesTableBody');

const totalRevenueEl = document.getElementById('totalRevenue');
const totalWeightEl = document.getElementById('totalWeight');
const weightInKgEl = document.getElementById('weightInKg');
const totalSalesEl = document.getElementById('totalSales');
const clearDataBtn = document.getElementById('clearDataBtn');

document.addEventListener('DOMContentLoaded', () => {
    render();
});

salesForm.addEventListener('submit', (e) => {
    e.preventDefault();

    const newSale = {
        id: Date.now(),
        date: new Date().toLocaleDateString() + ' ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        name: itemNameInput.value.trim(),
        price: parseFloat(unitPriceInput.value),
        quantity: parseInt(quantityInput.value, 10),
        weightGrams: parseFloat(weightGramsInput.value)
    };

    sales.push(newSale);
    saveAndRender();
    salesForm.reset();
    quantityInput.value = '1';
});

salesTableBody.addEventListener('click', (e) => {
    if (e.target.classList.contains('btn-delete')) {
        const id = parseInt(e.target.getAttribute('data-id'), 10);
        sales = sales.filter(sale => sale.id !== id);
        saveAndRender();
    }
});

clearDataBtn.addEventListener('click', () => {
    if (sales.length === 0) return;
    if (confirm('Are you sure you want to clear all recorded sales?')) {
        sales = [];
        saveAndRender();
    }
});

function saveAndRender() {
    localStorage.setItem('salesData', JSON.stringify(sales));
    render();
}

function render() {
    salesTableBody.innerHTML = '';

    let grandTotalRevenue = 0;
    let grandTotalWeight = 0;

    if (sales.length === 0) {
        salesTableBody.innerHTML = `
            <tr>
                <td colspan="8" style="text-align: center; color: #8b949e; padding: 20px;">
                    No sales recorded yet.
                </td>
            </tr>
        `;
    } else {
        sales.forEach((sale) => {
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;

            grandTotalRevenue += rowTotalPrice;
            grandTotalWeight += rowTotalWeight;

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${sale.date}</td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td>$${sale.price.toFixed(2)}</td>
                <td>${sale.quantity}</td>
                <td>${sale.weightGrams.toLocaleString()} g</td>
                <td><strong>${rowTotalWeight.toLocaleString()} g</strong></td>
                <td><strong>$${rowTotalPrice.toFixed(2)}</strong></td>
                <td><button class="btn-delete" data-id="${sale.id}">Delete</button></td>
            `;
            salesTableBody.appendChild(tr);
        });
    }

    totalRevenueEl.textContent = `$${grandTotalRevenue.toFixed(2)}`;
    totalWeightEl.firstChild.textContent = `${grandTotalWeight.toLocaleString()} g `;
    weightInKgEl.textContent = `(${(grandTotalWeight / 1000).toFixed(2)} kg)`;
    totalSalesEl.textContent = sales.length;
}

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
