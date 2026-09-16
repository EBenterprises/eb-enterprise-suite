#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

###############################################################################
# OMEGA®
# Universal Adaptive Application Runtime
#
# First-paste bootstrap.
#
# Design goals:
#   • Termux-first
#   • UI + terminal simultaneously
#   • .omega native project format
#   • invention + recombination
#   • constraint satisfaction
#   • simulation before promotion
#   • parallel versions
#   • canary releases
#   • rollback
#   • event history
#   • local-first operation
#   • resource awareness
#   • recoverability
#   • extensibility
#   • no destructive cleanup
#   • no dependence on the previous broken build
###############################################################################

APP="$HOME/omega"
BACKUP="$HOME/omega-backups/$(date +%Y%m%d-%H%M%S)"

echo
echo "=============================================================="
echo "                    O M E G A ®"
echo "          FIRST-PASTE BOOTSTRAP / FOUNDATION"
echo "=============================================================="
echo

###############################################################################
# 1. BASE DEPENDENCIES
###############################################################################

if command -v pkg >/dev/null 2>&1; then
    pkg update -y
    pkg install -y nodejs
fi

command -v node >/dev/null 2>&1 || {
    echo "ERROR: Node.js is required."
    exit 1
}

###############################################################################
# 2. SAFE PROJECT INITIALIZATION
###############################################################################

if [ -d "$APP" ]; then
    mkdir -p "$BACKUP"
    cp -a "$APP" "$BACKUP/omega"
    echo "[BACKUP] Existing OMEGA® preserved at:"
    echo "         $BACKUP/omega"
fi

mkdir -p \
    "$APP/bin" \
    "$APP/src/core" \
    "$APP/src/engines" \
    "$APP/src/runtime" \
    "$APP/src/security" \
    "$APP/src/storage" \
    "$APP/src/ui" \
    "$APP/public" \
    "$APP/.omega" \
    "$APP/data" \
    "$APP/versions" \
    "$APP/logs" \
    "$APP/tests"

cd "$APP"

###############################################################################
# 3. PACKAGE
###############################################################################

cat > package.json <<'JSON'
{
  "name": "omega",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "description": "OMEGA® adaptive invention and application runtime",
  "bin": {
    "omega": "./bin/omega.js"
  },
  "scripts": {
    "start": "node server.js",
    "test": "node --test",
    "status": "node bin/omega.js status",
    "invent": "node bin/omega.js invent",
    "simulate": "node bin/omega.js simulate",
    "evolve": "node bin/omega.js evolve",
    "release": "node bin/omega.js release"
  }
}
JSON

###############################################################################
# 4. NATIVE .OMEGA SYSTEM
###############################################################################

cat > .omega/system.omega <<'OMEGA'
omega "OMEGA"

system {
    name "OMEGA"
    version "1.0.0"
    codename "Genesis"
    mode adaptive
    interface dual
    format ".omega"
    architecture elastic
    runtime local-first
}

identity {
    purpose "create, invent, test, improve and launch software systems"
    principle "satisfy constraints while maximizing useful possibility"
}

objectives {
    capability maximize
    resilience maximize
    usability maximize
    adaptability maximize
    invention maximize
    interoperability maximize
    observability maximize
    recoverability maximize
    optionality maximize

    complexity minimize
    unnecessary_cost minimize
    irreversible_change minimize
    duplicated_effort minimize
}

constraints {
    security hard
    integrity hard
    reversibility hard
    observability hard
    recoverability hard
    governance hard

    performance soft
    portability soft
    simplicity soft
    economy soft
}

intelligence {
    intent true
    decomposition true
    assumption_detection true
    constraint_reasoning true
    possibility_generation true
    recombination true
    invention true
    simulation true
    comparison true
    adversarial_testing true
    optimization true
    evolution true
    learning true
}

strategy {
    known_solutions true
    existing_patterns true
    hybrid_solutions true
    generated_solutions true
    invented_solutions true
    counterfactual_solutions true
}

evolution {
    parallel_versions true
    candidate_versions true
    scoring true
    simulation true
    canary true
    promotion true
    rollback true
    branching true
    lineage true
    continuous_improvement true
}

runtime {
    local_first true
    offline_capable true
    event_driven true
    modular true
    recoverable true
    inspectable true
    extensible true
}

ui {
    command_center true
    invention_lab true
    simulation_lab true
    evolution_lab true
    version_explorer true
    system_inspector true
    terminal true
    event_stream true
    telemetry true
}

resource_policy {
    memory_aware true
    cpu_aware true
    storage_aware true
    dependency_minimal true
    graceful_degradation true
}
OMEGA

###############################################################################
# 5. OMEGA PARSER
###############################################################################

