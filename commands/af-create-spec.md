---
model: opus
effort: high
---

# /af-create-spec

**Trigger:** PM describes a feature or bug to the Lead.

**Steps:**
1. Load agent: `.af/agents/lead.md`
2. Lead asks clarifying questions until the feature is clear
3. Lead drafts SPEC using `.af/templates/spec.md` with status `draft`
4. PM reviews and confirms — Lead updates status to `ready`
5. Save to `.af/specs/active/SPEC-####.md` — next available number across `.af/specs/active/` and `.af/specs/archived/`

**Output:** Path to the confirmed SPEC file.

**Stop here.** Do not load the Developer. Do not start implementing. The PM runs `/af-implement-spec` in a separate session when they're ready.
