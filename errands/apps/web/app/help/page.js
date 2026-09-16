import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function HelpPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Support</div>
        <h1>Help</h1>
        <p>Support, safety and issue resolution for ERRANDS® users.</p>
      </section>

      <article className="card full">
        <h2>How can we help?</h2>
        <p>
          Support cases, safety reports and operational assistance will be
          routed through the support service.
        </p>
      </article>
    </main>
  );
}
