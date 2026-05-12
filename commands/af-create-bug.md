# /af-create-bug

**Trigger:** PM reports a bug to the Lead. The bug is filed directly inside af — there is no external tracker.

**Steps:**
1. Load agent: `.af/agents/lead.md`
2. Lead asks clarifying questions if the report is incomplete (one at a time)
3. Lead reads only the files related to the reported area to find root cause
4. Lead drafts the BUG as a JSON object following `.af/templates/bug.md` (schema reference), with `status: "open"`. Link `story` to the matching `US-XXXX` from `.af/docs/usm/data.js` whenever possible; leave `null` only for true orphans (rare).
5. PM confirms — Lead flips `status` to `"in-progress"` once work starts
6. Append the entry to `.af/docs/usm/bugs.js` (`window.USM_BUGS`). ID is `BUG-####` — next available number above the highest ID currently in `bugs.js` (fixed/wont-fix entries count). Set `foundAt` to today's date in ISO 8601.

**Key difference from /af-create-spec:** Lead is allowed to read source files to identify root cause — but only files directly related to the bug, not broad exploration.

**Output:** The ID of the confirmed BUG (e.g. `BUG-0003`) and the file it was written to.
