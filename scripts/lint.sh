#!/bin/sh
# Repo-only checks, safe for CI (never reads $HOME): script syntax, JSON,
# skill/agent frontmatter, builtin-name collisions, guard policy tests.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
rc=0
bad() { echo "FAIL  $*" >&2; rc=1; }
ok()  { echo "ok    $*"; }

for f in "$root"/install.sh "$root"/scripts/*.sh; do
  if sh -n "$f"; then ok "syntax ${f#"$root"/}"; else bad "syntax ${f#"$root"/}"; fi
done
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -x "$root"/install.sh "$root"/scripts/*.sh; then ok "shellcheck"; else bad "shellcheck"; fi
else
  echo "skip  shellcheck not installed"
fi

python3 - "$root" <<'PY' || rc=1
import glob, json, os, re, sys
root = sys.argv[1]
rc = 0
def bad(m):
    global rc; print(f"FAIL  {m}", file=sys.stderr); rc = 1
def ok(m): print(f"ok    {m}")
rel = lambda p: os.path.relpath(p, root)

def frontmatter(path):
    text = open(path, encoding="utf-8").read()
    end = text.find("\n---", 4)
    if not text.startswith("---\n") or end < 0: return None
    fm, key = {}, None
    for line in text[4:end].splitlines():
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            fm[key] = "" if val in (">", "|", ">-", "|-") else val
        elif key and line[:1] in (" ", "\t"):
            fm[key] = (fm[key] + " " + line.strip()).strip()
    return fm

for p in sorted(glob.glob(f"{root}/**/*.json", recursive=True)):
    try: json.load(open(p)); ok(f"json {rel(p)}")
    except ValueError as e: bad(f"json {rel(p)}: {e}")

# Agent Skills spec: kebab-case name == folder, <= 64 chars; description <= 1024.
skills = {}
for harness, dirs in {"claude": ["shared", "claude"], "pi": ["shared", "pi"]}.items():
    names = skills[harness] = set()
    for d in dirs:
        for sd in sorted(glob.glob(f"{root}/{d}/skills/*/")):
            name = os.path.basename(sd.rstrip("/"))
            if name in names: bad(f"{harness}: skill '{name}' defined twice")
            names.add(name)
for sd in sorted(glob.glob(f"{root}/*/skills/*/")):
    f = os.path.join(sd, "SKILL.md")
    fm = frontmatter(f) if os.path.isfile(f) else None
    if fm is None: bad(f"{rel(sd)}: missing SKILL.md or frontmatter"); continue
    name, desc, folder = fm.get("name", ""), fm.get("description", ""), os.path.basename(sd.rstrip("/"))
    errs = []
    if name != folder: errs.append(f"name '{name}' != folder '{folder}'")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64: errs.append("name not kebab-case <= 64")
    if not desc or len(desc) > 1024: errs.append(f"description length {len(desc)} not in 1..1024")
    for e in errs: bad(f"{rel(f)}: {e}")
    if not errs: ok(f"skill {rel(f)}")

# Agents: required fields, no builtin shadowing, preloaded skills exist.
builtin = {
    "claude": re.compile(r"(Explore|Plan|general-purpose|claude|claude-code-guide|statusline-setup)"),
    "pi": re.compile(r"(scout|researcher|evidence-auditor|worker|reviewer|oracle|delegate|claude-code.*|codex-exec.*|cursor-agent.*)"),
}
for harness in ("claude", "pi"):
    for f in sorted(glob.glob(f"{root}/{harness}/agents/*.md")):
        fm = frontmatter(f) or {}
        name = fm.get("name", "")
        errs = [f"missing {k}" for k in ("name", "description") if not fm.get(k)]
        if builtin[harness].fullmatch(name): errs.append(f"name '{name}' shadows a {harness} builtin")
        for s in re.findall(r"[a-z0-9][a-z0-9-]*", fm.get("skills", "")):
            if s not in skills[harness]: errs.append(f"preloads unknown skill '{s}'")
        for e in errs: bad(f"{rel(f)}: {e}")
        if not errs: ok(f"agent {rel(f)}")
sys.exit(rc)
PY

if out="$(node --test "$root/shared/guard/*.test.ts" 2>&1)"; then
  ok "guard policy tests ($(printf '%s\n' "$out" | awk '/^ℹ pass/{print $3}') passed)"
else
  printf '%s\n' "$out" >&2; bad "guard policy tests"
fi
exit $rc
