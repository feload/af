# /af-implement-spec

**Trigger:** PM hands the Developer the ID of the work item to implement. This can be either:

- **`US-XXXX`** — the SPEC lives inline on the User Story (default for 1:1 work). The Developer reads and updates the US file directly.
- **`SPEC-XXXX`** — the SPEC is a standalone file under `source/specs/` (cross-cutting work, or a US that was split across several SPECs).

**Steps:**
1. Load agent: `.af/agents/developer.md`
2. Locate the work item:
   - If the argument is `US-XXXX`: open `.af/docs/usm/source/stories/US-XXXX.json` (find the path via `.af/docs/usm/source/INDEX.md` if needed). Verify the US `status` is `"ready"` and that it carries inline SPEC fields (`subtasks` at minimum). If the US is `ready` because of linked standalone SPECs only (no inline `subtasks`), stop and ask the PM which standalone SPEC to implement.
   - If the argument is `SPEC-XXXX`: open `.af/docs/usm/source/specs/SPEC-XXXX.json`. Verify `status` is `"ready"`. Do not read `.af/docs/usm/specs.js`; it is a generated artifact.
3. **Mark the work item active.** For the inline path, flip the US `status` from `ready` to `active`. For the standalone path, leave the SPEC at `ready` (the SPEC's lifecycle has no `active` value — the linked US, if any, can be flipped to `active` by the PM separately).
4. Implement subtasks in order, flipping each `done` to `true` in the same JSON file when complete. Run `python3 .af/bin/build-usm.py` after edits so the bundles stay in sync (the pre-commit hook does this for you on commit if `git config core.hooksPath .af/hooks` is set).
5. Notify PM when all subtasks are complete (hand off the test tree + run commands per `.af/agents/developer.md`).

**Output:** Changed source files + the updated work item file (US or SPEC) + regenerated bundles. PM must accept before the PR is created:

- Inline path: PM flips US `status` to `"done"` after review (and merges the PR; the US stays `done` as a record).
- Standalone path: PM flips SPEC `status` to `"approved"` after review, and to `"archived"` after the PR is merged.
