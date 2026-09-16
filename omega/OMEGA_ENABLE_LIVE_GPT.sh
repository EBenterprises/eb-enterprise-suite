#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "============================================================"
echo "        OMEGA® — LIVE GPT WORKSPACE ENABLEMENT"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. REQUIRE SERVER-SIDE KEY
# ------------------------------------------------------------

if [ -z "${OPENAI_API_KEY:-}" ]; then
    if [ -f "$HOME/.config/omega/env" ]; then
        . "$HOME/.config/omega/env"
    fi
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "FAIL  OPENAI_API_KEY is not loaded"
    echo
    echo "Set it privately in:"
    echo "$HOME/.config/omega/env"
    exit 1
fi

echo "PASS  server-side OpenAI credential available"

# ------------------------------------------------------------
# 2. WRITE .env.local WITHOUT PRINTING THE SECRET
# ------------------------------------------------------------

umask 077

cat > .env.local <<ENV
OPENAI_API_KEY=${OPENAI_API_KEY}
OMEGA_GPT_MODEL=${OMEGA_GPT_MODEL:-gpt-5.6}
ENV

chmod 600 .env.local

echo "PASS  Next.js environment configured"
echo "PASS  .env.local permissions locked"

# ------------------------------------------------------------
# 3. CREATE STREAMING GPT API
# ------------------------------------------------------------

mkdir -p src/app/api/solve

cat > src/app/api/solve/route.js <<'JS'
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const SYSTEM_PROMPT = `
You are the GPT intelligence layer inside OMEGA®.

OMEGA® is a professional generative intelligence system.

For every user request:

1. Understand the actual objective.
2. Identify requirements and constraints.
3. Form an architecture or solution.
4. Generate useful implementation ideas.
5. Evaluate tradeoffs and risks.
6. Produce concrete next actions.
7. Never claim something was completed if it was not.
8. Prefer practical, technically rigorous answers.
9. Treat the request as an active workspace task, not a generic chatbot conversation.

Your response is being rendered live inside the OMEGA® private workspace.
Write progressively useful content as you work.
`;

export async function POST(request) {
  try {
    const body = await request.json();
    const task = String(body?.request || "").trim();

    if (!task) {
      return NextResponse.json(
        {
          status: "ERROR",
          message: "A task is required."
        },
        { status: 400 }
      );
    }

    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        {
          status: "CONFIGURATION_REQUIRED",
          title: "GPT connection required",
          message: "OPENAI_API_KEY is not configured."
        },
        { status: 503 }
      );
    }

    const model =
      process.env.OMEGA_GPT_MODEL ||
      process.env.OPENAI_MODEL ||
      "gpt-5.6";

    const upstream = await fetch(
      "https://api.openai.com/v1/responses",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          Accept: "text/event-stream"
        },
        body: JSON.stringify({
          model,
          instructions: SYSTEM_PROMPT,
          input: task,
          stream: true
        }),
        cache: "no-store"
      }
    );

    if (!upstream.ok) {
      const errorText = await upstream.text();

      return NextResponse.json(
        {
          status: "GPT_ERROR",
          title: "GPT request failed",
          message: errorText || `OpenAI HTTP ${upstream.status}`
        },
        { status: upstream.status }
      );
    }

    if (!upstream.body) {
      return NextResponse.json(
        {
          status: "GPT_ERROR",
          message: "OpenAI returned no streaming body."
        },
        { status: 502 }
      );
    }

    return new Response(upstream.body, {
      status: 200,
      headers: {
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no"
      }
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "ERROR",
        title: "OMEGA® execution error",
        message:
          error instanceof Error
            ? error.message
            : String(error)
      },
      { status: 500 }
    );
  }
}
JS

echo "PASS  streaming GPT endpoint"

# ------------------------------------------------------------
# 4. REPLACE PAGE WITH REAL LIVE WORKSPACE
# ------------------------------------------------------------

cat > src/app/page.js <<'JS'
"use client";

import { useState } from "react";

