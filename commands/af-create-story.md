---
model: sonnet
effort: medium
---

# /af-create-story

**Trigger:** PM wants to add a new User Story (Option) to the USM. Stories are the scope unit in af — they live inside the map under a Step, not in an external tracker.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Open `.af/docs/usm/data.js`. If `window.USM_DATA.activities` is empty (no activities or no steps under any activity), **stop**. Tell the PM the backbone is missing and that they should run `/af-create-backbone` first, then `/af-create-story` again. Do not improvise the backbone here.
3. If a backbone exists, read `.af/docs/domain.md`, `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, and `data.js` itself so the Lead understands the existing map.

**Steps:**

1. Ask the PM to describe the story in plain language — who the user is, what they want to do, and why it matters.
2. Suggest the Step the story should hang from. Pick the closest match from the existing `steps` inside an `activity` and present it to the PM with the activity it belongs to (e.g. *Activity "Onboarding" → Step "Sign up"*). The PM confirms, picks a different Step, or asks for a new Step.
3. If the PM wants a new Step (because the story doesn't fit anything existing), draft the Step inline: ask for the parent Activity, propose an `id` and `title`, confirm, and append it to that activity's `steps[]` in `data.js`. **Do not** add new Activities here — Activities belong to `/af-create-backbone`.
4. Ask clarifying questions one at a time until the story has narrative (description), rationale, and acceptance criteria. Tasks are optional and only added if the PM volunteers concrete tasks at this stage.
5. Draft the story as a JSON object following the `stories[]` schema in `.af/docs/usm.md`:
   - `id`: next free `US-####` above the highest ID currently in `data.js` (deduped across activities/steps).
   - `status`: `"proposed"`.
   - `slice`: `null` (Backlog by default — the PM moves it to a slice later when planning a release).
   - `description`, `rationale`, `acceptance`: filled from the conversation.
   - `tasks`: omit unless the PM provided them.
6. Show the PM the drafted entry and the target Step, confirm.
7. On confirmation, append the entry to `stories[]` of the matching Step in `.af/docs/usm/data.js`. Preserve every other entry — never replace the array.

**Output:** The ID of the confirmed US (e.g. `US-0014`), the Activity/Step it was attached to, and the file it was written to (`.af/docs/usm/data.js`). The HTML USM at `.af/docs/usm/index.html` picks it up automatically on next reload.

**Stop here.** Do not load the Lead for SPEC drafting. Story creation is its own session — the PM runs `/af-create-spec` in a separate session when they're ready to spec out the story.
