#!/bin/sh
# af — update an already-initialized host's framework files to a target version.
#
# Usage (invoked by /af-update):
#   sh ~/.af/<global>/bin/update-here.sh           # catches host up to ~/.af/current
#   sh ~/.af/<global>/bin/update-here.sh v0.5.0    # catches host up to v0.5.0,
#                                                  # fetching the version into
#                                                  # ~/.af/v0.5.0/ if not cached.
#
# Overwrites framework files (agents/, templates/, docs/workflow.md, docs/usm.md,
# docs/usm/index.html, docs/usm/styles.css, bin/, hooks/) and regenerates the
# bundled USM .js files from .af/docs/usm/source/. Bumps .af/VERSION on success.
#
# Does NOT touch: anything under .af/docs/usm/source/ (host-populated USM
# data), .af/docs/architecture.md, .af/docs/domain.md, .af/docs/conventions.md,
# AGENTS.md, CLAUDE.md. The /af-update slash command handles host-populated
# docs interactively after this script returns.

set -eu

REPO="feload/af"
RAW_BASE="https://raw.githubusercontent.com/${REPO}"
API_BASE="https://api.github.com/repos/${REPO}"

err() { printf "Error: %s\n" "$1" >&2; exit 1; }

AF_HOME="${AF_HOME:-$HOME/.af}"
CURRENT_FILE="${AF_HOME}/current"

[ -f .af/VERSION ] || err "no .af/VERSION in $(pwd) — run /af-init first."

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    [ -f "$CURRENT_FILE" ] || err "no global af install at ${CURRENT_FILE} — run install.sh first or pass a version."
    TARGET=$(head -n1 "$CURRENT_FILE" | tr -d ' \t\n\r')
fi
[ -n "$TARGET" ] || err "could not resolve target version"

CACHE="${AF_HOME}/${TARGET}"

