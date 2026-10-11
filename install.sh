#!/bin/sh
# Link this repo into the live pi / Claude Code config. Usage: install.sh [pi|claude|all]
# Idempotent. Never overwrites a real file or directory (skips and reports),
# except ~/.claude/CLAUDE.md, which is moved to CLAUDE.md.bak once. Removes
# links into this repo that are no longer targets; only reports foreign ones.
set -eu
root="$(cd "$(dirname "$0")" && pwd)"
. "$root/scripts/lib.sh"
target="${1:-all}"
case "$target" in pi|claude|all) ;; *) echo "usage: $0 [pi|claude|all]" >&2; exit 2 ;; esac
[ "$root" = "$HOME/code/agents" ] ||
  echo "WARN  repo is at $root; CLAUDE.md, pi/settings.json and the guard hook expect ~/code/agents" >&2
skipped=0

if [ "$target" != pi ] && [ -f "$cl/CLAUDE.md" ] && [ ! -L "$cl/CLAUDE.md" ]; then
  if [ -e "$cl/CLAUDE.md.bak" ]; then echo "SKIP  $cl/CLAUDE.md.bak already exists; not replacing CLAUDE.md" >&2; skipped=1
  else mv "$cl/CLAUDE.md" "$cl/CLAUDE.md.bak"; echo "bak   $cl/CLAUDE.md.bak"; fi
fi

builtin="$pa/npm/node_modules/pi-subagents/agents"
while IFS="$tab" read -r src dst; do
  [ -n "$src" ] || continue
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then echo "SKIP  $dst exists and is not a symlink" >&2; skipped=1; continue; fi
  case "$dst" in "$pa/agents/"*)
    n="$(fm_name "$src")"
    if [ -f "$builtin/$n.md" ]; then echo "SKIP  agent '$n' would shadow a pi-subagents builtin" >&2; skipped=1; continue; fi ;;
  esac
  mkdir -p "$(dirname "$dst")"; ln -sfn "$src" "$dst"; echo "link  $dst"
done <<EOF
$(targets "$target")
EOF

while IFS="$tab" read -r kind l; do
  case "$kind" in
    stale) rm "$l"; echo "prune $l" ;;
    dangling) echo "WARN  $l -> $(readlink "$l") is dangling (not managed here)" >&2 ;;
  esac
done <<EOF
$(stray_links "$target")
EOF
exit $skipped
