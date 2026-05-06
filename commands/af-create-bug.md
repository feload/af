# /af-create-bug

**Trigger:** PM reports a bug to the Lead.

**Steps:**
1. Load agent: `.af/agents/lead.md`
2. Lead asks clarifying questions if report is incomplete
3. Lead reads only the files related to the reported area to find root cause
4. Lead writes BUG SPEC using `.af/templates/bug.md` with status `draft`
5. PM confirms — Lead updates status to `ready`
6. Save to `.af/specs/active/BUG-####.md` — next available number across `.af/specs/active/` and `.af/specs/archived/`

**Key difference from /af-create-spec:** Lead is allowed to read source files to identify root cause — but only files directly related to the bug, not broad exploration.

**Output:** Path to the confirmed BUG SPEC file.