fetch_version() {
    if ! curl -fsSL -o /dev/null "${API_BASE}/git/refs/tags/${TARGET}" 2>/dev/null; then
        err "tag ${TARGET} not found in ${REPO}"
    fi
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT
    curl -fsSL "${RAW_BASE}/${TARGET}/MANIFEST" -o "$TMP" \
        || err "could not fetch MANIFEST for ${TARGET}"
    [ -s "$TMP" ] || err "MANIFEST is empty"

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        src=$(printf "%s\n" "$line" | awk '{print $1}')
        [ -n "$src" ] || continue
        case "$src" in commands/*) continue ;; esac
        dst="${CACHE}/${src}"
        mkdir -p "$(dirname "$dst")"
        curl -fsSL "${RAW_BASE}/${TARGET}/${src}" -o "$dst" \
            || err "could not fetch ${src} for ${TARGET}"
        case "$src" in bin/*|hooks/*) chmod +x "$dst" ;; esac
    done < "$TMP"

    cp "$TMP" "${CACHE}/MANIFEST"
    printf "%s\n" "$TARGET" > "${CACHE}/VERSION"
}

if [ ! -d "$CACHE" ]; then
    printf "Fetching af %s into %s...\n" "$TARGET" "$CACHE"
    fetch_version
fi

CURRENT=$(head -n1 .af/VERSION | tr -d ' \t\n\r')
if [ "$CURRENT" = "$TARGET" ]; then
    printf "Already at %s — nothing to do.\n" "$TARGET"
    exit 0
fi

printf "Updating .af/ from %s to %s...\n" "$CURRENT" "$TARGET"

overwrite() {
    src="$1"
    dst="$2"
    [ -f "${CACHE}/${src}" ] || err "missing in cache: ${CACHE}/${src}"
    mkdir -p "$(dirname "$dst")"
    cp "${CACHE}/${src}" "$dst"
    printf "  write  %s\n" "$dst"
}

overwrite "agents/lead.md"                    ".af/agents/lead.md"
overwrite "agents/developer.md"               ".af/agents/developer.md"
overwrite "templates/spec.md"                 ".af/templates/spec.md"
overwrite "templates/bug.md"                  ".af/templates/bug.md"
overwrite "docs/workflow.md"                  ".af/docs/workflow.md"
overwrite "docs/usm.md"                       ".af/docs/usm.md"
overwrite "docs/usm/index.html"               ".af/docs/usm/index.html"
overwrite "docs/usm/styles.css"               ".af/docs/usm/styles.css"
overwrite "bin/bootstrap-here.sh"             ".af/bin/bootstrap-here.sh"
overwrite "bin/update-here.sh"                ".af/bin/update-here.sh"
overwrite "bin/build-usm.py"                  ".af/bin/build-usm.py"
overwrite "bin/migrate-data-to-source.py"     ".af/bin/migrate-data-to-source.py"
overwrite "bin/migrate-specs-bugs-to-source.py" ".af/bin/migrate-specs-bugs-to-source.py"
overwrite "hooks/pre-commit"                  ".af/hooks/pre-commit"
chmod +x .af/bin/bootstrap-here.sh .af/bin/update-here.sh \
         .af/bin/build-usm.py .af/bin/migrate-data-to-source.py \
         .af/bin/migrate-specs-bugs-to-source.py \
         .af/hooks/pre-commit

# Detect pre-source hosts (have data.js but no source/) and run the migrators.
PRE_SOURCE=0
if [ -f .af/docs/usm/data.js ] && [ ! -d .af/docs/usm/source ]; then
    PRE_SOURCE=1
    printf "\nDetected pre-source layout (data.js exists, source/ does not).\n"
    printf "Running migrators to split bundles into per-item JSON under source/...\n"
    if ! command -v python3 >/dev/null 2>&1; then
        cat <<EOF

  python3 is required to run the migrators but was not found.
  After installing python3, run by hand:

    python3 .af/bin/migrate-data-to-source.py
    python3 .af/bin/migrate-specs-bugs-to-source.py
    python3 .af/bin/build-usm.py

EOF
    else
        python3 .af/bin/migrate-data-to-source.py \
            || err "migrate-data-to-source.py failed — see output above and re-run manually"
        if [ -f .af/docs/usm/specs.js ] || [ -f .af/docs/usm/bugs.js ]; then
            python3 .af/bin/migrate-specs-bugs-to-source.py \
                || err "migrate-specs-bugs-to-source.py failed — see output above and re-run manually"
        fi
    fi
fi

# Backfill the per-project title into skeleton.json for hosts that predate
# it. Defaults to the repo directory name; leaves an existing name untouched.
if command -v python3 >/dev/null 2>&1 && [ -f .af/docs/usm/source/skeleton.json ]; then
    AF_PROJECT_NAME=$(basename "$(pwd)") python3 - <<'PY' || \
        printf "  warn   could not backfill project name in skeleton.json\n"
import json, os, sys
p = ".af/docs/usm/source/skeleton.json"
try:
    data = json.load(open(p, encoding="utf-8"))
except Exception:
    sys.exit(0)
if not isinstance(data, dict) or data.get("project"):
    sys.exit(0)
ordered = {"project": os.environ.get("AF_PROJECT_NAME", "")}
for k, v in data.items():
    if k != "project":
        ordered[k] = v
with open(p, "w", encoding="utf-8") as f:
    json.dump(ordered, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("  write  .af/docs/usm/source/skeleton.json (added project name)")
PY
fi

# Regenerate the bundles so they match the new build script's output.
if command -v python3 >/dev/null 2>&1; then
    if [ -d .af/docs/usm/source ]; then
        python3 .af/bin/build-usm.py >/dev/null 2>&1 || \
            printf "  warn   build-usm.py failed — run it manually\n"
        printf "  build  .af/docs/usm/{data,specs,bugs}.js + source/INDEX.md\n"
    fi
else
    printf "  warn   python3 not found — run python3 .af/bin/build-usm.py before opening the USM\n"
fi

printf "%s\n" "$TARGET" > .af/VERSION
printf "  write  .af/VERSION (%s)\n" "$TARGET"

cat <<EOF

Framework files updated to ${TARGET}.

These host-populated files were NOT touched:
  .af/docs/architecture.md
  .af/docs/domain.md
  .af/docs/conventions.md
  .af/docs/usm/source/   (per-item JSON: stories, releases, specs, bugs, skeleton)

The bundled .af/docs/usm/{data,specs,bugs}.js were regenerated from
source/ — they are artifacts, not data.
EOF

if [ "$PRE_SOURCE" = "1" ]; then
    cat <<EOF

This host used the pre-source layout (single data.js/specs.js/bugs.js).
The migrators split those files into per-item JSON under
.af/docs/usm/source/. Review the new layout, commit, and consider
enabling the pre-commit hook to keep bundles in sync:

  git config core.hooksPath .af/hooks
EOF
fi

cat <<EOF

The /af-update slash command will diff the three host docs against
${TARGET}'s placeholder and ask whether to keep yours, take the new
placeholder, or merge manually.
EOF
