# EB Platform® Architecture

Request Runner® is the first application built on EB Platform®.

## Principles

1. Additive evolution.
2. Stable contracts.
3. Platform-independent application logic.
4. Infrastructure adapters rather than application rewrites.
5. One authoritative runtime boundary.
6. Modules are independently extensible.
7. Data persistence is abstracted.
8. Realtime is abstracted.
9. Security is centralized.
10. Observability is built into the platform.
11. Deployment topology does not dictate domain architecture.
12. Existing working application code is preserved during migration.

## Core

- Runtime
- Dependency container
- Module registry
- Command bus
- Query bus
- Event bus
- Middleware
- Error model

## Domain

- Customers
- Requests
- Orders
- Dispatch
- Drivers
- Locations
- Scheduling
- Payments
- Notifications
- Operations
- Administration

## Infrastructure

Current Android/Termux compatibility is retained through the existing
Webpack-based Next.js launcher.

Future deployment environments are adapters around the same application
contracts.

## Scaling Model

The platform can evolve from:

single process

to:

multi-process

to:

worker pools

to:

distributed services

to:

regional infrastructure

without requiring the domain layer to be rewritten.