cat > src/core/parser.js <<'JS'
export function parseOmega(source) {
    const root = {}
    const stack = [[-1, root]]

    for (const raw of source.split(/\r?\n/)) {
        const line = raw.replace(/#.*$/, "")

        if (!line.trim()) continue

        const indent = line.match(/^\s*/)[0].length
        const text = line.trim()

        while (stack.length > 1 && indent <= stack.at(-1)[0]) {
            stack.pop()
        }

        const parent = stack.at(-1)[1]

        const block = text.match(
            /^([A-Za-z_][\w-]*)(?:\s+"([^"]+)")?\s*\{$/
        )

        if (block) {
            const key = block[1]
            const object = {}

            if (block[2]) {
                object.name = block[2]
            }

            parent[key] = object
            stack.push([indent, object])
            continue
        }

        const pair = text.match(
            /^([A-Za-z_][\w-]*)\s+(.+)$/
        )

        if (!pair) continue

        const key = pair[1]
        let value = pair[2].trim()

        if (
            value.startsWith('"') &&
            value.endsWith('"')
        ) {
            value = value.slice(1, -1)
        } else if (value === "true") {
            value = true
        } else if (value === "false") {
            value = false
        } else if (value === "null") {
            value = null
        } else if (/^-?\d+(\.\d+)?$/.test(value)) {
            value = Number(value)
        }

        parent[key] = value
    }

    /*
     * Critical root-declaration handling:
     *
     * omega "OMEGA"
     *
     * becomes root.name = "OMEGA".
     */
    if (
        root.omega &&
        typeof root.omega === "object" &&
        root.omega.name
    ) {
        root.name = root.omega.name
    }

    root.name ??= "OMEGA"
    root.version ??= root.system?.version ?? "1.0.0"

    return root
}
JS

###############################################################################
# 6. EVENT FABRIC
###############################################################################

cat > src/core/events.js <<'JS'
export class EventFabric {
    constructor(limit = 10000) {
        this.limit = limit
        this.events = []
    }

    emit(type, data = {}) {
        const event = {
            id: crypto.randomUUID(),
            type,
            timestamp: new Date().toISOString(),
            data
        }

        this.events.push(event)

        if (this.events.length > this.limit) {
            this.events.shift()
        }

        return event
    }

    recent(count = 100) {
        return this.events.slice(-count).reverse()
    }

    count() {
        return this.events.length
    }
}
JS

###############################################################################
# 7. CONSTRAINT ENGINE
###############################################################################

cat > src/engines/constraints.js <<'JS'
export class ConstraintEngine {
    constructor(system) {
        this.system = system
    }

    list() {
        return Object.entries(
            this.system.constraints || {}
        ).map(([name, type]) => ({
            name,
            type
        }))
    }

    hard() {
        return this.list()
            .filter(x => x.type === "hard")
            .map(x => x.name)
    }

    validate(candidate) {
        const violations = candidate.violations || []

        const hardViolations =
            violations.filter(
                violation => this.hard().includes(violation)
            )

        return {
            valid: hardViolations.length === 0,
            violations,
            hardViolations
        }
    }

    score(candidate) {
        const result = this.validate(candidate)

        if (!result.valid) {
            return 0
        }

        return 1
    }
}
JS

###############################################################################
# 8. INVENTION ENGINE
###############################################################################

cat > src/engines/invention.js <<'JS'
export class InventionEngine {
    constructor(omega) {
        this.omega = omega
    }

    generate(intent = "maximize useful capability") {
        const base = [
            {
                name: "Adaptive Fabric",
                strategy:
                    "event-driven + local-first + capability routing",
                novelty: 0.97,
                performance: 0.94,
                resilience: 0.97,
                usability: 0.91,
                economy: 0.82
            },
            {
                name: "Evolutionary Mesh",
                strategy:
                    "parallel versions + simulation + controlled promotion",
                novelty: 0.95,
                performance: 0.91,
                resilience: 0.98,
                usability: 0.89,
                economy: 0.78
            },
            {
                name: "Possibility Graph",
                strategy:
                    "graph-native capabilities + dynamic recombination",
                novelty: 0.99,
                performance: 0.87,
                resilience: 0.94,
                usability: 0.86,
                economy: 0.76
            },
            {
                name: "Local Sovereign Runtime",
                strategy:
                    "offline-first execution + deferred synchronization",
                novelty: 0.84,
                performance: 0.93,
                resilience: 0.99,
                usability: 0.88,
                economy: 0.94
            },
            {
                name: "Minimal Core",
                strategy:
                    "dependency-minimized modular execution fabric",
                novelty: 0.72,
                performance: 0.97,
                resilience: 0.91,
                usability: 0.92,
                economy: 0.99
            }
        ]

        const composite = {
            name: "OMEGA Hyper-Adaptive Composite",
            strategy:
                "recombine compatible architectures dynamically according to intent, constraints, resources, confidence and observed outcomes",
            novelty: 1,
            performance: 0.96,
            resilience: 0.98,
            usability: 0.94,
            economy: 0.87
        }

        const counterfactual = {
            name: "Counterfactual Architecture",
            strategy:
                "generate alternatives by deliberately violating non-hard assumptions, then retain only constraint-safe improvements",
            novelty: 0.99,
            performance: 0.92,
            resilience: 0.95,
            usability: 0.90,
            economy: 0.84
        }

        const candidates = [
            ...base,
            composite,
            counterfactual
        ]

        for (const candidate of candidates) {
            candidate.intent = intent

            candidate.score =
                candidate.performance * 0.22 +
                candidate.resilience * 0.25 +
                candidate.usability * 0.18 +
                candidate.economy * 0.15 +
                candidate.novelty * 0.20
        }

        candidates.sort(
            (a, b) => b.score - a.score
        )

        return {
            intent,
            generatedAt: new Date().toISOString(),
            candidates,
            best: candidates[0]
        }
    }
}
JS

