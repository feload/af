# BUG schema (one file per bug under `.af/docs/usm/source/bugs/`)

A BUG is a JSON object stored in its own file at `.af/docs/usm/source/bugs/BUG-XXXX.json`. Use this template as the field-by-field reference when writing one. The bundled `.af/docs/usm/bugs.js` is a generated artifact rebuilt by `.af/bin/build-usm.py` — never hand-edit it. Full schema docs: `.af/docs/usm.md`.

```js
{
  "id": "BUG-0001",             // BUG-####, zero-padded, unique across all entries (fixed/wont-fix entries count)
  "title": "Short bug description",
  "status": "open",             // open | in-progress | fixed | wont-fix
  "story": "US-0002",           // Matches a story id from .af/docs/usm/source/stories/ (look it up in source/INDEX.md) — OPTIONAL: null/missing for bugs that don't map to any US (rare; usually infra). Orphan bugs are surfaced in the "Unassigned" tray of the USM header.
  "foundAt": "2026-05-12",      // ISO 8601, the day PM reported it

  "description": "What is wrong. One clear sentence.",
  "stepsToReproduce": [
    "step 1",
    "step 2"
  ],
  "expected": "What should happen.",
  "actual": "What happens instead.",
  "affectedArea": "Files or modules suspected by PM. Leave blank if unknown.",

  "rootCause": "Lead fills this in after targeted investigation. Be specific — name the file, line, and why it breaks.",

  "fix": [
    {
      "description": "[Action verb] — files: `path/to/file` — what to change: [exact description] — done when: [criteria]",
      "done": false
    }
  ],

  "regressionTest": "Mandatory. What test to add or update so this cannot silently recur.",
  "doneCriteria": [
    "Bulleted PM walkthrough. Each bullet is one verifiable step or check.",
    "Example: `Sign up with mixed-case email; log out; log back in with the same email in lowercase — login succeeds`."
  ]
}
```

## Rules
- Status starts at `"open"` when PM reports it. Lead → `"in-progress"` once work starts. PR merged → `"fixed"`. Decision not to fix → `"wont-fix"`.
- `rootCause`, `fix`, `regressionTest` and `doneCriteria` must be filled before the Developer starts.
- `regressionTest` is mandatory — no bug fix ships without one.
- `story` is optional but should be set whenever possible — a bug without a US is rare. If you can't attach it to a US, the bug shows up in the "Unassigned" tray of the USM.
- `doneCriteria` is an array of strings. One bullet per check, each item one short sentence. Never a single text blob — the USM renders it as `<ul>`. If there is only one check, still wrap it in an array of one.
