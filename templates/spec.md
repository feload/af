# SPEC schema

SPEC content (`context`, `problem`, `constraints`, `subtasks`, `edgeCases`, `doneCriteria`) can live in two places:

- **Inline on the US** — preferred for 1:1 work. The same six fields below sit directly on `.af/docs/usm/source/stories/US-XXXX.json`. No standalone file is created. The US's own `status` drives readiness (`proposed` → `ready` when the PM confirms the inline content).
- **Standalone file** — under `.af/docs/usm/source/specs/SPEC-XXXX.json`. Use when the work is cross-cutting (no matching US, `story: null`) or when a single US is large enough to warrant multiple SPECs.

Either way, the fields below describe what the Lead writes. The Developer reads the SPEC from the US (inline path) or from the standalone file. The bundled `.af/docs/usm/specs.js` is a generated artifact rebuilt by `.af/bin/build-usm.py` — never hand-edit it. Full reading rules: `.af/agents/lead.md`. Full schema docs: `.af/docs/usm.md`.

## Standalone SPEC file

```js
{
  "id": "SPEC-0001",            // SPEC-####, zero-padded, unique across all entries (archived ones count)
  "title": "Short feature name",
  "status": "draft",            // draft | ready | approved | archived
  "story": "US-0001",           // Matches a story id from .af/docs/usm/source/stories/ (look it up in source/INDEX.md) — OPTIONAL: null/missing for cross-cutting work (infra, refactor, CI) that doesn't map to a user-visible US

  "context": "Why this is being built. One short paragraph readable cold by a Developer who has never seen this product.",
  "problem": "What is missing or broken today. Concrete — not a generic restatement of the user story.",
  "constraints": [
    "One bullet per hard limit or architectural decision. Each item is one short sentence.",
    "Examples: `no new deps`, `must keep X compatible`, `follow pattern Y from file Z`, `new Django app named careers`, `new Pinia store at frontend/src/stores/careers.ts`."
  ],

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

  "edgeCases": [
    "One bullet per non-obvious path. Format: `<trigger> → <expected behavior>`.",
    "Example: `PDF over 10 MB → return 413 with key cv.errors.too_large`."
  ],
  "doneCriteria": [
    "Bulleted PM walkthrough of the running app. Each bullet is one verifiable step or check.",
    "Example: `PM logs in, navigates to /profile/import, selects a 1 MB PDF, sees \"processed\" status`.",
    "Reference the acceptance criteria of the linked US."
  ]
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

## Inline SPEC on a US

When the SPEC is written inline on a US, the JSON above is collapsed onto `source/stories/US-XXXX.json` minus the four fields that belong to the US itself: `id`, `title`, `status` and `story`. Only `context`, `problem`, `constraints`, `subtasks`, `edgeCases` and `doneCriteria` are added to the story file. The US's `status` becomes the readiness signal:

- `proposed` → inline SPEC still in draft (or not started yet).
- `ready` → inline SPEC confirmed by the PM; Developer can pick it up.
- `active` → Developer is implementing.
- `done` → implemented and accepted by the PM.

Subtasks on the inline SPEC obey the same format and rules as the standalone version. The completeness checklist in `.af/agents/lead.md` applies identically — the only difference is the file the Lead writes to.

## Rules

- Every field except `edgeCases` must be filled before the SPEC is marked ready (US `status: ready` for inline, SPEC `status: ready` for standalone).
- For a standalone SPEC, `story` is optional. Leave `null` for cross-cutting work; drafts without `story` are surfaced in the "Unassigned" tray of the USM header.
- The SPEC does **not** carry acceptance criteria — those live on the linked US (`acceptance` array in `.af/docs/usm/source/stories/US-XXXX.json`) and the USM already shows them when the user opens the story. The SPEC's `doneCriteria` is the PM walkthrough that proves those criteria are satisfied end-to-end.
- `constraints`, `edgeCases` and `doneCriteria` are arrays of strings. One bullet per item, each item one short sentence ending with a period. Never a single text blob — the USM renders these as `<ul>`/`<ol>`. If a section truly has only one item, still wrap it in an array of one.
- Subtasks must include the tests the Developer must write and the i18n keys to add (when there is user-facing text).
- Subtasks must include the migration creation step whenever models change.
- Keep subtasks independently implementable and ordered so each finishes in a runnable state.
- The `description` is one line in the format above — do not split into multiple JSON fields.
