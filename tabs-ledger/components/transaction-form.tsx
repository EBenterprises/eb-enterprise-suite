"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

type Customer = {
  id: string;
  name: string;
};

export function TransactionForm({
  customers,
}: {
  customers: Customer[];
}) {
  const router = useRouter();

  const [customerId, setCustomerId] = useState(customers[0]?.id ?? "");
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [item, setItem] = useState("");
  const [quantity, setQuantity] = useState("");
  const [amount, setAmount] = useState("");
  const [location, setLocation] = useState("");
  const [note, setNote] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();

    if (!customerId) {
      setError("Select a customer.");
      return;
    }

    if (!amount || Number(amount) <= 0) {
      setError("Enter a valid amount.");
      return;
    }

    setSaving(true);
    setError("");

    try {
      const occurredAt =
        date && time ? `${date}T${time}` : undefined;

      const response = await fetch("/api/transactions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          customer_id: customerId,
          occurred_at: occurredAt,
          item,
          quantity: quantity === "" ? null : Number(quantity),
          amount: Number(amount),
          location,
          note,
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(
          result.error || "Unable to create transaction."
        );
      }

      router.push(`/customers/${customerId}`);
      router.refresh();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Unable to create transaction."
      );
      setSaving(false);
    }
  }

  return (
    <form className="card form-card" onSubmit={submit}>
      {customers.length === 0 ? (
        <div className="error">
          No customers exist yet. Create a customer first.
        </div>
      ) : (
        <>
          <label>
            Customer
            <select
              value={customerId}
              onChange={(event) => setCustomerId(event.target.value)}
              required
            >
              {customers.map((customer) => (
                <option key={customer.id} value={customer.id}>
                  {customer.name}
                </option>
              ))}
            </select>
          </label>

          <div className="form-grid">
            <label>
              Date
              <input
                type="date"
                value={date}
                onChange={(event) => setDate(event.target.value)}
              />
            </label>

            <label>
              Time
              <input
                type="time"
                value={time}
                onChange={(event) => setTime(event.target.value)}
              />
            </label>
          </div>

          <label>
            Item
            <input
              value={item}
              onChange={(event) => setItem(event.target.value)}
              placeholder="Item / service"
            />
          </label>

          <div className="form-grid">
            <label>
              Quantity
              <input
                type="number"
                min="0"
                step="any"
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
              />
            </label>

            <label>
              Amount (CAD)
              <input
                required
                type="number"
                min="0.01"
                step="0.01"
                value={amount}
                onChange={(event) => setAmount(event.target.value)}
              />
            </label>
          </div>

          <label>
            Location
            <input
              value={location}
              onChange={(event) => setLocation(event.target.value)}
            />
          </label>

          <label>
            Note
            <textarea
              rows={4}
              value={note}
              onChange={(event) => setNote(event.target.value)}
            />
          </label>

          {error && <div className="error">{error}</div>}

          <button
            className="button primary"
            disabled={saving}
            type="submit"
          >
            {saving ? "Recording…" : "Record transaction"}
          </button>
        </>
      )}
    </form>
  );
}
