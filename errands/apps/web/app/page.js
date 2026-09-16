import Brand from "../components/Brand";
import Navigation from "../components/Navigation";

const capabilities = [
  ["Errands", "Create and manage errands from request through completion."],
  ["Coordination", "Use addresses, landmarks, entrances, meeting points or live locations."],
  ["Dispatch", "Match requests with available runners and operational capacity."],
  ["Tracking", "Maintain realtime movement, arrival and handoff state."],
  ["Communication", "Keep customer, runner and operations communication connected."],
  ["Operations", "Provide the control surface required to operate the complete platform."]
];

export default function Home() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">The errands coordination platform</div>
        <h1>Get things done.</h1>
        <p>
          ERRANDS® connects requests, people, places, runners, coordination,
          tracking and operations into one platform.
        </p>

        <div className="actions">
          <a className="button primary" href="/errands/new">
            Create an errand
          </a>
          <a className="button" href="/dashboard">
            Open dashboard
          </a>
        </div>
      </section>

      <section className="section">
        <div className="section-title">Platform capabilities</div>

        <div className="grid">
          {capabilities.map(([title, description]) => (
            <article className="card" key={title}>
              <h3>{title}</h3>
              <p>{description}</p>
            </article>
          ))}
        </div>
      </section>

      <footer className="footer">
        ERRANDS® — proprietary platform architecture and software.
      </footer>
    </main>
  );
}
