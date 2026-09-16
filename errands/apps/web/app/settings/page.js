import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function SettingsPage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Configuration</div>
        <h1>Settings</h1>
        <p>Account, privacy, notifications, security and platform settings.</p>
      </section>

      <article className="card full">
        <h2>Settings</h2>
        <p>Configuration modules will be connected to the account services.</p>
      </article>
    </main>
  );
}
