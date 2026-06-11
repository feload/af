# AI-Assisted Development Workflow

## Roles

**PM (user)** — owns the USM. Maintains the backbone (Activities + Steps), files Stories under Steps, confirms SPECs and Bugs, reviews implementations, approves PRs.

**Lead** — turns a Story into a SPEC detailed enough that the Developer can implement it without exploring or making scope decisions. Also drafts BUG entries from PM reports.

**Developer** — implements the SPEC (or the BUG fix) as written. Does not explore, does not decide scope.

## Domain first, then backbone, then stories

af is self-contained: there is no external tracker. All scope lives in the USM under `.af/docs/usm/`. The single source of truth is per-item JSON under `.af/docs/usm/source/`; the bundled `.af/docs/usm/{data,specs,bugs}.js` are generated artifacts rebuilt by `.af/bin/build-usm.py`. New work flows top-down:

1. **Domain** — `.af/docs/domain.md` must be populated (entities, business rules, glossary) before the backbone is meaningful. The Lead refuses to design a backbone over an empty `domain.md`.
2. **Backbone** — Activities (the user's journey, left-to-right) and Steps (concrete actions inside each Activity) live in `.af/docs/usm/source/skeleton.json`. Build or extend with `/af-create-backbone`.
3. **Slices (releases)** — a slice groups the User Stories that will ship together, anchored by a **goal**: one sentence describing what shipping the release achieves for the user or the business. Create with `/af-create-slice`. The goal is the rubric for what belongs in the slice and what stays in the Backlog. A slice in `planning` may sketch its goal later, but it must have a non-empty `goal` before its status flips to `in-progress` or `released`. `/af-create-slice` optionally continues into a Backlog sweep and a value-delivery walkthrough (10-axis rubric in `agents/lead.md`) to surface stories that would block end-to-end value — navigation, access, edge states, observability, etc. — and propose them as new US. `/af-review-slice <slice-id>` reruns the delta before flipping the slice to `in-progress`.
4. **Stories** — User Stories (Options) hang off Steps via their `step` field, one file per story under `.af/docs/usm/source/stories/`. Create with `/af-create-story`. When the PM names a slice, the Lead reads the slice's goal and uses it to anchor the story's narrative, rationale and acceptance criteria. Default `slice` is `null` (Backlog) when the PM has no destination in mind.
5. **SPECs / Bugs** — written against a Story. The SPEC content lives **inline on the US by default** (six extra fields on `source/stories/US-XXXX.json`: `context`, `problem`, `constraints`, `subtasks`, `edgeCases`, `doneCriteria`). A standalone file under `source/specs/` is created only for cross-cutting work (`story: null`) or when a single US is large enough to be split into multiple SPECs. Bugs always live as their own file under `source/bugs/`.

## Flow

```
PM: backbone exists? if not → /af-create-backbone (writes source/skeleton.json)
PM: planning a release? → /af-create-slice (writes source/releases/<slice>.json with a goal; optionally sweeps Backlog and walks the 10-axis rubric to propose missing US)
PM: /af-create-story → US-####.json proposed in source/stories/ (slice: <slice-id> or null for Backlog, anchored on slice goal when given)
PM: /af-create-spec → Lead writes SPEC content inline on the US (or, for cross-cutting / multi-SPEC work, a SPEC-####.json under source/specs/) → PM confirms → US status: ready (or SPEC status: ready for the standalone path)
PM: /af-review-slice <slice-id> → readiness table + rubric delta + verdict → PM flips slice to in-progress when ready
Developer: /af-implement-spec <US-####|SPEC-####> → implements subtasks + tests → hands off test tree + run commands
            (or /af-implement-slice <slice-id> → implements every ready US in the slice back-to-back on one branch → single combined handoff)
PM: review + run tests → US status: done (or SPEC status: approved)
Developer: create PR
PM: approve PR → entry stays as a record (US done, SPEC archived)
```

After every write under `source/`, `build-usm.py` regenerates the bundled `.js` files and `source/INDEX.md`. With the pre-commit hook enabled (`git config core.hooksPath .af/hooks`) the rebuild also happens automatically at commit time.

## Rules

- Every Slice has a `goal`. It may be empty while the slice is in `planning`, but it must be filled before the slice's status flips to `in-progress` or `released`. A slice without a goal is a garbage bag — refuse to plan against it.
- Every Story either serves the goal of the slice it's attached to or sits in Backlog (`slice: null`). The PM moves a story into a slice only when its narrative visibly advances the slice's goal.
- Every implementation starts from either a US with `status: ready` (inline SPEC confirmed) or a standalone SPEC with `status: ready`. Every fix starts from an `in-progress` BUG.
- The SPEC is the single source of truth — inline or standalone, it must be complete enough to implement without questions.
- The SPEC is inline on the US by default. Create a standalone file under `source/specs/` only when (a) the work is cross-cutting and has no matching US (`story: null`), or (b) the PM explicitly wants the US split into multiple SPECs.
- Lead is responsible for SPEC quality: if Developer is blocked, Lead failed to spec it well enough.
- Developer does not make scope decisions — if something is ambiguous, they stop and flag it.
- New Activities are only added via `/af-create-backbone`. `/af-create-story` may add a new Step inline when no existing Step fits, but never a new Activity.

## Bug flow

```
PM: /af-create-bug → Lead investigates root cause (targeted) → writes BUG-####.json in source/bugs/ → PM confirms → status: in-progress
Developer: /af-fix-bug → applies fix + writes regression test → notifies PM
PM: verify fix → ok to ship
Developer: create PR
PM: approve PR → status: fixed
```

- Lead **is** allowed to read source files to find root cause — but only files directly related to the bug.
- Regression test is mandatory — no bug fix is complete without one.
- The US that the bug belongs to does **not** change status. A US shipped as `done` stays `done` even with an open bug filed against it. The USM signals open bugs on a US with a 🐞N badge on the US tile (and stops dimming released-band US tiles that have open bugs).

## Bug found mid-development (US in `active`)

If a defect surfaces while the Developer is implementing the US, decide where it belongs:

- **In scope of the active SPEC** — an acceptance criterion is not yet met, or a subtask uncovered a small adjacent issue inside the same files. Fix it in the current SPEC (inline or standalone), no new BUG entry.
- **Out of scope of the active SPEC** — the defect is in files or behavior not listed in the SPEC, or in code that was already shipped. Stop, file a separate BUG entry as a new file in `.af/docs/usm/source/bugs/` (`status: open`, link `story` if it fits one), and continue with the original SPEC. The bug is triaged like any other afterwards.

The rule: if you can address it without changing the SPEC's subtasks, it's in scope. If addressing it would require new subtasks or touch files the SPEC didn't list, it's a separate BUG.

## Drafts and orphan entries

The USM header surfaces two trays:

- **🐞 N open bugs** — counter of bugs with status `open` or `in-progress`. Click toggles a filter that hides every US without open bugs, so the map shows only where it hurts.
- **📋 N unassigned** — counter of (a) all standalone SPECs with `status: "draft"`, (b) all bugs with `story: null` and (c) all standalone SPECs with `story: null`. Click opens the side pane in tray mode, listing the groups with full detail. This is the Lead's review surface for unfinished or unattached work.

A standalone SPEC may legitimately have `story: null` for cross-cutting work (infrastructure, refactor, CI). Such SPECs are not pinned to a US in the map, but the Developer can still implement them by ID — they live under `source/specs/` like any other. Drafts always show up in the tray regardless of whether they have a `story`, as a reminder for the Lead to finish them. Inline SPECs do not appear in the tray: their readiness is the US's own `status`, which the PM already sees on the map.

## Artifact location and naming

Everything af tracks lives under `.af/docs/usm/source/` (the single source of truth):

- Backbone: `.af/docs/usm/source/skeleton.json` — Activities + Steps, no stories.
- Stories: `.af/docs/usm/source/stories/US-XXXX.json` — one file per story. Carries its `step` field to nest under the backbone at build time, and (when self-spec'd) the inline SPEC fields `context`, `problem`, `constraints`, `subtasks`, `edgeCases`, `doneCriteria`.
- Releases (slices): `.af/docs/usm/source/releases/<slice-id>.json` — `{ id, title, goal, status? }`. `goal` is the one-sentence rubric for what belongs in the slice.
- Standalone SPECs: `.af/docs/usm/source/specs/SPEC-XXXX.json` — only for cross-cutting work or US that warrant multiple SPECs.
- Bugs:  `.af/docs/usm/source/bugs/BUG-XXXX.json`.
- Catalogue: `.af/docs/usm/source/INDEX.md` — grep-friendly listing of all stories (with a `spec` column showing `inline` / `external` / `—`), standalone SPECs and bugs with id, title and status.

The bundled `.af/docs/usm/{data,specs,bugs}.js` are generated artifacts produced by `.af/bin/build-usm.py` for the static HTML viewer to read. Never hand-edit them.

IDs are zero-padded and unique across history:

- User Stories: `US-####` (e.g. `US-0001`)
- Features:    `SPEC-####`
- Bugs:        `BUG-####`

The next number is one above the highest ID currently listed in `source/INDEX.md` — including archived/fixed entries, which stay in `source/` as a record.

Each standalone SPEC or BUG links to a User Story via the `story` field (e.g. `"story": "US-0001"`). A story can have many standalone SPECs and many bugs in addition to its own inline SPEC content.

Schema reference: `.af/docs/usm.md`.

## US status lifecycle

| status     | meaning                                                                       |
|------------|-------------------------------------------------------------------------------|
| `proposed` | PM filed it. Narrative may be complete; inline SPEC may be empty or in draft. |
| `ready`    | Spec'd and confirmed (inline SPEC, or at least one linked SPEC `ready`).       |
| `active`   | Developer is implementing.                                                    |
| `done`     | Implemented and accepted by the PM.                                           |
| `dropped`  | Cut from scope.                                                               |

## Standalone SPEC status lifecycle

| status     | meaning                                                  |
|------------|----------------------------------------------------------|
| `draft`    | Lead writing it, or PM hasn't confirmed yet              |
| `ready`    | Confirmed — Developer can start                          |
| `approved` | Implemented and accepted by PM, awaiting PR              |
| `archived` | PR merged; entry kept as a record                        |

## BUG status lifecycle

| status        | meaning                                              |
|---------------|------------------------------------------------------|
| `open`        | PM just reported it                                  |
| `in-progress` | Lead/Developer working on it                         |
| `fixed`       | Corrected and merged                                 |
| `wont-fix`    | Decision not to fix                                  |

## Session focus

Each command does one phase of the workflow and stops. The agent does not auto-progress to the next phase — if the PM wants to move on, they start a new session with the next command.

- `/af-create-backbone` defines or extends Activities + Steps in `source/skeleton.json`. Requires `domain.md` populated. It does not create Stories.
- `/af-create-slice` writes a new slice file under `source/releases/` with `id`, `title`, `goal` (mandatory), and `status` (`planning` by default). After writing it, the command offers to continue into a Backlog sweep (move candidate stories into the slice one-by-one) and a value-delivery walkthrough (10-axis rubric anchored on the goal — propose new US for gaps, after checking for cross-slice coverage). The PM can stop after the slice is recorded and resume later. It does not write SPECs and does not add new Activities.
- `/af-review-slice <slice-id>` is the readiness check before flipping a slice to `in-progress`. Shows a US-by-US readiness table (which SPECs are `draft`/`ready`/`approved`), reruns the value-delivery rubric as a delta against the current state, asks about scope changes, and prints a verdict — *ready to flip* or *pendings before flip*. It does not edit the slice's `status` (PM does that manually) and it does not write SPECs.
- `/af-create-story` files a new US under an existing Step (and may add a Step inline if needed) as a new file in `source/stories/`. When the PM names a slice, the slice's goal anchors the story. It does not write SPEC content — the PM runs `/af-create-spec` in a separate session when ready.
- `/af-create-spec` writes SPEC content. By default it edits the US file in place, adding the six inline SPEC fields and flipping US `status` to `ready` on confirmation. Falls back to a standalone file under `source/specs/SPEC-XXXX.json` for cross-cutting work (`story: null`) or when the PM explicitly wants the US split across multiple SPECs. It does not implement.
- `/af-create-bug` writes a BUG as a new file in `source/bugs/`. It does not fix.
- `/af-implement-spec` implements either a US with `status: ready` (inline SPEC path) or a standalone SPEC with `status: ready` from `source/specs/`. It does not pick up another work item.
- `/af-implement-slice <slice-id>` is the one command that deliberately breaks the single-phase rule: it implements every ready US in an `in-progress` slice back-to-back, in backbone order, on one `feat/<slice-id>` branch, with no PM stop between stories, then produces one combined handoff. It skips US that are not `ready` (they need `/af-create-spec` first), halts on a genuine blocker, and leaves the implemented US `active` for the PM's review — it never writes SPECs and never flips a US to `done`.
- `/af-fix-bug` fixes an `in-progress` (or `open`, after confirmation) BUG from `source/bugs/` and writes a regression test. It does not pick up another BUG.

Keep sessions focused on a single phase. This keeps scope and review boundaries crisp.
