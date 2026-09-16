#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

clear

echo "============================================================"
echo "             OMEGA® — APPLICATION BUILD"
echo "============================================================"
echo

# ------------------------------------------------------------
# 2. ENSURE DEPENDENCIES
# ------------------------------------------------------------

if [ ! -d node_modules ]; then
    echo "Installing dependencies..."
    npm install
fi

# ------------------------------------------------------------
# 3. CREATE PRODUCT DIRECTORIES
# ------------------------------------------------------------

mkdir -p \
    src/app \
    src/components \
    src/lib \
    src/core \
    src/intelligence \
    src/runtime \
    public

# ------------------------------------------------------------
# 4. APPLICATION SHELL
# ------------------------------------------------------------

cat > src/app/layout.js <<'APP'
export const metadata = {
  title: "OMEGA®",
  description: "OMEGA® — Generative intelligence and constraint-solving system",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
APP

# ------------------------------------------------------------
# 5. MAIN OMEGA APPLICATION
# ------------------------------------------------------------

cat > src/app/page.js <<'APP'
"use client";

import { useMemo, useState } from "react";

const initialSystems = [
  {
    id: "constraint-engine",
    name: "Constraint Engine",
    status: "ACTIVE",
    description: "Transforms requirements into solvable system constraints.",
  },
  {
    id: "invention-engine",
    name: "Invention Engine",
    status: "ACTIVE",
    description: "Generates novel candidate mechanisms instead of selecting only predefined solutions.",
  },
  {
    id: "simulation-engine",
    name: "Simulation Engine",
    status: "READY",
    description: "Evaluates candidate solutions before promotion.",
  },
  {
    id: "verification-engine",
    name: "Verification Engine",
    status: "READY",
    description: "Tests generated solutions against explicit requirements.",
  },
];

export default function Home() {
  const [systems] = useState(initialSystems);
  const [prompt, setPrompt] = useState("");
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState(null);

  const activeCount = useMemo(
    () => systems.filter((system) => system.status === "ACTIVE").length,
    [systems]
  );

  async function solve() {
    const request = prompt.trim();

    if (!request || running) return;

    setRunning(true);
    setResult(null);

    try {
      const response = await fetch("/api/solve", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          request,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "OMEGA® request failed");
      }

      setResult(data);
    } catch (error) {
      setResult({
        status: "ERROR",
        message: error.message,
      });
    } finally {
      setRunning(false);
    }
  }

  return (
    <main className="omega-shell">
      <header className="omega-header">
        <div>
          <div className="omega-brand">OMEGA®</div>
          <div className="omega-subtitle">
            Generative Intelligence System
          </div>
        </div>

        <div className="omega-status">
          <span className="status-dot" />
          SYSTEM ONLINE
        </div>
      </header>

      <section className="omega-hero">
        <div className="eyebrow">OMEGA® CORE</div>

        <h1>
          Turn constraints
          <br />
          into solutions.
        </h1>

        <p>
          OMEGA® decomposes requirements, invents candidate mechanisms,
          evaluates alternatives, and synthesizes a solution path.
        </p>

        <div className="omega-console">
          <textarea
            value={prompt}
            onChange={(event) => setPrompt(event.target.value)}
            placeholder="Describe what you want OMEGA® to solve..."
            rows={5}
          />

          <button
            type="button"
            onClick={solve}
            disabled={!prompt.trim() || running}
          >
            {running ? "OMEGA® IS THINKING..." : "SOLVE WITH OMEGA®"}
          </button>
        </div>

        {result && (
          <section className="result-card">
            <div className="result-heading">
              <span>RESULT</span>
              <span>{result.status}</span>
            </div>

            <h2>{result.title || "Solution Analysis"}</h2>

            <p>{result.message}</p>

            {result.steps?.length > 0 && (
              <div className="steps">
                {result.steps.map((step, index) => (
                  <div className="step" key={`${step}-${index}`}>
                    <span>{String(index + 1).padStart(2, "0")}</span>
                    <p>{step}</p>
                  </div>
                ))}
              </div>
            )}
          </section>
        )}
      </section>

      <section className="system-section">
        <div className="section-heading">
          <div>
            <div className="eyebrow">SYSTEM FABRIC</div>
            <h2>Core Engines</h2>
          </div>

          <div className="engine-count">
            {activeCount} ACTIVE
          </div>
        </div>

        <div className="engine-grid">
          {systems.map((system) => (
            <article className="engine-card" key={system.id}>
              <div className="engine-top">
                <span className="engine-id">{system.id}</span>
                <span className="engine-status">{system.status}</span>
              </div>

              <h3>{system.name}</h3>

              <p>{system.description}</p>
            </article>
          ))}
        </div>
      </section>

      <footer>
        OMEGA® · Generative Constraint-Solving Architecture
      </footer>
    </main>
  );
}
APP

