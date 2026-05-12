# /af-implement-spec

**Trigger:** PM hands the Developer a SPEC ID to implement.

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Find the SPEC entry in `.af/docs/usm/specs.js` by its ID (e.g. `SPEC-0001`) — verify `status` is `"ready"`
3. Implement subtasks in order, flipping each `done` to `true` in `specs.js` when complete
4. Notify PM when all subtasks are complete

**Output:** Changed source files + updated entry in `specs.js`. PM must approve (`status: "approved"`) before PR is created.
