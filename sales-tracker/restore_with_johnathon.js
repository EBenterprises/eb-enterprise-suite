const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, 'transactions.json');

const exactTransactions = [
  {
    "id": 1790840000000,
    "timestamp": 1790840000000,
    "date": "2026-09-30 12:30",
    "customer": "Johnathon",
    "landmark": "Westbank Centre",
    "gps": "49.8880, -119.4960",
    "item": "3.5g Unit",
    "amount": 45,
    "cashCollected": 45,
    "balance": 0,
    "status": "Paid"
  },
  {
    "id": 1790764914368,
    "timestamp": 1790764914368,
    "date": "2026-09-30 10:41",
    "customer": "Chris Bell",
    "landmark": "Kennys House (front door)",
    "gps": "49.8440, -119.6176",
    "item": "1.75g Unit",
    "amount": 40,
    "cashCollected": 0,
    "balance": 40,
    "status": "Balance"
  },
  {
    "id": 1790764752773,
    "timestamp": 1790764752773,
    "date": "2026-09-30 10:39",
    "customer": "Chris Bell",
    "landmark": "Kenny's House",
    "gps": "49.8440, -119.6176",
    "item": "1.75g Unit",
    "amount": 40,
    "cashCollected": 0,
    "balance": 80,
    "status": "Balance"
  },
  {
    "id": 1790782860000,
    "timestamp": 1790782860000,
    "date": "2026-09-30 08:41",
    "customer": "Dan",
    "landmark": "Johnson Bentley skate park camp",
    "gps": "49.8250, -119.6233",
    "item": "3.5g Unit",
    "amount": 55,
    "cashCollected": 50,
    "balance": 5,
    "status": "Balance"
  },
  {
    "id": 1790670600000,
    "timestamp": 1790670600000,
    "date": "2026-09-29 01:30",
    "customer": "Lane",
    "landmark": "Bayview Entrance",
    "gps": "49.8437, -119.6171",
    "item": "28g Unit",
    "amount": 300,
    "cashCollected": 0,
    "balance": 300,
    "status": "Balance"
  }
];

fs.writeFileSync(DATA_FILE, JSON.stringify(exactTransactions, null, 2));
console.log("[+] Successfully updated transactions with Johnathon, Chris Bell, Dan, and Lane!");