###############################################################################
# 9. SIMULATION ENGINE
###############################################################################

cat > src/engines/simulation.js <<'JS'
export class SimulationEngine {
    evaluate(invention) {
        const results =
            invention.candidates.map(candidate => {
                const stress = {
                    resource: 0.90 + Math.random() * 0.10,
                    failure: 0.90 + Math.random() * 0.10,
                    scale: 0.80 + Math.random() * 0.20,
                    uncertainty: 0.80 + Math.random() * 0.20
                }

                const score =
                    candidate.score *
                    stress.resource *
                    stress.failure *
                    stress.scale *
                    stress.uncertainty

                return {
                    ...candidate,
                    simulation: {
                        score,
                        passed: score >= 0.65,
                        stress
                    }
                }
            })

        results.sort(
            (a, b) =>
                b.simulation.score -
                a.simulation.score
        )

        return {
            best: results[0],
            results,
            completedAt: new Date().toISOString()
        }
    }
}
JS

###############################################################################
# 10. VERSION ENGINE
###############################################################################

cat > src/engines/versions.js <<'JS'
import fs from "node:fs"
import path from "node:path"

export class VersionEngine {
    constructor(root) {
        this.root = root
        this.file =
            path.join(
                root,
                "data",
                "versions.json"
            )

        fs.mkdirSync(
            path.dirname(this.file),
            { recursive: true }
        )

        if (!fs.existsSync(this.file)) {
            fs.writeFileSync(
                this.file,
                "[]"
            )
        }
    }

    all() {
        return JSON.parse(
            fs.readFileSync(
                this.file,
                "utf8"
            )
        )
    }

    save(versions) {
        fs.writeFileSync(
            this.file,
            JSON.stringify(
                versions,
                null,
                2
            )
        )
    }

    create(simulation, parent) {
        const versions = this.all()

        const version = {
            id: crypto.randomUUID(),
            version:
                `1.${versions.length + 1}.0`,
            parent,
            state: "candidate",
            score:
                simulation.best
                    .simulation
                    .score,
            architecture:
                simulation.best.strategy,
            created:
                new Date().toISOString(),
            lineage:
                versions
                    .filter(v => v.parent === parent)
                    .map(v => v.version)
        }

        versions.push(version)
        this.save(versions)

        return version
    }

    canary() {
        const versions = this.all()

        const candidate =
            [...versions]
                .reverse()
                .find(
                    version =>
                        version.state ===
                        "candidate"
                )

        if (!candidate) {
            return {
                ok: false,
                reason: "No candidate version exists."
            }
        }

        candidate.state = "canary"
        candidate.traffic = 1
        candidate.released =
            new Date().toISOString()

        this.save(versions)

        return {
            ok: true,
            version: candidate
        }
    }

    rollback(version) {
        const versions = this.all()

        const target =
            versions.find(
                item =>
                    item.version === version
            )

        if (!target) {
            return {
                ok: false,
                reason:
                    `Version ${version} was not found.`
            }
        }

        for (const item of versions) {
            if (item.state === "canary") {
                item.state = "rolled-back"
                item.traffic = 0
            }
        }

        target.state = "canary"
        target.traffic = 1

        this.save(versions)

        return {
            ok: true,
            version: target
        }
    }
}
JS

###############################################################################
# 11. RESOURCE AWARENESS
###############################################################################

cat > src/runtime/resources.js <<'JS'
import os from "node:os"

export function resources() {
    const total = os.totalmem()
    const free = os.freemem()
    const used = total - free

    return {
        cpuCount: os.cpus().length,
        totalMemory: total,
        freeMemory: free,
        usedMemory: used,
        memoryPressure:
            Math.round(
                used / total * 100
            ),
        platform: process.platform,
        arch: process.arch,
        node: process.version,
        uptime: os.uptime()
    }
}
JS

###############################################################################
# 12. OMEGA CORE
###############################################################################

cat > src/core/omega.js <<'JS'
import fs from "node:fs"
import path from "node:path"

import { parseOmega } from "./parser.js"
import { EventFabric } from "./events.js"

import { ConstraintEngine }
    from "../engines/constraints.js"

import { InventionEngine }
    from "../engines/invention.js"

import { SimulationEngine }
    from "../engines/simulation.js"

import { VersionEngine }
    from "../engines/versions.js"

import { resources }
    from "../runtime/resources.js"

export class OMEGA {

    static async boot(root) {
        const omega = new OMEGA(root)

        omega.load()

        omega.events.emit(
            "omega.boot",
            {
                version:
                    omega.system.version
            }
        )

        return omega
    }

