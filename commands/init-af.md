# /init-af

**Trigger:** PM runs this once after `install.sh` has copied the framework into `.af/`.

**Prerequisites:** `.af/VERSION` exists (created by `install.sh`).

**Steps:**
1. Confirm framework is installed by checking `.af/VERSION` exists — abort with a clear message if missing
2. Explore the project (max 15 files: README, package manifest, entry points, source samples, test samples, config files)
3. Populate `.af/docs/architecture.md`, `.af/docs/domain.md`, and `.af/docs/conventions.md` with what is found — leave the original placeholder text in any section that cannot be confirmed from evidence

**Output:** Updated docs and a list of doc sections left as placeholders.
