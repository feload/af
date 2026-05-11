#!/bin/sh
# af — bootstrap the framework into the current directory from a global install.
#
# Reads the active version from ~/.af/current, then copies the cached
# framework files from ~/.af/<version>/ into ./.af/. Existing files are
# never overwritten.
#
# Invoked by /af-init when ./.af/VERSION is missing. Can also be run
# directly: sh ~/.af/current-dir/bin/bootstrap-here.sh

set -eu

err() { printf "Error: %s\n" "$1" >&2; exit 1; }

AF_HOME="${AF_HOME:-$HOME/.af}"
CURRENT_FILE="${AF_HOME}/current"

[ -f "$CURRENT_FILE" ] || err "no global af install found at ${AF_HOME}/current. Run install.sh from feload/af first."

VERSION=$(head -n1 "$CURRENT_FILE" | tr -d ' \t\n\r')
[ -n "$VERSION" ] || err "${CURRENT_FILE} is empty"

CACHE="${AF_HOME}/${VERSION}"
[ -d "$CACHE" ] || err "cache directory ${CACHE} not found"

copy_file() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ]; then
        printf "  skip   %s (exists)\n" "$dst"
        return
    fi
    [ -f "${CACHE}/${src}" ] || err "missing in cache: ${CACHE}/${src}"
    mkdir -p "$(dirname "$dst")"
    cp "${CACHE}/${src}" "$dst"
    printf "  write  %s\n" "$dst"
}

printf "Bootstrapping af %s into %s...\n" "$VERSION" "$(pwd)"

copy_file "agents/lead.md"           ".af/agents/lead.md"
copy_file "agents/developer.md"      ".af/agents/developer.md"
copy_file "templates/spec.md"        ".af/templates/spec.md"
copy_file "templates/bug.md"         ".af/templates/bug.md"
copy_file "docs/workflow.md"         ".af/docs/workflow.md"
copy_file "docs/architecture.md"     ".af/docs/architecture.md"
copy_file "docs/domain.md"           ".af/docs/domain.md"
copy_file "docs/conventions.md"      ".af/docs/conventions.md"

mkdir -p .af/specs/active .af/specs/archived
[ -f .af/specs/active/.gitkeep ] || touch .af/specs/active/.gitkeep
[ -f .af/specs/archived/.gitkeep ] || touch .af/specs/archived/.gitkeep

if [ ! -f .af/VERSION ]; then
    printf "%s\n" "$VERSION" > .af/VERSION
    printf "  write  .af/VERSION\n"
else
    printf "  skip   .af/VERSION (exists)\n"
fi

if [ ! -f AGENTS.md ]; then
    cat > AGENTS.md <<'AGENTS_EOF'
# AGENTS.md

This project uses the **af** AI-assisted development framework.

## Workflow

- The PM (you) optionally drafts and creates cards via `/af-create-card`.
- The PM hands work to the Lead via `/af-create-spec` or `/af-create-bug`.
- The Lead writes a SPEC into `.af/specs/active/`. PM confirms.
- The Developer implements via `/af-implement-spec` or `/af-fix-bug`.
- PM approves; PR is opened; SPEC moves to `.af/specs/archived/`.

Full rules: `.af/docs/workflow.md`. Role definitions: `.af/agents/`.

## Project context

Run `/af-init` in Claude Code to populate `.af/docs/architecture.md`,
`.af/docs/domain.md`, and `.af/docs/conventions.md` from the codebase.

## Updating

Re-run `install.sh` to refresh the global cache, then `/af-update` in this
repo to bring `.af/` to that version. `/af-update v0.X.0` targets a specific
version. Specs and host-populated docs are preserved.
AGENTS_EOF
    printf "  write  AGENTS.md\n"
else
    printf "  skip   AGENTS.md (exists) — add a pointer to .af/docs/workflow.md manually\n"
fi

if [ ! -f CLAUDE.md ]; then
    printf "See AGENTS.md.\n" > CLAUDE.md
    printf "  write  CLAUDE.md\n"
else
    printf "  skip   CLAUDE.md (exists)\n"
fi

printf "\nDone. af %s bootstrapped into %s.\n" "$VERSION" "$(pwd)"
