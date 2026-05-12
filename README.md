# af — AI-Assisted Development Framework

A lightweight workflow for shipping software with AI coding assistants (Claude Code, Cursor, etc.).

af splits AI-assisted development into three roles — **PM**, **Lead**, and **Developer** — and routes work through a User Story Map and small, well-bounded artifacts (SPECs and BUG SPECs) so the assistant always knows exactly what to build, and you always know exactly what got built. Everything lives inside the repo; there is no external tracker.

## Why af

Most AI-coding sessions fail the same way: vague prompt → assistant explores too much → drifts off-scope → produces code you don't trust. af fixes that by separating the *thinking* from the *typing*:

- The **Lead** turns a fuzzy idea into a precise SPEC. No code yet.
- The **Developer** implements the SPEC verbatim. No exploration, no scope decisions.
- The **PM** (you) owns scope and approves at every gate.

The result: short, predictable AI sessions that stop where you expect them to.

## How it works

```
PM: backbone exists? if not → /af-create-backbone (Activities + Steps in data.js)
PM: /af-create-story → US-#### proposed under a Step (slice: null, Backlog)
PM: /af-create-spec → Lead writes SPEC → PM confirms → status: ready
Developer: implement subtasks + write tests → hand off test tree and run commands to PM
PM: review + run tests → status: approved
Developer: create PR
PM: approve PR → status: archived
```

Each step is its own session — the assistant does one phase per command and stops, so there's no drift across phases.

Bugs follow the same shape, with one extra rule: every fix ships with a regression test.

## Install

af installs globally by default — once. Then `/af-init` bootstraps any repo:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh
```

This places slash commands in `~/.claude/commands/` and caches framework files in `~/.af/<version>/`. To use af in a repo, `cd` into it, open [Claude Code](https://github.com/anthropics/claude-code), and run `/af-init`.

To pin a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.7.0
```

For per-project install instead (slash commands and framework files all live inside the repo):

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- --local
```

For the security-conscious — review before running:

```sh
curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh -o af-install.sh
less af-install.sh
sh af-install.sh v0.7.0
```

### Updating an existing repo

When a new af version ships, re-run `install.sh` to refresh the global cache, then run `/af-update` inside any repo to bring its `.af/` up to that version. To target a specific version directly, pass it as an argument: `/af-update v0.8.0` (the helper fetches it from GitHub if not already cached). Updates overwrite framework files and bump `.af/VERSION`; they never touch the USM data (`.af/docs/usm/data.js`, `specs.js`, `bugs.js`). Host-populated docs (`architecture.md`, `domain.md`, `conventions.md`) are diffed against the new placeholder and you decide per file whether to keep, overwrite, or merge.

### Requirements

- POSIX shell (Linux, macOS, or Git Bash / WSL on Windows)
- `curl`
- A Claude Code installation in the consuming environment

### What gets created

**Global install** (`install.sh`):

```
~/.claude/commands/         # /af-* workflow + lifecycle commands
~/.af/
├── current                 # text file — active version (e.g. "v0.5.0")
└── <version>/
    ├── VERSION
    ├── MANIFEST
    ├── agents/
    ├── templates/
    ├── docs/
    └── bin/
        ├── bootstrap-here.sh
        └── update-here.sh
```

**Per-repo bootstrap** (`/af-init`, or `install.sh --local`):

```
<your project>/
├── .af/
│   ├── VERSION
│   ├── agents/
│   ├── templates/
│   ├── docs/
│   │   ├── architecture.md
│   │   ├── domain.md
│   │   ├── conventions.md
│   │   ├── workflow.md
│   │   ├── usm.md
│   │   └── usm/            # data.js, specs.js, bugs.js, index.html, styles.css
│   └── bin/
├── AGENTS.md               # only if you didn't already have one
└── CLAUDE.md               # only if you didn't already have one
```

Existing files are never overwritten. If you already have `AGENTS.md` or `CLAUDE.md`, add a pointer to `.af/docs/workflow.md` manually.

## Repository layout (this repo)

| Path | What lives there |
|---|---|
| [agents/](agents/) | Role prompts — `lead.md`, `developer.md` |
| [commands/](commands/) | Slash command sources, installed to `~/.claude/commands/` (global) or `.claude/commands/` (`--local`) |
| [templates/](templates/) | `spec.md`, `bug.md` — the artifacts the Lead fills in |
| [docs/](docs/) | `workflow.md` (the rules) + host-side placeholders (`architecture.md`, `domain.md`, `conventions.md`) populated in the host by `/af-init` |
| [bin/bootstrap-here.sh](bin/bootstrap-here.sh) | POSIX helper that copies cached framework files into the current repo. Invoked by `/af-init` |
| [MANIFEST](MANIFEST) | Maps source paths in this repo to target paths in a host project |
| [install.sh](install.sh) | POSIX shell installer (global by default, `--local` for per-project) |
| [AGENTS.md](AGENTS.md) | Guide for AI agents working on the framework itself |

## The flow in detail

### Domain and backbone come first

Before any feature work, two things must exist in the host project:

- **`.af/docs/domain.md`** populated with entities, business rules, and glossary. `/af-init` writes a placeholder; you fill it.
- **A backbone** in `.af/docs/usm/data.js` — Activities (the user's journey, left-to-right) and Steps (concrete actions inside each Activity). Run `/af-create-backbone` to draft or extend it. The command refuses to run if `domain.md` is still the placeholder.

### Feature work

1. **PM runs `/af-create-story`** to file a new US under an existing Step. The Lead suggests the Step that best fits the story; PM confirms. New Stories land in Backlog (`slice: null`) by default.
2. **PM runs `/af-create-spec`** in a new session and points the Lead at the US.
3. **Lead asks one clarifying question at a time** until the SPEC is unambiguous, then drafts it using the [SPEC template](templates/spec.md) as a JSON entry in `.af/docs/usm/specs.js`.
4. **PM reviews and confirms.** Status flips from `draft` to `ready`.
5. **PM runs `/af-implement-spec`** and hands the SPEC ID to the Developer.
6. **Developer reads the SPEC, implements each subtask in order**, flips each `done` to `true` in `specs.js`, and writes tests organized to read as a description of the application's behavior. Developer does not run the test suite — instead prints a tree of the tests added or modified in the session and hands the PM the exact commands to run them (and may optionally offer to run them on the PM's behalf).
7. **PM runs the tests, verifies, and approves.** Developer opens a PR.
8. **PM merges**; SPEC status flips to `archived` and the entry stays in `specs.js` as a record.

### Bug work

Same shape, but `/af-create-bug` lets the Lead read source files (narrowly — only files related to the bug) to identify root cause and write the BUG entry directly into `.af/docs/usm/bugs.js`. `/af-fix-bug` requires a regression test. The same test handoff applies: Developer prints the test tree and the run commands, PM runs them.

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
