# af — AI-Assisted Development Framework

A lightweight workflow for shipping software with AI coding assistants (Claude Code, Cursor, etc.).

af splits AI-assisted development into three roles — **PM**, **Lead**, and **Developer** — and routes work through small, well-bounded artifacts (SPECs and BUG SPECs) so the assistant always knows exactly what to build, and you always know exactly what got built.

## Why af

Most AI-coding sessions fail the same way: vague prompt → assistant explores too much → drifts off-scope → produces code you don't trust. af fixes that by separating the *thinking* from the *typing*:

- The **Lead** turns a fuzzy idea into a precise SPEC. No code yet.
- The **Developer** implements the SPEC verbatim. No exploration, no scope decisions.
- The **PM** (you) owns scope and approves at every gate.

The result: short, predictable AI sessions that stop where you expect them to.

## How it works

```
PM: create card (external tracker)
PM → Lead: share card
Lead: write SPEC → PM confirms → status: ready
Developer: implement subtasks → notify PM
PM: review + test → status: approved
Developer: create PR
PM: approve PR → close card
```

Bugs follow the same shape, with one extra rule: every fix ships with a regression test.

## Install

Run from the root of your project:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh
```

To pin a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.1.1
```

For the security-conscious — review before running:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh -o af-install.sh
less af-install.sh
sh af-install.sh v0.1.1
```

After install, open the project in [Claude Code](https://github.com/anthropics/claude-code) and run `/init-af` to populate the project-context docs from your codebase.

### Requirements

- POSIX shell (Linux, macOS, or Git Bash / WSL on Windows)
- `curl`
- A Claude Code installation in the consuming environment

### What gets created in your project

```
<your project>/
├── .af/
│   ├── VERSION
│   ├── agents/
│   ├── templates/
│   ├── docs/
│   └── specs/
│       ├── active/
│       └── archived/
├── .claude/commands/       # slash commands — Claude Code reads them here
├── AGENTS.md               # only if you didn't already have one
└── CLAUDE.md               # only if you didn't already have one
```

Existing files are never overwritten. If you already have `AGENTS.md` or `CLAUDE.md`, add a pointer to `.af/docs/workflow.md` manually.

## Repository layout (this repo)

| Path | What lives there |
|---|---|
| [agents/](agents/) | Role prompts — `lead.md`, `developer.md` |
| [commands/](commands/) | Slash command sources, installed to host's `.claude/commands/` |
| [templates/](templates/) | `spec.md`, `bug.md` — the artifacts the Lead fills in |
| [docs/](docs/) | `workflow.md` (the rules) + host-side placeholders (`architecture.md`, `domain.md`, `conventions.md`) populated in the host by `/init-af` |
| [MANIFEST](MANIFEST) | Maps source paths in this repo to target paths in a host project |
| [install.sh](install.sh) | POSIX shell installer |
| [AGENTS.md](AGENTS.md) | Guide for AI agents working on the framework itself |

## The flow in detail

### Feature work

1. **PM creates a card** in whatever tracker they use (Linear, Jira, Trello — external to af).
2. **PM runs `/create-spec`** and describes the feature to the Lead.
3. **Lead asks one clarifying question at a time** until the feature is clear, then drafts a SPEC using the [SPEC template](templates/spec.md).
4. **PM reviews and confirms.** Status flips from `draft` to `ready`. SPEC is saved as `.af/specs/active/SPEC-####.md`.
5. **PM runs `/implement-spec`** and hands the SPEC to the Developer.
6. **Developer reads the SPEC, implements each subtask in order**, marks each `[x]`, and stops at the end.
7. **PM verifies and approves.** Developer opens a PR.
8. **PM merges and archives** the SPEC into `.af/specs/archived/`.

### Bug work

Same shape, but `/create-bug` lets the Lead read source files (narrowly — only files related to the bug) to identify root cause. `/fix-bug` requires a regression test.

## SPEC quality bar

The SPEC is the contract. It is good enough when a Developer reading it knows:

- Exactly what to build and why
- Which files to touch and what to change in each
- What the expected behavior is after each subtask
- What edge cases or constraints to respect

If the Developer has to ask a question mid-implementation, the Lead failed to spec it well enough.

## Versioning

af uses semantic versioning: `vMAJOR.MINOR.PATCH`.

- **MAJOR** — breaking changes to artifacts host projects depend on (renamed/removed agents, commands, or template fields).
- **MINOR** — additive changes (new agent, new command, new optional template field).
- **PATCH** — wording, clarifications, prompt tweaks that don't change the contract.

Each host project records the framework version it was initialized with in a single `.af-version` file. See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Compatibility

af is assistant-agnostic in principle — the agents and templates are plain markdown. In practice, slash commands target [Claude Code](https://github.com/anthropics/claude-code). Adapting the commands to other assistants is mostly a matter of renaming `.claude/commands/` to whatever directory your tool reads.

## License

MIT.

## Contributing

af is opinionated by design — it ships a specific workflow, not a toolkit. Issues and PRs that sharpen the existing roles or fix prompt ambiguities are welcome. Issues proposing alternate workflows are likely to be declined; fork freely instead.
