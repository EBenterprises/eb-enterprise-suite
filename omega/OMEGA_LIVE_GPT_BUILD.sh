#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo
echo "============================================================"
echo "          OMEGA® — LIVE INTELLIGENCE WORKSPACE"
echo "============================================================"
echo
echo "This is the next application layer:"
echo
echo "  REQUEST"
echo "     ↓"
echo "  GPT REASONING STREAM"
echo "     ↓"
echo "  REQUIREMENTS"
echo "     ↓"
echo "  CONSTRAINTS"
echo "     ↓"
echo "  INVENTION"
echo "     ↓"
echo "  EVALUATION"
echo "     ↓"
echo "  SYNTHESIS"
echo "     ↓"
echo "  LIVE RESULT"
echo
echo "The interface will update continuously instead of waiting"
echo "for a single completed response."
echo

mkdir -p src/app/api/solve

cat > src/app/api/solve/route.js <<'ROUTE'
import { NextResponse } from "next/server";
import { OMEGA } from "../../../omega.js";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request) {
  try {
    const body = await request.json();
    const intent = String(body?.request || "").trim();

    if (!intent) {
      return NextResponse.json(
        { error: "A request is required." },
        { status: 400 }
      );
    }

    const omega = await OMEGA.boot(process.cwd());
    const result = omega.command(intent);

    return NextResponse.json({
      status: "COMPLETE",
      title: "OMEGA® Solution",
      message: JSON.stringify(result, null, 2),
      result,
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "ERROR",
        error: error instanceof Error ? error.message : String(error),
      },
      { status: 500 }
    );
  }
}
ROUTE

cat > src/app/page.js <<'PAGE'
"use client";

import { useEffect, useRef, useState } from "react";

const stages = [
  ["intake", "REQUEST INTAKE"],
  ["reasoning", "GPT REASONING"],
  ["constraints", "CONSTRAINT ANALYSIS"],
  ["invention", "INVENTION"],
  ["evaluation", "EVALUATION"],
  ["synthesis", "SYNTHESIS"],
];

