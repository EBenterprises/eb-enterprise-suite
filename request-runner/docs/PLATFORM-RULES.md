# EB Platform® Engineering Rules

## Rule 1

Do not replace the architecture to solve an implementation problem.

## Rule 2

Fix the smallest layer responsible for the problem.

## Rule 3

Preserve working code.

## Rule 4

New functionality becomes a module, service, adapter, or extension.

## Rule 5

Business logic must not depend directly on Android, Termux, or a specific
database.

## Rule 6

Infrastructure may change without changing domain contracts.

## Rule 7

All destructive migrations require a backup.

## Rule 8

One authoritative launcher.

## Rule 9

One authoritative configuration.

## Rule 10

Tests accompany platform capabilities.

## Rule 11

Scale horizontally through contracts, events, queues, workers, and adapters.

## Rule 12

Do not introduce artificial capacity ceilings.
