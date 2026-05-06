#!/bin/sh
# af — install the AI-assisted development framework into the current directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.1.1
#
# Two-step (recommended for review):
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh -o af-install.sh
#   less af-install.sh
#   sh af-install.sh v0.1.1
#
# Existing files are never overwritten.

set -eu

REPO="feload/af"
RAW_BASE="https://raw.githubusercontent.com/${REPO}"
API_BASE="https://api.github.com/repos/${REPO}"

VERSION="${1:-}"

err() { printf "Error: %s\n" "$1" >&2; exit 1; }

resolve_latest() {
    curl -fsSL "${API_BASE}/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
        | head -n1
}

if [ -z "$VERSION" ]; then
    printf "Resolving latest af release...\n"
    VERSION=$(resolve_latest)
    [ -n "$VERSION" ] || err "could not resolve latest release. Pass a version explicitly: sh install.sh v0.1.1"
fi

printf "Installing af %s...\n" "$VERSION"

if ! curl -fsSL -o /dev/null "${API_BASE}/git/refs/tags/${VERSION}" 2>/dev/null; then
    err "tag ${VERSION} not found in ${REPO}"
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -fsSL "${RAW_BASE}/${VERSION}/MANIFEST" -o "$TMP" \
    || err "could not fetch MANIFEST from ${REPO} at ${VERSION}"
[ -s "$TMP" ] || err "MANIFEST is empty"

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|\#*) continue ;;
    esac
    src=$(printf "%s\n" "$line" | awk '{print $1}')
    dst=$(printf "%s\n" "$line" | awk '{print $2}')
    [ -n "$src" ] && [ -n "$dst" ] || continue

    if [ -e "$dst" ]; then
        printf "  skip   %s (exists)\n" "$dst"
        continue
    fi

    mkdir -p "$(dirname "$dst")"
    curl -fsSL "${RAW_BASE}/${VERSION}/${src}" -o "$dst" \
        || err "could not fetch ${src}"
    printf "  write  %s\n" "$dst"
done < "$TMP"

mkdir -p .af/specs/active .af/specs/archived
[ -f .af/specs/active/.gitkeep ] || touch .af/specs/active/.gitkeep
[ -f .af/specs/archived/.gitkeep ] || touch .af/specs/archived/.gitkeep

printf "%s\n" "$VERSION" > .af/VERSION
printf "  write  .af/VERSION\n"

if [ ! -f AGENTS.md ]; then
    cat > AGENTS.md <<'AGENTS_EOF'
# AGENTS.md

This project uses the **af** AI-assisted development framework.

## Workflow

- The PM (you) hands work to the Lead via `/create-spec` or `/create-bug`.
- The Lead writes a SPEC into `.af/specs/active/`. PM confirms.
- The Developer implements via `/implement-spec` or `/fix-bug`.
- PM approves; PR is opened; SPEC moves to `.af/specs/archived/`.

Full rules: `.af/docs/workflow.md`. Role definitions: `.af/agents/`.

## Project context

Run `/init-af` in Claude Code to populate `.af/docs/architecture.md`,
`.af/docs/domain.md`, and `.af/docs/conventions.md` from the codebase.
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

cat <<EOF

Done. af ${VERSION} installed into $(pwd).

Next steps:
  1. Open this project in Claude Code.
  2. Run /init-af to populate .af/docs/architecture.md, .af/docs/domain.md,
     and .af/docs/conventions.md from your codebase.
EOF
