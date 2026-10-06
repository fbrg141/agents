#!/bin/sh
# Union claude/settings.permissions.json into ~/.claude/settings.json.
# Backs up once to settings.json.pre-agents-repo; touches only permissions.ask/deny.
# Never symlink settings.json: Orca manages hooks inside it.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
live="$HOME/.claude/settings.json"
[ -f "$live" ] || { echo "no $live" >&2; exit 1; }
[ -e "$live.pre-agents-repo" ] || cp -p "$live" "$live.pre-agents-repo"
python3 - "$root/claude/settings.permissions.json" "$live" <<'PY'
import json, os, sys, tempfile
want = json.load(open(sys.argv[1]))["permissions"]
path = sys.argv[2]
cfg = json.load(open(path))
perm = cfg.setdefault("permissions", {})
added = 0
for kind, rules in want.items():
    cur = perm.setdefault(kind, [])
    for r in rules:
        if r not in cur:
            cur.append(r); added += 1
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path)); os.close(fd)
with open(tmp, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False); f.write("\n")
os.chmod(tmp, os.stat(path).st_mode & 0o777); os.replace(tmp, path)
print(f"added {added} permission rule(s)")
PY
