#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="youtube-to-mp3"
ROOT="$HOME/$APP"

echo "=== YouTube to MP3® — FULL BUILD ==="

rm -rf "$ROOT"
mkdir -p "$ROOT"/{app/api/convert,app/api/status/[id],components,lib,public,styles}

cd "$ROOT"

cat > package.json <<'JSON'
{
  "name": "youtube-to-mp3",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --webpack",
    "build": "next build --webpack",
    "start": "next start"
  },
  "dependencies": {
    "next": "16.3.0",
    "react": "19.1.0",
    "react-dom": "19.1.0"
  }
}
JSON

cat > next.config.js <<'JS'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true
};

module.exports = nextConfig;
JS

cat > jsconfig.json <<'JSON'
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}
JSON

cat > .gitignore <<'EOF2'
node_modules
.next
.env
.env.local
*.log
tmp/
downloads/
EOF2

cat > app/layout.js <<'JS'
import "./globals.css";

export const metadata = {
  title: "YouTube to MP3®",
  description: "Authorized media conversion platform"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
JS

cat > app/page.js <<'JS'
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
JS

cat > app/api/convert/route.js <<'JS'
import { NextResponse } from "next/server";

function validUrl(value) {
  try {
    const url = new URL(value);

    return (
      url.protocol === "https:" &&
      (
        url.hostname === "youtube.com" ||
        url.hostname === "www.youtube.com" ||
        url.hostname === "youtu.be" ||
        url.hostname.endsWith(".youtube.com")
      )
    );
  } catch {
    return false;
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { url, quality = "192" } = body;

    if (!validUrl(url)) {
      return NextResponse.json(
        {
          error:
            "Enter a valid HTTPS YouTube URL for media you own or are authorized to download."
        },
        { status: 400 }
      );
    }

    const allowed = ["128", "192", "256", "320"];

    if (!allowed.includes(String(quality))) {
      return NextResponse.json(
        { error: "Unsupported audio quality." },
        { status: 400 }
      );
    }

    /*
      Conversion worker integration point.

      A production worker should:
      1. Verify authorization where applicable.
      2. Obtain the permitted source media.
      3. Extract audio with an appropriate licensed/authorized tool.
      4. Encode MP3.
      5. Store the temporary result.
      6. Return a short-lived download URL.
      7. Delete the temporary file automatically.

      This route deliberately does not implement unauthorized
      downloading of YouTube content.
    */

    return NextResponse.json({
      status: "queued",
      message:
        "Conversion infrastructure is ready. Connect an authorized media conversion worker to process this job.",
      quality: `${quality} kbps`
    });
  } catch {
    return NextResponse.json(
      { error: "Invalid conversion request." },
      { status: 400 }
    );
  }
}
JS

cat > app/api/status/[id]/route.js <<'JS'
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    status: "pending",
    progress: 0
  });
}
JS

cat > lib/conversion.js <<'JS'
export const AUDIO_QUALITIES = [
  { value: "128", label: "128 kbps" },
  { value: "192", label: "192 kbps" },
  { value: "256", label: "256 kbps" },
  { value: "320", label: "320 kbps" }
];

export function createJob(url, quality) {
  return {
    id: crypto.randomUUID(),
    url,
    quality,
    status: "queued",
    progress: 0,
    createdAt: new Date().toISOString()
  };
}
JS

cat > components/Brand.js <<'JS'
export default function Brand() {
  return (
    <div className="brand">
      <span className="brandMark">▶</span>
      YouTube to MP3<span className="registered">®</span>
    </div>
  );
}
JS

cat > app/globals.css <<'CSS'
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
  background: #070707;
  color: #f5f5f5;
  font-family:
    Inter,
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background:
    radial-gradient(circle at 50% 0%, #1b1b1b 0, #0b0b0b 35%, #050505 75%);
}

.nav {
  width: 100%;
  max-width: 1240px;
  margin: 0 auto;
  padding: 22px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 15px;
}