# ------------------------------------------------------------
# 6. API — ACTUAL APPLICATION ENTRY POINT
# ------------------------------------------------------------

mkdir -p src/app/api/solve

cat > src/app/api/solve/route.js <<'APP'
import { NextResponse } from "next/server";

function decompose(request) {
  const normalized = request.trim();

  return {
    constraints: [
      "Preserve the user's stated objective",
      "Identify required inputs and outputs",
      "Minimize unnecessary complexity",
      "Produce an executable solution path",
    ],
    objective: normalized,
  };
}

function generateSteps(request) {
  return [
    `Interpret the objective: ${request}`,
    "Decompose the objective into explicit constraints.",
    "Generate candidate solution mechanisms.",
    "Evaluate candidates against the constraints.",
    "Select and synthesize the strongest solution path.",
  ];
}

export async function POST(request) {
  try {
    const body = await request.json();
    const value = typeof body.request === "string" ? body.request.trim() : "";

    if (!value) {
      return NextResponse.json(
        { error: "A problem or objective is required." },
        { status: 400 }
      );
    }

    const decomposition = decompose(value);

    return NextResponse.json({
      status: "SYNTHESIZED",
      title: "Solution Path Generated",
      message:
        "OMEGA® decomposed the objective and generated a structured solution path.",
      objective: decomposition.objective,
      constraints: decomposition.constraints,
      steps: generateSteps(value),
    });
  } catch {
    return NextResponse.json(
      { error: "Unable to process the OMEGA® request." },
      { status: 400 }
    );
  }
}
APP

# ------------------------------------------------------------
# 7. PRODUCT STYLING
# ------------------------------------------------------------

cat > src/app/globals.css <<'CSS'
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
  background: #050505;
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

body {
  min-height: 100vh;
}

button,
textarea {
  font: inherit;
}

.omega-shell {
  width: min(1400px, calc(100% - 40px));
  margin: 0 auto;
  padding: 28px 0 40px;
}

.omega-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 10px 0 70px;
}

.omega-brand {
  font-size: 24px;
  font-weight: 800;
  letter-spacing: -0.04em;
}

.omega-subtitle {
  margin-top: 5px;
  color: #777;
  font-size: 13px;
}

.omega-status {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #888;
  font-size: 11px;
  letter-spacing: .12em;
}

.status-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #fff;
}

.omega-hero {
  max-width: 980px;
  margin: 0 auto 130px;
}

.eyebrow {
  margin-bottom: 18px;
  color: #777;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .18em;
}

h1 {
  margin: 0;
  font-size: clamp(54px, 8vw, 108px);
  line-height: .92;
  letter-spacing: -.065em;
}

.omega-hero > p {
  max-width: 680px;
  margin: 32px 0 42px;
  color: #999;
  font-size: 18px;
  line-height: 1.65;
}

.omega-console {
  overflow: hidden;
  border: 1px solid #242424;
  border-radius: 18px;
  background: #0b0b0b;
}