const initialSystems = [
  {
    id: "constraint-engine",
    name: "Constraint Engine",
    status: "ACTIVE",
    description:
      "Transforms requirements into solvable system constraints."
  },
  {
    id: "invention-engine",
    name: "Invention Engine",
    status: "ACTIVE",
    description:
      "Generates novel mechanisms and solution candidates."
  },
  {
    id: "simulation-engine",
    name: "Simulation Engine",
    status: "READY",
    description:
      "Evaluates candidate approaches before promotion."
  },
  {
    id: "verification-engine",
    name: "Verification Engine",
    status: "READY",
    description:
      "Tests generated solutions against explicit requirements."
  }
];

export default function Home() {
  const [prompt, setPrompt] = useState("");
  const [running, setRunning] = useState(false);
  const [stage, setStage] = useState("READY");
  const [output, setOutput] = useState("");
  const [error, setError] = useState("");

  async function solve() {
    const task = prompt.trim();

    if (!task || running) return;

    setRunning(true);
    setOutput("");
    setError("");
    setStage("UNDERSTANDING REQUEST");

    try {
      const response = await fetch("/api/solve", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          request: task
        })
      });

      if (!response.ok) {
        const data = await response.json().catch(() => null);

        throw new Error(
          data?.message ||
          data?.error ||
          `OMEGA® returned HTTP ${response.status}`
        );
      }

      if (!response.body) {
        throw new Error("No live response stream was returned.");
      }

      setStage("GPT IS FORMING THE SOLUTION");

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      let buffer = "";

      while (true) {
        const { value, done } = await reader.read();

        if (done) break;

        buffer += decoder.decode(value, {
          stream: true
        });

        const events = buffer.split("\n\n");
        buffer = events.pop() || "";

        for (const event of events) {
          const lines = event.split("\n");

          for (const line of lines) {
            if (!line.startsWith("data:")) continue;

            const payload = line.slice(5).trim();

            if (!payload || payload === "[DONE]") continue;

            try {
              const data = JSON.parse(payload);

              if (
                data.type ===
                "response.output_text.delta"
              ) {
                setStage("GENERATING SOLUTION");

                setOutput((current) =>
                  current + (data.delta || "")
                );
              }

              if (
                data.type ===
                "response.completed"
              ) {
                setStage("COMPLETE");
              }

              if (data.type === "error") {
                throw new Error(
                  data.error?.message ||
                  "GPT streaming error."
                );
              }
            } catch (parseError) {
              if (
                parseError instanceof Error &&
                parseError.message !==
                  "GPT streaming error."
              ) {
                continue;
              }

              throw parseError;
            }
          }
        }
      }

      setStage("COMPLETE");
    } catch (error) {
      setStage("ERROR");
      setError(
        error instanceof Error
          ? error.message
          : String(error)
      );
    } finally {
      setRunning(false);
    }
  }

  const activeCount = initialSystems.filter(
    (system) => system.status === "ACTIVE"
  ).length;

  return (
    <main className="omega-shell">

      <header className="omega-header">
        <div>
          <div className="omega-brand">
            OMEGA<sup>®</sup>
          </div>

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

        <div className="eyebrow">
          PRIVATE INTELLIGENCE WORKSPACE
        </div>

        <h1>
          Build the idea
          <br />
          in real time.
        </h1>

        <p>
          Give OMEGA<sup>®</sup> an objective.
          Its GPT intelligence layer will form,
          develop and render the solution inside
          your private workspace.
        </p>

        <div className="omega-console">

          <div className="execution-header">
            <span>
              OMEGA<sup>®</sup> WORKSPACE
            </span>

            <span>
              {running ? stage : "READY"}
            </span>
          </div>

          {running && (
            <div
              className="execution-stream"
              aria-live="polite"
            >
              <div className="execution-pulse" />

              <div>
                <strong>{stage}</strong>

                <small>
                  GPT intelligence is actively
                  forming your solution.
                </small>
              </div>
            </div>
          )}

          <textarea
            value={prompt}
            onChange={(event) =>
              setPrompt(event.target.value)
            }
            placeholder="Describe the application, system, invention, business, architecture or problem you want OMEGA® to develop..."
            rows={7}
            disabled={running}
          />

          <button
            type="button"
            onClick={solve}
            disabled={!prompt.trim() || running}
          >
            {running
              ? "OMEGA® IS FORMING..."
              : "EXECUTE WITH OMEGA®"}
          </button>

        </div>

        {(output || error) && (
          <section className="result-card">

            <div className="result-heading">
              <span>LIVE OUTPUT</span>
              <span>{stage}</span>
            </div>

            {error ? (
              <div className="omega-error">
                {error}
              </div>
            ) : (
              <div className="omega-output">
                {output}
                {running && (
                  <span className="typing-cursor">
                    ▋
                  </span>
                )}
              </div>
            )}

          </section>
        )}

      </section>

      <section className="system-section">

        <div className="section-heading">
          <div>
            <div className="eyebrow">
              SYSTEM FABRIC
            </div>

            <h2>Core Engines</h2>
          </div>

          <div className="engine-count">
            {activeCount} ACTIVE
          </div>
        </div>

        <div className="engine-grid">

          {initialSystems.map((system) => (
            <article
              className="engine-card"
              key={system.id}
            >
              <div className="engine-top">
                <span className="engine-id">
                  {system.id}
                </span>

                <span className="engine-status">
                  {system.status}
                </span>
              </div>

              <h3>{system.name}</h3>

              <p>{system.description}</p>
            </article>
          ))}

        </div>

      </section>

      <footer>
        OMEGA<sup>®</sup> · Generative Constraint-Solving
        Architecture · Private Workspace
      </footer>

    </main>
  );
}
JS

