#!/usr/bin/env bash
# doc-screening skill installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Tunging/doc-screening/main/install.sh | bash            # user scope
#   curl -fsSL ... | bash -s -- --project                                                              # this repo only
#   curl -fsSL ... | bash -s -- --uninstall [--project]
set -euo pipefail

REPO="${DOC_SCREENING_REPO:-Tunging/doc-screening}"
BRANCH="${DOC_SCREENING_BRANCH:-main}"
RAW="${DOC_SCREENING_BASE_URL:-https://raw.githubusercontent.com/${REPO}/${BRANCH}}/SKILL.md"

SCOPE="user"
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --project)  SCOPE="project" ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ "$SCOPE" = "project" ]; then
  DEST_DIR="$PWD/.claude/skills/doc-screening"
else
  DEST_DIR="${HOME}/.claude/skills/doc-screening"
fi
DEST="$DEST_DIR/SKILL.md"

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then wget -qO- "$1"
  else echo "need curl or wget" >&2; exit 1; fi
}

if [ "$UNINSTALL" = 1 ]; then
  if [ -f "$DEST" ]; then rm "$DEST" && rmdir "$DEST_DIR" 2>/dev/null || true
    echo "removed $DEST"
  else
    echo "not found: $DEST"; exit 1
  fi
  exit 0
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
fetch "$RAW" > "$TMP" || { echo "download failed: $RAW" >&2; exit 1; }

# sanity: file must be the skill, not an error page
if [ ! -s "$TMP" ] || ! grep -q '^name: doc-screening' "$TMP"; then
  echo "download failed or invalid SKILL.md from $RAW" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
mv "$TMP" "$DEST"

echo "installed: $DEST  (repo ${REPO}@${BRANCH})"
echo
echo "Claude Code : already available in new sessions (skills dir scanned at startup)."
echo "omp         : auto-discovers ~/.claude/skills; in a running TUI run /reload-plugins."
echo "Verify      : claude -> /skills list, omp -> /extensions > Skills; ask for 文档巡检 / docs screening."
if [ "$SCOPE" = "project" ]; then
  echo
  echo "Project scope: commit $DEST_DIR to share with the team, or add '.claude/skills/' to .gitignore for personal use."
fi
