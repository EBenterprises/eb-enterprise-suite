"use client";

import { useEffect, useState } from "react";

export default function Portal() {
  const [status, setStatus] = useState("CONNECTING");

  useEffect(() => {
    fetch("/api/status", { cache: "no-store" })
      .then((response) => {
        setStatus(response.ok ? "ONLINE" : "DEGRADED");
      })
      .catch(() => setStatus("OFFLINE"));
  }, []);

  return (
    <div className="portal">
      <header className="topbar">
        <a className="wordmark" href="/">
          OMEGA<span className="registered">®</span>
        </a>

        <div className="portal-header-title">SECURE WORKSPACE</div>

        <a className="back-link" href="/">
          ← Command Center
        </a>
      </header>

      <main className="portal-main">
        <div className="portal-heading">
          <div className="overline">PRIVATE INSTANCE</div>
          <h1>Your OMEGA<span className="registered">®</span> workspace.</h1>
          <p>
            Requests, solutions, system activity, versions, and account
            resources will live here as the platform expands.
          </p>
        </div>

        <div className="portal-grid">
          <section className="portal-card portal-card-large">
            <div className="portal-card-label">WORKSPACE</div>
            <h2>Command Center</h2>
            <p>Submit and monitor live OMEGA® requests.</p>
            <a href="/">Open Command Center →</a>
          </section>

          <section className="portal-card">
            <div className="portal-card-label">RUNTIME</div>
            <div className="portal-status">
              <span />
              {status}
            </div>
            <p>Private OMEGA® runtime connection.</p>
          </section>

          <section className="portal-card">
            <div className="portal-card-label">PROJECTS</div>
            <h2>0</h2>
            <p>Projects will appear here.</p>
          </section>

          <section className="portal-card">
            <div className="portal-card-label">REQUEST HISTORY</div>
            <h2>Ready</h2>
            <p>Persistent request history is the next workspace layer.</p>
          </section>
        </div>
      </main>
    </div>
  );
}
