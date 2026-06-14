---
model: sonnet
effort: medium
---

# /af-create-slice

**Trigger:** PM wants to plan a new release (slice) — record its goal, attach the User Stories that will ship together, and detect what is missing to deliver value end-to-end.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Read `.af/docs/usm.md` (slice schema, especially "Slice goal" and "Slice status"), `.af/docs/workflow.md` (release-goal-driven slicing), and `.af/docs/usm/source/INDEX.md` (existing stories, slices, statuses).
3. List the files under `.af/docs/usm/source/releases/` so the proposed slice id does not collide.

**Phase 1 — Record the slice**

1. Ask the PM for the slice's **goal** — one sentence in the future tense from the user's perspective (e.g. *"Returning users can resume a draft from any device"*, not *"Implement draft sync"*). The goal is mandatory before the slice can flip to `in-progress` or `released`.
2. Ask for a short `title` (e.g. *"v1.0 — Multi-device drafts"*) and a stable `id` in kebab-case (e.g. `v1-0`). Confirm both.
3. Ask for the initial `status`. Default to `planning`. Refuse `in-progress` or `released` if the goal is empty.
4. Draft `{ id, title, goal, status }`, show it to the PM, confirm. On confirmation, write to `.af/docs/usm/source/releases/<slice-id>.json` and run `python3 .af/bin/build-usm.py`.

**Decision point**

5. Ask the PM whether to continue planning the slice's content (Backlog sweep + value-delivery walkthrough) or stop here with the slice in `planning`.
   - **Stop here** → jump to **Output**.
   - **Continue** → proceed to Phase 2.

**Phase 2 — Sweep the Backlog**

6. Read stories in `source/stories/` with `slice: null`. For each that visibly serves the slice's goal, present one at a time:
   *"`US-####` <title> — looks like it serves the goal because <reason>. Move into this slice?"*
   - **Yes** → rewrite the story's JSON with `slice: <slice-id>`. Run `build-usm.py`.
   - **No** → leave it in Backlog.
7. Stop the sweep when every candidate has been triaged or the PM signals "no more matches".

**Phase 3 — Value-delivery walkthrough**

8. Apply the **Value-delivery rubric** defined in `.af/agents/lead.md` anchored on the slice's goal. Walk through the 10 axes in order. For each axis use the cross-slice coverage protocol (clear match / ambiguous match / no match) described in that section.
9. When the PM accepts a new US for an axis, draft it following the `/af-create-story` schema: next free `US-####` from `source/INDEX.md`, `step` from `source/skeleton.json` (pick the closest existing step; do not add new Activities here), narrative + rationale + acceptance anchored on the slice goal. PM confirms. Write to `source/stories/US-####.json` with `slice: <slice-id>` and `status: "proposed"`. Run `build-usm.py`.
10. When the PM points to a US in another slice as covering an axis, leave that US untouched — it already lives where it shipped. Just note it in the session output.
11. Stop when the 10 axes have been triaged.

**Output:** The slice id, its goal, total stories now under the slice (moved + newly proposed), and a one-line note per axis: covered (by which US), new US (which `US-####`), or not applicable.

**Scope (what this command does *not* do):**

- It does not flip an existing slice's status to `in-progress` or `released` — status transitions are PM-driven edits to the slice file. Re-run `build-usm.py` after the edit.
- It does not write SPECs — that is `/af-create-spec`. Pass it this slice's id to spec every un-spec'd US in the slice in one session, or a single `US-####` to spec one at a time.
- It does not add new Activities — those belong to `/af-create-backbone`.

**Stop here.** Slice planning is its own session. Next, the PM runs `/af-create-spec <slice-id>` to spec the slice's US in one pass (or `/af-create-spec <US-####>` one at a time), and `/af-review-slice` before flipping `planning → in-progress`.
