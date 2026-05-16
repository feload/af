# User Story Map (USM)

Visual map of the product. Lives as a static site in this repo; needs no
server or dependencies. Besides the story map, it holds the **SPECs**
and **BUGs** as the single source of truth — the Lead writes them here
(not in `.md` files) and the Developer reads them straight from the JSON.

## Location

`.af/docs/usm/`

```
.af/docs/usm/
├── index.html         # The interactive map
├── styles.css         # Styles (light and dark theme)
├── data.js            # GENERATED — do not hand-edit (window.USM_DATA)
├── specs.js           # GENERATED — do not hand-edit (window.USM_SPECS)
├── bugs.js            # GENERATED — do not hand-edit (window.USM_BUGS)
└── source/            # Single source of truth — edit these files
    ├── INDEX.md       # Grep-friendly catalogue (stories, SPECs, bugs)
    ├── skeleton.json  # Activities + steps (no stories)
    ├── releases/      # One file per slice: <slice-id>.json
    ├── stories/       # One file per story: US-XXXX.json
    ├── specs/         # One file per SPEC: SPEC-XXXX.json
    └── bugs/          # One file per bug: BUG-XXXX.json
```

The bundled `.js` files are **generated artifacts** produced by
`.af/bin/build-usm.py`. The HTML viewer reads them because the USM is a
static site (no server, no `fetch()`). Authors edit the per-item JSON
under `source/`.

## Build and pre-commit hook

After editing anything under `source/`, regenerate the bundles:

```bash
python3 .af/bin/build-usm.py
```

This rewrites `data.js`, `specs.js`, `bugs.js` and `source/INDEX.md`
from the per-item files. It is idempotent and fast — skips a bundle if
its `source/<dir>/` doesn't exist yet (so adoption can be gradual).

A pre-commit hook does the same automatically: when any file under
`source/` (or `bin/build-usm.py` itself) is staged, it regenerates the
bundles and `git add`s them so they never drift. Enable once per clone:

```bash
git config core.hooksPath .af/hooks
```

This is opt-in — `/af-init` and `/af-update` print the hint but never
touch the user's git config.

## How to view it

- **Double-click** `index.html` — opens in the browser.
- On distros where the browser (Brave/Chrome) runs in a Flatpak/Snap
  sandbox and can't see `.af/` (hidden), use native Firefox:
  ```bash
  firefox .af/docs/usm/index.html
  ```
- Or serve it from a local server:
  ```bash
  python3 -m http.server 8000 --directory .af/docs/usm
  ```

## How the USM is organized

Patton-style structure:

- **Activities** (top horizontal row) — the user's journey through the
  product, left to right. Sticky on vertical scroll.
- **Steps** (horizontal row under each activity) — the concrete actions
  the user takes inside each activity. Also sticky.
- **Stories** (vertical columns under each step) — the options or
  variants of how the user performs that step.

A story's `status` follows this lifecycle:

- `proposed` — PM filed it. Narrative may be complete; the inline SPEC may be empty or in draft.
- `ready` — fully spec'd (inline content confirmed by the PM, or at least one external SPEC linked with `status: ready`). The Developer can pick it up.
- `active` — the Developer is implementing.
- `done` — implemented and accepted by the PM.
- `dropped` — cut from scope.

Stories are grouped into **horizontal bands** by version (slice).
Vertical band order: unreleased slices on top (`planning` +
`in-progress`, in planning order), then released versions (most recent
first), and at the bottom the Backlog (stories with no slice assigned).
Each band's chip shows the release status as a suffix: "Version v1.0 ·
planning", "Version v1.1 · in development", "Version MVP · released".

## State and interaction

- Click a story → opens the right-side panel with narrative, rationale,
  acceptance criteria, tasks, **related SPECs** and **related bugs**
  (each with the full template detail, collapsible). The URL becomes
  `#US-XXXX` so refreshing or sharing reopens the same story.
- Click a band's chip → collapses or expands its stories.
- Hover a step or any cell in its column → highlights the entire column
  with a colored band.
- Horizontal drag on the map → horizontal scroll, Miro-style.
- Normal vertical scroll to traverse the bands.

## Visual signals

Indicators that help the PM read the map's state without opening each
story:

- **🐞N badge on the US card** — appears when that US has bugs in
  `open` or `in-progress`. The count aggregates the live bugs for that
  US.
- **A released US with bugs is not dimmed** — US cards in released
  bands normally render dim (their job is done). If they have open
  bugs, opacity goes back to 1 so they stand out among the quiet ones.
