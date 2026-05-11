# AGENTS.md

This is the **af** framework — a workflow for AI-assisted software development. It defines roles (PM, Lead, Developer), commands, and templates that get installed into a host project under `.af/`.

For the public-facing description, see [README.md](README.md).

## Repo layout

- `agents/` — role prompts (`lead.md`, `developer.md`)
- `commands/` — canonical source of slash commands. Installed into `~/.claude/commands/` by default, or `.claude/commands/` under `--local`
- `templates/` — SPEC and BUG SPEC templates
- `docs/workflow.md` — the workflow rules
- `docs/architecture.md`, `docs/domain.md`, `docs/conventions.md` — placeholder templates for host-side context, populated by `/af-init` in the host
- `bin/bootstrap-here.sh` — POSIX helper that copies cached framework files from `~/.af/<version>/` into the current repo's `.af/`. Invoked by `/af-init`
- `bin/update-here.sh` — POSIX helper that overwrites a host's framework files to a target version. Invoked by `/af-update`
- `MANIFEST` — list of host-installable paths with target locations
- `install.sh` — POSIX shell installer (global default, `--local` per-project)
- `README.md`, `CHANGELOG.md`, `LICENSE` — framework metadata, never installed

## Slash command naming convention

All af slash commands use the `af-*` prefix, regardless of whether they drive a workflow phase or manage the framework install. Two categories share the prefix:

- **Workflow commands:** `/af-create-card`, `/af-create-spec`, `/af-create-bug`, `/af-implement-spec`, `/af-fix-bug`. Each maps to one phase of the workflow.
- **Lifecycle commands:** `/af-init`, `/af-update` (and any future `/af-remove`). These manage the framework install in a host, not the workflow.

When adding a new command, use the `af-` prefix and pick a verb that makes its category obvious.

## Path conventions inside framework files

Path references in `agents/`, `commands/`, `templates/`, and `docs/workflow.md` describe how files appear *in a host after install*. So you'll see `.af/agents/lead.md` even though the file lives at `agents/lead.md` in this repo. This is intentional — these markdown files are read in the host context, not here.

When editing any path reference, write the host-side path (`.af/...`), not the framework-repo path.

## Working on the framework

When changing an agent, command, or template:

1. Edit the file under `agents/`, `commands/`, `templates/`, or `docs/`.
2. If file paths or references changed, update every other file that mentions them.
3. If you added or removed an installable file, update `MANIFEST`.
4. Bump the version per the rules in [README.md](README.md#versioning) and add a [CHANGELOG.md](CHANGELOG.md) entry.
5. Tag the commit with the new version (`vX.Y.Z`) and create a GitHub Release so `install.sh`'s "latest" lookup picks it up.

## Slash commands during framework development

The slash commands in `commands/` are only usable in a *host project* where af is installed. When working on this repo, `/af-create-spec` etc. are not directly available — read the markdown files when reasoning about behavior, or run `install.sh` recursively against this repo.

## Testing changes locally

To verify an install before publishing a release:

1. Create a release-candidate tag (e.g. `v0.3.0-rc1`) and push it.
2. **Global install:** in a scratch directory, run `curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.3.0-rc1`. Inspect `~/.claude/commands/` and `~/.af/<version>/`.
3. **Per-repo bootstrap:** `cd` into a different scratch repo, open Claude Code, run `/af-init`. Inspect `.af/` in that repo.
4. **Local-mode regression:** in another scratch dir, run `... | sh -s -- --local v0.3.0-rc1`. Inspect `.af/` and `.claude/commands/` inside that dir.

Once verified, push the real release tag and create a GitHub Release with the corresponding `CHANGELOG.md` notes.