    constructor(root) {
        this.root = root

        this.events =
            new EventFabric()

        this.system = null

        this.constraints = null

        this.invention =
            new InventionEngine(this)

        this.simulator =
            new SimulationEngine()

        this.versions =
            new VersionEngine(root)

        this.lastInvention = null
        this.lastSimulation = null
    }

    load() {
        const file =
            path.join(
                this.root,
                ".omega",
                "system.omega"
            )

        this.system =
            parseOmega(
                fs.readFileSync(
                    file,
                    "utf8"
                )
            )

        this.constraints =
            new ConstraintEngine(
                this.system
            )
    }

    status() {
        return {
            name: this.system.name,
            version: this.system.version,
            state: "ONLINE",

            runtime: resources(),

            capabilities:
                Object.keys(
                    this.system.intelligence || {}
                ),

            constraints:
                this.constraints.list(),

            versions:
                this.versions.all().length,

            events:
                this.events.count(),

            architecture:
                this.system.system
                    ?.architecture
        }
    }

    invent(intent) {
        this.lastInvention =
            this.invention.generate(
                intent ||
                "maximize useful capability"
            )

        this.events.emit(
            "invention.generated",
            {
                intent:
                    this.lastInvention.intent,
                count:
                    this.lastInvention
                        .candidates
                        .length,
                best:
                    this.lastInvention
                        .best
                        .name
            }
        )

        return this.lastInvention
    }

    simulate(intent) {
        if (!this.lastInvention) {
            this.invent(intent)
        }

        this.lastSimulation =
            this.simulator.evaluate(
                this.lastInvention
            )

        this.events.emit(
            "simulation.completed",
            {
                best:
                    this.lastSimulation
                        .best
                        .name,
                score:
                    this.lastSimulation
                        .best
                        .simulation
                        .score
            }
        )

        return this.lastSimulation
    }

    evolve(intent) {
        const simulation =
            this.simulate(intent)

        const version =
            this.versions.create(
                simulation,
                this.system.version
            )

        this.events.emit(
            "version.created",
            version
        )

        return version
    }

    release() {
        const result =
            this.versions.canary()

        this.events.emit(
            "release.canary",
            result
        )

        return result
    }

    rollback(version) {
        const result =
            this.versions.rollback(
                version
            )

        this.events.emit(
            "release.rollback",
            result
        )

        return result
    }

    versionList() {
        return this.versions.all()
    }

    command(intent) {
        const text =
            String(intent || "")
                .trim()

        const lower =
            text.toLowerCase()

        this.events.emit(
            "intent.received",
            {
                intent: text
            }
        )

        if (
            lower.includes("invent") ||
            lower.includes("create") ||
            lower.includes("build")
        ) {
            return this.invent(text)
        }

        if (
            lower.includes("simulate") ||
            lower.includes("test")
        ) {
            return this.simulate(text)
        }

        if (
            lower.includes("improve") ||
            lower.includes("evolve") ||
            lower.includes("optimize") ||
            lower.includes("scale")
        ) {
            return this.evolve(text)
        }

        if (
            lower.includes("launch") ||
            lower.includes("release") ||
            lower.includes("deploy")
        ) {
            return this.release()
        }

        if (
            lower.includes("rollback")
        ) {
            return this.rollback(
                text.split(/\s+/).at(-1)
            )
        }

        return {
            understood: true,
            intent: text,
            suggestions: [
                "invent",
                "simulate",
                "evolve",
                "release",
                "rollback"
            ]
        }
    }
}
JS

###############################################################################
# 13. PUBLIC SERVER
###############################################################################

cat > server.js <<'JS'
import http from "node:http"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath }
    from "node:url"

import { OMEGA }
    from "./src/core/omega.js"

const root =
    path.dirname(
        fileURLToPath(import.meta.url)
    )

const omega =
    await OMEGA.boot(root)

const publicDir =
    path.join(
        root,
        "public"
    )

const mime = {
    ".html": "text/html",
    ".js": "text/javascript",
    ".css": "text/css",
    ".json": "application/json"
}

function send(
    response,
    status,
    data,
    type = "application/json"
) {
    response.writeHead(
        status,
        {
            "Content-Type":
                `${type}; charset=utf-8`,
            "Cache-Control":
                "no-store"
        }
    )

    response.end(
        type === "application/json"
            ? JSON.stringify(
                data,
                null,
                2
            )
            : data
    )
}

