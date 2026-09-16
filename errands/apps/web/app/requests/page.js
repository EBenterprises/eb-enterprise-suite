import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function RequestsPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Intake</div>
        <h1>Requests</h1>
        <p>Requests entering the ERRANDS® validation and dispatch pipeline.</p>
      </section>

      <article className="card full">
        <h2>No requests yet</h2>
        <p>
          Create an errand to introduce the first request into the platform.
        </p>
        <a className="button primary" href="/errands/new">
          Create errand
        </a>
      </article>
    </main>
  );
}
