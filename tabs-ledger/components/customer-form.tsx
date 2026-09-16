"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export function CustomerForm() {
  const router = useRouter();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError("");

    try {
      const response = await fetch("/api/customers", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name,
          email,
          phone,
          notes,
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || "Unable to create customer.");
      }

      router.push(`/customers/${result.customer.id}`);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to create customer.");
      setSaving(false);
    }
  }

  return (
    <form className="card form-card" onSubmit={submit}>
      <h2>New customer</h2>

      <label>
        Name
        <input
          required
          value={name}
          onChange={(event) => setName(event.target.value)}
          autoComplete="name"
        />
      </label>

      <label>
        Email
        <input
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          autoComplete="email"
        />
      </label>

      <label>
        Phone
        <input
          value={phone}
          onChange={(event) => setPhone(event.target.value)}
          autoComplete="tel"
        />
      </label>

      <label>
        Notes
        <textarea
          rows={4}
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
        />
      </label>

      {error && <div className="error">{error}</div>}

      <button className="button primary" disabled={saving} type="submit">
        {saving ? "Saving…" : "Create customer"}
      </button>
    </form>
  );
}