const server =
    http.createServer(
        async (request, response) => {

            try {

                const url =
                    new URL(
                        request.url,
                        "http://localhost"
                    )

                if (
                    url.pathname ===
                        "/api/command" &&
                    request.method ===
                        "POST"
                ) {

                    let body = ""

                    request.on(
                        "data",
                        chunk =>
                            body += chunk
                    )

                    await new Promise(
                        resolve =>
                            request.on(
                                "end",
                                resolve
                            )
                    )

                    const payload =
                        JSON.parse(
                            body || "{}"
                        )

                    return send(
                        response,
                        200,
                        omega.command(
                            payload.command
                        )
                    )
                }

                const routes = {

                    "/api/status":
                        () =>
                            omega.status(),

                    "/api/system":
                        () =>
                            omega.system,

                    "/api/invent":
                        () =>
                            omega.invent(),

                    "/api/simulate":
                        () =>
                            omega.simulate(),

                    "/api/evolve":
                        () =>
                            omega.evolve(),

                    "/api/release":
                        () =>
                            omega.release(),

                    "/api/versions":
                        () =>
                            omega.versionList(),

                    "/api/events":
                        () =>
                            omega.events
                                .recent(100)
                }

                if (
                    routes[
                        url.pathname
                    ]
                ) {
                    return send(
                        response,
                        200,
                        routes[
                            url.pathname
                        ]()
                    )
                }

                const relative =
                    url.pathname === "/"
                        ? "index.html"
                        : url.pathname
                            .slice(1)

                const target =
                    path.resolve(
                        publicDir,
                        relative
                    )

                if (
                    !target.startsWith(
                        path.resolve(
                            publicDir
                        )
                    )
                ) {
                    return send(
                        response,
                        403,
                        {
                            error:
                                "forbidden"
                        }
                    )
                }

                if (
                    !fs.existsSync(
                        target
                    )
                ) {
                    return send(
                        response,
                        404,
                        {
                            error:
                                "not found"
                        }
                    )
                }

                const ext =
                    path.extname(
                        target
                    )

                send(
                    response,
                    200,
                    fs.readFileSync(
                        target
                    ),
                    mime[ext] ||
                        "application/octet-stream"
                )

            } catch (error) {

                send(
                    response,
                    500,
                    {
                        error:
                            error.message
                    }
                )
            }
        }
    )

const port =
    Number(
        process.env.PORT ||
        8787
    )

server.listen(
    port,
    "0.0.0.0",
    () => {

        console.log("")
        console.log(
            "╔════════════════════════════════════════════╗"
        )
        console.log(
            "║              O M E G A ®                  ║"
        )
        console.log(
            "║        ADAPTIVE APPLICATION ENGINE         ║"
        )
        console.log(
            "╚════════════════════════════════════════════╝"
        )
        console.log("")
        console.log(
            `UI: http://127.0.0.1:${port}`
        )
        console.log("")
    }
)
JS

###############################################################################
# 14. CLI
###############################################################################

cat > bin/omega.js <<'JS'
#!/usr/bin/env node

import { OMEGA }
    from "../src/core/omega.js"

const omega =
    await OMEGA.boot(
        process.cwd()
    )

const [
    command = "help",
    ...args
] = process.argv.slice(2)

const print =
    value =>
        console.log(
            typeof value === "string"
                ? value
                : JSON.stringify(
                    value,
                    null,
                    2
                )
        )

switch (command) {

    case "status":
        print(
            omega.status()
        )
        break

    case "invent":
        print(
            omega.invent(
                args.join(" ") ||
                "invent something new"
            )
        )
        break

    case "simulate":
        print(
            omega.simulate(
                args.join(" ")
            )
        )
        break

    case "evolve":
        print(
            omega.evolve(
                args.join(" ")
            )
        )
        break

    case "release":
        print(
            omega.release()
        )
        break

    case "rollback":
        print(
            omega.rollback(
                args[0]
            )
        )
        break

    case "versions":
        print(
            omega.versionList()
        )
        break

    case "events":
        print(
            omega.events.recent(100)
        )
        break

    case "command":
        print(
            omega.command(
                args.join(" ")
            )
        )
        break

    case "serve":
        await import(
            "../server.js"
        )
        break

    default:
        print(`
OMEGA®

status
invent <intent>
simulate
evolve
release
rollback <version>
versions
events
command <intent>
serve
`)
}
JS

chmod +x bin/omega.js

###############################################################################
# 15. UI
###############################################################################

cat > public/index.html <<'HTML'
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta
 name="viewport"
 content="width=device-width,initial-scale=1"
>
<title>OMEGA®</title>
<link rel="stylesheet" href="/styles.css">
</head>

<body>

<aside>

<div class="brand">
    <span>Ω</span>
    OMEGA®
</div>

<button data-view="home">
    ⌂ Command
</button>

<button data-view="invent">
    ✦ Invent
</button>

<button data-view="evolve">
    ↻ Evolve
</button>

<button data-view="system">
    ◈ System
</button>

<button data-view="terminal">
    ⌘ Terminal
</button>

<div class="online">
    <i></i>
    OMEGA ONLINE
</div>

</aside>

<main>

<header>

<div>
<small>
    ADAPTIVE APPLICATION ENGINE
</small>

<h1 id="title">
    Command Center
</h1>
</div>

<div id="version">
    v1.0.0
</div>

</header>

<section
 id="home"
 class="view active"
>

<div class="hero">

<div class="hero-text">

<div class="symbol">
    Ω
</div>

<h2>
    Build beyond<br>
    the obvious.
</h2>

