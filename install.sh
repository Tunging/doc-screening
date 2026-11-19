#!/usr/bin/env bash
# doc-screening + doc-cleanup skill installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Tunging/doc-screening/main/install.sh | bash            # user scope, both skills
#   curl -fsSL ... | bash -s -- --project                                                               # this repo only
#   curl -fsSL ... | bash -s -- --only doc-screening                                                    # single skill
#   curl -fsSL ... | bash -s -- --uninstall [--project]
set -euo pipefail

REPO="${DOC_SCREENING_REPO:-Tunging/doc-screening}"
BRANCH="${DOC_SCREENING_BRANCH:-main}"
BASE="${DOC_SCREENING_BASE_URL:-https://raw.githubusercontent.com/${REPO}/${BRANCH}}"
ALL_SKILLS="doc-screening doc-cleanup"

SCOPE="user"
UNINSTALL=0
ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project)  SCOPE="project" ;;
    --uninstall) UNINSTALL=1 ;;
    --only) shift; ONLY="${1:-}" ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

case "$ONLY" in
  "")              SKILLS=(${ALL_SKILLS}) ;;
  doc-screening|doc-cleanup) SKILLS=($ONLY) ;;
  *) echo "--only must be doc-screening or doc-cleanup" >&2; exit 2 ;;
esac

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then wget -qO- "$1"
  else echo "need curl or wget" >&2; exit 1; fi
}

install_one() { # $1 = skill name
  local name="$1"
  local dest_dir dest tmp
  if [ "$SCOPE" = "project" ]; then dest_dir="$PWD/.claude/skills/$name"
  else dest_dir="${HOME}/.claude/skills/$name"; fi
  dest="$dest_dir/SKILL.md"

  tmp=$(mktemp)
  fetch "$BASE/skills/$name/SKILL.md" > "$tmp" || { echo "download failed: $BASE/skills/$name/SKILL.md" >&2; rm -f "$tmp"; return 1; }
  if [ ! -s "$tmp" ] || ! grep -q "^name: $name" "$tmp"; then
    echo "invalid SKILL.md from $BASE/skills/$name/SKILL.md" >&2; rm -f "$tmp"; return 1
  fi
  mkdir -p "$dest_dir"
  mv "$tmp" "$dest"
  echo "installed: $dest"
}

uninstall_one() { # $1 = skill name
  local name="$1"
  local dest_dir
  if [ "$SCOPE" = "project" ]; then dest_dir="$PWD/.claude/skills/$name"
  else dest_dir="${HOME}/.claude/skills/$name"; fi
  if [ -f "$dest_dir/SKILL.md" ]; then
    rm "$dest_dir/SKILL.md" && rmdir "$dest_dir" 2>/dev/null || true
    echo "removed $dest_dir/SKILL.md"
  else
    echo "not found: $dest_dir/SKILL.md"
  fi
}

FAIL=0
if [ "$UNINSTALL" = 1 ]; then
  for s in "${SKILLS[@]}"; do uninstall_one "$s"; done
else
  for s in "${SKILLS[@]}"; do install_one "$s" || FAIL=1; done
  echo
  echo "Claude Code : new sessions pick these up automatically (skills dir scanned at startup)."
  echo "omp         : auto-discovers ~/.claude/skills; in a running TUI run /reload-plugins."
  echo "Workflow    : 1) run doc-screening (read-only report) -> 2) review -> 3) tell doc-cleanup which rows are confirmed."
  if [ "$SCOPE" = "project" ]; then
    echo
    echo "Project scope: commit .claude/skills/ to share with the team, or gitignore it for personal use."
  fi
fi
exit $FAIL
