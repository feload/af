# Conventions

## Repository Structure
- `[path]/` — [what lives here and what does not]
- `[path]/` — [what lives here and what does not]

## Naming Conventions
- Files: [pattern, e.g. kebab-case]
- Variables/functions: [pattern, e.g. camelCase]
- Types/classes: [pattern, e.g. PascalCase]
- Constants: [pattern, e.g. SCREAMING_SNAKE]
- [Domain-specific rule, e.g. "handlers are suffixed with Handler"]

## Testing Conventions
- Test files: [location and naming pattern]
- Unit tests cover: [what — e.g. pure functions, domain logic]
- Integration tests cover: [what — e.g. DB queries, API handlers]
- Do not test: [what — e.g. framework internals, config parsing]

## Refactoring Rules
- Extract only when duplication appears [N] or more times
- Do not change behavior and structure in the same commit
- Shared utilities go in [path] — not inlined or duplicated

## Forbidden Practices
- No [language/framework anti-pattern]
- No commented-out code committed to the repo
- No hardcoded secrets or environment-specific values in source
