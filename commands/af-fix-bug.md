# /af-fix-bug

**Trigger:** PM hands the Developer a BUG ID to fix.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Open the BUG file at `.af/docs/usm/source/bugs/BUG-XXXX.json` (find the path via `.af/docs/usm/source/INDEX.md` if needed) — verify `status` is `"in-progress"` (or `"open"` if PM just confirmed the handoff). Do not read `.af/docs/usm/bugs.js`; it is a generated artifact.
3. Apply each step in `fix[]` in order, flipping each `done` to `true` in the same JSON file when complete. Run `python3 .af/bin/build-usm.py` after edits so the bundles stay in sync (the pre-commit hook does this for you on commit if `git config core.hooksPath .af/hooks` is set).
4. Write the regression test described in `regressionTest` — mandatory, not optional
5. Notify PM when complete

**Key difference from /af-implement-spec:** Regression test is always required. No fix is complete without one.

**Output:** Changed source files + regression test + updated `source/bugs/BUG-XXXX.json` + regenerated bundles. PM must approve before PR is created. After merge, `status` flips to `"fixed"`.
