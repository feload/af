# AGENTS.md

This is the **af** framework — a workflow for AI-assisted software development. It defines roles (PM, Lead, Developer), commands, and templates that get installed into a host project under `.af/`.

For the public-facing description, see [README.md](README.md).

## Repo layout

- `agents/` — role prompts (`lead.md`, `developer.md`)
- `commands/` — canonical source of slash commands. Installed into a host's `.claude/commands/`
- `templates/` — SPEC and BUG SPEC templates
- `docs/workflow.md` — the workflow rules
- `docs/architecture.md`, `docs/domain.md`, `docs/conventions.md` — placeholder templates for host-side context, populated by `/init-af` in the host
- `MANIFEST` — list of host-installable paths with target locations
- `install.sh` — POSIX shell installer
- `README.md`, `CHANGELOG.md`, `LICENSE`, `VERSION` — framework metadata, never installed

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

1. Create a release-candidate tag (e.g. `v0.1.1-rc1`) and push it.
2. In a scratch directory, run `curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.1.1-rc1`.
3. Inspect the `.af/` and `.claude/commands/` output.

Once verified, push the real release tag and create a GitHub Release with the corresponding `CHANGELOG.md` notes.