<p>
    OMEGA® converts intent into possibilities,
    possibilities into tested architectures,
    architectures into versions,
    and versions into controlled releases.
</p>

<div class="command">

<input
 id="intent"
 placeholder="Tell OMEGA® what you want..."
>

<button id="run">
    Run →
</button>

</div>

<div class="quick">

<button data-command="invent">
    ✦ Invent
</button>

<button data-command="simulate">
    ◈ Simulate
</button>

<button data-command="evolve">
    ↻ Evolve
</button>

<button data-command="release">
    ↑ Launch
</button>

</div>

</div>

<div class="orb">
    Ω
</div>

</div>

<div
 id="stats"
 class="stats"
></div>

<div class="panel">

<h3>
    LIVE EVENT FABRIC
</h3>

<div id="events"></div>

</div>

</section>

<section
 id="invent"
 class="view"
>

<div class="panel">

<h3>
    INVENTION LAB
</h3>

<p class="muted">
    Generate, recombine and score alternative architectures.
</p>

<div id="inventions"></div>

</div>

</section>

<section
 id="evolve"
 class="view"
>

<div class="panel">

<h3>
    EVOLUTION LAB
</h3>

<div id="versions"></div>

</div>

</section>

<section
 id="system"
 class="view"
>

<div class="panel">

<h3>
    .OMEGA SYSTEM
</h3>

<pre id="system"></pre>

</div>

</section>

<section
 id="terminal"
 class="view"
>

<div class="terminal">

<div id="terminalOutput"></div>

<div class="prompt">

<span>
    ω&gt;
</span>

<input
 id="terminalInput"
 placeholder="status"
>

</div>

</div>

</section>

</main>

<script src="/app.js"></script>

</body>
</html>
HTML

cat > public/styles.css <<'CSS'
*{
    box-sizing:border-box;
}

body{
    margin:0;
    background:#07080c;
    color:#f5f7fb;
    font-family:
        system-ui,
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        sans-serif;
}

aside{
    position:fixed;
    left:0;
    top:0;
    bottom:0;
    width:245px;
    padding:22px 14px;
    background:#0c0e13;
    border-right:1px solid #252a34;
    display:flex;
    flex-direction:column;
    gap:7px;
}

.brand{
    padding:8px 10px 28px;
    font-size:21px;
    font-weight:800;
}

.brand span{
    font-size:32px;
    margin-right:7px;
}

aside button{
    border:0;
    background:transparent;
    color:#929baa;
    text-align:left;
    padding:13px;
    border-radius:10px;
    cursor:pointer;
    font-size:14px;
}

aside button:hover{
    background:#181b22;
    color:white;
}

.online{
    margin-top:auto;
    padding:12px;
    color:#6d7685;
    font-size:11px;
}

.online i{
    display:inline-block;
    width:7px;
    height:7px;
    border-radius:50%;
    background:#52df8a;
    margin-right:7px;
}

main{
    margin-left:245px;
    padding:30px;
    max-width:1550px;
}

header{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:28px;
}

small{
    color:#717a88;
    letter-spacing:2px;
    font-size:10px;
}

h1{
    margin:5px 0;
    font-size:30px;
}

#version{
    padding:8px 13px;
    border:1px solid #2a303a;
    border-radius:30px;
    color:#a1a9b6;
}

.view{
    display:none;
}

.view.active{
    display:block;
}

.hero{
    min-height:470px;
    border:1px solid #292f3a;
    border-radius:25px;
    padding:48px;
    display:flex;
    align-items:center;
    justify-content:space-between;
    background:
        radial-gradient(
            circle at 80% 50%,
            #293052,
            transparent 34%
        ),
        #0d0f15;
}

.hero-text{
    max-width:700px;
}

.symbol{
    font-size:22px;
}

.hero h2{
    font-size:52px;
    line-height:.98;
    margin:10px 0 20px;
}

.hero p{
    color:#929baa;
    line-height:1.7;
    max-width:650px;
}

.command{
    margin-top:25px;
    display:flex;
    background:#07090c;
    border:1px solid #343a46;
    border-radius:13px;
    padding:5px;
}

.command input{
    flex:1;
    border:0;
    outline:0;
    background:none;
    color:white;
    padding:14px;
}

.command button{
    border:0;
    border-radius:9px;
    padding:10px 17px;
    background:#f3f5f8;
    color:#08090d;
    cursor:pointer;
}

.quick{
    display:flex;
    gap:8px;
    margin-top:10px;
    flex-wrap:wrap;
}

.quick button{
    border:1px solid #2a3039;
    border-radius:9px;
    padding:9px 13px;
    background:#171a20;
    color:#c5cbd4;
}

.orb{
    width:280px;
    height:280px;
    border-radius:50%;
    display:grid;
    place-items:center;
    font-size:100px;
    background:
        radial-gradient(
            circle,
            #414a78,
            #171b2c 50%,
            #090b10 72%
        );
    box-shadow:
        0 0 120px #252b50;
}