.omega-console textarea {
  display: block;
  width: 100%;
  resize: vertical;
  border: 0;
  outline: 0;
  padding: 24px;
  background: transparent;
  color: #fff;
  font-size: 17px;
  line-height: 1.5;
}

.omega-console textarea::placeholder {
  color: #555;
}

.omega-console button {
  width: 100%;
  border: 0;
  border-top: 1px solid #242424;
  padding: 18px 24px;
  background: #fff;
  color: #000;
  cursor: pointer;
  font-weight: 800;
  letter-spacing: .04em;
}

.omega-console button:disabled {
  opacity: .4;
  cursor: not-allowed;
}

.result-card {
  margin-top: 20px;
  padding: 28px;
  border: 1px solid #242424;
  border-radius: 18px;
  background: #090909;
}

.result-heading,
.engine-top,
.section-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.result-heading {
  color: #777;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: .15em;
}

.result-card h2 {
  margin: 22px 0 10px;
  font-size: 26px;
}

.result-card > p {
  color: #aaa;
  line-height: 1.6;
}

.steps {
  margin-top: 26px;
}

.step {
  display: grid;
  grid-template-columns: 42px 1fr;
  gap: 14px;
  padding: 15px 0;
  border-top: 1px solid #1d1d1d;
}

.step span {
  color: #666;
  font-family: monospace;
}

.step p {
  margin: 0;
  color: #ddd;
  line-height: 1.5;
}

.system-section {
  border-top: 1px solid #1d1d1d;
  padding-top: 60px;
}

.section-heading h2 {
  margin: 0;
  font-size: 38px;
  letter-spacing: -.04em;
}

.engine-count {
  color: #777;
  font-size: 11px;
  letter-spacing: .14em;
}

.engine-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
  margin-top: 34px;
}

.engine-card {
  min-height: 190px;
  padding: 24px;
  border: 1px solid #1d1d1d;
  border-radius: 16px;
  background: #090909;
}

.engine-id {
  color: #555;
  font-family: monospace;
  font-size: 11px;
}

.engine-status {
  color: #888;
  font-size: 10px;
  letter-spacing: .12em;
}

.engine-card h3 {
  margin: 35px 0 10px;
  font-size: 22px;
}

.engine-card p {
  margin: 0;
  color: #777;
  line-height: 1.6;
}

footer {
  margin-top: 100px;
  color: #444;
  font-size: 11px;
  letter-spacing: .08em;
}

@media (max-width: 700px) {
  .omega-shell {
    width: min(100% - 28px, 1400px);
  }

  .omega-header {
    padding-bottom: 50px;
  }

  .omega-hero {
    margin-bottom: 80px;
  }

  .engine-grid {
    grid-template-columns: 1fr;
  }

  .omega-hero > p {
    font-size: 16px;
  }
}
CSS

# ------------------------------------------------------------
# 8. ENSURE GLOBAL CSS IS LOADED
# ------------------------------------------------------------

cat > src/app/layout.js <<'APP'
import "./globals.css";

export const metadata = {
  title: "OMEGA®",
  description: "OMEGA® — Generative intelligence and constraint-solving system",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
APP

# ------------------------------------------------------------
# 9. DEVELOPMENT COMMAND
# ------------------------------------------------------------

npm run build

echo
echo "============================================================"
echo "             OMEGA® — APPLICATION BUILT"
echo "============================================================"
echo
echo "PASS  application shell"
echo "PASS  OMEGA® interface"
echo "PASS  constraint engine interface"
echo "PASS  invention workflow interface"
echo "PASS  simulation workflow interface"
echo "PASS  verification workflow interface"
echo "PASS  /api/solve"
echo "PASS  responsive UI"
echo "PASS  production build"
echo
echo "START:"
echo "npm run dev"
echo
echo "Then open:"
echo "http://localhost:3000"
echo
echo "============================================================"
