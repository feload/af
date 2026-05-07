# /init-af

**Trigger:** PM runs this once in a repo. Bootstraps `.af/` if missing, then populates the project-context docs from the codebase.

**Prerequisites:** af installed globally (`~/.af/current` exists). Run `install.sh` from feload/af first if not.

**Steps:**

1. **Bootstrap (if needed).** If `.af/VERSION` does not exist in the current directory:
   - Run `~/.af/current` to get the active version, then execute `~/.af/<version>/bin/bootstrap-here.sh` via Bash. This copies `agents/`, `templates/`, `docs/`, creates `.af/specs/{active,archived}/`, writes `.af/VERSION`, and adds `AGENTS.md`/`CLAUDE.md` if missing.
   - If `~/.af/current` does not exist, abort with: "af is not installed globally. Run install.sh from feload/af first."
   - If `.af/VERSION` already exists, skip this step.
2. **Confirm framework presence.** `.af/VERSION`, `.af/agents/lead.md`, `.af/agents/developer.md`, `.af/templates/spec.md`, `.af/templates/bug.md`, and `.af/docs/workflow.md` should all exist. If any are missing after bootstrap, abort with a clear message.
3. **Explore the project** (max 15 files: README, package manifest, entry points, source samples, test samples, config files).
4. **Populate** `.af/docs/architecture.md`, `.af/docs/domain.md`, and `.af/docs/conventions.md` with what is found — leave the original placeholder text in any section that cannot be confirmed from evidence.

**Output:** Whether bootstrap ran, the updated docs, and a list of doc sections left as placeholders.
