# Changelog

All notable changes to the af framework are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [Semantic Versioning](https://semver.org/).

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
