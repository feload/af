# Architecture

## System Overview
- [One sentence: what the system does and who uses it]
- Runtime: [e.g. Node.js 20, Python 3.12]
- Deployment: [e.g. single server, serverless, Docker]

## Main Modules
- `[module]` — [single-line responsibility]
- `[module]` — [single-line responsibility]

## Dependency Rules
- [module A] depends on [module B] — never the reverse
- Shared state lives in [location] — not in individual modules
- External services are accessed only through [layer/abstraction]

## Critical Architectural Decisions
- [Decision and the constraint it enforces]
- [Decision and the constraint it enforces]

## Forbidden Patterns
- No business logic in [layer]
- No direct DB access from [layer]
- No circular dependencies between modules