- **🐞 N open bugs** (header chip) — global total. Clicking it toggles
  a filter that hides every US without open bugs: the map switches to
  "where it hurts" mode. Click again to clear.
- **📋 N unassigned** (header chip) — includes SPEC drafts (with or
  without a story) and orphan bugs (without a story). Clicking it
  opens the side panel in inbox mode, showing each item with its full
  detail. It's the Lead's review queue.

## Data schema

The bundled `data.js` is generated by `build-usm.py` from three sources
under `source/`:

- `source/skeleton.json` — `{ activities: [{ id, title, steps: [{ id, title }] }] }`. No stories.
- `source/releases/<slice-id>.json` — `{ id, title, goal, status? }`. `goal` is the one-line statement of *what shipping this release is meant to achieve* — the criterion by which the PM picks which US belong in the slice. `status` is optional (`planning | in-progress | released`).
- `source/stories/US-XXXX.json` — one file per story:

```json
{
  "id": "US-0042",
  "title": "...",
  "status": "proposed",         // proposed | ready | active | done | dropped
  "slice": "v1-0",              // slice id or null for Backlog
  "step": "create-account",     // step id from skeleton.json — REQUIRED
  "description": "As X, I want Y so that Z",
  "rationale": "why it matters (1-2 lines)",
  "acceptance": [],
  "tasks": [],                  // optional: [{ title, status }]

  // Optional inline SPEC — present when the story carries its own
  // implementation plan instead of (or in addition to) external SPEC files.
  // Same fields as a standalone SPEC, minus id/title/status/story (those live
  // on the US itself). When any of these are present, the US is "self-spec'd".
  "context": "why we are building it (one short paragraph)",
  "problem": "what is broken or missing (specific)",
  "constraints": [],            // array of bullets
  "subtasks": [                 // ordered, independently implementable subtasks
    {
      "description": "[verb] — files: `path` — what to change: [what] — done when: [criterion]",
      "done": false
    }
  ],
  "edgeCases": [],              // array: `<trigger> → <behavior>`
  "doneCriteria": []            // array: PM walkthrough, one verifiable step per bullet
}
```

The build script groups stories by `step`, sorts them by `id` within
each step, and nests them under the matching step in the skeleton to
produce `window.USM_DATA = { slices, activities }`. The inline SPEC
fields are passed through untouched so the viewer can render them.

To find a story without opening every file, grep `source/INDEX.md`.

A story can be spec'd two ways:

1. **Inline** (default for 1:1 work) — the SPEC fields above live on the
   US itself. No separate SPEC file. The PM confirms the inline content
   and flips US `status` to `ready`. The Developer reads the US and
   implements its `subtasks` directly.
2. **External** — one or more standalone files under `source/specs/`
   point at the US via their `story` field. Use this for cross-cutting
   work that doesn't map to a single US (`story: null`), or when a US
   is large enough to warrant multiple SPECs.

Both forms can coexist on the same US: inline subtasks for the main
slice of work plus one or more external SPECs for sub-pieces.

### Slice (release) goal

`goal` is a single sentence: *what does shipping this release achieve
for the user or the business?* It is the rubric by which the PM picks
which US belong in the slice and which stay in the Backlog — every
candidate story must serve the goal, or the slice is the wrong home
for it.

- A slice in `planning` may have an empty `goal` while it is being
  sketched, but it must have a non-empty `goal` before its status
  flips to `in-progress` or `released`. Working on stories with no
  shared destination is how slices turn into garbage bags.
- The goal is one sentence, in the future tense from the user's
  perspective when possible (e.g. *"Returning users can resume a
  draft from any device"* — not *"Implement draft sync"*).
- `/af-create-story` reads the goal of any slice the PM names and
  uses it to anchor the story's narrative and acceptance criteria.

### Slice (release) status

`status` can take three values:

- `planning` — scope under discussion, no work started on the slice's US.
- `in-progress` — at least one US in the slice is `active` or `done`.
- `released` — shipped to production. Stories render dim on the map.

The field is **optional**. If present, it wins. If missing, it is inferred:

- At least one US is `active` or `done` in the slice → `in-progress`.
- All are `proposed` (or the slice is empty) → `planning`.
- `released` is **never** inferred — it must always be set by hand by
  the PM, because shipping is a human decision, not a state derivable
  from the work.

This lets the PM override when convenient (lock a release on
`in-progress` even if every US is `done`, for instance, while waiting
for a deployment window).

## SPECs schema

A SPEC's content (`context`, `problem`, `constraints`, `subtasks`,
`edgeCases`, `doneCriteria`) lives in one of two places:

