#!/data/data/com.termux/files/usr/bin/bash
set -e

cd "$HOME/omega"

echo "========================================"
echo " OMEGA® ENGINE UPGRADE"
echo "========================================"

npm install better-sqlite3

mkdir -p src/lib/engine
mkdir -p src/app/api/engine/status
mkdir -p src/app/api/engine/modules
mkdir -p src/app/api/engine/events
mkdir -p src/app/api/engine/tasks
mkdir -p data

cat > src/lib/engine/database.js <<'JS'
import Database from "better-sqlite3";
import path from "path";

const dbPath = path.join(process.cwd(), "data", "omega.db");

const db = new Database(dbPath);

db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS system (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS modules (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    payload TEXT,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    status TEXT NOT NULL,
    payload TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    actor TEXT NOT NULL,
    payload TEXT,
    created_at TEXT NOT NULL
  );
`);

export default db;
JS

cat > src/lib/engine/core.js <<'JS'
import db from "./database";

function now() {
  return new Date().toISOString();
}

export function initializeEngine() {
  const timestamp = now();

  const defaults = [
    ["engine.version", "1.0.0"],
    ["engine.codename", "Genesis"],
    ["engine.status", "ONLINE"],
    ["engine.platform", "OMEGA®"],
  ];

  const stmt = db.prepare(`
    INSERT INTO system (key, value, updated_at)
    VALUES (?, ?, ?)
    ON CONFLICT(key)
    DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
  `);

  const transaction = db.transaction(() => {
    for (const item of defaults) {
      stmt.run(item[0], item[1], timestamp);
    }
  });

  transaction();
}

export function getSystemState() {
  initializeEngine();

  const rows = db
    .prepare("SELECT key, value, updated_at FROM system")
    .all();

  return Object.fromEntries(
    rows.map((row) => [
      row.key,
      {
        value: row.value,
        updated_at: row.updated_at,
      },
    ])
  );
}

export function registerModule({
  id,
  name,
  version = "1.0.0",
  status = "ONLINE",
}) {
  const timestamp = now();

  db.prepare(`
    INSERT INTO modules
      (id, name, version, status, created_at, updated_at)
    VALUES
      (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id)
    DO UPDATE SET
      name = excluded.name,
      version = excluded.version,
      status = excluded.status,
      updated_at = excluded.updated_at
  `).run(
    id,
    name,
    version,
    status,
    timestamp,
    timestamp
  );

  return getModule(id);
}

export function getModule(id) {
  return db
    .prepare("SELECT * FROM modules WHERE id = ?")
    .get(id);
}

export function getModules() {
  return db
    .prepare("SELECT * FROM modules ORDER BY id")
    .all();
}

export function emitEvent(type, payload = {}) {
  const result = db
    .prepare(`
      INSERT INTO events (type, payload, created_at)
      VALUES (?, ?, ?)
    `)
    .run(
      type,
      JSON.stringify(payload),
      now()
    );

  return db
    .prepare("SELECT * FROM events WHERE id = ?")
    .get(result.lastInsertRowid);
}

export function getEvents(limit = 100) {
  return db
    .prepare(`
      SELECT *
      FROM events
      ORDER BY id DESC
      LIMIT ?
    `)
    .all(limit);
}

export function createTask(name, payload = {}) {
  const timestamp = now();

  const result = db
    .prepare(`
      INSERT INTO tasks
        (name, status, payload, created_at, updated_at)
      VALUES
        (?, 'QUEUED', ?, ?, ?)
    `)
    .run(
      name,
      JSON.stringify(payload),
      timestamp,
      timestamp
    );

  return db
    .prepare("SELECT * FROM tasks WHERE id = ?")
    .get(result.lastInsertRowid);
}

export function getTasks(limit = 100) {
  return db
    .prepare(`
      SELECT *
      FROM tasks
      ORDER BY id DESC
      LIMIT ?
    `)
    .all(limit);
}

export function audit(action, actor = "system", payload = {}) {
  return db
    .prepare(`
      INSERT INTO audit_log
        (action, actor, payload, created_at)
      VALUES
        (?, ?, ?, ?)
    `)
    .run(
      action,
      actor,
      JSON.stringify(payload),
      now()
    );
}
JS

cat > src/lib/engine/bootstrap.js <<'JS'
import {
  initializeEngine,
  registerModule,
  emitEvent,
  audit,
} from "./core";

let booted = false;

export function bootOmega() {
  if (booted) return;

  initializeEngine();

  const modules = [
    ["core", "OMEGA CORE"],
    ["data", "DATA"],
    ["network", "NETWORK"],
    ["security", "SECURITY"],
    ["automation", "AUTOMATION"],
    ["extensions", "EXTENSIONS"],
  ];

  for (const [id, name] of modules) {
    registerModule({
      id,
      name,
      version: "1.0.0",
      status: id === "core" ? "ONLINE" : "READY",
    });
  }

  emitEvent("ENGINE_BOOT", {
    version: "1.0.0",
    codename: "Genesis",
  });

  audit("ENGINE_BOOT", "system", {
    platform: "OMEGA®",
  });

  booted = true;
}
JS

cat > src/app/api/engine/status/route.js <<'JS'
import { NextResponse } from "next/server";
import {
  getSystemState,
  getModules,
  getEvents,
  getTasks,
} from "@/lib/engine/core";
import { bootOmega } from "@/lib/engine/bootstrap";

export async function GET() {
  bootOmega();

  return NextResponse.json({
    ok: true,
    engine: {
      status: "ONLINE",
      system: getSystemState(),
    },
    modules: getModules(),
    events: getEvents(10),
    tasks: getTasks(10),
    timestamp: new Date().toISOString(),
  });
}
JS

cat > src/app/api/engine/modules/route.js <<'JS'
import { NextResponse } from "next/server";
import {
  getModules,
  registerModule,
} from "@/lib/engine/core";
import { bootOmega } from "@/lib/engine/bootstrap";

export async function GET() {
  bootOmega();

  return NextResponse.json({
    ok: true,
    modules: getModules(),
  });
}

export async function POST(request) {
  bootOmega();

  const body = await request.json();

  if (!body.id || !body.name) {
    return NextResponse.json(
      {
        ok: false,
        error: "id and name are required",
      },
      { status: 400 }
    );
  }

  const module = registerModule({
    id: body.id,
    name: body.name,
    version: body.version || "1.0.0",
    status: body.status || "READY",
  });

  return NextResponse.json({
    ok: true,
    module,
  });
}
JS

cat > src/app/api/engine/events/route.js <<'JS'
import { NextResponse } from "next/server";
import {
  emitEvent,
  getEvents,
} from "@/lib/engine/core";
import { bootOmega } from "@/lib/engine/bootstrap";

export async function GET() {
  bootOmega();

  return NextResponse.json({
    ok: true,
    events: getEvents(),
  });
}

export async function POST(request) {
  bootOmega();

  const body = await request.json();

  if (!body.type) {
    return NextResponse.json(
      {
        ok: false,
        error: "event type is required",
      },
      { status: 400 }
    );
  }

  return NextResponse.json({
    ok: true,
    event: emitEvent(
      body.type,
      body.payload || {}
    ),
  });
}
JS

cat > src/app/api/engine/tasks/route.js <<'JS'
import { NextResponse } from "next/server";
import {
  createTask,
  getTasks,
} from "@/lib/engine/core";
import { bootOmega } from "@/lib/engine/bootstrap";

export async function GET() {
  bootOmega();

  return NextResponse.json({
    ok: true,
    tasks: getTasks(),
  });
}

export async function POST(request) {
  bootOmega();

  const body = await request.json();

  if (!body.name) {
    return NextResponse.json(
      {
        ok: false,
        error: "task name is required",
      },
      { status: 400 }
    );
  }

  return NextResponse.json({
    ok: true,
    task: createTask(
      body.name,
      body.payload || {}
    ),
  });
}
JS

cat > src/app/dashboard/page.js <<'JS'
"use client";

import { useEffect, useState } from "react";

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [error, setError] = useState("");

  async function load() {
    try {
      const response = await fetch("/api/engine/status");

      if (!response.ok) {
        throw new Error("Engine request failed");
      }

      setData(await response.json());
    } catch (err) {
      setError(err.message);
    }
  }

  useEffect(() => {
    load();

    const timer = setInterval(load, 5000);

    return () => clearInterval(timer);
  }, []);

  return (
    <main className="simplePage">
      <a href="/">← OMEGA®</a>

      <div className="eyebrow">
        OMEGA® / ENGINE
      </div>

      <h1>Engine Dashboard</h1>

      {error && (
        <div className="placeholder">
          <strong>ENGINE ERROR</strong>
          <span>{error}</span>
        </div>
      )}

      {data && (
        <>
          <div className="stats">
            <div className="stat">
              <span>ENGINE</span>
              <strong>{data.engine.status}</strong>
            </div>

            <div className="stat">
              <span>MODULES</span>
              <strong>{data.modules.length}</strong>
            </div>

            <div className="stat">
              <span>EVENTS</span>
              <strong>{data.events.length}</strong>
            </div>

            <div className="stat">
              <span>TASKS</span>
              <strong>{data.tasks.length}</strong>
            </div>
          </div>

          <div className="sectionHeader">
            <div>
              <div className="eyebrow">
                LIVE REGISTRY
              </div>
              <h3>Engine Modules</h3>
            </div>
          </div>

          <div className="moduleList">
            {data.modules.map((module) => (
              <div
                className="listItem"
                key={module.id}
              >
                <strong>{module.name}</strong>
                <span>
                  v{module.version}
                </span>
                <small>
                  {module.status}
                </small>
              </div>
            ))}
          </div>
        </>
      )}
    </main>
  );
}
JS

echo
echo "Validating OMEGA® Engine..."
npm run build

echo
echo "========================================"
echo " OMEGA® ENGINE INSTALLED"
echo "========================================"
echo
echo "Start:"
echo "  ~/launch-omega.sh"
echo
echo "Engine:"
echo "  http://localhost:3000/dashboard"
echo
echo "Health:"
echo "  http://localhost:3000/api/engine/status"
echo
echo "Database:"
echo "  $HOME/omega/data/omega.db"
echo
