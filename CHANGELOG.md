# Changelog

All notable changes to the af framework are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [Semantic Versioning](https://semver.org/).

## v0.13.0 — 2026-06-09

### Added
- **Per-project USM title.** `source/skeleton.json` gains an optional `project` field. The viewer titles the page and its `<h1>` as `"<project> — User Story Map"`, falling back to `af` when unset. `/af-init` (via `bootstrap-here.sh`) seeds it with the repo directory name; `/af-update` (via `update-here.sh`) backfills it for hosts that predate the field; `migrate-data-to-source.py` sets it on migrated hosts; `build-usm.py` carries it into `data.js`. `/af-create-backbone` now preserves the field when rewriting the skeleton. Documented in `docs/usm.md`.
- **Opinionated defaults in `docs/conventions.md`.** Testing, Refactoring, Commit, Language/Locale, Communication Style and Forbidden Practices now ship with stack-agnostic defaults instead of empty placeholders. `/af-init` fills only the remaining `[...]` placeholders and preserves the prose defaults. The Developer agent now reads `conventions.md` (it never did), so commit/communication/forbidden rules reach the agent that writes code and PRs.

### Changed
- **English-only.** Translated the USM viewer (`docs/usm/index.html`, `docs/usm/styles.css`) from Spanish to English and rebranded its title from "Fredo" to the per-project/`af` default. Removed Spanish and bilingual-locale assumptions from the framework: `agents/lead.md` no longer hardcodes `es-MX`/`en` i18n files or "both locales", `templates/spec.md` drops the "in both locales" example, `conventions.md` sets agent responses to English, and the slice commands rename "Fase" → "Phase".
- The USM viewer's `localStorage` key is renamed `fredo_usm_pending_v2` → `af_usm_pending_v2`. Any unsaved drag-and-drop changes pending at update time are dropped (transient UI state only).

## v0.12.0 — 2026-05-16

### Changed (breaking)
- SPEC content lives **inline on the US by default**. The six fields `context`, `problem`, `constraints`, `subtasks`, `edgeCases` and `doneCriteria` are now optional fields on `source/stories/US-XXXX.json`, and `/af-create-spec` writes them there in place instead of creating a separate file. Reason: most stories map 1:1 to a single SPEC, so the standalone file was ceremony — the inline path removes a file and a state machine for the common case while keeping the role boundary (Lead spec, Developer implement) intact.
- A standalone file under `source/specs/SPEC-XXXX.json` is still created for two cases: (a) cross-cutting work that has no matching US (`story: null`), and (b) a US the PM wants to split across multiple SPECs. Existing standalone SPECs keep working with no migration.
- US lifecycle gains a `ready` state: `proposed | ready | active | done | dropped`. `ready` means the US is fully spec'd (inline SPEC confirmed by the PM, or at least one linked standalone SPEC at `ready`) and the Developer can pick it up. The standalone SPEC lifecycle (`draft | ready | approved | archived`) is unchanged.
- `/af-implement-spec` now accepts either `US-XXXX` (inline path — verifies US `status: ready`, flips it to `active` on start, PM flips to `done` on approval) or `SPEC-XXXX` (standalone path — unchanged behavior).
- `/af-review-slice` readiness table is reworded so a row resolves to `ready` when the US itself is at `status: ready` (inline) **or** any of its linked SPECs is `ready`.

### Added
- USM viewer renders inline SPEC content on the story panel as a `SPEC` section above the (now optional) `Additional SPECs` block. The `ready` US status gets its own swatch in the header legend, a blue tile background on the map, and a status badge on the panel.
- `source/INDEX.md` story table gains a `Spec` column: `inline`, `external (N)`, `inline + N ext`, or `—`.

## v0.11.0 — 2026-05-16

### Added
- **Value-delivery rubric** in `agents/lead.md` — 10 axes (Discovery, Access, Happy path, Edge states, Closure, Persistence, Localization+accessibility, Observability, Security, Performance) anchored on the slice's `goal`. For each axis the Lead checks whether the current set of stories lets the user reach and complete the goal end-to-end. Includes a cross-slice coverage protocol so axes already addressed by US in `released` or `in-progress` slices are surfaced as matches (clear or ambiguous) before any new US is proposed. Reason: PMs were ending up with slices that picked the obvious US for a goal but missed crosscutting prerequisites (navigation, access, observability) without which the user could not actually realize value.
- `/af-review-slice <slice-id>` slash command (sonnet/medium). Readiness check before flipping a slice to `in-progress`: prints a US-by-US readiness table (SPEC status: `no SPEC` / `pending Lead` / `pending PM` / `ready` / `approved` / `archived`), reruns the value-delivery rubric as a delta against the current state of the slice, asks about scope changes, and prints a verdict — *ready to flip* or *pendings before flip*. Does not edit the slice's `status` (PM does that manually) and does not write SPECs.

### Changed
- `/af-create-slice` now offers a content-planning continuation after recording the slice. Phase 1 is unchanged — capture `{id, title, goal, status}` and write `source/releases/<slice-id>.json`. After confirmation it asks whether to continue. If yes: Phase 2 sweeps `source/stories/` for Backlog candidates and moves the ones that visibly serve the goal into the slice one-by-one; Phase 3 walks the 10-axis Value-delivery rubric anchored on the goal and, for each gap, proposes a new US (PM confirms one-by-one before any file is written). The PM can stop after Phase 1 and resume later — the slice stays in `planning`. The previous Stop after writing the slice file is preserved as the early-exit path.
- `docs/workflow.md` updated: the Flow diagram now lists `/af-review-slice` between SPEC drafting and implementation; the Slices bullet (under *Domain first, then backbone, then stories*) names the rubric; the Session focus list adds `/af-review-slice` and rewrites the `/af-create-slice` bullet to describe the three-phase flow.

## v0.10.0 — 2026-05-15

### Added
- Slices (releases) now carry a `goal` field — one sentence describing what shipping the release achieves for the user or the business. The goal is the rubric by which the PM decides which US belong in the slice. Documented in `docs/usm.md` and `docs/workflow.md`.
- `/af-create-slice` slash command (sonnet/medium). Drafts a slice with `id`, `title`, `goal` (mandatory) and `status` (`planning` by default), writes it to `.af/docs/usm/source/releases/<slice-id>.json`, and rebuilds the bundles.

### Changed
- `/af-create-story` is now slice-goal-aware: when the PM names a slice, the Lead reads `source/releases/<slice-id>.json` and anchors the story's narrative, rationale and acceptance criteria on that slice's goal. If the named slice has an empty `goal`, the command stops and asks the PM to set the goal first.
- A slice in `planning` may have an empty `goal`, but it cannot flip to `in-progress` or `released` without one. Stories that don't visibly serve a slice's goal stay in Backlog.
- `agents/lead.md` instructs the Lead to read the slice file alongside the SPEC context and to push back on stories whose scope does not serve the slice's goal.

## v0.9.0 — 2026-05-15

### Changed (breaking)
- USM source of truth moves to per-item JSON files under `.af/docs/usm/source/` (`skeleton.json`, `releases/<slice>.json`, `stories/US-XXXX.json`, `specs/SPEC-XXXX.json`, `bugs/BUG-XXXX.json`). The bundled `.af/docs/usm/{data,specs,bugs}.js` become **generated artifacts** produced by `.af/bin/build-usm.py` — never hand-edit. Reason: a single bundled `data.js`/`specs.js`/`bugs.js` was hostile to git diffs, merge conflicts and Claude's context window once the catalogue grew past ~150 stories and a dozen SPECs.
- Story entries now carry a `step` field that maps them to the matching `step.id` from `source/skeleton.json`; the build script groups stories by `step` and nests them under the backbone at build time.
- `agents/lead.md`, `agents/developer.md`, `templates/spec.md`, `templates/bug.md`, `docs/usm.md`, `docs/workflow.md`, and every slash command in `commands/` updated to write to and read from `source/`. Reading or hand-editing the bundled `.js` is explicitly forbidden.
- The `update-here.sh` "host-populated, never touched" set flips from `data.js`/`specs.js`/`bugs.js` (now overwritten as regenerated artifacts) to everything under `.af/docs/usm/source/`.

### Added
- `bin/build-usm.py` — idempotent rebuild of the bundled `.js` files and `source/INDEX.md` from per-item JSON. Skips a bundle if its `source/<dir>/` doesn't exist yet (gradual adoption).
- `bin/migrate-data-to-source.py`, `bin/migrate-specs-bugs-to-source.py` — one-shot migrators with lossless round-trip verification. Existing hosts can run them (or `update-here.sh` runs them automatically when it detects the pre-source layout) to split their `data.js`/`specs.js`/`bugs.js` into per-item files.
- `hooks/pre-commit` — git hook that re-runs `build-usm.py` and re-stages the regenerated bundles whenever anything under `source/` (or `bin/build-usm.py` itself) is staged. Opt-in: enable per clone with `git config core.hooksPath .af/hooks`. `/af-init` and `/af-update` print the one-liner but never modify the user's git config.
- `bin/bootstrap-here.sh` now seeds an empty `source/` tree (`skeleton.json` + `.gitkeep` files under `releases/`, `stories/`, `specs/`, `bugs/`), installs `build-usm.py` and `pre-commit`, and runs `build-usm.py` once so the static viewer has bundles to read.
- `bin/update-here.sh` detects pre-source hosts (have `data.js`, no `source/`) and runs the migrators automatically (when `python3` is available), then regenerates the bundles. Prints a clear manual fallback when `python3` is missing.

### Notes
- The `card` field was already removed from SPECs and BUGs in v0.8.0 and stays out of the new templates.

## v0.8.0 — 2026-05-12

### Changed (breaking)
- Scope creation moves inside af. There is no external tracker anymore — Stories live in the USM (`.af/docs/usm/data.js`) under Activities + Steps, and SPECs/Bugs link to them via `story`.
- `/af-create-card` is removed and replaced by `/af-create-story`. `/af-create-story` requires an existing backbone (Activities + Steps in `data.js`); it refuses to run if `activities` is empty and tells the PM to run `/af-create-backbone` first. New Stories default to `slice: null` (Backlog). The Lead suggests the matching Step from the existing backbone; the PM confirms or asks for a new Step (added inline). Adding new Activities is reserved for `/af-create-backbone`.
- `card` field removed from the SPEC and BUG schemas (`templates/spec.md`, `templates/bug.md`, `docs/usm.md`). The USM detail pane no longer renders a "Card: ..." line. Existing entries with a leftover `card` value are simply ignored.
- `docs/workflow.md` rewritten: domain-first → backbone → stories → SPECs/Bugs. Removed every mention of external cards.

### Added
- `/af-create-backbone` slash command (opus/high). Drafts or extends the USM backbone (Activities + Steps) in `data.js`. Verifies `.af/docs/domain.md` has been populated (placeholders replaced) before running — refuses on an empty domain. Two modes: sketch a general structure or build piece by piece. Never creates Stories, never touches Slices. New Steps get `stories: []`.
- `/af-create-story` slash command (sonnet/medium). Files a new US under an existing Step. Lead suggests the Step; PM confirms or asks for a new one (added inline). Default `slice: null`.

### Removed
- `.af/specs/active/` and `.af/specs/archived/` directories are no longer created by `install.sh` (per-project mode) — the JSON `specs.js`/`bugs.js` files have been canonical since v0.6.

## v0.7.0 — 2026-05-11

### Changed (breaking)
- Lifecycle commands renamed to align with the `af-*` prefix used by every other command: `/init-af` → `/af-init`, `/update-af` → `/af-update`. The old names are removed, not aliased. Users upgrading need to re-run `install.sh` to drop the new files into `~/.claude/commands/`; the old `init-af.md` and `update-af.md` files left behind in that directory by prior installs can be deleted manually.
- `AGENTS.md` updated: a single `af-*` prefix now covers both workflow and lifecycle commands. The previous two-prefix convention (`af-*` for workflow, `*-af` for lifecycle) is retired.

### Fixed
- `/af-init` is now idempotent. If `.af/VERSION` already exists in the current directory, the command aborts immediately and points the PM at `/af-update`. The previous `/init-af` would silently re-explore the codebase and could overwrite host-populated `.af/docs/*` content on a second run.

## v0.6.0 — 2026-05-07

### Changed
- `agents/developer.md` — Developer no longer runs the test suite by default. After implementing, the Developer prints a tree of the tests added or modified in the session (scoped to the changes, not the full suite), provides the exact commands the PM should run, and may optionally offer to run them on the PM's behalf. Tests must also be organized to read as a description of the application's behavior — grouped by feature/scenario, plainly named, structured setup → action → outcome — so the PM can confirm coverage from the names alone.
- `commands/af-implement-spec.md` and `commands/af-fix-bug.md` — handoff step updated to require the test tree + run commands when notifying the PM.

## v0.5.0 — 2026-05-07

### Added
- `/update-af` slash command + `bin/update-here.sh` helper. Brings an already-initialized repo's `.af/` up to a newer framework version. Bare `/update-af` catches the repo up to whatever `~/.af/current` points to; `/update-af v0.5.0` fetches a specific version from GitHub if not already cached. Overwrites framework files (`agents/`, `templates/`, `docs/workflow.md`, `bin/`) and bumps `.af/VERSION`. Never touches `.af/specs/`. Host-populated docs (`architecture.md`, `domain.md`, `conventions.md`) are diffed against the target's placeholder and the PM is asked per file whether to keep, overwrite, or merge.

### Conventions
- Lifecycle commands (initialize, update, future remove) use the `*-af` suffix: `/init-af`, `/update-af`. Workflow commands use the `af-*` prefix: `/af-create-card`, `/af-create-spec`, etc.

## v0.4.0 — 2026-05-07

### Added
- `/af-create-card` — backend-agnostic helper for creating cards (tracker work items via MCP, file rows, links, etc.). The PM tells the agent where cards live and the command helps draft and create them. Can produce multiple cards in one session.
- *Session focus* section in `docs/workflow.md`: each command does one phase and stops; the agent does not auto-progress to the next phase.
- Per-command `model` and `effort` frontmatter so each phase runs on the right tier: `/af-create-card` sonnet/medium, `/af-create-spec` opus/high, `/af-create-bug` opus/xhigh, `/af-implement-spec` sonnet/medium, `/af-fix-bug` sonnet/high, `/init-af` sonnet/medium.

### Changed
- Every command (`/af-create-card`, `/af-create-spec`, `/af-create-bug`, `/af-implement-spec`, `/af-fix-bug`) now ends with an explicit "Stop here" rule that prevents auto-progressing into the next workflow phase.
- `agents/lead.md` and `agents/developer.md` reinforce the same rule.
- Generated `AGENTS.md` boilerplate (in `install.sh`) mentions the optional `/af-create-card` step.

## v0.3.0 — 2026-05-06

### Added
- Global install mode (now the default for `install.sh`): slash commands go to `~/.claude/commands/`, framework files cached in `~/.af/<version>/`, active version recorded in `~/.af/current`. One install, then `/init-af` works in any repo.
- `bin/bootstrap-here.sh` — POSIX helper invoked by `/init-af` that copies cached framework files into the current repo's `.af/` and creates `AGENTS.md`/`CLAUDE.md` if missing.

### Changed
- `/init-af` now bootstraps `.af/` from the global cache when missing, then proceeds with its existing populate-docs behavior.
- `install.sh --local` preserves the previous per-project install behavior for users who prefer project-scoped commands.

## v0.2.0 — 2026-05-06

### Changed
- Slash commands now use the `/af-` namespace prefix: `/create-spec` → `/af-create-spec`, `/create-bug` → `/af-create-bug`, `/implement-spec` → `/af-implement-spec`, `/fix-bug` → `/af-fix-bug`. `/init-af` is unchanged.

## v0.1.0 — 2026-05-06

Initial release.

### Added
- Lead and Developer agents (`agents/lead.md`, `agents/developer.md`)
- Slash commands: `/create-spec`, `/create-bug`, `/implement-spec`, `/fix-bug`, `/init-af`
- SPEC and BUG SPEC templates (`templates/spec.md`, `templates/bug.md`)
- Workflow documentation (`docs/workflow.md`) and host-project doc placeholders (`docs/architecture.md`, `docs/domain.md`, `docs/conventions.md`)
- `install.sh` POSIX shell installer with optional version pinning
- `MANIFEST` mapping framework source paths to host-side targets
- `AGENTS.md` and `CLAUDE.md` at the framework repo root
- `install.sh` generates `AGENTS.md` and `CLAUDE.md` in host projects when missing
- Framework files install under `.af/` in the host; slash commands at `.claude/commands/`
