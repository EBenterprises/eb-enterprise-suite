import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function MessagesPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Communication</div>
        <h1>Messages</h1>
        <p>Customer, runner and operations conversations.</p>
      </section>

      <article className="card full">
        <h2>No conversations</h2>
        <p>
          Conversations will be associated with users, errands and operational
          events.
        </p>
      </article>
    </main>
  );
}
