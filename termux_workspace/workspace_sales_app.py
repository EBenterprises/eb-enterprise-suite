#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Sales Tracker & Ledger Application with Weight Tracking
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
SALES_LEDGER = os.path.join(WORKSPACE_DIR, "sales_ledger.json")

def load_ledger():
    if os.path.exists(SALES_LEDGER):
        try:
            with open(SALES_LEDGER, "r") as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_ledger(ledger):
    with open(SALES_LEDGER, "w") as f:
        json.dump(ledger, f, indent=2)

def add_sale(item, quantity, unit_price, weight_grams=0.0, category="General"):
    ledger = load_ledger()
    total_price = quantity * unit_price
    total_weight = quantity * weight_grams
    timestamp = datetime.datetime.now().isoformat()
    
    sale_entry = {
        "id": len(ledger) + 1,
        "timestamp": timestamp,
        "item": item,
        "category": category,
        "quantity": quantity,
        "unit_price": unit_price,
        "total_price": total_price,
        "weight_grams": weight_grams,
        "total_weight_grams": total_weight
    }
    
    ledger.append(sale_entry)
    save_ledger(ledger)
    print(f"[+] Sale recorded: {quantity}x {item} ({weight_grams}g ea) @ ${unit_price:.2f} = ${total_price:.2f} [Total Weight: {total_weight}g]")

def view_ledger():
    ledger = load_ledger()
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - SALES LEDGER & WEIGHT REPORT")
    print("=============================================================")
    if not ledger:
        print("No sales recorded yet.")
        return

    grand_total = 0.0
    grand_weight = 0.0
    for s in ledger:
        w_str = f" | {s.get('total_weight_grams', 0.0)}g" if s.get('weight_grams', 0.0) > 0 else ""
        print(f"[{s['id']}] {s['timestamp'][:10]} | {s['category']} | {s['quantity']}x {s['item']} @ ${s['unit_price']:.2f} = ${s['total_price']:.2f}{w_str}")
        grand_total += s['total_price']
        grand_weight += s.get('total_weight_grams', 0.0)
    print("-------------------------------------------------------------")
    print(f"Total Revenue: ${grand_total:.2f} | Total Mass: {grand_weight}g")
    print("=============================================================")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 workspace_sales_app.py add <item> <quantity> <unit_price> [weight_grams] [category]")
        print("  python3 workspace_sales_app.py report")
        return

    command = sys.argv[1].lower()
    if command == "add":
        if len(sys.argv) < 5:
            print("Error: Missing arguments for 'add'. Use: add <item> <quantity> <unit_price> [weight_grams] [category]")
            return
        item = sys.argv[2]
        try:
            quantity = float(sys.argv[3])
            unit_price = float(sys.argv[4])
        except ValueError:
            print("Error: Quantity and unit price must be numbers.")
            return
        
        weight_grams = 0.0
        category = "General"
        
        if len(sys.argv) > 5:
            try:
                weight_grams = float(sys.argv[5])
                if len(sys.argv) > 6:
                    category = sys.argv[6]
            except ValueError:
                # If the 5th argument is not a float, treat it as category
                category = sys.argv[5]

        add_sale(item, quantity, unit_price, weight_grams, category)
    elif command == "report":
        view_ledger()
    else:
        print(f"Unknown command: {command}")

if __name__ == "__main__":
    main()
