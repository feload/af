#!/bin/sh
# af — bootstrap the framework into the current directory from a global install.
#
# Reads the active version from ~/.af/current, then copies the cached
# framework files from ~/.af/<version>/ into ./.af/. Existing files are
# never overwritten. SPECs and bugs live as per-item JSON files under
# .af/docs/usm/source/{specs,bugs}/ — the bundled .js files are generated
# artifacts produced by .af/bin/build-usm.py.
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
copy_file "templates/base.css"       ".af/templates/base.css"
copy_file "docs/workflow.md"         ".af/docs/workflow.md"
copy_file "docs/architecture.md"     ".af/docs/architecture.md"
copy_file "docs/domain.md"           ".af/docs/domain.md"
copy_file "docs/conventions.md"      ".af/docs/conventions.md"
copy_file "docs/usm.md"              ".af/docs/usm.md"
copy_file "docs/usm/index.html"      ".af/docs/usm/index.html"
copy_file "docs/usm/styles.css"      ".af/docs/usm/styles.css"
copy_file "bin/build-usm.py"         ".af/bin/build-usm.py"
copy_file "hooks/pre-commit"         ".af/hooks/pre-commit"
chmod +x .af/bin/build-usm.py .af/hooks/pre-commit 2>/dev/null || true

# Title the USM per-project: default the name to the repo directory.
# JSON-escape backslashes and double quotes so odd directory names are safe.
PROJECT_NAME=$(basename "$(pwd)")
PROJECT_NAME_ESC=$(printf '%s' "$PROJECT_NAME" | sed 's/\\/\\\\/g; s/"/\\"/g')

if write_inline ".af/docs/usm/source/skeleton.json"; then
    cat > .af/docs/usm/source/skeleton.json <<EOF
{
  "project": "${PROJECT_NAME_ESC}",
  "activities": []
}
EOF
    printf "  write  .af/docs/usm/source/skeleton.json\n"
fi

for dir in releases stories specs bugs; do
    keep=".af/docs/usm/source/${dir}/.gitkeep"
    if [ ! -e "$keep" ]; then
        mkdir -p ".af/docs/usm/source/${dir}"
        : > "$keep"
        printf "  write  %s\n" "$keep"
    else
        printf "  skip   %s (exists)\n" "$keep"
    fi
done

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
  (Activities + Steps under `.af/docs/usm/source/skeleton.json`) and
  files stories under those Steps via `/af-create-story` (one file per
  story under `.af/docs/usm/source/stories/`).
- The PM hands a story to the Lead via `/af-create-spec`, or reports a
  bug via `/af-create-bug`.
- The Lead writes one JSON file per SPEC under
  `.af/docs/usm/source/specs/SPEC-XXXX.json` (or
  `.af/docs/usm/source/bugs/BUG-XXXX.json` for bugs). PM confirms.
- The Developer implements via `/af-implement-spec` or `/af-fix-bug`,
  reading the SPEC file directly from `source/`. `/af-implement-slice
  <slice-id>` implements a whole release in one run.
- PM approves; PR is opened; SPEC `status` flips to `archived` (or bug
  `status` to `fixed`) in the same JSON file.

The bundled `.af/docs/usm/{data,specs,bugs}.js` are **generated
artifacts** — never hand-edit them. Run
`python3 .af/bin/build-usm.py` after editing anything under `source/`,
or enable the pre-commit hook to do it automatically:

```
git config core.hooksPath .af/hooks
```

Full rules: `.af/docs/workflow.md`. Role definitions: `.af/agents/`.

## Project context

Run `/af-init` in Claude Code to populate `.af/docs/architecture.md`,
`.af/docs/domain.md`, and `.af/docs/conventions.md` from the codebase.

## User Story Map, SPECs and BUGs

The visual map of activities, steps, stories, releases, SPECs and bugs
lives under `.af/docs/usm/` as a static HTML site. The single source of
truth is `.af/docs/usm/source/` (per-item JSON). Open
`.af/docs/usm/index.html` to view. See `.af/docs/usm.md` for the full
data schema.

## Updating

Re-run `install.sh` to refresh the global cache, then `/af-update` in
this repo to bring `.af/` to that version. `/af-update v0.X.0` targets
a specific version. Host-populated docs and everything under
`.af/docs/usm/source/` are preserved; the bundled `.js` files are
regenerated.
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

# Generate the bundled .js files so the static viewer has something to read.
if command -v python3 >/dev/null 2>&1; then
    python3 .af/bin/build-usm.py >/dev/null 2>&1 || \
        printf "  warn   build-usm.py failed — run it manually before opening the USM\n"
    printf "  build  .af/docs/usm/{data,specs,bugs}.js + source/INDEX.md\n"
else
    printf "  warn   python3 not found — run python3 .af/bin/build-usm.py before opening the USM\n"
fi

cat <<EOF

Done. af ${VERSION} bootstrapped into $(pwd).

To auto-rebuild the USM bundles on every commit (recommended), run:

  git config core.hooksPath .af/hooks

This is not done automatically because modifying your git config is
intrusive. Skip it and run \`python3 .af/bin/build-usm.py\` by hand
after editing files under \`.af/docs/usm/source/\` instead.
EOF
