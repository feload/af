---
model: opus
effort: high
---

# /af-create-backbone

**Trigger:** PM wants to define or extend the USM backbone — the row of Activities (top) and their Steps (the second row). Stories hang off Steps; without a backbone there is nowhere to put them.

**Pre-flight (mandatory):**

1. Load agent: `.af/agents/lead.md`.
2. Read `.af/docs/domain.md`. **Verify it is populated** — i.e. the placeholders (`[Concept]`, `[Entity]`, `[Rule]`, `[Term]`) have been replaced with real content describing the product domain. If `domain.md` still looks like the template, **stop**. Tell the PM: "The backbone reflects the domain; populate `.af/docs/domain.md` first (entities, business rules, glossary), then re-run `/af-create-backbone`." Do not invent a backbone from nothing.
3. Read `.af/docs/architecture.md`, `.af/docs/conventions.md`, `.af/docs/usm.md`, and the current `.af/docs/usm/data.js` so the Lead knows what (if anything) is already there.

**Steps:**

1. Ask the PM which mode they want:
   - **Sketch a general structure** — Lead proposes a first-pass backbone (Activities left-to-right by user journey, with Steps under each) based on `domain.md`. PM reviews, edits, confirms.
   - **Build piece by piece** — Lead asks one Activity at a time, then the Steps inside each Activity. Slower but better when the PM is still discovering the journey.
2. In either mode, drive to a backbone where:
   - Activities form the user's journey left-to-right (e.g. *Discover → Onboard → Use → Share*).
   - Each Activity has at least one Step describing a concrete action the user takes inside it.
   - Activity and Step `id`s are short, kebab-case, and stable (they appear in URLs and analytics if any). `title` is the human label.
3. If `data.js` already has Activities, **extend** rather than replace: append new Activities and Steps. Preserve existing entries and their `stories[]` exactly.
4. Show the PM the proposed delta (which Activities and Steps will be added or updated), confirm.
5. On confirmation, write `.af/docs/usm/data.js` with the merged backbone. Keep `slices` and all existing `stories[]` arrays intact. Each new Step gets `stories: []`.

**Output:** Summary of Activities and Steps added or modified, and the file written (`.af/docs/usm/data.js`). The HTML USM picks it up on next reload.

**Scope (what this command does *not* do):**

- It does not create Stories. Use `/af-create-story` after the backbone is in place.
- It does not create or modify Slices (releases). Slices are managed by the PM directly in `data.js`.
- It does not write SPECs or Bugs.

**Stop here.** Backbone definition is its own session — the PM runs `/af-create-story` in a separate session when they're ready to add a User Story under one of the new Steps.
