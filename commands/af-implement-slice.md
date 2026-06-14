# /af-implement-slice

**Trigger:** PM wants an entire release (slice) implemented in one go, instead of invoking `/af-implement-spec` once per User Story. Argument: `<slice-id>` (matches `.af/docs/usm/source/releases/<slice-id>.json`).

This command breaks the usual one-phase-per-session rule on purpose: it walks the whole slice back-to-back with no PM stop between stories. It still does not write SPECs and does not mark its own work accepted — those stay the PM's calls.

**Steps:**
1. Load agent: `.af/agents/developer.md`.
2. **Verify the slice.** Open `.af/docs/usm/source/releases/<slice-id>.json`. It must exist and have a non-empty `goal`. Its `status` must be `in-progress` — if `planning`, stop and point the PM at `/af-review-slice <slice-id>` (a release that has not passed readiness review is not something to batch-implement); if `released`, stop and report it is already shipped. Do not read the generated `data.js`.
3. **Build the work queue.** From `.af/docs/usm/source/INDEX.md` and `source/stories/`, collect every US with `slice: <slice-id>`, plus any standalone SPEC under `source/specs/` whose linked `story` is one of those US. Partition:
   - **implementable** — a US with `status: ready` carrying inline `subtasks`, or a standalone SPEC with `status: ready`.
   - **not ready** — a US still `proposed` (no confirmed SPEC). These need `/af-create-spec <slice-id>` (or `/af-create-spec <US-####>`) first; never touch them.
   - **already settled** — US already `active` or `done`. Skip; report for context.
   Order the implementable queue by **backbone position**: Activity left-to-right, then Step order, then US, so implementation follows the user's journey through the slice.
4. **Create the branch.** From `main`, run `git checkout -b feat/<slice-id>` so every commit for the release lands on one dedicated branch instead of `main`. (This mirrors `/af-implement-spec`'s per-work-item branch, scoped to the slice.)
5. **Print the plan before writing any code:**
   - "Implementing N items in order: …"
   - "Skipping M not ready (run `/af-create-spec <slice-id>` to spec them): …"
   - "Already active/done: …"
   Then proceed without waiting — this is a whole-slice run.
6. **Implement the queue back-to-back**, applying the `/af-implement-spec` behavior to each item with no stop in between:
   - Inline path: flip the US `status` from `ready` to `active`, implement its `subtasks` in order, flip each `done` to `true` in the US file as it lands.
   - Standalone path: leave the SPEC `status` at `ready` (it has no `active` state), implement its `subtasks` in order, flip each `done` to `true` in the SPEC file.
   - Run `python3 .af/bin/build-usm.py` after each item so the bundles stay in sync (the pre-commit hook does this on commit if `git config core.hooksPath .af/hooks` is set).
7. **On a blocker — stop the whole run.** If the Developer hits genuine ambiguity, or an out-of-scope defect per the *Bug found mid-development* rule in `.af/docs/workflow.md`, halt immediately. Report which US blocked, why, what was completed before it, and what is still queued. Do not skip the blocked item and carry on — a blocker means the slice cannot ship as-is and the PM needs to know.
8. **One handoff at the end.** When the queue is exhausted (or halted), produce a single batch handoff per `.af/agents/developer.md`: a combined tree of the tests added or modified across every item implemented this run, the full set of run commands, and a summary — implemented / skipped-not-ready / already-settled / blocked.

**Output:** All changed source files on the `feat/<slice-id>` branch + the updated US/SPEC files + regenerated bundles, and one combined handoff. The slice's implemented US are left `active` for the PM's final review.

**What it explicitly does NOT do:**
- Write SPECs. Not-ready US are reported, never auto-spec'd — that is `/af-create-spec`, a PM-confirmed phase.
- Flip any US to `done` or any SPEC to `approved`. `done` means *accepted by the PM*; the Developer marking its own work accepted is a false record, batch run or not. The PM flips each US to `done` in one review pass after the handoff.
- Add Activities, Steps, or new stories, or move stories between slices.

**PM follow-up after the handoff:** review and run the tests, flip each implemented US to `done` (standalone SPECs to `approved`), then the Developer opens the PR from `feat/<slice-id>`. After merge the entries stay in `source/` as a record.
