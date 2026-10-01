const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 51205;
const DATA_FILE = path.join(__dirname, 'transactions.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function readTransactionsFromFile() {
  if (!fs.existsSync(DATA_FILE)) {
    return [];
  }
  try {
    const data = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    return [];
  }
}

function writeTransactionsToFile(transactions) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
}

app.put('/api/transactions/:id', (req, res) => {
  const { id } = req.params;
  const { timestamp, customer, amount } = req.body;
  
  let transactions = readTransactionsFromFile();
  const index = transactions.findIndex(tx => tx.id === id);
  
  if (index === -1) {
    return res.status(404).json({ error: 'Transaction not found' });
  }

  if (timestamp) {
    transactions[index].timestamp = timestamp;
  }
  if (customer !== undefined) {
    transactions[index].customer = customer;
  }
  if (amount !== undefined) {
    transactions[index].amount = amount;
  }

  writeTransactionsToFile(transactions);
  res.json({ success: true, transaction: transactions[index] });
});

app.get('/api/transactions', (req, res) => {
  const transactions = readTransactionsFromFile();
  transactions.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  res.json(transactions);
});

app.listen(PORT, () => {
  console.log(`Sales-Tracker v5 running on http://127.0.0.1:${PORT}`);
});
