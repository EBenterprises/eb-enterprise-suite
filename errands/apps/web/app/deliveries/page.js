import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function DeliveriesPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Execution</div>
        <h1>Deliveries</h1>
        <p>Active and completed handoff operations.</p>
      </section>

      <article className="card full">
        <h2>No deliveries</h2>
        <p>
          Delivery records will appear here after an errand reaches execution.
        </p>
      </article>
    </main>
  );
}
