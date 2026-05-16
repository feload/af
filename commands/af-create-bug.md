# /af-create-bug

**Trigger:** PM reports a bug to the Lead. The bug is filed directly inside af — there is no external tracker.

**Steps:**
1. Load agent: `.af/agents/lead.md`
2. Lead asks clarifying questions if the report is incomplete (one at a time)
3. Lead reads only the files related to the reported area to find root cause
4. Lead drafts the BUG as a JSON object following `.af/templates/bug.md` (schema reference), with `status: "open"`. Link `story` to the matching `US-XXXX` whenever possible — look the US up in `.af/docs/usm/source/INDEX.md`; leave `null` only for true orphans (rare).
5. PM confirms — Lead flips `status` to `"in-progress"` once work starts
6. Write the entry to `.af/docs/usm/source/bugs/BUG-####.json`. ID is `BUG-####` — next available number above the highest ID currently listed in `source/INDEX.md` (fixed/wont-fix entries count). Set `foundAt` to today's date in ISO 8601. One file per bug — never edit another bug's file.
7. Run `python3 .af/bin/build-usm.py` so the generated `bugs.js` and `source/INDEX.md` pick up the new entry.

**Key difference from /af-create-spec:** Lead is allowed to read source files to identify root cause — but only files directly related to the bug, not broad exploration.

**Output:** The ID of the confirmed BUG (e.g. `BUG-0003`) and the file written (`.af/docs/usm/source/bugs/BUG-XXXX.json`). Never hand-edit the bundled `bugs.js`; it is a generated artifact rebuilt by `build-usm.py`.
