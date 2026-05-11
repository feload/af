#!/bin/sh
# af — install the AI-assisted development framework.
#
# Default (global) install — slash commands at ~/.claude/commands/, framework
# files cached at ~/.af/<version>/. Run /af-init in any repo to bootstrap it.
#
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- v0.7.0
#
# Per-project install — drops everything into the current directory:
#
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- --local
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh | sh -s -- --local v0.7.0
#
# Two-step (recommended for review):
#   curl -fsSL https://raw.githubusercontent.com/feload/af/main/install.sh -o af-install.sh
#   less af-install.sh
#   sh af-install.sh v0.7.0
#
# Existing files are never overwritten.

set -eu

REPO="feload/af"
RAW_BASE="https://raw.githubusercontent.com/${REPO}"
API_BASE="https://api.github.com/repos/${REPO}"

MODE="global"
VERSION=""

err() { printf "Error: %s\n" "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --local)  MODE="local";  shift ;;
        --global) MODE="global"; shift ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --*) err "unknown flag: $1" ;;
        *)
            [ -z "$VERSION" ] || err "unexpected argument: $1"
            VERSION="$1"
            shift
            ;;
    esac
done

resolve_latest() {
    curl -fsSL "${API_BASE}/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
        | head -n1
}

if [ -z "$VERSION" ]; then
    printf "Resolving latest af release...\n"
    VERSION=$(resolve_latest)
    [ -n "$VERSION" ] || err "could not resolve latest release. Pass a version explicitly: sh install.sh v0.3.0"
fi

printf "Installing af %s (%s mode)...\n" "$VERSION" "$MODE"

if ! curl -fsSL -o /dev/null "${API_BASE}/git/refs/tags/${VERSION}" 2>/dev/null; then
    err "tag ${VERSION} not found in ${REPO}"
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -fsSL "${RAW_BASE}/${VERSION}/MANIFEST" -o "$TMP" \
    || err "could not fetch MANIFEST from ${REPO} at ${VERSION}"
[ -s "$TMP" ] || err "MANIFEST is empty"

AF_HOME="${AF_HOME:-$HOME/.af}"
GLOBAL_CMD_DIR="$HOME/.claude/commands"
GLOBAL_CACHE="${AF_HOME}/${VERSION}"

# Resolve the install destination for a given MANIFEST line.
# Sets DST_PATH, OVERWRITE (1 or 0), and EXEC (1 or 0).
resolve_dst() {
    src="$1"
    host_dst="$2"
    EXEC=0
    case "$src" in
        bin/*) EXEC=1 ;;
    esac
    if [ "$MODE" = "local" ]; then
        DST_PATH="$host_dst"
        OVERWRITE=0
        return
    fi
    # Global mode.
    case "$src" in
        commands/*)
            DST_PATH="${GLOBAL_CMD_DIR}/$(basename "$src")"
            OVERWRITE=1
            ;;
        *)
            DST_PATH="${GLOBAL_CACHE}/${src}"
            OVERWRITE=1
            ;;
    esac
}

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|\#*) continue ;;
    esac
    src=$(printf "%s\n" "$line" | awk '{print $1}')
    host_dst=$(printf "%s\n" "$line" | awk '{print $2}')
    [ -n "$src" ] && [ -n "$host_dst" ] || continue

    resolve_dst "$src" "$host_dst"

    if [ "$OVERWRITE" = "0" ] && [ -e "$DST_PATH" ]; then
        printf "  skip   %s (exists)\n" "$DST_PATH"
        continue
    fi

    mkdir -p "$(dirname "$DST_PATH")"
    curl -fsSL "${RAW_BASE}/${VERSION}/${src}" -o "$DST_PATH" \
        || err "could not fetch ${src}"
    [ "$EXEC" = "1" ] && chmod +x "$DST_PATH"
    printf "  write  %s\n" "$DST_PATH"
done < "$TMP"

if [ "$MODE" = "global" ]; then
    mkdir -p "$GLOBAL_CACHE"
    cp "$TMP" "${GLOBAL_CACHE}/MANIFEST"
    printf "%s\n" "$VERSION" > "${GLOBAL_CACHE}/VERSION"
    printf "%s\n" "$VERSION" > "${AF_HOME}/current"
    printf "  write  %s/MANIFEST\n" "$GLOBAL_CACHE"
    printf "  write  %s/VERSION\n" "$GLOBAL_CACHE"
    printf "  write  %s/current\n" "$AF_HOME"

    cat <<EOF

Done. af ${VERSION} installed globally.

  Slash commands: ${GLOBAL_CMD_DIR}/
  Framework cache: ${GLOBAL_CACHE}/
  Active version: ${AF_HOME}/current

Next steps:
  1. cd into any repo.
  2. Open it in Claude Code.
  3. Run /af-init to bootstrap .af/ and populate the project-context docs.
EOF
    exit 0
fi

# --- Local-mode-only finalization (per-project AGENTS.md/CLAUDE.md/specs dirs) ---

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

cat <<EOF

Done. af ${VERSION} installed into $(pwd).

Next steps:
  1. Open this project in Claude Code.
  2. Run /af-init to populate .af/docs/architecture.md, .af/docs/domain.md,
     and .af/docs/conventions.md from your codebase.
EOF