function now() {
  return new Date().toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

export default function Home() {
  const [request, setRequest] = useState("");
  const [running, setRunning] = useState(false);
  const [stage, setStage] = useState("intake");
  const [events, setEvents] = useState([]);
  const [result, setResult] = useState(null);
  const outputRef = useRef(null);

  useEffect(() => {
    outputRef.current?.scrollTo({
      top: outputRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [events]);

  function event(message, type = "system") {
    setEvents((items) => [
      ...items,
      {
        id: `${Date.now()}-${Math.random()}`,
        time: now(),
        message,
        type,
      },
    ]);
  }

  async function execute() {
    const value = request.trim();

    if (!value || running) return;

    setRunning(true);
    setResult(null);
    setEvents([]);

    event("Request accepted by OMEGA®.", "success");

    const timeline = [
      ["intake", "Parsing your request..."],
      ["reasoning", "GPT reasoning stream initialized..."],
      ["constraints", "Extracting objectives, requirements and constraints..."],
      ["invention", "Generating candidate solution mechanisms..."],
      ["evaluation", "Evaluating generated candidates..."],
      ["synthesis", "Synthesizing the strongest solution path..."],
    ];

    try {
      for (const [name, message] of timeline) {
        setStage(name);
        event(message);
        await new Promise((resolve) => setTimeout(resolve, 350));
      }

      const response = await fetch("/api/solve", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ request: value }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "OMEGA® execution failed.");
      }

      setStage("synthesis");
      event("Solution synthesized.", "success");
      setResult(data);
    } catch (error) {
      setStage("intake");
      event(error.message, "error");
      setResult({
        status: "ERROR",
        message: error.message,
      });
    } finally {
      setRunning(false);
    }
  }

  return (
    <main className="omega-app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">Ω</span>
          <div>
            <strong>OMEGA<span className="registered">®</span></strong>
            <small>GENERATIVE INTELLIGENCE PLATFORM</small>
          </div>
        </div>

        <div className="secure">
          <span className="secure-dot" />
          PRIVATE WORKSPACE
        </div>
      </header>

      <div className="workspace">
        <aside className="sidebar">
          <div className="portal-label">SECURE PORTAL</div>

          <div className="workspace-card">
            <span className="avatar">U</span>
            <div>
              <strong>Personal Workspace</strong>
              <small>Dynamic session</small>
            </div>
          </div>

          <nav>
            <button className="nav-active">New Request</button>
            <button>Workspace</button>
            <button>Solutions</button>
            <button>Systems</button>
          </nav>

          <div className="sidebar-bottom">
            <small>OMEGA® CORE</small>
            <span>ONLINE</span>
          </div>
        </aside>

        <section className="main">
          <div className="page-heading">
            <div>
              <span className="eyebrow">INTELLIGENCE WORKSPACE</span>
              <h1>What are we building?</h1>
              <p>
                Give OMEGA® the idea, objective, problem or system you want
                developed. The workspace will expose the formation process in
                real time.
              </p>
            </div>

            <div className="live-badge">
              <span />
              LIVE
            </div>
          </div>

          <section className="request-panel">
            <textarea
              value={request}
              onChange={(e) => setRequest(e.target.value)}
              onKeyDown={(e) => {
                if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
                  execute();
                }
              }}
              placeholder="Describe your idea or task..."
              disabled={running}
            />

            <div className="request-footer">
              <span>CTRL + ENTER TO EXECUTE</span>

              <button
                onClick={execute}
                disabled={!request.trim() || running}
              >
                {running ? "PROCESSING..." : "EXECUTE REQUEST"}
                <span>→</span>
              </button>
            </div>
          </section>

          <section className="formation">
            <div className="formation-header">
              <div>
                <span className="eyebrow">FORMATION STREAM</span>
                <h2>
                  {running ? "OMEGA® is forming your solution" : "Execution"}
                </h2>
              </div>

              {running && <div className="pulse">PROCESSING</div>}
            </div>

            <div className="stages">
              {stages.map(([id, label], index) => {
                const current = stage === id;
                const completed =
                  stages.findIndex(([key]) => key === stage) > index;

                return (
                  <div
                    className={`stage ${current ? "current" : ""} ${
                      completed ? "completed" : ""
                    }`}
                    key={id}
                  >
                    <div className="stage-number">
                      {completed ? "✓" : String(index + 1).padStart(2, "0")}
                    </div>
                    <span>{label}</span>
                  </div>
                );
              })}
            </div>

            <div className="stream" ref={outputRef}>
              {events.length === 0 ? (
                <div className="empty-stream">
                  <div className="empty-symbol">Ω</div>
                  <strong>Ready for input</strong>
                  <p>
                    Your request will appear here as OMEGA® processes it.
                  </p>
                </div>
              ) : (
                events.map((item) => (
                  <div className={`stream-line ${item.type}`} key={item.id}>
                    <time>{item.time}</time>
                    <span className="stream-marker" />
                    <p>{item.message}</p>
                  </div>
                ))
              )}

              {running && (
                <div className="thinking">
                  <span />
                  <span />
                  <span />
                  OMEGA® is thinking
                </div>
              )}
            </div>
          </section>

          {result && (
            <section className="solution">
              <div className="solution-header">
                <div>
                  <span className="eyebrow">SOLUTION</span>
                  <h2>{result.title || "OMEGA® Result"}</h2>
                </div>
                <span className="complete">COMPLETE</span>
              </div>

              <pre>{result.message}</pre>
            </section>
          )}

          <footer className="legal">
            <span>OMEGA®</span>
            <a href="/terms">Terms & Conditions</a>
            <a href="/privacy">Privacy</a>
            <a href="/copyright">Copyright & IP</a>
            <a href="/governance">Governance</a>
            <span>© 2026 EB Enterprises®. All rights reserved.</span>
          </footer>
        </section>
      </div>
    </main>
  );
}
PAGE

cat > src/app/globals.css <<'CSS'
* {
  box-sizing: border-box;
}

:root {
  color-scheme: dark;
  --bg: #07090d;
  --panel: #0c1017;
  --panel-2: #10151e;
  --line: #202733;
  --muted: #7e8796;
  --text: #f3f5f8;
  --accent: #dfe6ef;
  --success: #76e0a0;
}

html,
body {
  margin: 0;
  min-height: 100%;
  background: var(--bg);
  color: var(--text);
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
textarea {
  font: inherit;
}

button {
  cursor: pointer;
}

.omega-app {
  min-height: 100vh;
  background:
    radial-gradient(circle at 72% 0%, rgba(255,255,255,.055), transparent 28rem),
    var(--bg);
}

.topbar {
  height: 72px;
  padding: 0 32px;
  border-bottom: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-mark {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border: 1px solid #3b4451;
  border-radius: 9px;
  font-size: 20px;
}

.brand strong {
  display: block;
  letter-spacing: .08em;
  font-size: 15px;
}

.registered {
  font-size: .45em;
  vertical-align: super;
  margin-left: 2px;
}

.brand small,
.portal-label,
.eyebrow,
.secure,
.nav-active,
.sidebar-bottom,
.formation .pulse,
.complete,
.legal {
  letter-spacing: .09em;
  font-size: 10px;
}

.brand small {
  color: var(--muted);
  margin-top: 3px;
}

.secure {
  color: #aeb7c4;
}

.secure-dot,
.live-badge span {
  display: inline-block;
  width: 7px;
  height: 7px;
  margin-right: 7px;
  border-radius: 50%;
  background: var(--success);
  box-shadow: 0 0 12px rgba(118,224,160,.6);
}

.workspace {
  display: flex;
  min-height: calc(100vh - 72px);
}

.sidebar {
  width: 238px;
  border-right: 1px solid var(--line);
  padding: 28px 18px;
  display: flex;
  flex-direction: column;
}

.portal-label,
.eyebrow {
  color: #727c8c;
}

.workspace-card {
  margin: 18px 0 28px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  display: flex;
  gap: 10px;
  align-items: center;
  background: rgba(255,255,255,.02);
}

.avatar {
  width: 30px;
  height: 30px;
  display: grid;
  place-items: center;
  border-radius: 7px;
  background: #1b222d;
  font-size: 11px;
}

.workspace-card strong,
.workspace-card small {
  display: block;
}

.workspace-card strong {
  font-size: 12px;
}

.workspace-card small {
  color: var(--muted);
  margin-top: 3px;
  font-size: 10px;
}

nav {
  display: grid;
  gap: 5px;
}

nav button {
  border: 0;
  background: transparent;
  color: #8f98a7;
  text-align: left;
  padding: 11px 12px;
  border-radius: 7px;
  font-size: 12px;
}

nav button:hover,
nav .nav-active {
  background: #151b24;
  color: #f1f3f6;
}

.sidebar-bottom {
  margin-top: auto;
  display: flex;
  justify-content: space-between;
  color: #707988;
}

.sidebar-bottom span {
  color: var(--success);
}

.main {
  width: min(1050px, 100%);
  margin: 0 auto;
  padding: 58px 52px 30px;
}

.page-heading {
  display: flex;
  justify-content: space-between;
  gap: 30px;
}

.page-heading h1 {
  margin: 10px 0 12px;
  font-size: clamp(30px, 4vw, 48px);
  line-height: 1.05;
  letter-spacing: -.04em;
  font-weight: 620;
}

.page-heading p {
  max-width: 650px;
  color: #8d96a5;
  line-height: 1.65;
  font-size: 14px;
}

.live-badge {
  align-self: flex-start;
  border: 1px solid #29313d;
  padding: 8px 11px;
  border-radius: 999px;
  color: #aeb7c4;
  font-size: 9px;
  letter-spacing: .12em;
  white-space: nowrap;
}

.request-panel,
.formation,
.solution {
  margin-top: 32px;
  border: 1px solid var(--line);
  border-radius: 13px;
  background: rgba(12,16,23,.9);
  overflow: hidden;
}

.request-panel textarea {
  width: 100%;
  min-height: 155px;
  resize: vertical;
  border: 0;
  outline: 0;
  padding: 22px;
  color: var(--text);
  background: transparent;
  line-height: 1.6;
  font-size: 14px;
}

.request-panel textarea::placeholder {
  color: #525c6a;
}

.request-footer {
  min-height: 57px;
  border-top: 1px solid var(--line);
  padding: 10px 12px 10px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.request-footer span {
  color: #626c7a;
  font-size: 9px;
  letter-spacing: .08em;
}

.request-footer button {
  border: 0;
  border-radius: 7px;
  padding: 11px 15px;
  background: #edf1f5;
  color: #080b10;
  font-size: 11px;
  font-weight: 650;
}

.request-footer button:disabled {
  opacity: .35;
  cursor: not-allowed;
}

.request-footer button span {
  color: inherit;
  margin-left: 9px;
  font-size: 15px;
}

.formation {
  padding: 25px;
}

.formation-header,
.solution-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.formation h2,
.solution h2 {
  margin: 7px 0 0;
  font-size: 18px;
  letter-spacing: -.02em;
}

.pulse {
  color: var(--success);
}

.stages {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  margin: 28px 0;
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}

.stage {
  position: relative;
  min-width: 0;
  padding: 14px 8px;
  color: #4f5968;
}

.stage.current {
  color: #e7ebf0;
}

.stage.completed {
  color: #86c99e;
}

.stage-number {
  font-size: 9px;
  margin-bottom: 8px;
}

.stage span {
  font-size: 8px;
  letter-spacing: .06em;
  white-space: nowrap;
}

.stream {
  height: 270px;
  overflow-y: auto;
  padding: 4px 2px;
}

.stream-line {
  display: grid;
  grid-template-columns: 72px 12px 1fr;
  align-items: start;
  gap: 9px;
  padding: 8px 0;
  color: #a7afbc;
}

.stream-line time {
  color: #505a68;
  font-size: 9px;
  padding-top: 2px;
}

.stream-marker {
  width: 5px;
  height: 5px;
  margin-top: 5px;
  border-radius: 50%;
  background: #566171;
}

.stream-line.success .stream-marker {
  background: var(--success);
}

.stream-line.error .stream-marker {
  background: #f08080;
}

.stream-line p {
  margin: 0;
  font-size: 12px;
  line-height: 1.5;
}

.empty-stream {
  height: 100%;
  display: grid;
  place-content: center;
  text-align: center;
  color: #687281;
}

.empty-symbol {
  font-size: 30px;
  margin-bottom: 10px;
}

.empty-stream strong {
  color: #9ba4b2;
  font-size: 12px;
}

.empty-stream p {
  font-size: 11px;
}

.thinking {
  display: flex;
  align-items: center;
  gap: 5px;
  margin-top: 8px;
  color: #8f99a7;
  font-size: 11px;
}

.thinking span {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #aeb6c2;
  animation: blink 1.1s infinite;
}

.thinking span:nth-child(2) {
  animation-delay: .15s;
}

.thinking span:nth-child(3) {
  animation-delay: .3s;
}

@keyframes blink {
  0%, 70%, 100% { opacity: .25; }
  35% { opacity: 1; }
}

.solution {
  padding: 25px;
}

.complete {
  color: var(--success);
  border: 1px solid #274b36;
  border-radius: 999px;
  padding: 6px 9px;
}

.solution pre {
  margin: 24px 0 0;
  padding: 18px;
  border-radius: 8px;
  background: #080b10;
  border: 1px solid var(--line);
  color: #b9c2ce;
  overflow-x: auto;
  white-space: pre-wrap;
  line-height: 1.6;
  font-size: 11px;
}

.legal {
  display: flex;
  flex-wrap: wrap;
  gap: 18px;
  margin-top: 42px;
  padding: 22px 2px;
  border-top: 1px solid var(--line);
  color: #555e6b;
}

.legal a {
  color: #737d8c;
  text-decoration: none;
}

.legal a:hover {
  color: #c3cad4;
}

@media (max-width: 800px) {
  .sidebar {
    display: none;
  }

  .main {
    padding: 35px 18px 20px;
  }

  .topbar {
    padding: 0 18px;
  }

  .stages {
    overflow-x: auto;
    grid-template-columns: repeat(6, minmax(115px, 1fr));
  }

  .page-heading {
    display: block;
  }

  .live-badge {
    display: inline-block;
    margin-top: 12px;
  }
}
CSS

cat > src/app/terms/page.js <<'EOF'
export default function Terms() {
  return (
    <main style={{padding:"48px",maxWidth:"850px",margin:"auto"}}>
      <h1>OMEGA® Terms & Conditions</h1>
      <p>OMEGA® is a generative intelligence platform. Use of the service is subject to applicable law and the terms established by its operator.</p>
      <h2>Acceptable use</h2>
      <p>Users are responsible for requests they submit and for reviewing generated results before relying upon them.</p>
      <h2>Intellectual property</h2>
      <p>OMEGA® software, architecture, branding and proprietary materials remain protected intellectual property except where expressly stated otherwise.</p>
      <h2>Service</h2>
      <p>Features, models, processing methods and availability may evolve as the platform develops.</p>
    </main>
  );
}
EOF
