#!/bin/sh
# Verify the live pi / Claude Code config matches this repo. Read-only.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
rc=0
bad() { echo "FAIL  $*" >&2; rc=1; }
ok()  { echo "ok    $*"; }

# expect_link <live path> <repo target>
expect_link() {
  if [ ! -L "$1" ]; then bad "$1 is not a symlink"; return; fi
  t="$(readlink "$1")"
  [ "$t" = "$2" ] || { bad "$1 -> $t (expected $2)"; return; }
  [ -e "$1" ] || { bad "$1 is a dangling link"; return; }
  ok "$1"
}
fm_name() { awk '/^---/{n++; next} n==1 && /^name:/{sub(/^name:[ \t]*/,""); print; exit}' "$1"; }

pa="$HOME/.pi/agent"; cl="$HOME/.claude"
expect_link "$pa/APPEND_SYSTEM.md" "$root/pi/APPEND_SYSTEM.md"
expect_link "$pa/settings.json" "$root/pi/settings.json"
expect_link "$pa/AGENTS.md" "$root/shared/CORE.md"
for d in "$root"/pi/skills/*/; do expect_link "$pa/skills/$(basename "$d")" "${d%/}"; done
for f in "$root"/pi/extensions/*.ts; do [ -f "$f" ] && expect_link "$pa/extensions/$(basename "$f")" "$f"; done
expect_link "$cl/CLAUDE.md" "$root/claude/CLAUDE.md"
for d in "$root"/claude/skills/*/; do expect_link "$cl/skills/$(basename "$d")" "${d%/}"; done
for f in "$root"/claude/agents/*.md; do [ -f "$f" ] && expect_link "$cl/agents/$(basename "$f")" "$f"; done

# pi agents must not shadow builtins
builtin="$pa/npm/node_modules/pi-subagents/agents"
for f in "$root"/pi/agents/*.md; do
  [ -f "$f" ] || continue
  n="$(fm_name "$f")"; expect_link "$pa/agents/$(basename "$f")" "$f"
  [ -f "$builtin/$n.md" ] && bad "pi agent '$n' shadows a pi-subagents builtin"
done
# claude agents must not reuse a built-in name
for f in "$root"/claude/agents/*.md; do
  [ -f "$f" ] || continue
  n="$(fm_name "$f")"
  case "$n" in Explore|Plan|general-purpose|claude|claude-code-guide|statusline-setup) bad "claude agent '$n' reuses a built-in name" ;; esac
done

# JSON validity
for j in "$root/pi/settings.json" "$cl/settings.json"; do
  if python3 -m json.tool "$j" >/dev/null 2>&1; then ok "valid JSON $j"; else bad "invalid JSON $j"; fi
done

# claude permission guards present
if [ -f "$root/claude/settings.permissions.json" ]; then
  python3 - "$root/claude/settings.permissions.json" "$cl/settings.json" <<'PY' || rc=1
import json, sys
want = json.load(open(sys.argv[1]))["permissions"]
have = json.load(open(sys.argv[2])).get("permissions", {})
miss = [(k, r) for k, rules in want.items() for r in rules if r not in have.get(k, [])]
for k, r in miss: print(f"FAIL  claude permissions.{k} missing {r}", file=sys.stderr)
sys.exit(1 if miss else 0)
PY
fi

sh "$root/scripts/check.sh" || rc=1
exit $rc
