---
model: sonnet
effort: medium
---

# /af-init

**Trigger:** PM runs this once in a repo. Bootstraps `.af/` and populates the project-context docs from the codebase.

**Prerequisites:** af installed globally (`~/.af/current` exists). Run `install.sh` from feload/af first if not.

**Steps:**

1. **Check idempotency.** If `.af/VERSION` already exists in the current directory, abort with: "This repo is already initialized (af <version-from-.af/VERSION>). `/af-init` only runs on uninitialized repos — use `/af-update` to refresh framework files or repopulate host-populated docs." Do not touch any file.
2. **Bootstrap.** Read `~/.af/current` to get the active version, then execute `~/.af/<version>/bin/bootstrap-here.sh` via Bash. This copies `agents/`, `templates/`, `docs/`, `bin/build-usm.py`, `hooks/pre-commit`, seeds an empty `.af/docs/usm/source/` tree (with `skeleton.json` and `.gitkeep` markers), runs `build-usm.py` to produce the bundled `data.js`/`specs.js`/`bugs.js`, writes `.af/VERSION`, and adds `AGENTS.md`/`CLAUDE.md` if missing. If `~/.af/current` does not exist, abort with: "af is not installed globally. Run install.sh from feload/af first."
3. **Confirm framework presence.** `.af/VERSION`, `.af/agents/lead.md`, `.af/agents/developer.md`, `.af/templates/spec.md`, `.af/templates/bug.md`, `.af/docs/workflow.md`, `.af/bin/build-usm.py`, `.af/hooks/pre-commit`, `.af/docs/usm/source/skeleton.json`, and `.af/docs/usm/data.js` should all exist. If any are missing after bootstrap, abort with a clear message.
4. **Explore the project** (max 15 files: README, package manifest, entry points, source samples, test samples, config files).
5. **Populate** `.af/docs/architecture.md`, `.af/docs/domain.md`, and `.af/docs/conventions.md` with what is found — leave the original placeholder text in any section that cannot be confirmed from evidence. In `conventions.md`, replace only the `[...]` placeholders; the prose defaults already filled in (Testing, Refactoring, Commit, Language/Locale, Communication Style, Forbidden Practices) are opinionated and intentional — preserve them verbatim unless the codebase clearly contradicts one.

**Output:** Whether bootstrap ran, the updated docs, and a list of doc sections left as placeholders. Mention the one-liner the PM may run to enable the pre-commit hook that keeps the USM bundles in sync: `git config core.hooksPath .af/hooks`. Do **not** run it for them.

**Stop here.** Do not load any agent. Do not start a SPEC, fix, or implementation. Initialization is its own session.
