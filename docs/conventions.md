# Conventions

Sections with `[...]` placeholders are stack-specific — `/af-init` fills
them from the codebase. The rest are opinionated defaults that apply to
every project; keep them unless a project has a reason to override.

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
- Write only critical, required tests. No filler or "garbage" tests for trivial code.
- Tests must reflect the most important behavior of the application.
- Tests must be independent: no internet or external network dependencies.
- Use mocks and stubs for external dependencies (network, services, I/O).
- Both unit and integration tests are expected where they add real value.
- Do not test: framework internals, config parsing.
- Test files: [location and naming pattern]

## Refactoring Rules
- Extract only when duplication appears 3 or more times.
- Do not change behavior and structure in the same commit.
- Shared utilities go in [path] — not inlined or duplicated.

## Commit Conventions
- No `Co-Authored-By:` lines.
- No "Generated with Claude Code" or similar attribution in commit messages or PRs.
- Commit message format: [to be defined]

## Styling
- Never ship an unstyled UI. Any page or component with a visible surface gets at least baseline styling — readable typography, spacing, colors, and visible focus states.
- Detect the theme automatically from the system via `prefers-color-scheme`, with **dark as the fallback** (the default applies when no preference is reported).
- `.af/templates/base.css` is a dependency-free starting point that already does this (CSS custom properties, dark-default with a light override, focus rings, sensible form/button defaults). Use it as the base: load it before app-specific CSS, or port its tokens into the project's own styling system (Tailwind theme, CSS-in-JS, design tokens) rather than reinventing them.
- Drive colors and spacing through tokens/custom properties so a theme change is a token change, not a rule rewrite. Do not hardcode a single color scheme that ignores the system preference.

## Language / Locale
- Source code and identifiers: English.
- AI agent responses: English.

## Communication Style
- Always write in plain, easy-to-understand English. Short sentences, common words, direct phrasing.
- Be concise: cut decorative qualifiers, meta-labels ("in plain English", "to put it simply"), and filler.
- Use as few words as possible, as long as the message does not suffer for it. When the user needs more info, go deeper with extensive explanations.
- Applies to all writing: agent responses, docs, comments, commit messages, PRs, and code review.
- Be critical, not a yes-man: do not agree by default. When the human proposes something, evaluate it against scalability, security, and data integrity, and give a clear recommendation with the reasoning. Critique to move the work forward, not to block it.

## Forbidden Practices
- No overengineering. Keep code simple; build only what is critical and required.
- No commented-out code committed to the repo.
- No hardcoded secrets or environment-specific values in source.
- No [language/framework anti-pattern].
