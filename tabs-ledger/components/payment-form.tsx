"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

type Customer = {
  id: string;
  name: string;
};

export function PaymentForm({
  customers,
}: {
  customers: Customer[];
}) {
  const router = useRouter();

  const [customerId, setCustomerId] = useState(customers[0]?.id ?? "");
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [amount, setAmount] = useState("");
  const [location, setLocation] = useState("");
  const [note, setNote] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [result, setResult] = useState<{
    allocated_cents: number;
    unapplied_cents: number;
  } | null>(null);

  async function submit(event: FormEvent) {
    event.preventDefault();

    if (!customerId) {
      setError("Select a customer.");
      return;
    }

    if (!amount || Number(amount) <= 0) {
      setError("Enter a valid payment amount.");
      return;
    }

    setSaving(true);
    setError("");
    setResult(null);

    try {
      const occurredAt =
        date && time ? `${date}T${time}` : undefined;

      const response = await fetch("/api/payments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          customer_id: customerId,
          amount: Number(amount),
          occurred_at: occurredAt,
          location,
          note,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Unable to record payment.");
      }

      const allocated = data.allocations.reduce(
        (sum: number, row: { amount_cents: number }) =>
          sum + row.amount_cents,
        0
      );

      setResult({
        allocated_cents: allocated,
        unapplied_cents: data.unapplied_cents,
      });

      setAmount("");
      setNote("");

      router.refresh();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Unable to record payment."
      );
    } finally {
      setSaving(false);
    }
  }

  const money = (cents: number) =>
    new Intl.NumberFormat("en-CA", {
      style: "currency",
      currency: "CAD",
    }).format(cents / 100);

  return (
    <form className="card form-card" onSubmit={submit}>
      {customers.length === 0 ? (
        <div className="error">
          Create a customer before recording a payment.
        </div>
      ) : (
        <>
          <label>
            Customer
            <select
              required
              value={customerId}
              onChange={(event) => setCustomerId(event.target.value)}
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
            Payment amount (CAD)
            <input
              required
              type="number"
              min="0.01"
              step="0.01"
              value={amount}
              onChange={(event) => setAmount(event.target.value)}
            />
          </label>

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

          {result && (
            <div className="success-box">
              <strong>Payment recorded.</strong>
              <div>Allocated: {money(result.allocated_cents)}</div>
              <div>Unapplied: {money(result.unapplied_cents)}</div>
            </div>
          )}

          <button
            className="button primary"
            disabled={saving}
            type="submit"
          >
            {saving ? "Recording…" : "Record payment"}
          </button>
        </>
      )}
    </form>
  );
}
