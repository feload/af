# Changelog

All notable changes to the af framework are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [Semantic Versioning](https://semver.org/).

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
