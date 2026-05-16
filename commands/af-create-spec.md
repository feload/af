# /af-create-spec

**Trigger:** PM picks an existing US from the USM (look it up in `.af/docs/usm/source/INDEX.md`) and asks the Lead to spec it out. If no matching US exists yet, the PM should run `/af-create-story` first. For cross-cutting work that has no matching US (infra, refactor, CI), this command can still produce a standalone SPEC with `story: null`.

**Default behavior:** the SPEC content is written **inline on the US**. The Lead edits `.af/docs/usm/source/stories/US-XXXX.json` to add the six SPEC fields (`context`, `problem`, `constraints`, `subtasks`, `edgeCases`, `doneCriteria`) and, on PM confirmation, flips the US `status` from `proposed` to `ready`. No standalone file is created.

A standalone file under `source/specs/SPEC-XXXX.json` is only created when:

- The work is cross-cutting and has no matching US (`story: null`), or
- The PM explicitly wants the US split across several SPECs (large story, parallel implementations, separate ownership).

**Steps:**

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

**Do not:** write `.md` files in `.af/specs/` — that location is deprecated. Do not hand-edit the bundled `.af/docs/usm/specs.js` either; it is a generated artifact rebuilt by `build-usm.py`.
