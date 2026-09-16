export default function LegalDocument({ label, title, children }) {
  return (
    <div className="legal">
      <header className="topbar">
        <a className="wordmark" href="/">
          OMEGA<span className="registered">®</span>
        </a>
        <a className="back-link" href="/">← Home</a>
      </header>

      <main className="legal-main">
        <div className="overline">{label}</div>
        <h1>{title}</h1>
        <div className="legal-content">{children}</div>
      </main>
    </div>
  );
}
