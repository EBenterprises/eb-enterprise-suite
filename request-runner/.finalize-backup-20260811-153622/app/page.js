import Link from "next/link";

export default function Home() {
  return (
    <main className="shell">
      <section className="hero">
        <span className="eyebrow">REQUEST RUNNER®</span>
        <h1>Tell us what you’re looking for.</h1>
        <p>Submit a pickup or delivery request in plain language. Your request appears on the operations server in real time.</p>
        <div className="actions">
          <Link className="button primary" href="/request">Make a Request</Link>
          <Link className="button" href="/ops">Open Operations</Link>
        </div>
      </section>
      <section className="cards">
        <article><b>1. Request</b><span>Describe what you need.</span></article>
        <article><b>2. Match</b><span>Operations sees it instantly.</span></article>
        <article><b>3. Complete</b><span>Status and ETA update live.</span></article>
      </section>
    </main>
  );
}