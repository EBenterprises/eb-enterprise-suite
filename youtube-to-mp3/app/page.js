"use client";

import { useState } from "react";

export default function Home() {
  const [url, setUrl] = useState("");
  const [quality, setQuality] = useState("192");
  const [status, setStatus] = useState("idle");
  const [message, setMessage] = useState("");

  async function convert() {
    if (!url.trim()) {
      setMessage("Paste a media URL first.");
      return;
    }

    setStatus("working");
    setMessage("Preparing conversion…");

    try {
      const response = await fetch("/api/convert", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url, quality })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Conversion request failed.");
      }

      setStatus("ready");
      setMessage(data.message);
    } catch (error) {
      setStatus("error");
      setMessage(error.message);
    }
  }

  return (
    <main className="page">
      <nav className="nav">
        <div className="brand">
          <span className="brandMark">▶</span>
          <span>YouTube to MP3<span className="registered">®</span></span>
        </div>
        <span className="badge">AUTHORIZED MEDIA</span>
      </nav>

      <section className="hero">
        <div className="eyebrow">AUDIO CONVERSION PLATFORM</div>

        <h1>
          Turn authorized
          <br />
          <span>video into audio.</span>
        </h1>

        <p className="subtitle">
          Convert media you own or have permission to download into
          high-quality MP3 audio.
        </p>

        <section className="converter">
          <label htmlFor="url">MEDIA URL</label>

          <div className="inputRow">
            <input
              id="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="Paste your authorized media URL"
              autoComplete="off"
            />

            <select
              value={quality}
              onChange={(e) => setQuality(e.target.value)}
              aria-label="Audio quality"
            >
              <option value="128">128 kbps</option>
              <option value="192">192 kbps</option>
              <option value="256">256 kbps</option>
              <option value="320">320 kbps</option>
            </select>

            <button onClick={convert} disabled={status === "working"}>
              {status === "working" ? "PROCESSING…" : "CONVERT"}
            </button>
          </div>

          <div className={`status ${status}`}>
            <span className="statusDot" />
            {message || "Ready for an authorized media URL."}
          </div>
        </section>

        <div className="features">
          <article>
            <div className="icon">01</div>
            <h3>PASTE</h3>
            <p>Enter the URL of media you are authorized to download.</p>
          </article>

          <article>
            <div className="icon">02</div>
            <h3>CONVERT</h3>
            <p>Choose your preferred MP3 bitrate and start processing.</p>
          </article>

          <article>
            <div className="icon">03</div>
            <h3>EXPORT</h3>
            <p>Receive the generated audio when the conversion completes.</p>
          </article>
        </div>
      </section>

      <footer>
        <span>YouTube to MP3®</span>
        <span>© 2026 EB Enterprises®</span>
      </footer>
    </main>
  );
}
