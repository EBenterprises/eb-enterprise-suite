export default function Privacy() {
  return (
    <LegalPage
      title="Privacy Policy"
      label="LEGAL / PRIVACY"
      children={
        <>
          <p>
            OMEGA® is designed to treat workspace information as private
            application data. This page establishes the product surface for
            the platform&apos;s privacy practices.
          </p>

          <h2>Information</h2>
          <p>
            Depending on the services enabled for your account, OMEGA® may
            process account information, requests, generated results, project
            information, technical telemetry, and security information.
          </p>

          <h2>Use</h2>
          <p>
            Information is used to provide, secure, operate, improve, and
            administer the OMEGA® service.
          </p>

          <h2>Security</h2>
          <p>
            OMEGA® is intended to use appropriate technical and organizational
            safeguards for account and workspace information.
          </p>

          <h2>Your controls</h2>
          <p>
            Account-level privacy controls, data retention, export, and
            deletion capabilities belong in the authenticated portal.
          </p>
        </>
      }
    />
  );
}

function LegalPage({ title, label, children }) {
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