.stats{
    display:grid;
    grid-template-columns:
        repeat(4,1fr);
    gap:12px;
    margin:14px 0;
}

.card,
.panel{
    background:#0d0f14;
    border:1px solid #252a33;
    border-radius:16px;
    padding:18px;
}

.card strong{
    display:block;
    margin-top:5px;
    font-size:25px;
}

.muted{
    color:#777f8d;
    font-size:12px;
}

.panel{
    margin-top:14px;
}

.panel h3{
    margin-top:0;
    font-size:12px;
    letter-spacing:1.5px;
}

.event,
.candidate,
.version{
    margin-top:9px;
    padding:13px;
    border:1px solid #20252e;
    border-radius:10px;
    background:#090b0f;
}

.event{
    display:flex;
    justify-content:space-between;
}

.score{
    float:right;
}

.bar{
    height:5px;
    margin-top:10px;
    background:#20242d;
    border-radius:5px;
    overflow:hidden;
}

.bar i{
    display:block;
    height:100%;
    background:#9ca7ff;
}

.terminal{
    min-height:600px;
    background:#030405;
    border:1px solid #282d36;
    border-radius:16px;
    padding:18px;
    font-family:
        ui-monospace,
        SFMono-Regular,
        Menlo,
        monospace;
    color:#b9c4d5;
}

.prompt{
    display:flex;
    gap:9px;
    margin-top:15px;
}

.prompt input{
    flex:1;
    background:none;
    border:0;
    outline:0;
    color:white;
    font:inherit;
}

pre{
    white-space:pre-wrap;
    overflow:auto;
}

@media(max-width:850px){

    aside{
        position:static;
        width:100%;
        height:auto;
        flex-direction:row;
        overflow-x:auto;
    }

    .brand{
        padding:8px 12px;
    }

    .online{
        display:none;
    }

    main{
        margin:0;
        padding:16px;
    }

    .hero{
        padding:28px;
    }

    .orb{
        display:none;
    }

    .hero h2{
        font-size:38px;
    }

    .stats{
        grid-template-columns:
            repeat(2,1fr);
    }
}
CSS

cat > public/app.js <<'JS'
const $ =
    selector =>
        document.querySelector(selector)

const $$ =
    selector =>
        [...document.querySelectorAll(selector)]

async function api(
    endpoint,
    options
){
    const response =
        await fetch(
            endpoint,
            options
        )

    return response.json()
}

function show(view){

    $$(".view").forEach(
        element =>
            element.classList.toggle(
                "active",
                element.id === view
            )
    )

    const titles = {
        home:"Command Center",
        invent:"Invention Lab",
        evolve:"Evolution Lab",
        system:"System",
        terminal:"Terminal"
    }

    $("#title").textContent =
        titles[view]

    if(view === "invent")
        loadInvent()

    if(view === "evolve")
        loadVersions()

    if(view === "system")
        loadSystem()
}

$$("aside button").forEach(
    button => {
        button.onclick = () =>
            show(
                button.dataset.view
            )
    }
)

async function status(){

    const result =
        await api(
            "/api/status"
        )

    $("#version").textContent =
        "v" + result.version

    const cards = [
        ["Runtime",result.state],
        ["Constraints",
            result.constraints.length],
        ["Versions",
            result.versions],
        ["Events",
            result.events]
    ]

    $("#stats").innerHTML =
        cards.map(
            card => `
                <div class="card">
                    <span class="muted">
                        ${card[0]}
                    </span>
                    <strong>
                        ${card[1]}
                    </strong>
                </div>
            `
        ).join("")

    const events =
        await api(
            "/api/events"
        )

    $("#events").innerHTML =
        events.slice(0,10).map(
            event => `
                <div class="event">
                    <span>
                        ${event.type}
                    </span>
                    <span class="muted">
                        ${new Date(
                            event.timestamp
                        ).toLocaleTimeString()}
                    </span>
                </div>
            `
        ).join("")
}

async function command(text){

    text =
        String(text || "").trim()

    if(!text)
        return

    const result =
        await api(
            "/api/command",
            {
                method:"POST",
                headers:{
                    "Content-Type":
                        "application/json"
                },
                body:JSON.stringify({
                    command:text
                })
            }
        )

    $("#terminalOutput")
        .insertAdjacentHTML(
            "beforeend",
            `
            <pre>
ω&gt; ${text}
${JSON.stringify(
    result,
    null,
    2
)}
            </pre>
            `
        )

    await status()
}

$("#run").onclick =
    () =>
        command(
            $("#intent").value
        )

$("#intent").onkeydown =
    event => {
        if(event.key === "Enter"){
            command(
                $("#intent").value
            )
        }
    }

$$("[data-command]").forEach(
    button => {
        button.onclick =
            () =>
                command(
                    button.dataset.command
                )
    }
)

$("#terminalInput").onkeydown =
    event => {

        if(event.key === "Enter"){

            command(
                event.target.value
            )

            event.target.value = ""
        }
    }

