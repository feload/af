# /af-implement-spec

**Trigger:** PM hands the Developer a SPEC ID to implement.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Open the SPEC file at `.af/docs/usm/source/specs/SPEC-XXXX.json` (find the path via `.af/docs/usm/source/INDEX.md` if needed) — verify `status` is `"ready"`. Do not read `.af/docs/usm/specs.js`; it is a generated artifact.
3. Implement subtasks in order, flipping each `done` to `true` in the same JSON file when complete. Run `python3 .af/bin/build-usm.py` after edits so the bundles stay in sync (the pre-commit hook does this for you on commit if `git config core.hooksPath .af/hooks` is set).
4. Notify PM when all subtasks are complete

**Output:** Changed source files + updated `source/specs/SPEC-XXXX.json` + regenerated bundles. PM must approve (`status: "approved"`) before PR is created.
