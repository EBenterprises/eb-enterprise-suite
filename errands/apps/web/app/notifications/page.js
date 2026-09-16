import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function NotificationsPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Events</div>
        <h1>Notifications</h1>
        <p>Important updates from the ERRANDS® platform.</p>
      </section>

      <article className="card full">
        <h2>All clear</h2>
        <p>No notifications currently require attention.</p>
      </article>
    </main>
  );
}
