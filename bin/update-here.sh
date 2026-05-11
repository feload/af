#!/bin/sh
# af — update an already-initialized host's framework files to a target version.
#
# Usage (invoked by /af-update):
#   sh ~/.af/<global>/bin/update-here.sh           # catches host up to ~/.af/current
#   sh ~/.af/<global>/bin/update-here.sh v0.5.0    # catches host up to v0.5.0,
#                                                  # fetching the version into
#                                                  # ~/.af/v0.5.0/ if not cached.
#
# Overwrites framework files only — agents/, templates/, docs/workflow.md, bin/.
# Bumps .af/VERSION to the target on success.
#
# Does NOT touch: .af/specs/, .af/docs/architecture.md, .af/docs/domain.md,
# .af/docs/conventions.md, AGENTS.md, CLAUDE.md. The /af-update slash command
# handles host-populated docs interactively after this script returns.

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
        case "$src" in bin/*) chmod +x "$dst" ;; esac
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

overwrite "agents/lead.md"           ".af/agents/lead.md"
overwrite "agents/developer.md"      ".af/agents/developer.md"
overwrite "templates/spec.md"        ".af/templates/spec.md"
overwrite "templates/bug.md"         ".af/templates/bug.md"
overwrite "docs/workflow.md"         ".af/docs/workflow.md"
overwrite "bin/bootstrap-here.sh"    ".af/bin/bootstrap-here.sh"
overwrite "bin/update-here.sh"       ".af/bin/update-here.sh"
chmod +x .af/bin/bootstrap-here.sh .af/bin/update-here.sh

printf "%s\n" "$TARGET" > .af/VERSION
printf "  write  .af/VERSION (%s)\n" "$TARGET"

cat <<EOF

Framework files updated to ${TARGET}.

Three host-populated docs were NOT touched:
  .af/docs/architecture.md
  .af/docs/domain.md
  .af/docs/conventions.md

The /af-update slash command will diff each against ${TARGET}'s placeholder
and ask whether to keep yours, take the new placeholder, or merge manually.
EOF
