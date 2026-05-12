# AI-Assisted Development Workflow

## Roles

**PM (user)** — owns the USM. Maintains the backbone (Activities + Steps), files Stories under Steps, confirms SPECs and Bugs, reviews implementations, approves PRs.

**Lead** — turns a Story into a SPEC detailed enough that the Developer can implement it without exploring or making scope decisions. Also drafts BUG entries from PM reports.

**Developer** — implements the SPEC (or the BUG fix) as written. Does not explore, does not decide scope.

## Domain first, then backbone, then stories

af is self-contained: there is no external tracker. All scope lives in the USM under `.af/docs/usm/`. New work flows top-down:

1. **Domain** — `.af/docs/domain.md` must be populated (entities, business rules, glossary) before the backbone is meaningful. The Lead refuses to design a backbone over an empty `domain.md`.
2. **Backbone** — Activities (the user's journey, left-to-right) and Steps (concrete actions inside each Activity) live in `.af/docs/usm/data.js`. Build or extend with `/af-create-backbone`.
3. **Stories** — User Stories (Options) hang off Steps in the same `data.js`. Create with `/af-create-story`. Default `slice` is `null` (Backlog); the PM moves them into a slice when planning a release.
4. **SPECs / Bugs** — written against a Story (or as cross-cutting work). Live as JSON in `.af/docs/usm/specs.js` and `.af/docs/usm/bugs.js`.

## Flow

```
PM: backbone exists? if not → /af-create-backbone
PM: /af-create-story → US-#### proposed in data.js (slice: null)
PM: /af-create-spec → Lead writes SPEC entry in specs.js → PM confirms → status: ready
Developer: /af-implement-spec → implements subtasks + tests → hands off test tree + run commands
PM: review + run tests → status: approved
Developer: create PR
PM: approve PR → status: archived
```

## Rules

- Every Story starts in Backlog (`slice: null`) unless the PM explicitly slices it.
- Every implementation starts from a `ready` SPEC; every fix starts from an `in-progress` BUG.
- The SPEC is the single source of truth — it must be complete enough to implement without questions.
- Lead is responsible for SPEC quality: if Developer is blocked, Lead failed to spec it well enough.
- Developer does not make scope decisions — if something is ambiguous, they stop and flag it.
- New Activities are only added via `/af-create-backbone`. `/af-create-story` may add a new Step inline when no existing Step fits, but never a new Activity.

## Bug flow

```
PM: /af-create-bug → Lead investigates root cause (targeted) → writes BUG entry in bugs.js → PM confirms → status: in-progress
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

- **In scope of the active SPEC** — an acceptance criterion is not yet met, or a subtask uncovered a small adjacent issue inside the same files. Fix it in the current SPEC, no new BUG entry.
- **Out of scope of the active SPEC** — the defect is in files or behavior not listed in the SPEC, or in code that was already shipped. Stop, file a separate BUG entry in `bugs.js` (`status: open`, link `story` if it fits one), and continue with the original SPEC. The bug is triaged like any other afterwards.

The rule: if you can address it without changing the SPEC's subtasks, it's in scope. If addressing it would require new subtasks or touch files the SPEC didn't list, it's a separate BUG.

## Drafts and orphan entries

The USM header surfaces two trays:

- **🐞 N bugs abiertos** — counter of bugs with status `open` or `in-progress`. Click toggles a filter that hides every US without open bugs, so the map shows only where it hurts.
- **📋 N sin asignar** — counter of (a) all SPECs with `status: "draft"`, (b) all bugs with `story: null` and (c) all SPECs with `story: null`. Click opens the side pane in tray mode, listing the groups with full detail. This is the Lead's review surface for unfinished or unattached work.

A SPEC may legitimately have `story: null` for cross-cutting work (infrastructure, refactor, CI). Such SPECs are not pinned to a US in the map, but the Developer can still implement them by ID — they live in `specs.js` like any other. Drafts always show up in the tray regardless of whether they have a `story`, as a reminder for the Lead to finish them.

## Artifact location and naming

Everything af tracks lives under `.af/docs/usm/`:

- Backbone + Stories: `.af/docs/usm/data.js` (`window.USM_DATA`)
- SPECs: `.af/docs/usm/specs.js` (`window.USM_SPECS`)
- Bugs:  `.af/docs/usm/bugs.js`  (`window.USM_BUGS`)

IDs are zero-padded and unique across history:

- User Stories: `US-####` (e.g. `US-0001`)
- Features:    `SPEC-####`
- Bugs:        `BUG-####`

The next number is one above the highest ID currently present in the file — including archived/fixed entries, which stay in the JSON as a record.

Each SPEC or BUG links to a User Story via the `story` field (e.g. `"story": "US-0001"`). A story can have many SPECs and many bugs.

Schema reference: `.af/docs/usm.md`.

## SPEC status lifecycle

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

- `/af-create-backbone` defines or extends Activities + Steps in `data.js`. Requires `domain.md` populated. It does not create Stories.
- `/af-create-story` files a new US under an existing Step (and may add a Step inline if needed). It does not write SPECs.
- `/af-create-spec` writes a SPEC entry in `specs.js`. It does not implement.
- `/af-create-bug` writes a BUG entry in `bugs.js`. It does not fix.
- `/af-implement-spec` implements a `ready` SPEC from `specs.js`. It does not pick up another SPEC.
- `/af-fix-bug` fixes an `in-progress` (or `open`, after confirmation) BUG from `bugs.js` and writes a regression test. It does not pick up another BUG.

Keep sessions focused on a single phase. This keeps scope and review boundaries crisp.
