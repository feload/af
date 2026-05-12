#!/bin/sh
# af — bootstrap the framework into the current directory from a global install.
#
# Reads the active version from ~/.af/current, then copies the cached
# framework files from ~/.af/<version>/ into ./.af/. Existing files are
# never overwritten. SPECs and bugs live as JSON entries in
# .af/docs/usm/specs.js and .af/docs/usm/bugs.js — not as .md files.
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

write_inline() {
    dst="$1"
    if [ -e "$dst" ]; then
        printf "  skip   %s (exists)\n" "$dst"
        return 1
    fi
    mkdir -p "$(dirname "$dst")"
    return 0
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
copy_file "docs/usm.md"              ".af/docs/usm.md"
copy_file "docs/usm/index.html"      ".af/docs/usm/index.html"
copy_file "docs/usm/styles.css"      ".af/docs/usm/styles.css"

if write_inline ".af/docs/usm/data.js"; then
    cat > .af/docs/usm/data.js <<'DATA_EOF'
window.USM_DATA = {
  "slices": [],
  "activities": []
};
DATA_EOF
    printf "  write  .af/docs/usm/data.js\n"
fi

if write_inline ".af/docs/usm/specs.js"; then
    cat > .af/docs/usm/specs.js <<'SPECS_EOF'
// SPECs ligados (o no) a historias del USM. Cuando aplica, cada SPEC se
// liga a una historia por `story` (ID del US). Si es trabajo transversal
// (infra, refactor, CI) `story` puede ser null/omitirse. Es la fuente
// única de verdad de los SPECs en este repo: el Lead escribe aquí (no en
// .md). El Developer lee de aquí. Los drafts (con o sin story) aparecen
// en la bandeja "Sin asignar" del header del USM.
window.USM_SPECS = [];
SPECS_EOF
    printf "  write  .af/docs/usm/specs.js\n"
fi

if write_inline ".af/docs/usm/bugs.js"; then
    cat > .af/docs/usm/bugs.js <<'BUGS_EOF'
// Bugs ligados (cuando aplica) a historias del USM. Cada bug se liga a
// una historia por `story` (ID del US). `story` puede ser null para bugs
// huérfanos (raro; usualmente infra) — esos aparecen en la bandeja "Sin
// asignar" del header del USM. Es la fuente única de verdad de los bugs:
// el Lead escribe aquí (no en .md). El Developer lee de aquí.
window.USM_BUGS = [];
BUGS_EOF
    printf "  write  .af/docs/usm/bugs.js\n"
fi

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

- The PM (you) shapes the USM backbone via `/af-create-backbone`
  (Activities + Steps under `.af/docs/usm/data.js`) and files stories
  under those Steps via `/af-create-story`.
- The PM hands a story to the Lead via `/af-create-spec`, or reports a
  bug via `/af-create-bug`.
- The Lead writes a SPEC as a JSON entry in `.af/docs/usm/specs.js`
  (or in `.af/docs/usm/bugs.js` for bugs). PM confirms.
- The Developer implements via `/af-implement-spec` or `/af-fix-bug`,
  reading the SPEC entry directly from the JSON.
- PM approves; PR is opened; SPEC `status` flips to `archived` (or bug
  `status` to `fixed`) in the same JSON file.

Full rules: `.af/docs/workflow.md`. Role definitions: `.af/agents/`.

## Project context

Run `/af-init` in Claude Code to populate `.af/docs/architecture.md`,
`.af/docs/domain.md`, and `.af/docs/conventions.md` from the codebase.

## User Story Map, SPECs and BUGs

The visual map of activities, steps, stories, releases, SPECs and bugs
lives under `.af/docs/usm/` as a static HTML site. SPECs and bugs are
also the canonical source of work — the Lead writes JSON entries in
`specs.js` / `bugs.js` and the Developer reads them from there. Open
`.af/docs/usm/index.html` to view. See `.af/docs/usm.md` for the full
data schema.

## Updating

Re-run `install.sh` to refresh the global cache, then `/af-update` in this
repo to bring `.af/` to that version. `/af-update v0.X.0` targets a specific
version. Host-populated docs and the USM data (data.js, specs.js, bugs.js)
are preserved.
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
