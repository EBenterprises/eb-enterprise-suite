import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function DashboardPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Command center</div>
        <h1>Dashboard</h1>
        <p>
          Your operational view of active errands, requests, coordination and
          delivery activity.
        </p>
      </section>

      <section className="grid">
        <article className="card">
          <div className="status">
            <span className="status-dot" />
            System online
          </div>
          <h3>Active errands</h3>
          <p>0 currently active.</p>
        </article>

        <article className="card">
          <h3>Pending requests</h3>
          <p>0 waiting for dispatch.</p>
        </article>

        <article className="card">
          <h3>Runner activity</h3>
          <p>0 runners currently assigned.</p>
        </article>

        <article className="card wide">
          <h3>Location coordination</h3>
          <p>
            ERRANDS® supports conventional addresses as well as landmarks,
            businesses, entrances, meeting points, coordinates and shared
            locations.
          </p>
        </article>

        <article className="card wide">
          <h3>Operational state</h3>
          <p>
            The dashboard becomes the central surface for dispatch, matching,
            tracking, messaging, safety and support as those services are
            connected.
          </p>
        </article>
      </section>
    </main>
  );
}
