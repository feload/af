# /af-fix-bug

**Trigger:** PM hands the Developer a BUG SPEC to fix.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Read `.af/specs/active/BUG-####.md` — verify status is `ready`
3. Apply fix steps in order, marking each `[x]` when done
4. Write the regression test — mandatory, not optional
5. Notify PM when complete

**Key difference from /af-implement-spec:** Regression test is always required. No fix is complete without it.

**Output:** Changed files + regression test + updated BUG SPEC. PM must approve before PR is created.
