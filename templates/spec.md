# SPEC schema (entry in `.af/docs/usm/specs.js`)

A SPEC is a JSON object inside the `window.USM_SPECS` array. The Lead appends one per feature. The Developer reads from here. Full reading rules: `.af/agents/lead.md`. Full schema docs: `.af/docs/usm.md`.

```js
{
  "id": "SPEC-0001",            // SPEC-####, zero-padded, unique across all entries (archived ones count)
  "title": "Short feature name",
  "status": "draft",            // draft | ready | approved | archived
  "story": "US-0001",           // Matches an id from data.js — OPTIONAL: null/missing for cross-cutting work (infra, refactor, CI) that doesn't map to a user-visible US

  "context": "Why this is being built. One short paragraph readable cold by a Developer who has never seen this product.",
  "problem": "What is missing or broken today. Concrete — not a generic restatement of the user story.",
  "constraints": "Hard limits and architectural decisions made in this SPEC. List them: no new deps, must keep X compatible, follow pattern Y from file Z, new Django app named `careers`, new Pinia store at `frontend/src/stores/careers.ts`, etc.",

  "subtasks": [
    {
      "description": "[Action verb] — files: `backend/apps/careers/models.py` — what to change: [exact description, including field names, types, choices, indexes, db_table] — done when: [verifiable criterion the Developer can confirm]",
      "done": false
    },
    {
      "description": "[Action verb] — files: `backend/apps/careers/migrations/` — what to change: run `uv run python manage.py makemigrations careers` and commit the generated file — done when: a `0001_initial.py` (or next number) exists creating the new model(s)",
      "done": false
    }
  ],

  "edgeCases": "Enumerate non-obvious paths the Developer must handle, each with the expected behavior. E.g.: if the user uploads a PDF over 10 MB, return 413 with key `cv.errors.too_large` in both locales.",
  "doneCriteria": "How PM verifies end-to-end in the running app. Reference the acceptance criteria of the linked US."
}
```

## Subtask format (mandatory)

Every subtask must include all four parts on one line:

```
[verb] — files: `path/to/real/file` — what to change: [specific] — done when: [verifiable]
```

- `[verb]` is concrete: `Create`, `Extend`, `Replace`, `Add endpoint`, `Add test`, `Add i18n keys`, `Run`, `Wire`, `Register`.
- `files:` lists real paths that exist or that this subtask creates. Never `path/to/file`.
- `what to change:` is specific enough that two Developers would produce the same code: field names, types, route paths, function signatures, Pinia store keys, i18n keys.
- `done when:` is verifiable without running the app where possible (a file/symbol exists, a test passes, a migration is committed). For UI subtasks, name the visible behavior.

Forbidden subtask verbs: `Investigate`, `Decide`, `Explore`, `Consider`, `Figure out`. Those are Lead work, not Developer work.

## Status lifecycle

- `draft` — Lead writing, or PM has not confirmed yet.
- `ready` — PM confirmed. Developer may start. **Every box of the SPEC completeness checklist (in `.af/agents/lead.md`) must be checked before flipping here.**
- `approved` — implemented and accepted by PM, awaiting PR.
- `archived` — PR merged. Entry stays as a record.

## Rules

- Every field except `edgeCases` must be filled before `ready`.
- `story` is optional. Leave `null` for cross-cutting work; drafts without `story` are surfaced in the "Sin asignar" tray of the USM header.
- Subtasks must include the tests the Developer must write and the i18n keys to add (when there is user-facing text).
- Subtasks must include the migration creation step whenever models change.
- Keep subtasks independently implementable and ordered so each finishes in a runnable state.
- The `description` is one line in the format above — do not split into multiple JSON fields.
