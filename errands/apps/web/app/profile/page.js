import Brand from "../../components/Brand";
import Navigation from "../../components/Navigation";

export default function ProfilePage() {
  return (
    <main className="shell">
      <header className="topbar">
        <Brand />
        <Navigation />
      </header>

      <section className="hero">
        <div className="eyebrow">Account</div>
        <h1>Profile</h1>
        <p>Identity, contact information and account preferences.</p>
      </section>

      <article className="card full">
        <h2>Profile</h2>
        <p>Authentication and identity services will populate this surface.</p>
      </article>
    </main>
  );
}
