# /implement-spec

**Trigger:** PM hands the Developer a SPEC file to implement.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Read `.af/specs/active/SPEC-####.md` — verify status is `ready`
3. Implement subtasks in order, marking each `[x]` when done
4. Notify PM when all subtasks are complete

**Output:** Changed files + updated SPEC. PM must approve before PR is created.
