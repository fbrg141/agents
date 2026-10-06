#!/bin/sh
# Link this repo into the live pi / Claude Code config. Usage: install.sh [pi|claude|all]
# Idempotent. Never overwrites a real file or directory (skips and reports),
# except ~/.claude/CLAUDE.md, which is moved to CLAUDE.md.bak once.
set -eu
root="$(cd "$(dirname "$0")" && pwd)"
target="${1:-all}"
skipped=0

link() { # link <src> <dst>
  if [ -e "$2" ] && [ ! -L "$2" ]; then echo "SKIP  $2 exists and is not a symlink" >&2; skipped=1; return; fi
  mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; echo "link  $2"
}
fm_name() { awk '/^---/{n++; next} n==1 && /^name:/{sub(/^name:[ \t]*/,""); print; exit}' "$1"; }

install_pi() {
  a="$HOME/.pi/agent"
  link "$root/pi/APPEND_SYSTEM.md" "$a/APPEND_SYSTEM.md"
  link "$root/pi/settings.json" "$a/settings.json"
  link "$root/shared/CORE.md" "$a/AGENTS.md"
  for d in "$root"/pi/skills/*/; do [ -d "$d" ] && link "${d%/}" "$a/skills/$(basename "$d")"; done
  for f in "$root"/pi/extensions/*.ts; do [ -f "$f" ] && link "$f" "$a/extensions/$(basename "$f")"; done
  builtin="$a/npm/node_modules/pi-subagents/agents"
  for f in "$root"/pi/agents/*.md; do
    [ -f "$f" ] || continue
    n="$(fm_name "$f")"
    if [ -f "$builtin/$n.md" ]; then echo "SKIP  agent '$n' would shadow a pi-subagents builtin" >&2; skipped=1; continue; fi
    link "$f" "$a/agents/$(basename "$f")"
  done
}

install_claude() {
  c="$HOME/.claude"
  if [ -f "$c/CLAUDE.md" ] && [ ! -L "$c/CLAUDE.md" ]; then
    if [ -e "$c/CLAUDE.md.bak" ]; then echo "SKIP  $c/CLAUDE.md.bak already exists; not replacing CLAUDE.md" >&2; skipped=1
    else mv "$c/CLAUDE.md" "$c/CLAUDE.md.bak"; echo "bak   $c/CLAUDE.md.bak"; fi
  fi
  link "$root/claude/CLAUDE.md" "$c/CLAUDE.md"
  for d in "$root"/claude/skills/*/; do [ -d "$d" ] && link "${d%/}" "$c/skills/$(basename "$d")"; done
  for f in "$root"/claude/agents/*.md; do [ -f "$f" ] && link "$f" "$c/agents/$(basename "$f")"; done
}

case "$target" in
  pi) install_pi ;; claude) install_claude ;; all) install_pi; install_claude ;;
  *) echo "usage: $0 [pi|claude|all]" >&2; exit 2 ;;
esac
exit $skipped
