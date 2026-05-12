# /af-fix-bug

**Trigger:** PM hands the Developer a BUG ID to fix.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Find the BUG entry in `.af/docs/usm/bugs.js` by its ID (e.g. `BUG-0001`) — verify `status` is `"in-progress"` (or `"open"` if PM just confirmed the handoff)
3. Apply each step in `fix[]` in order, flipping each `done` to `true` in `bugs.js` when complete
4. Write the regression test described in `regressionTest` — mandatory, not optional
5. Notify PM when complete

**Key difference from /af-implement-spec:** Regression test is always required. No fix is complete without it.

**Output:** Changed source files + regression test + updated entry in `bugs.js`. PM must approve before PR is created. After merge, `status` flips to `"fixed"`.
