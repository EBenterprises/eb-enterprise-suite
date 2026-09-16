#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

clear

echo "============================================================"
echo "              OMEGA® — GPT RUNTIME"
echo "============================================================"
echo

mkdir -p src/app/api/solve

# ------------------------------------------------------------
# SERVER: REAL GPT STREAM
# ------------------------------------------------------------

cat > src/app/api/solve/route.js <<'JS'
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const SYSTEM_PROMPT = `
You are the intelligence layer inside OMEGA®.

OMEGA® is a professional generative intelligence system.
Its purpose is not merely to answer questions.

For every user request:

1. Understand the objective.
2. Extract requirements and constraints.
3. Identify unknowns.
4. Generate possible approaches.
5. Invent useful mechanisms where existing approaches are insufficient.
6. Evaluate alternatives.
7. Select and synthesize the strongest direction.
8. Produce concrete next actions.
9. Continue developing the user's idea rather than stopping at a summary.

Think progressively and visibly.
Do not pretend work happened when it did not.
Do not fabricate external actions.
When implementation is requested, provide implementation-ready decisions.

Maintain professional product, engineering, security, accessibility,
privacy, governance, and intellectual-property standards.

OMEGA® is the orchestration layer.
GPT is the reasoning and generative intelligence layer.
`;

export async function POST(request) {
  try {
    const body = await request.json();
    const task = String(body?.request || "").trim();

    if (!task) {
      return NextResponse.json(
        { error: "A task is required." },
        { status: 400 }
      );
    }

    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        {
          error:
            "OPENAI_API_KEY is not configured. Configure the server environment before executing GPT tasks."
        },
        { status: 503 }
      );
    }

    const model =
      process.env.OMEGA_GPT_MODEL ||
      "gpt-5";

    const upstream = await fetch(
      "https://api.openai.com/v1/responses",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          stream: true,
          input: [
            {
              role: "system",
              content: SYSTEM_PROMPT,
            },
            {
              role: "user",
              content: task,
            },
          ],
        }),
      }
    );

    if (!upstream.ok) {
      const errorText = await upstream.text();

      return NextResponse.json(
        {
          error: `GPT API error ${upstream.status}: ${errorText}`
        },
        { status: upstream.status }
      );
    }

    const encoder = new TextEncoder();
    const decoder = new TextDecoder();

    const stream = new ReadableStream({
      async start(controller) {
        const reader = upstream.body.getReader();
        let buffer = "";

        try {
          while (true) {
            const { done, value } = await reader.read();

            if (done) break;

            buffer += decoder.decode(value, {
              stream: true
            });

            const lines = buffer.split("\n");
            buffer = lines.pop() || "";

            for (const line of lines) {
              const trimmed = line.trim();

              if (!trimmed.startsWith("data:")) {
                continue;
              }

              const payload = trimmed.slice(5).trim();

              if (!payload || payload === "[DONE]") {
                continue;
              }

              try {
                const event = JSON.parse(payload);

                if (
                  event.type ===
                  "response.output_text.delta"
                ) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${JSON.stringify({
                        type: "delta",
                        text: event.delta || ""
                      })}\n\n`
                    )
                  );
                }

                if (
                  event.type ===
                  "response.completed"
                ) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${JSON.stringify({
                        type: "complete"
                      })}\n\n`
                    )
                  );
                }

                if (
                  event.type ===
                  "response.failed"
                ) {
                  controller.enqueue(
                    encoder.encode(
                      `data: ${JSON.stringify({
                        type: "error",
                        message:
                          event.response?.error?.message ||
                          "GPT execution failed."
                      })}\n\n`
                    )
                  );
                }
              } catch {
                // Ignore malformed SSE fragments.
              }
            }
          }
        } catch (error) {
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({
                type: "error",
                message:
                  error?.message ||
                  "GPT stream interrupted."
              })}\n\n`
            )
          );
        } finally {
          controller.close();
        }
      }
    });

    return new Response(stream, {
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
        error:
          error?.message ||
          "OMEGA® execution failed."
      },
      { status: 500 }
    );
  }
}
JS

# ------------------------------------------------------------
# CLIENT: REAL-TIME GENERATION
# ------------------------------------------------------------

cat > src/app/page.js <<'JS'
"use client";

import { useRef, useState } from "react";

const stages = [
  "ANALYZING",
  "DECOMPOSING",
  "EXPLORING",
  "INVENTING",
  "EVALUATING",
  "SYNTHESIZING"
];

export default function Home() {
  const [task, setTask] = useState("");
  const [running, setRunning] = useState(false);
  const [stage, setStage] = useState("READY");
  const [output, setOutput] = useState("");
  const [error, setError] = useState("");

  const stageTimer = useRef(null);

  function startStages() {
    let index = 0;

    setStage(stages[index]);

    stageTimer.current = setInterval(() => {
      index += 1;

      if (index >= stages.length) {
        clearInterval(stageTimer.current);
        return;
      }

      setStage(stages[index]);
    }, 1400);
  }

  function stopStages(finalStage = "COMPLETE") {
    if (stageTimer.current) {
      clearInterval(stageTimer.current);
      stageTimer.current = null;
    }

    setStage(finalStage);
  }

  async function execute() {
    const request = task.trim();

    if (!request || running) {
      return;
    }

    setRunning(true);
    setOutput("");
    setError("");

    startStages();

    try {
      const response = await fetch("/api/solve", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          request
        })
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));

        throw new Error(
          data.error ||
          `OMEGA® execution failed (${response.status}).`
        );
      }

      if (!response.body) {
        throw new Error("GPT stream was unavailable.");
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();

        if (done) break;

        buffer += decoder.decode(value, {
          stream: true
        });

        const events = buffer.split("\n\n");
        buffer = events.pop() || "";

        for (const event of events) {
          const line = event
            .split("\n")
            .find((item) => item.startsWith("data:"));

          if (!line) continue;

          try {
            const payload = JSON.parse(
              line.slice(5).trim()
            );

            if (payload.type === "delta") {
              setOutput((current) =>
                current + payload.text
              );
            }

            if (payload.type === "error") {
              throw new Error(
                payload.message ||
                "GPT stream failed."
              );
            }

            if (payload.type === "complete") {
              stopStages("COMPLETE");
            }
          } catch (eventError) {
            if (
              eventError instanceof Error &&
              eventError.message !==
                "Unexpected end of JSON input"
            ) {
              throw eventError;
            }
          }
        }
      }

      stopStages("COMPLETE");
    } catch (executionError) {
      stopStages("ERROR");

      setError(
        executionError?.message ||
        "OMEGA® execution failed."
      );
    } finally {
      setRunning(false);
    }
  }

  return (
    <main className="omega-shell">
      <header className="omega-header">
        <div>
          <div className="omega-brand">
            OMEGA<sup>®</sup>
          </div>

          <div className="omega-subtitle">
            Generative Intelligence Workspace
          </div>
        </div>

        <div className="omega-status">
          <span
            className={
              running
                ? "status-dot live"
                : "status-dot"
            }
          />

          {stage}
        </div>
      </header>

      <section className="omega-workspace">
        <div className="eyebrow">
          PRIVATE INTELLIGENCE PORTAL
        </div>

        <h1>
          Build the idea
          <br />
          in real time.
        </h1>

        <p className="omega-description">
          Give OMEGA<sup>®</sup> an objective.
          The intelligence layer develops the
          request progressively while the workspace
          renders the result as it is generated.
        </p>

        <div className="omega-console">
          <textarea
            value={task}
            onChange={(event) =>
              setTask(event.target.value)
            }
            placeholder="What do you want OMEGA® to create, solve, design, improve, or invent?"
            disabled={running}
            onKeyDown={(event) => {
              if (
                event.key === "Enter" &&
                (event.ctrlKey || event.metaKey)
              ) {
                execute();
              }
            }}
          />

          <button
            type="button"
            onClick={execute}
            disabled={
              !task.trim() || running
            }
          >
            {running
              ? `OMEGA® · ${stage}`
              : "EXECUTE"}
          </button>
        </div>

        {(running || output || error) && (
          <section className="execution-panel">
            <div className="execution-header">
              <span>
                LIVE OMEGA<sup>®</sup> EXECUTION
              </span>

              <span>{stage}</span>
            </div>

            {running && (
              <div className="execution-stream">
                <div className="thinking">
                  <span />
                  <span />
                  <span />
                </div>

                <div className="execution-label">
                  GPT INTELLIGENCE ACTIVE
                </div>
              </div>
            )}

            {output && (
              <article className="gpt-output">
                {output}
                {running && (
                  <span className="cursor" />
                )}
              </article>
            )}

            {error && (
              <div className="execution-error">
                {error}
              </div>
            )}
          </section>
        )}
      </section>

      <footer>
        <span>OMEGA<sup>®</sup></span>
        <span>Secure Workspace</span>
        <span>Privacy</span>
        <span>Terms</span>
        <span>
          © {new Date().getFullYear()} All Rights Reserved
        </span>
      </footer>
    </main>
  );
}
JS

# ------------------------------------------------------------
# PROFESSIONAL GLOBAL STYLING
# ------------------------------------------------------------

cat > src/app/globals.css <<'CSS'
:root {
  --bg: #07090d;
  --panel: #0d1118;
  --panel-2: #111722;
  --border: #202936;
  --text: #f5f7fa;
  --muted: #8b96a6;
  --accent: #dce7f7;
  --success: #65e6a0;
  --danger: #ff7777;
}

* {
  box-sizing: border-box;
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

body {
  min-height: 100vh;
}

button,
textarea {
  font: inherit;
}

.omega-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.omega-header {
  width: min(1440px, 100%);
  margin: 0 auto;
  padding: 28px 36px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border);
}

.omega-brand {
  font-size: 25px;
  font-weight: 760;
  letter-spacing: -0.04em;
}

.omega-brand sup,
footer sup {
  font-size: 0.42em;
  vertical-align: super;
  line-height: 0;
  margin-left: 0.08em;
}

.omega-subtitle {
  margin-top: 5px;
  color: var(--muted);
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.omega-status {
  display: flex;
  align-items: center;
  gap: 9px;
  color: var(--muted);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.1em;
}

.status-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--success);
}

.status-dot.live {
  animation: pulse 1.1s infinite;
}

.omega-workspace {
  width: min(1120px, calc(100% - 48px));
  margin: 0 auto;
  padding: 100px 0 80px;
  flex: 1;
}

.eyebrow {
  color: var(--muted);
  font-size: 11px;
  font-weight: 750;
  letter-spacing: 0.14em;
}

h1 {
  margin: 18px 0 25px;
  font-size: clamp(48px, 7vw, 92px);
  line-height: 0.96;
  letter-spacing: -0.065em;
  font-weight: 720;
}

.omega-description {
  max-width: 700px;
  color: var(--muted);
  font-size: 17px;
  line-height: 1.7;
}

.omega-console {
  margin-top: 42px;
  border: 1px solid var(--border);
  background: var(--panel);
  border-radius: 16px;
  padding: 18px;
}

textarea {
  width: 100%;
  min-height: 150px;
  resize: vertical;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--text);
  font-size: 17px;
  line-height: 1.65;
}

textarea::placeholder {
  color: #586272;
}

button {
  margin-top: 15px;
  width: 100%;
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 15px 18px;
  background: var(--accent);
  color: #07090d;
  cursor: pointer;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.1em;
}

button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.execution-panel {
  margin-top: 22px;
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--panel);
  overflow: hidden;
}

.execution-header {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  padding: 14px 18px;
  border-bottom: 1px solid var(--border);
  color: var(--muted);
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.1em;
}

.execution-stream {
  padding: 16px 18px;
  border-bottom: 1px solid var(--border);
}

.thinking {
  display: flex;
  gap: 6px;
}

.thinking span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--text);
  animation: thinking 1s infinite;
}

.thinking span:nth-child(2) {
  animation-delay: 0.15s;
}

.thinking span:nth-child(3) {
  animation-delay: 0.3s;
}

.execution-label {
  margin-top: 10px;
  color: var(--muted);
  font-size: 10px;
  letter-spacing: 0.09em;
}

.gpt-output {
  padding: 26px;
  white-space: pre-wrap;
  font-size: 16px;
  line-height: 1.75;
}

.cursor {
  display: inline-block;
  width: 7px;
  height: 19px;
  margin-left: 4px;
  vertical-align: -3px;
  background: var(--text);
  animation: blink 0.8s infinite;
}

.execution-error {
  padding: 20px;
  color: var(--danger);
  line-height: 1.6;
}

footer {
  width: min(1440px, 100%);
  margin: 0 auto;
  padding: 22px 36px;
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  color: var(--muted);
  border-top: 1px solid var(--border);
  font-size: 11px;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }

  50% {
    opacity: 0.35;
  }
}

@keyframes thinking {
  0%,
  100% {
    opacity: 0.25;
    transform: translateY(0);
  }

  50% {
    opacity: 1;
    transform: translateY(-3px);
  }
}

@keyframes blink {
  0%,
  45% {
    opacity: 1;
  }

  46%,
  100% {
    opacity: 0;
  }
}

@media (max-width: 700px) {
  .omega-header {
    padding: 22px 20px;
  }

  .omega-workspace {
    width: min(100% - 32px, 1120px);
    padding: 64px 0;
  }

  h1 {
    font-size: 54px;
  }

  footer {
    padding: 20px;
  }
}
CSS

# ------------------------------------------------------------
# ENVIRONMENT
# ------------------------------------------------------------

touch .env.local

grep -q '^OMEGA_GPT_MODEL=' .env.local 2>/dev/null || \
  printf '\nOMEGA_GPT_MODEL=gpt-5\n' >> .env.local

# Remove duplicate empty key placeholders created by the previous script.
python - <<'PY'
from pathlib import Path

p = Path(".env.local")
lines = p.read_text().splitlines()

seen = set()
out = []

for line in lines:
    if line.startswith("OPENAI_API_KEY="):
        if "OPENAI_API_KEY" in seen:
            continue
        seen.add("OPENAI_API_KEY")
    out.append(line)

p.write_text("\n".join(out) + "\n")
PY

# ------------------------------------------------------------
# VERIFY ONLY WHAT IS REQUIRED TO RUN
# ------------------------------------------------------------

node --check src/app/api/solve/route.js
node --check src/omega.js

echo
echo "============================================================"
echo "OMEGA® GPT RUNTIME INSTALLED"
echo "============================================================"
echo
echo "REAL GPT STREAM:       READY"
echo "LIVE UI RENDERING:     READY"
echo "DYNAMIC TASKS:         READY"
echo "OMEGA® CORE:           PRESERVED"
echo
echo "MODEL:"
grep '^OMEGA_GPT_MODEL=' .env.local
echo

if grep -q '^OPENAI_API_KEY=.\+' .env.local 2>/dev/null; then
  echo "API KEY: CONFIGURED"
else
  echo "API KEY: NOT CONFIGURED"
  echo
  echo "Configure the key in .env.local or the Termux environment."
fi

echo
echo "START:"
echo "npm run dev"
echo
echo "============================================================"
