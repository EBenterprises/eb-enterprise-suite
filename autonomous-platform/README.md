# Autonomous Platform Completion Engine®

The engine converts one high-level request into a durable autonomous execution process.

Core loop:

REQUEST
↓
PLAN
↓
DECOMPOSE
↓
BUILD
↓
VERIFY
↓
TEST
↓
REPAIR
↓
BRANCH
↓
REBUILD
↓
VERIFY
↓
DEPLOY
↓
MONITOR
↓
COMPLETE

The important architectural property is that continuation is an engine
responsibility rather than a conversational responsibility.

A failure becomes another machine-readable work item.

A repair becomes another execution cycle.

A discovered requirement can expand the plan.

A failed verification returns execution to the appropriate earlier phase.

State is persisted to disk so the process can be resumed.

Project-specific build, test, deployment, LLM, GitHub, Vercel,
container/VM, cloud, mobile, web, database and other capabilities
should be implemented as adapters under `adapters/`.

Run:

node bin/platform.js "Build my complete platform..."

Check:

node bin/status.js

Verify:

node bin/verify.js

Worker:

node bin/worker.js
