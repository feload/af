---
model: sonnet
effort: medium
---

# /af-create-slice

**Trigger:** PM wants to create a new release (slice) in the USM. A slice groups the User Stories that will ship together and is anchored by a **goal** — the one sentence that justifies why those stories ship as a set.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Read `.af/docs/usm.md` (slice schema, especially the "Slice goal" and "Slice status" sections), `.af/docs/workflow.md` (release-goal-driven slicing), and `.af/docs/usm/source/INDEX.md` if it exists so the Lead knows the in-flight slices.
3. List the existing files under `.af/docs/usm/source/releases/` so the proposed slice id doesn't collide with one already on disk.

**Steps:**

1. Ask the PM for the slice's **goal** — one sentence describing *what shipping this release achieves for the user or business*, future-tense from the user's perspective where possible (e.g. *"Returning users can resume a draft from any device"*, not *"Implement draft sync"*). The goal is mandatory before the slice can flip to `in-progress` or `released`.
2. Ask the PM for a short `title` for the slice (e.g. *"v1.0 — Multi-device drafts"*) and a stable `id` in kebab-case (e.g. `v1-0`, `mvp`, `pilot-tenant`). Confirm both.
3. Ask the PM for the initial `status`. Default to `planning`. Decline to set `in-progress` or `released` if the goal is empty.
4. Draft the slice as a JSON object:
   ```json
   {
     "id": "<slice-id>",
     "title": "<short title>",
     "goal": "<one-sentence goal>",
     "status": "planning"
   }
   ```
5. Show the PM the drafted entry and confirm.
6. On confirmation, write the entry to `.af/docs/usm/source/releases/<slice-id>.json`. One file per slice — never edit another slice's file.
7. Run `python3 .af/bin/build-usm.py` so the generated `data.js` picks up the new slice.

**Output:** The slice id (e.g. `v1-0`), its goal, and the file written (`.af/docs/usm/source/releases/<slice-id>.json`). The HTML USM at `.af/docs/usm/index.html` picks it up on next reload.

**Scope (what this command does *not* do):**

- It does not create Stories. After the slice exists, run `/af-create-story` (or move existing Backlog stories into the slice manually) and reference the slice — the Lead will use the slice's goal to anchor each story.
- It does not flip an existing slice's status to `in-progress` or `released`. Status transitions are PM-driven edits to the slice's JSON file. Re-run `build-usm.py` after the edit.
- It does not write SPECs or Bugs.

**Stop here.** Slice creation is its own session — the PM runs `/af-create-story` in a separate session when they're ready to file stories under the new slice.
