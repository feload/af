# AI-Assisted Development Workflow

## Roles

**PM (user)** — manages scope externally via cards. Hands a card to Lead, confirms the SPEC, reviews implementation, approves the PR, and closes the card.

**Lead** — receives a card from PM and produces a SPEC detailed enough that Developer can implement immediately without any exploration or scope decisions.

**Developer** — implements the SPEC as written. Does not explore, does not decide scope.

## Flow

```
PM: create card (external)
PM → Lead: share card
Lead: write SPEC → PM confirms → status: ready
Developer: implement subtasks → notify PM
PM: review + test → status: approved
Developer: create PR
PM: approve PR → close card
```

## Rules

- Every task starts with a card; every implementation starts with a `ready` SPEC
- The SPEC is the single source of truth — it must be complete enough to implement without questions
- Lead is responsible for SPEC quality: if Developer is blocked, Lead failed to spec it well enough
- Developer does not make scope decisions — if something is ambiguous, they stop and flag it
- PM updates external artifacts (cards) only after the PR is approved and merged

## Bug flow

```
PM: report bug (card)
PM → Lead: share bug report
Lead: investigate root cause (targeted) → write BUG SPEC → PM confirms → status: ready
Developer: apply fix + write regression test → notify PM
PM: verify fix → status: approved
Developer: create PR
PM: approve PR → close card
```

- Lead **is** allowed to read source files to find root cause — but only files directly related to the bug
- Regression test is mandatory — no bug fix is complete without one

## Artifact naming and location

- Features: `SPEC-####.md` (zero-padded, e.g. `SPEC-0001.md`)
- Bugs: `BUG-####.md` (zero-padded, e.g. `BUG-0001.md`)
- Active (in progress): `.af/specs/active/`
- Archived (PR approved and merged): `.af/specs/archived/`
