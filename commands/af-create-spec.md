# /af-create-spec

**Trigger:** PM picks an existing US from the USM (look it up in `.af/docs/usm/source/INDEX.md`) and asks the Lead to spec it out. If no matching US exists yet, the PM should run `/af-create-story` first.

**Steps:**

1. Load agent: `.af/agents/lead.md`.
2. **Preparation (mandatory, before any question):** read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, and the target US in `.af/docs/usm/source/stories/US-XXXX.json` (use `source/INDEX.md` to find it). Then read the existing code paths the SPEC will touch (the related Django app under `backend/apps/`, at least one existing page under `frontend/src/pages/` plus its store and service, the test patterns under `backend/apps/users/tests/integration/` and `frontend/tests/unit/`). This is so subtasks can name real files. For cross-cutting work that doesn't map to a US, skip the US lookup and note the gap in `constraints`.
3. Lead asks clarifying questions only for what the codebase cannot answer — product intent, acceptance edge cases, scope boundaries. One question at a time.
4. Lead drafts the SPEC as a JSON object following the schema in `.af/templates/spec.md`. `status: "draft"`. Every box of the "SPEC completeness checklist" in `.af/agents/lead.md` must be checked before flipping status.
5. PM reviews. On confirmation, Lead flips `status` to `"ready"`.
6. **Register:** write the entry to `.af/docs/usm/source/specs/SPEC-####.json`. ID is `SPEC-####` — next available number above the highest ID currently listed in `source/INDEX.md` (archived entries count). Set `story` to the matching `US-XXXX`, or `null` for cross-cutting work. One file per SPEC — never edit another SPEC's file.
7. Run `python3 .af/bin/build-usm.py` so the generated `specs.js` and `source/INDEX.md` pick up the new entry.

**Output:** The ID of the confirmed SPEC (e.g. `SPEC-0014`) and the file written (`.af/docs/usm/source/specs/SPEC-XXXX.json`). The HTML USM at `.af/docs/usm/index.html` picks it up automatically on next reload.

**Do not:** write `.md` files in `.af/specs/` — that location is deprecated. Do not hand-edit the bundled `.af/docs/usm/specs.js` either; it is a generated artifact rebuilt by `build-usm.py`.