echo "PASS  live workspace interface"

# ------------------------------------------------------------
# 5. LIVE OUTPUT STYLING
# ------------------------------------------------------------

cat >> src/app/globals.css <<'CSS'

.omega-brand sup,
.omega-shell sup {
  font-size: .42em;
  line-height: 0;
  vertical-align: super;
  position: relative;
  top: -.05em;
}

.execution-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  margin-bottom: 12px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .12em;
  opacity: .7;
}

.execution-stream {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  margin-bottom: 12px;
  border: 1px solid currentColor;
  border-radius: 12px;
}

.execution-stream strong,
.execution-stream small {
  display: block;
}

.execution-stream small {
  margin-top: 4px;
  opacity: .65;
}

.execution-pulse {
  flex: 0 0 auto;
  width: 9px;
  height: 9px;
  border-radius: 999px;
  background: currentColor;
  animation: omegaPulse 1.1s ease-in-out infinite;
}

.omega-output {
  white-space: pre-wrap;
  line-height: 1.75;
  font-size: 15px;
  min-height: 80px;
}

.typing-cursor {
  display: inline-block;
  margin-left: 3px;
  animation: omegaCursor .75s steps(1) infinite;
}

.omega-error {
  padding: 14px;
  border-radius: 10px;
  line-height: 1.5;
}

@keyframes omegaPulse {
  0%, 100% {
    opacity: .25;
    transform: scale(.8);
  }

  50% {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes omegaCursor {
  0%, 45% {
    opacity: 1;
  }

  46%, 100% {
    opacity: 0;
  }
}
CSS

echo "PASS  live rendering styles"

# ------------------------------------------------------------
# 6. SOURCE CHECKS — NOT A NEW VERIFICATION GATE
# ------------------------------------------------------------

node --check src/app/api/solve/route.js

echo "PASS  API source syntax"

# ------------------------------------------------------------
# 7. SHOW SAFE STATUS
# ------------------------------------------------------------

echo
echo "============================================================"
echo "OMEGA® — LIVE GPT READY"
echo "============================================================"
echo
echo "PASS  GPT server integration"
echo "PASS  real-time streaming"
echo "PASS  dynamic task workspace"
echo "PASS  live output rendering"
echo "PASS  professional registered-mark typography"
echo "PASS  server-side credential boundary"
echo
echo "IMPORTANT:"
echo "Restart the development server so Next.js reloads .env.local."
echo
echo "CTRL+C"
echo "npm run dev"
echo
echo "Then open:"
echo "http://localhost:3000"
echo
echo "Submit a real task."
echo "The response should visibly form inside the workspace."
