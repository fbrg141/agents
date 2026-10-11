#!/bin/sh
# Union claude/settings.merge.json into ~/.claude/settings.json.
# Backs up once to settings.json.pre-agents-repo; touches only permissions.ask/deny
# and appends our hook entries (matched by command, @ROOT@ = this repo).
# Never symlink settings.json: Claude Code and plugins write machine state into it.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
live="$HOME/.claude/settings.json"
[ -f "$live" ] || { echo "no $live" >&2; exit 1; }
[ -e "$live.pre-agents-repo" ] || cp -p "$live" "$live.pre-agents-repo"
python3 - "$root/claude/settings.merge.json" "$live" "$root" <<'PY'
import json, os, sys, tempfile
want = json.load(open(sys.argv[1]))
path, root = sys.argv[2], sys.argv[3]
cfg = json.load(open(path))
added = 0
perm = cfg.setdefault("permissions", {})
for kind, rules in want.get("permissions", {}).items():
    cur = perm.setdefault(kind, [])
    for r in rules:
        if r not in cur:
            cur.append(r); added += 1
hooks = cfg.setdefault("hooks", {})
for event, entries in want.get("hooks", {}).items():
    cur = hooks.setdefault(event, [])
    have = {h.get("command") for e in cur for h in e.get("hooks", [])}
    for e in entries:
        e = dict(e, hooks=[dict(h, command=h["command"].replace("@ROOT@", root)) for h in e["hooks"]])
        if not any(h["command"] in have for h in e["hooks"]):
            cur.append(e); added += 1
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path)); os.close(fd)
with open(tmp, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False); f.write("\n")
os.chmod(tmp, os.stat(path).st_mode & 0o777); os.replace(tmp, path)
print(f"added {added} setting(s)")
PY