async function loadInvent(){

    const result =
        await api(
            "/api/invent"
        )

    $("#inventions").innerHTML =
        result.candidates.map(
            candidate => `
                <div class="candidate">

                    <span class="score">
                        ${Math.round(
                            candidate.novelty *
                            100
                        )}% novelty
                    </span>

                    <strong>
                        ${candidate.name}
                    </strong>

                    <div class="muted">
                        ${candidate.strategy}
                    </div>

                    <div class="bar">
                        <i style="
                            width:${
                                candidate.resilience *
                                100
                            }%
                        "></i>
                    </div>

                </div>
            `
        ).join("")
}

async function loadVersions(){

    const versions =
        await api(
            "/api/versions"
        )

    $("#versions").innerHTML =
        versions.length
            ? versions
                .slice()
                .reverse()
                .map(
                    version => `
                        <div class="version">

                            <span class="score">
                                ${version.state}
                            </span>

                            <strong>
                                OMEGA®
                                ${version.version}
                            </strong>

                            <div class="muted">
                                score
                                ${Math.round(
                                    version.score *
                                    100
                                )}%
                                ·
                                ${version.architecture}
                            </div>

                        </div>
                    `
                ).join("")
            : `
                <p class="muted">
                    No versions yet.
                </p>
            `
}

async function loadSystem(){

    $("#system").textContent =
        JSON.stringify(
            await api(
                "/api/system"
            ),
            null,
            2
        )
}

status()

setInterval(
    status,
    4000
)
JS

###############################################################################
# 16. TESTS
###############################################################################

cat > tests/omega.test.js <<'JS'
import test from "node:test"
import assert from "node:assert/strict"

import { parseOmega }
    from "../src/core/parser.js"

test(
    "OMEGA root declaration",
    () => {

        const result =
            parseOmega(`
omega "TEST"

system {
    version "9.9.9"
    mode adaptive
}
`)

        assert.equal(
            result.name,
            "TEST"
        )

        assert.equal(
            result.system.version,
            "9.9.9"
        )

        assert.equal(
            result.system.mode,
            "adaptive"
        )
    }
)

test(
    "OMEGA booleans",
    () => {

        const result =
            parseOmega(`
omega "TEST"

runtime {
    local_first true
    offline_capable true
}
`)

        assert.equal(
            result.runtime.local_first,
            true
        )

        assert.equal(
            result.runtime.offline_capable,
            true
        )
    }
)
JS

###############################################################################
# 17. SAFE LAUNCHER
###############################################################################

cat > OMEGA_START.sh <<'START'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

if ! command -v node >/dev/null 2>&1; then
    echo "Node.js is missing."
    echo "Run:"
    echo "pkg install nodejs"
    exit 1
fi

npm test

clear

echo "╔══════════════════════════════════════════════════╗"
echo "║                  O M E G A ®                    ║"
echo "║          ADAPTIVE APPLICATION ENGINE             ║"
echo "╚══════════════════════════════════════════════════╝"
echo
echo "Starting UI..."
echo

exec node server.js
START

chmod +x OMEGA_START.sh

###############################################################################
# 18. TERMUX COMMAND WRAPPER
###############################################################################

cat > omega <<'OMEGACLI'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/omega"
exec node "$HOME/omega/bin/omega.js" "$@"
OMEGACLI

chmod +x omega

###############################################################################
# 19. RUN VALIDATION
###############################################################################

echo
echo "[OMEGA] Running foundation tests..."
npm test

echo
echo "[OMEGA] Checking parser..."
node -e '
import("./src/core/parser.js").then(({parseOmega})=>{
    const x=parseOmega(`
omega "OMEGA"
system {
    version "1.0.0"
}
`)
    if(x.name!=="OMEGA")
        throw new Error("OMEGA root parsing failed")
    console.log("[OK] .omega parser")
    console.log("[OK] root identity:",x.name)
    console.log("[OK] version:",x.system.version)
})
'

echo
echo "=============================================================="
echo " OMEGA® FOUNDATION INSTALLED"
echo "=============================================================="
echo
echo "Project:"
echo "  ~/omega"
echo
echo "Start:"
echo "  ~/omega/OMEGA_START.sh"
echo
echo "Or:"
echo "  cd ~/omega && npm start"
echo
echo "CLI:"
echo "  ~/omega/omega status"
echo "  ~/omega/omega invent \"build something better\""
echo "  ~/omega/omega simulate"
echo "  ~/omega/omega evolve"
echo "  ~/omega/omega release"
echo
echo "UI:"
echo "  http://127.0.0.1:8787"
echo
echo "Native architecture:"
echo "  .omega/       system definitions"
echo "  src/core/     OMEGA runtime"
echo "  src/engines/  invention/simulation/evolution"
echo "  src/runtime/  resource awareness"
echo "  public/       visual interface"
echo "  bin/          terminal interface"
echo "  versions/     version lineage"
echo "  data/         persistent state"
echo
echo "=============================================================="
echo

read -r -p "Launch OMEGA® now? [Y/n] " ANSWER
ANSWER="${ANSWER:-Y}"

if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    exec "$APP/OMEGA_START.sh"
fi
