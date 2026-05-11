---
model: sonnet
effort: medium
---

# /af-update

**Trigger:** PM wants to bring an already-initialized repo's `.af/` up to a newer framework version.

**Prerequisites:**
- `.af/VERSION` exists (repo was initialized via `/af-init`).
- af is installed globally and `~/.af/<global-version>/bin/update-here.sh` exists. If your global install predates `/af-update`, re-run `install.sh` first.

**Arguments:** `$ARGUMENTS` — optional version tag (e.g. `v0.5.0`). If omitted, the target is whatever `~/.af/current` points to. If the version isn't already cached at `~/.af/<version>/`, the helper script fetches it from GitHub.

**Steps:**

1. **Run the update script.** Read `~/.af/current` to get the global version, then invoke `~/.af/<global-version>/bin/update-here.sh $ARGUMENTS` via Bash. The script fetches the target if needed, overwrites framework files (`agents/`, `templates/`, `docs/workflow.md`, `bin/`), and bumps `.af/VERSION` to the target. It does not touch host-populated docs or `.af/specs/`.

2. **Review host-populated docs.** For each of `.af/docs/architecture.md`, `.af/docs/domain.md`, `.af/docs/conventions.md`:
   - Run `diff` against the target's placeholder at `~/.af/<target>/docs/<name>.md`.
   - If identical, tell the PM and skip.
   - If different, summarize the diff (new sections, removed sections, structural changes — not whole-file dump unless small) and ask the PM **per file** which to do:
     - **Keep mine** (default — the host's content is usually richer than the framework placeholder).
     - **Take new placeholder** (overwrite — destructive; only sensible if the host's version is still mostly placeholder text).
     - **Merge manually** (PM edits; you can show the new sections inline so they can paste).

3. **Summarize.** Print: target version, framework files refreshed, per-doc PM choices.

**Output:** Updated `.af/`, refreshed `.af/VERSION`, and a one-screen summary.

**Stop here.** Do not load any agent. Do not start a SPEC, fix, or implementation. Updating is its own session.
