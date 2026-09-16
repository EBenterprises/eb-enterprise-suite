"use client";

import { useState } from "react";
import Brand from "../../../components/Brand";
import Navigation from "../../../components/Navigation";

export default function NewErrandPage() {
  const [submitted, setSubmitted] = useState(false);

  function submit(event) {
    event.preventDefault();
    setSubmitted(true);
  }

  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Request intake</div>
        <h1>New errand</h1>
        <p>
          Describe what needs to happen and where coordination should occur.
        </p>
      </section>

      <section className="card full">
        {submitted ? (
          <>
            <div className="status">
              <span className="status-dot" />
              Request captured
            </div>

            <h2>Errand request ready for the platform pipeline.</h2>

            <p>
              The production request flow will continue through validation,
              matching, dispatch, coordination, tracking and completion.
            </p>

            <div className="actions">
              <a className="button primary" href="/dashboard">
                Return to dashboard
              </a>
            </div>
          </>
        ) : (
          <form className="form" onSubmit={submit}>
            <div className="field">
              <label htmlFor="title">What do you need done?</label>
              <input
                id="title"
                name="title"
                placeholder="Example: Pick something up and bring it to me"
                required
              />
            </div>

            <div className="field">
              <label htmlFor="details">Details</label>
              <textarea
                id="details"
                name="details"
                placeholder="Describe the errand, requirements or special instructions."
              />
            </div>

            <div className="field">
              <label htmlFor="pickup">Pickup coordination</label>
              <input
                id="pickup"
                name="pickup"
                placeholder="Address, business, landmark, entrance or meeting point"
                required
              />
            </div>

            <div className="field">
              <label htmlFor="dropoff">Drop-off coordination</label>
              <input
                id="dropoff"
                name="dropoff"
                placeholder="Address, landmark, shared location or meeting point"
                required
              />
            </div>

            <div className="field">
              <label htmlFor="timing">Timing</label>
              <select id="timing" name="timing" defaultValue="flexible">
                <option value="flexible">Flexible</option>
                <option value="asap">As soon as possible</option>
                <option value="scheduled">Scheduled</option>
              </select>
            </div>

            <button className="button primary" type="submit">
              Submit errand
            </button>
          </form>
        )}
      </section>
    </main>
  );
}
