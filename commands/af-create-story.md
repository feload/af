---
model: sonnet
effort: medium
---

# /af-create-story

**Trigger:** PM wants to add a new User Story (Option) to the USM. Stories are the scope unit in af — they live inside the map under a Step, not in an external tracker.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Open `.af/docs/usm/source/skeleton.json`. If `activities` is empty (no activities or no steps under any activity), **stop**. Tell the PM the backbone is missing and that they should run `/af-create-backbone` first, then `/af-create-story` again. Do not improvise the backbone here.
3. If a backbone exists, read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, `skeleton.json`, and `source/INDEX.md` so the Lead understands the existing map and the highest US id in use.
4. List the files under `.af/docs/usm/source/releases/`. These are the candidate slices the PM may attach the story to; each carries a `goal` that justifies its scope.

**Steps:**

1. Ask the PM whether the story belongs to a specific slice (release) or to the Backlog. If the PM names a slice, read `.af/docs/usm/source/releases/<slice-id>.json` and **anchor every later step on that slice's `goal`** — the story's narrative, rationale and acceptance criteria must visibly serve the goal. If the PM is unsure, list the non-released slices with their goals so they can pick one (or choose Backlog). If no slice has a matching goal, the story goes to Backlog (`slice: null`) and the PM can either run `/af-create-slice` to start a slice for it or move it later. If the named slice has an empty `goal`, **stop** and tell the PM to set the slice's goal first (via `/af-create-slice` or by editing the slice file directly) — without a goal the slice can't drive story selection.
2. Ask the PM to describe the story in plain language — who the user is, what they want to do, and why it matters. If a slice was named, frame the prompt around its goal (e.g. *"Within the goal '<goal>', what does the user want to do?"*).
3. Suggest the Step the story should hang from. Pick the closest match from the existing `steps` inside an `activity` and present it to the PM with the activity it belongs to (e.g. *Activity "Onboarding" → Step "Sign up"*). The PM confirms, picks a different Step, or asks for a new Step.
4. If the PM wants a new Step (because the story doesn't fit anything existing), draft the Step inline: ask for the parent Activity, propose an `id` and `title`, confirm, and append it to that activity's `steps[]` inside `source/skeleton.json`. **Do not** add new Activities here — Activities belong to `/af-create-backbone`.
5. Ask clarifying questions one at a time until the story has narrative (description), rationale, and acceptance criteria. If a slice was named, every acceptance criterion must be traceable to the slice's goal — push back on items that don't serve it. Tasks are optional and only added if the PM volunteers concrete tasks at this stage.
6. Draft the story as a JSON object following the `stories/US-XXXX.json` schema in `.af/docs/usm.md`:
   - `id`: next free `US-####` above the highest ID currently listed in `source/INDEX.md`.
   - `title`, `status: "proposed"`.
   - `slice`: the slice id the PM picked, or `null` for Backlog.
   - `step`: the id of the Step it hangs from (required — this is what the build script uses to nest the story under the backbone).
   - `description`, `rationale`, `acceptance`: filled from the conversation.
   - `tasks`: omit unless the PM provided them.
7. Show the PM the drafted entry and the target Step. If a slice was named, restate the slice goal next to the story so the alignment is explicit. Confirm.
8. On confirmation, write the entry to `.af/docs/usm/source/stories/US-####.json`. One file, one story — never append to or edit another story's file.
9. Run `python3 .af/bin/build-usm.py` so the generated `data.js` and `source/INDEX.md` reflect the new story.

**Output:** The ID of the confirmed US (e.g. `US-0014`), the Activity/Step it was attached to, the slice it was filed under (or `null` for Backlog), and the file written (`.af/docs/usm/source/stories/US-XXXX.json`). The HTML USM at `.af/docs/usm/index.html` picks it up automatically on next reload.

**Stop here.** Do not load the Lead for SPEC drafting. Story creation is its own session — the PM runs `/af-create-spec` in a separate session when they're ready to spec out the story.
