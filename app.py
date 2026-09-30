from datetime import datetime
from flask import Flask, jsonify, redirect, render_template, request, url_for

app = Flask(__name__)

# In-memory database with initial sample data and timestamps
transactions = [
    {
        "id": 1,
        "title": "Initial Affiliate Payout",
        "amount": 150.0,
        "type": "income",
        "timestamp": "2026-09-01T10:00",
    },
    {
        "id": 2,
        "title": "Hosting & Domain Renewal",
        "amount": 25.5,
        "type": "expense",
        "timestamp": "2026-09-15T14:30",
    },
]


@app.route("/")
def index():
    total_income = sum(
        t["amount"] for t in transactions if t["type"] == "income"
    )
    total_expense = sum(
        t["amount"] for t in transactions if t["type"] == "expense"
    )
    net_balance = total_income - total_expense
    return render_template(
        "index.html",
        transactions=transactions,
        total_income=total_income,
        total_expense=total_expense,
        net_balance=net_balance,
    )


@app.route("/add", methods=["POST"])
def add_transaction():
    title = request.form.get("title")
    amount = float(request.form.get("amount", 0))
    t_type = request.form.get("type")
    custom_timestamp = request.form.get("timestamp")

    if not custom_timestamp:
        custom_timestamp = datetime.now().strftime("%Y-%m-%dT%H:%M")

    new_id = max([t["id"] for t in transactions], default=0) + 1
    transactions.append(
        {
            "id": new_id,
            "title": title,
            "amount": amount,
            "type": t_type,
            "timestamp": custom_timestamp,
        }
    )
    return redirect(url_for("index"))


@app.route("/edit/<int:transaction_id>", methods=["POST"])
def edit_transaction(transaction_id):
    for t in transactions:
        if t["id"] == transaction_id:
            t["title"] = request.form.get("title", t["title"])
            t["amount"] = float(request.form.get("amount", t["amount"]))
            t["type"] = request.form.get("type", t["type"])
            new_ts = request.form.get("timestamp")
            if new_ts:
                t["timestamp"] = new_ts
            break
    return redirect(url_for("index"))


@app.route("/delete/<int:transaction_id>", methods=["POST"])
def delete_transaction(transaction_id):
    global transactions
    transactions = [t for t in transactions if t["id"] != transaction_id]
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
