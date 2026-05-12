# /af-create-spec

**Trigger:** PM picks an existing US from the USM (`.af/docs/usm/data.js`) and asks the Lead to spec it out. If no matching US exists yet, the PM should run `/af-create-story` first.

**Steps:**

1. Load agent: `.af/agents/lead.md`.
2. **Preparation (mandatory, before any question):** read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, and the target US in `.af/docs/usm/data.js`. Then read the existing code paths the SPEC will touch (the related Django app under `backend/apps/`, at least one existing page under `frontend/src/pages/` plus its store and service, the test patterns under `backend/apps/users/tests/integration/` and `frontend/tests/unit/`). This is so subtasks can name real files. For cross-cutting work that doesn't map to a US, skip the US lookup and note the gap in `constraints`.
3. Lead asks clarifying questions only for what the codebase cannot answer — product intent, acceptance edge cases, scope boundaries. One question at a time.
4. Lead drafts the SPEC as a JSON object following the schema in `.af/templates/spec.md`. `status: "draft"`. Every box of the "SPEC completeness checklist" in `.af/agents/lead.md` must be checked before flipping status.
5. PM reviews. On confirmation, Lead flips `status` to `"ready"`.
6. **Register:** append the entry to `.af/docs/usm/specs.js` (`window.USM_SPECS`). ID is `SPEC-####` — next available number above the highest ID currently in the file (archived entries count). Set `story` to the matching `US-XXXX` from `.af/docs/usm/data.js`, or `null` for cross-cutting work. Preserve every other entry — never replace the array.

**Output:** The ID of the confirmed SPEC (e.g. `SPEC-0014`) and the file it was written to (`.af/docs/usm/specs.js`). The HTML USM at `.af/docs/usm/index.html` picks it up automatically on next reload.

**Do not:** write `.md` files in `.af/specs/`. That location is deprecated. The JSON entry is the canonical SPEC.
