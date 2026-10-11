#!/bin/sh
# Verify this machine's live pi / Claude Code config matches the repo, then run
# the repo lint. Read-only.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/scripts/lib.sh"
rc=0
bad() { echo "FAIL  $*" >&2; rc=1; }
ok()  { echo "ok    $*"; }

if [ "$root" = "$HOME/code/agents" ]; then ok "repo at ~/code/agents"
else bad "repo is at $root; CLAUDE.md, pi/settings.json and the guard hook expect ~/code/agents"; fi

while IFS="$tab" read -r src dst; do
  [ -n "$src" ] || continue
  if [ ! -L "$dst" ]; then bad "$dst is not a symlink (run install.sh)"; continue; fi
  t="$(readlink "$dst")"
  if [ "$t" != "$src" ]; then bad "$dst -> $t (expected $src)"; continue; fi
  if [ -e "$dst" ]; then ok "$dst"; else bad "$dst is a dangling link"; fi
done <<EOF
$(targets all)
EOF

while IFS="$tab" read -r kind l; do
  case "$kind" in
    stale) bad "$l is a stale link into this repo (run install.sh)" ;;
    dangling) echo "WARN  $l -> $(readlink "$l") is dangling (not managed here)" >&2 ;;
  esac
done <<EOF
$(stray_links all)
EOF

# pi agents must not shadow the installed pi-subagents builtins
builtin="$pa/npm/node_modules/pi-subagents/agents"
for f in "$root"/pi/agents/*.md; do
  [ -f "$f" ] || continue
  n="$(fm_name "$f")"
  [ -f "$builtin/$n.md" ] && bad "pi agent '$n' shadows a pi-subagents builtin"
done

# pi loads the guard by path; Claude settings carry our permissions and hook
python3 - "$root" "$cl/settings.json" <<'PY' || rc=1
import json, os, sys
root, live = sys.argv[1], sys.argv[2]
rc = 0
def bad(m):
    global rc; print(f"FAIL  {m}", file=sys.stderr); rc = 1
pi = json.load(open(f"{root}/pi/settings.json"))
for p in pi.get("extensions", []) + pi.get("subagents", {}).get("defaultSubagentOnlyExtensions", []):
    if os.path.isfile(os.path.expanduser(p)): print(f"ok    pi extension {p}")
    else: bad(f"pi extension {p} does not exist")
try: cfg = json.load(open(live))
except (OSError, ValueError) as e: bad(f"{live}: {e}"); sys.exit(rc)
print(f"ok    valid JSON {live}")
want = json.load(open(f"{root}/claude/settings.merge.json"))
have = cfg.get("permissions", {})
for k, rules in want.get("permissions", {}).items():
    for r in rules:
        if r not in have.get(k, []): bad(f"claude permissions.{k} missing {r} (run scripts/merge-claude-settings.sh)")
for event, entries in want.get("hooks", {}).items():
    cmds = {h.get("command") for e in cfg.get("hooks", {}).get(event, []) for h in e.get("hooks", [])}
    for e in entries:
        for h in e["hooks"]:
            c = h["command"].replace("@ROOT@", root)
            if c in cmds: print(f"ok    claude hook {event}: {c}")
            else: bad(f"claude hook {event} missing {c} (run scripts/merge-claude-settings.sh)")
sys.exit(rc)
PY

sh "$root/scripts/lint.sh" || rc=1
exit $rc