.brand {
  font-size: 16px;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.brandMark {
  display: inline-flex;
  width: 31px;
  height: 31px;
  margin-right: 9px;
  border: 1px solid #444;
  border-radius: 9px;
  align-items: center;
  justify-content: center;
  font-size: 11px;
}

.registered {
  font-size: 8px;
  vertical-align: top;
  margin-left: 2px;
}

.badge {
  border: 1px solid #303030;
  border-radius: 999px;
  padding: 7px 10px;
  font-size: 9px;
  letter-spacing: .13em;
  color: #999;
}

.hero {
  width: min(1120px, calc(100% - 40px));
  margin: auto;
  padding: 70px 0 80px;
}

.eyebrow {
  color: #888;
  font-size: 10px;
  letter-spacing: .2em;
  font-weight: 700;
  margin-bottom: 18px;
}

h1 {
  margin: 0;
  font-size: clamp(48px, 9vw, 102px);
  line-height: .91;
  letter-spacing: -.07em;
  max-width: 1000px;
}

h1 span {
  color: #777;
}

.subtitle {
  max-width: 620px;
  color: #9b9b9b;
  font-size: 16px;
  line-height: 1.6;
  margin: 28px 0 42px;
}

.converter {
  padding: 22px;
  border: 1px solid #292929;
  border-radius: 20px;
  background: rgba(15, 15, 15, .86);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .35);
}

.converter label {
  display: block;
  margin-bottom: 10px;
  font-size: 9px;
  letter-spacing: .16em;
  color: #777;
  font-weight: 800;
}

.inputRow {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
}

input,
select {
  min-height: 52px;
  border: 1px solid #303030;
  border-radius: 11px;
  outline: none;
  background: #090909;
  color: #eee;
  padding: 0 15px;
}

input:focus {
  border-color: #666;
}

select {
  min-width: 130px;
}

button {
  min-height: 52px;
  border: 0;
  border-radius: 11px;
  padding: 0 23px;
  background: #f2f2f2;
  color: #050505;
  font-weight: 850;
  letter-spacing: .04em;
}

button:disabled {
  opacity: .5;
  cursor: wait;
}

.status {
  margin-top: 13px;
  min-height: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
  color: #777;
  font-size: 11px;
}

.statusDot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #555;
}

.status.ready .statusDot {
  background: #aaa;
}

.status.error {
  color: #bbb;
}

.status.error .statusDot {
  background: #ddd;
}

.features {
  margin-top: 90px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1px;
  background: #252525;
  border: 1px solid #252525;
  border-radius: 18px;
  overflow: hidden;
}

.features article {
  background: #090909;
  padding: 27px;
  min-height: 185px;
}

.icon {
  font-size: 10px;
  color: #666;
  margin-bottom: 40px;
}

.features h3 {
  font-size: 12px;
  letter-spacing: .14em;
  margin: 0 0 9px;
}

.features p {
  margin: 0;
  color: #777;
  font-size: 12px;
  line-height: 1.6;
}

footer {
  margin-top: auto;
  border-top: 1px solid #181818;
  padding: 22px 20px;
  display: flex;
  justify-content: space-between;
  color: #555;
  font-size: 10px;
  letter-spacing: .04em;
}

@media (max-width: 700px) {
  .nav {
    padding: 17px 15px;
  }

  .badge {
    display: none;
  }

  .hero {
    width: calc(100% - 30px);
    padding: 50px 0 60px;
  }

  h1 {
    font-size: clamp(52px, 16vw, 82px);
  }

  .subtitle {
    font-size: 14px;
    margin-bottom: 30px;
  }

  .converter {
    padding: 15px;
    border-radius: 16px;
  }

  .inputRow {
    grid-template-columns: 1fr;
  }

  input,
  select,
  button {
    width: 100%;
  }

  .features {
    grid-template-columns: 1fr;
    margin-top: 50px;
  }

  .features article {
    min-height: 150px;
  }

  .icon {
    margin-bottom: 25px;
  }

  footer {
    flex-direction: column;
    gap: 8px;
  }
}
CSS

cat > README.md <<'MD'
# YouTube to MP3®

Mobile-first authorized media conversion platform.

## Run

```bash
npm install
npm run dev