- **Inline on the US** — preferred for 1:1 work. The fields sit
  directly on `source/stories/US-XXXX.json` (see the schema above).
  No file under `source/specs/` is created. The US's own `status`
  drives readiness: `proposed` while the inline SPEC is in draft,
  `ready` once the PM confirms.
- **Standalone file** — under `source/specs/SPEC-XXXX.json`. Use for
  cross-cutting work that doesn't map to a single US (`story: null`),
  or when a US is large enough to warrant several SPECs. Each
  standalone SPEC carries its own `status` lifecycle.

One file per standalone SPEC under `source/specs/SPEC-XXXX.json`:

```json
{
  "id": "SPEC-0001",
  "title": "...",
  "status": "draft",           // draft | ready | approved | archived
  "story": "US-0001",          // matching US id, or null for cross-cutting work
  "context": "why we are building it (one short paragraph)",
  "problem": "what is broken or missing (specific)",
  "constraints": [],           // array of bullets
  "subtasks": [
    {
      "description": "[verb] — files: `path` — what to change: [what] — done when: [criterion]",
      "done": false
    }
  ],
  "edgeCases": [],             // array: `<trigger> → <behavior>`
  "doneCriteria": []           // array: PM walkthrough, one verifiable step per bullet
}
```

The next free ID is one above the highest SPEC listed in
`source/INDEX.md`. Append a new file, then run `build-usm.py` (or rely
on the pre-commit hook).

`constraints`, `edgeCases` and `doneCriteria` are **always arrays of strings**. One short sentence per bullet. The USM renders them as `<ul>`/`<ol>`. If a section has only one item, it's still a one-element array — never a bare string.

The SPEC **does not** carry its own acceptance criteria: the criteria live on the linked US (`acceptance` in `source/stories/US-XXXX.json`) and the USM already shows them when the user opens the story. The SPEC's `doneCriteria` is the PM walkthrough that proves those criteria are met end to end.

`status` means:
- `draft` — the Lead is writing it or the PM hasn't confirmed it yet
- `ready` — ready to implement (the Developer can pick it up)
- `approved` — implemented and approved by the PM, awaiting PR
- `archived` — PR merged; kept as a record

## Bugs schema

One file per bug under `source/bugs/BUG-XXXX.json`:

```json
{
  "id": "BUG-0001",
  "title": "...",
  "status": "open",            // open | in-progress | fixed | wont-fix
  "story": "US-0001",          // matching US id, or null for orphan bugs (rare)
  "foundAt": "2026-05-15",     // ISO 8601
  "description": "what's wrong (one clear sentence)",
  "stepsToReproduce": [],
  "expected": "what should happen",
  "actual": "what actually happens",
  "affectedArea": "suspect files/modules",
  "rootCause": "exactly what causes it",
  "fix": [
    { "description": "[verb] — files: `path` — what to change: [what] — done when: [criterion]", "done": false }
  ],
  "regressionTest": "test that prevents recurrence (mandatory)",
  "doneCriteria": []
}
```

`doneCriteria` is an array of strings, same rule as in SPECs. One short
sentence per bullet.

When a story's detail opens, the panel shows the story's inline SPEC
content (if any) first, then each standalone SPEC and each bug as a
collapsible card with all of these sections. By default, cards open
if they're alive (`ready`/`approved` for SPECs, `open`/`in-progress`
for bugs) and stay closed if they're done.

SPEC cards show only the technical detail for the Developer (context,
problem, constraints, subtasks, edge cases, done criteria). The
product acceptance criteria live on the US and are shown at the top of
the panel when the user opens the story.

## History

- Up to `v0.6` SPECs lived as `.md` files under `.af/specs/active/`
  and `archived/`. They were migrated to a single JSON array in
  `.af/docs/usm/specs.js`; the `.af/specs/` directory was removed.
- On `v0.9` the source of truth moved again, this time to per-item
  JSON files under `.af/docs/usm/source/`. The bundled `data.js`,
  `specs.js` and `bugs.js` became generated artifacts produced by
  `.af/bin/build-usm.py`. Reason: catalogues that grow past ~150
  stories and a dozen SPECs are hostile to diffs, merge conflicts and
  Claude's context window.
