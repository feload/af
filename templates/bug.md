# BUG schema (entry in `.af/docs/usm/bugs.js`)

A BUG is a JSON object inside the `window.USM_BUGS` array. Use this
template as the field-by-field reference when writing one. Full schema
docs: `.af/docs/usm.md`.

```js
{
  "id": "BUG-0001",             // BUG-####, zero-padded, unique across all entries (fixed/wont-fix entries count)
  "title": "Short bug description",
  "status": "open",             // open | in-progress | fixed | wont-fix
  "story": "US-0002",           // Matches an id from data.js — OPTIONAL: null/missing for bugs that don't map to any US (rare; usually infra). Orphan bugs are surfaced in the "Sin asignar" tray of the USM header.
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
  "doneCriteria": "How PM will verify the bug is fixed."
}
```

## Rules
- Status starts at `"open"` when PM reports it. Lead → `"in-progress"` once work starts. PR merged → `"fixed"`. Decision not to fix → `"wont-fix"`.
- `rootCause`, `fix`, `regressionTest` and `doneCriteria` must be filled before the Developer starts.
- `regressionTest` is mandatory — no bug fix ships without one.
- `story` is optional but should be set whenever possible — a bug without a US is rare. If you can't attach it to a US, the bug shows up in the "Sin asignar" tray of the USM.
