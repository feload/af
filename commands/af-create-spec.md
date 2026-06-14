# /af-create-spec

**Trigger:** PM asks the Lead to spec out work. Three ways to call it:

- **A single US** — pass a `US-####` (or omit the argument and the Lead asks which US, looking it up in `.af/docs/usm/source/INDEX.md`). Spec that one story. If no matching US exists yet, the PM should run `/af-create-story` first.
- **A whole slice** — pass a slice id (e.g. `v1-0`). The Lead specs **every un-spec'd US in that slice** in one session, US by US, with a per-US confirm and a skip for any story that is not defined enough yet. This is the batch path: a slice already declares its scope through its `goal`, so its US are the ones worth speccing, while undefined ideas sit in the Backlog (`slice: null`) and are never touched.
- **Cross-cutting work** — no matching US (infra, refactor, CI). Produces a standalone SPEC with `story: null`.

**Arguments:** `[<US-#### > | <slice-id>]` — optional.

- Argument matches `US-####` → **single-US mode**.
- Argument matches a file under `.af/docs/usm/source/releases/` → **slice mode**.
- No argument → ask the PM whether they want one US or a whole slice, then proceed accordingly. If the argument is neither a known US nor a known slice, stop and list the valid ones.

**Default behavior (both modes):** the SPEC content is written **inline on the US**. The Lead edits `.af/docs/usm/source/stories/US-XXXX.json` to add the six SPEC fields (`context`, `problem`, `constraints`, `subtasks`, `edgeCases`, `doneCriteria`) and, on PM confirmation, flips the US `status` from `proposed` to `ready`. No standalone file is created.

A standalone file under `source/specs/SPEC-XXXX.json` is only created when:

- The work is cross-cutting and has no matching US (`story: null`), or
- The PM explicitly wants a US split across several SPECs (large story, parallel implementations, separate ownership).

## Single-US mode

1. Load agent: `.af/agents/lead.md`.
2. **Preparation (mandatory, before any question):** read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, and the target US in `.af/docs/usm/source/stories/US-XXXX.json` (use `source/INDEX.md` to find it). Then read the existing code paths the SPEC will touch (the related Django app under `backend/apps/`, at least one existing page under `frontend/src/pages/` plus its store and service, the test patterns under `backend/apps/users/tests/integration/` and `frontend/tests/unit/`). This is so subtasks can name real files. For cross-cutting work that doesn't map to a US, skip the US lookup and note the gap in `constraints`.
3. **Pick the SPEC location:**
   - If there is a matching US and the PM has not asked for a split, write **inline** on `source/stories/US-XXXX.json`.
   - If the US is large enough that the PM wants to split it, ask: *"Inline (one SPEC on the US) or split across several standalone SPECs?"* On split, write standalone files.
   - If there is no matching US, write a standalone SPEC with `story: null`.
4. Lead asks clarifying questions only for what the codebase cannot answer — product intent, acceptance edge cases, scope boundaries. One question at a time.
5. Lead drafts the SPEC content using the schema in `.af/templates/spec.md`. Every box of the "SPEC completeness checklist" in `.af/agents/lead.md` must be checked before the work is confirmed.
6. PM reviews. On confirmation:
   - **Inline path:** merge the six SPEC fields into `source/stories/US-XXXX.json` and flip US `status` from `proposed` to `ready`. Do not create any file under `source/specs/`.
   - **Standalone path:** write the entry to `source/specs/SPEC-####.json` with `status: "ready"`. ID is `SPEC-####` — next available number above the highest ID currently listed in `source/INDEX.md` (archived entries count). Set `story` to the matching `US-XXXX`, or `null` for cross-cutting work. One file per SPEC — never edit another SPEC's file.
7. Run `python3 .af/bin/build-usm.py` so the generated bundles and `source/INDEX.md` pick up the change.

**Output:** Either the US id with its new inline SPEC and `status: ready`, or the standalone SPEC id (e.g. `SPEC-0014`) and the file written. The HTML USM at `.af/docs/usm/index.html` picks it up automatically on next reload.

## Slice mode

Spec a whole slice in one session. This deliberately spans several US — the spec-side counterpart to `/af-implement-slice` — but unlike implementation it is interactive: each US gets its own clarifying questions and confirm. The win over running single-US sessions one by one is that the mandatory preparation (domain, architecture, conventions, schema) is read once and reused across every US in the slice.

1. Load agent: `.af/agents/lead.md`.
2. **Resolve the slice.** Read `.af/docs/usm/source/releases/<slice-id>.json`. If it does not exist, **stop** and list the available slices. If its `goal` is empty, **stop** and ask the PM to set it first (via `/af-create-slice` or by editing the file) — the goal is the anchor every SPEC in the batch is held to.
3. **Preparation (mandatory, once for the batch):** read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, and `.af/docs/usm.md`. (Per-US code reading happens inside the loop, in step 6, since each US touches different paths.)
4. **Build the queue.** From `source/INDEX.md` and `source/stories/`, collect every US with `slice: <slice-id>`. Partition:
   - **to spec** — US with `status: proposed` and no inline `subtasks` and no linked standalone SPEC. These are the batch.
   - **already spec'd** — US `ready`/`active`/`done`, or with inline `subtasks`, or a linked SPEC at `ready` or beyond. Skip; report for context.
   Order the *to spec* queue by **backbone position**: Activity left-to-right, then Step order, then US — so speccing follows the user's journey through the slice.
5. **Print the plan before drafting any SPEC:**
   - "Speccing N US in order: …"
   - "Skipping M already spec'd: …"
   Restate the slice `goal` so every SPEC is anchored to it.
6. **Walk the queue, one US at a time.** Keep this review concise — the PM is deciding spec-or-skip, not reading a dossier. For each US:
   - Present **only the story itself and its acceptance criteria**: the user-facing narrative (e.g. *"As a `<user>`, I want … so that …"*) and the `acceptance` list. Do **not** print the rationale, tasks, slice metadata, ids, or any other field, and do not restate the slice goal here (it was stated once in the plan). No preamble or commentary — just the story and its acceptance, then the question.
   - Ask the PM: **spec it now, or skip it?** Skip any US that is not defined enough yet — it stays `proposed` for a later pass. This is the escape hatch for "not everything in the slice is fully fleshed out."
   - If spec_ing: read the code paths this US touches (per single-US mode step 2), ask clarifying questions one at a time, draft the six inline SPEC fields per the "SPEC completeness checklist" in `.af/agents/lead.md`, anchored on the slice goal. PM confirms. On confirmation, merge the fields into `source/stories/US-XXXX.json` and flip its `status` from `proposed` to `ready`. (A standalone or split SPEC is written only if the PM explicitly asks for it on that US, exactly as in single-US mode.)
   - Run `python3 .af/bin/build-usm.py` after each confirmed US so progress is persisted and the USM reflects it mid-batch.
7. **Final rebuild and summary.** Run `python3 .af/bin/build-usm.py` once more if any US was written since the last rebuild.

**Output (slice mode):** The slice id and its goal, then one line per US — `ready` (newly spec'd), `skipped` (left `proposed`, with the reason), or `already spec'd`. The HTML USM picks the changes up on next reload. Note any US the PM skipped so they know what is still outstanding before `/af-review-slice`.

**Do not:** write `.md` files in `.af/specs/` — that location is deprecated. Do not hand-edit the bundled `.af/docs/usm/specs.js` either; it is a generated artifact rebuilt by `build-usm.py`. Do not spec US outside the named slice, and never touch Backlog US (`slice: null`) in slice mode.
