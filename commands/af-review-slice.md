---
model: sonnet
effort: medium
---

# /af-review-slice

**Trigger:** PM wants to verify whether a slice is ready before flipping `planning → in-progress` (and optionally again before `released`). Lists pendings, re-runs the value-delivery rubric against the current state, and gives a verdict. Does not edit the slice's `status` — the PM still flips it manually.

**Arguments:** `<slice-id>` — id of the slice to review.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Read `.af/docs/usm/source/releases/<slice-id>.json`. If `goal` is empty, **stop** and ask the PM to set it first (via `/af-create-slice` or by editing the file directly).
3. Read every story in `source/stories/` with `slice: <slice-id>`. For each story, check whether it has inline SPEC content (`subtasks` array on the US itself) and/or any standalone SPECs under `source/specs/` (filter by `story == <US-id>`).
4. Read `source/INDEX.md` and the other files in `source/releases/` so cross-slice coverage checks can compare against `released`/`in-progress` slices.

**Steps:**

1. **Readiness table.** Show the PM one row per US with its SPEC source and an annotation. Pick the row state from the US `status` and the available SPEC content:
   - `no SPEC` — US `status: proposed` with no inline `subtasks` and no standalone SPEC. Resolve with `/af-create-spec`.
   - `pending Lead` — inline SPEC is being drafted (US still `proposed`, partial fields), or a linked standalone SPEC is `draft`. Lead still writing or awaiting clarification.
   - `pending PM` — inline SPEC fields are filled but the US `status` is still `proposed`, or a linked SPEC is `draft` and Lead believes it is complete. Awaiting PM confirmation.
   - `ready` — US `status: ready` (inline path) or at least one linked SPEC `status: ready` (standalone path). Developer can pick it up.
   - `active` / `done` — already in implementation; flag this if the slice is still `planning`.
   - `approved` / `archived` — applies to standalone SPECs only. Same flag as above when the slice is still `planning`.

2. **Rubric delta.** Apply the Value-delivery rubric (`.af/agents/lead.md`) against the current slice contents, surfacing **only changes since the last walkthrough**:
   - Axes already covered by a US in this slice → list as covered. No question.
   - Axes covered by a US in another slice with `status: released` or `in-progress` → list as covered (note which US and which slice). No question.
   - Axes where coverage regressed (covering slice de-scoped, story moved out) → flag and ask.
   - Axes where a new gap appeared (scope changed, a story was reshaped) → propose a new US following the same protocol as `/af-create-slice` Phase 3 (PM confirms one-by-one).

3. **Scope question.** Ask the PM one question: *"Has anything changed in the release's scope since the slice was created? Stakeholders adding requirements, stories that no longer apply, integrations dropped, etc."* Walk through any changes case by case. New US go through the same write protocol as `/af-create-slice` Phase 3.

4. **Verdict.** Print one of:
   - **Ready to flip to `in-progress`** — every US is at `status: ready` (inline path) or has at least one linked SPEC `status: ready` (or beyond), no rubric gaps, no scope changes pending.
   - **Pendings before flip** — list blockers, one line each, naming the responsible role (Lead, PM, Developer).

**Output:** Slice id, its goal, the readiness table, the rubric delta summary, and the verdict. No file is written by this command except newly-proposed US (which follow the same write protocol as `/af-create-slice` Phase 3).

**Scope (what this command does *not* do):**

- It does not edit `releases/<slice-id>.json` — the PM flips `status` manually after reviewing the verdict.
- It does not write SPECs — `no SPEC` and `pending Lead` rows are resolved by running `/af-create-spec` in separate sessions.
- It does not chain into `/af-create-spec` or `/af-implement-spec`.

**Stop here.** Slice review is its own session.
