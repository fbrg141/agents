#!/usr/bin/env bash
# Acceptance checks. Run from the repo root.
#   scripts/check.sh          network-free checks (criterion 1, items a-k)
#   scripts/check.sh --live   checks that call pi (criteria 2-7)
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
PI_ASK=scripts/pi-ask
FAILED=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Ignore the user's own pi-ask override; checks assume the built-in config.
export XDG_CONFIG_HOME="$TMP/no-user-config"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1${2:+: $2}"; FAILED=1; }
now_ms() { node -e 'process.stdout.write(String(Date.now()))'; }
# fm KEY FILE: value of a frontmatter key.
fm() { awk -v k="$1" 'NR>1 && /^---$/ {exit} NR>1 && index($0, k":") == 1 {sub("^" k ":[ ]*", ""); print}' "$2"; }

# ---------------------------------------------------------------- offline

check_a() {
  local ok=1 file dir name desc
  for file in skills/*/SKILL.md; do
    dir="$(basename "$(dirname "$file")")"
    if [[ "$(head -1 "$file")" != "---" ]]; then
      fail "1a $file" "no frontmatter"; ok=0; continue
    fi
    name="$(fm name "$file")"
    desc="$(fm description "$file")"
    [[ "$name" == "$dir" ]] || { fail "1a $file" "name '$name' != folder '$dir'"; ok=0; }
    [[ -n "$desc" ]] || { fail "1a $file" "empty description"; ok=0; }
    if [[ "$desc" != [\"\']* && ( "$desc" == *": "* || "$desc" == *" #"* ) ]]; then
      fail "1a $file" "unquoted description contains ': ' or ' #' (invalid YAML)"; ok=0
    fi
    (( ${#desc} <= 1536 )) || { fail "1a $file" "description has ${#desc} chars"; ok=0; }
  done
  (( ok )) && pass "1a skill frontmatter"
}

check_b() {
  local g d
  g="$(wc -l < global/CLAUDE.md | tr -d ' ')"
  d="$(wc -l < skills/debug/SKILL.md | tr -d ' ')"
  if (( g <= 60 && d <= 80 )); then
    pass "1b line limits (global/CLAUDE.md $g, debug $d)"
  else
    fail "1b line limits" "global/CLAUDE.md $g (max 60), debug $d (max 80)"
  fi
}

check_c() {
  local ok=1 f
  for f in scripts/pi-ask hooks/no-skip-tests; do
    node --check "$f" 2>"$TMP/err" || { fail "1c node --check $f" "$(cat "$TMP/err")"; ok=0; }
    [[ -x "$f" ]] || { fail "1c $f" "not executable"; ok=0; }
  done
  while IFS= read -r f; do
    bash -n "$f" 2>"$TMP/err" || { fail "1c bash -n $f" "$(cat "$TMP/err")"; ok=0; }
  done < <(git ls-files --cached --others --exclude-standard '*.sh')
  (( ok )) && pass "1c syntax and exec bits"
}

check_d() {
  TMP="$TMP" node - <<'EOF' || FAILED=1
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const dir = 'hooks/fixtures';
const hook = path.resolve('hooks/no-skip-tests');
const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort();
const need = ['ask-edit-it-skip', 'ask-edit-pytest-skip', 'ask-multiedit-xit', 'ask-write-new-skip',
  'none-edit-non-test', 'none-edit-no-marker', 'none-edit-marker-already-present',
  'ask-edit-approved-spec', 'ask-edit-tracked-acceptance', 'none-edit-untracked-acceptance',
  'none-edit-draft-spec', 'none-edit-inspected-file', 'none-edit-finished-task'];
let ok = true;
for (const n of need) if (!files.includes(`${n}.json`)) { console.log(`FAIL 1d missing fixture ${n}.json`); ok = false; }

// Sandbox: HOME with specs, repo "proj" (approved spec), repo "draft" (draft spec).
const sb = fs.mkdtempSync(path.join(process.env.TMP, 'hook.'));
const home = path.join(sb, 'home');
const write = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };
const git = (cwd, ...args) => {
  const r = spawnSync('git', ['-c', 'user.name=check', '-c', 'user.email=check@example.invalid', ...args],
    { cwd, encoding: 'utf8', env: { ...process.env, HOME: home } });
  if (r.status !== 0) { console.log(`FAIL 1d sandbox git ${args.join(' ')}: ${r.stderr}`); process.exit(1); }
};
const spec = (status) => `# Spec: x\n\nStatus: ${status}\n\n## Acceptance commands\n` +
  'Run from the repo root.\n```bash\nbash scripts/accept.sh && node scripts/new-check.sh\n' +
  'grep -q ok src/inspected.txt\n```\n\n## Stop conditions\n- x\n';
const repos = { REPO: path.join(sb, 'proj'), DRAFT: path.join(sb, 'draft'), DONE: path.join(sb, 'done') };
for (const r of Object.values(repos)) {
  write(path.join(r, 'scripts/accept.sh'), 'exit 1\n');
  write(path.join(r, 'src/inspected.txt'), 'ok\n');
  git(r, 'init', '-q');
  git(r, 'add', '.');
  git(r, 'commit', '-q', '-m', 'init');
  write(path.join(r, 'scripts/new-check.sh'), 'exit 1\n');
}
write(path.join(home, '.claude/specs/proj/2026-01-02-x/spec.md'), spec('APPROVED (2026-01-02)'));
write(path.join(home, '.claude/specs/draft/2026-01-03-y/spec.md'), spec('DRAFT (not approved)'));
write(path.join(home, '.claude/specs/done/2026-01-04-z/spec.md'), spec('APPROVED (2026-01-04)'));
write(path.join(home, '.claude/specs/done/2026-01-04-z/report.md'), '# Report\n');
const subst = { ...repos, HOME: home };
const fill = (s) => s.replace(/@(REPO|DRAFT|DONE|HOME)@/g, (_, k) => JSON.stringify(subst[k]).slice(1, -1));

let total = 0;
for (const f of files) {
  const input = fill(fs.readFileSync(`${dir}/${f}`, 'utf8'));
  const t0 = process.hrtime.bigint();
  const res = spawnSync(hook, { input, encoding: 'utf8', cwd: repos.REPO, env: { ...process.env, HOME: home } });
  total += Number(process.hrtime.bigint() - t0) / 1e6;
  const out = res.stdout.trim();
  if (res.status !== 0) { console.log(`FAIL 1d ${f}: exit ${res.status}`); ok = false; continue; }
  if (f.startsWith('ask-')) {
    let d;
    try { d = JSON.parse(out).hookSpecificOutput; } catch { d = null; }
    if (!d || d.permissionDecision !== 'ask' || d.hookEventName !== 'PreToolUse') {
      console.log(`FAIL 1d ${f}: expected ask, got ${JSON.stringify(out)}`); ok = false;
    } else if (f.includes('spec') !== /rule: approved spec/.test(d.permissionDecisionReason)
      || f.includes('acceptance') !== /rule: acceptance file/.test(d.permissionDecisionReason)) {
      console.log(`FAIL 1d ${f}: wrong rule in reason ${JSON.stringify(d.permissionDecisionReason)}`); ok = false;
    }
  } else if (out !== '') {
    console.log(`FAIL 1d ${f}: expected no output, got ${JSON.stringify(out)}`); ok = false;
  }
}
const avg = total / files.length;
if (avg >= 200) { console.log(`FAIL 1d hook average ${avg.toFixed(1)} ms (max 200)`); ok = false; }
if (ok) console.log(`PASS 1d hook fixtures (${files.length}, avg ${avg.toFixed(1)} ms)`);
process.exit(ok ? 0 : 1);
EOF
}

check_e() {
  local sandbox ok=1 name count hook matcher
  sandbox="$(mktemp -d "$TMP/home.XXXXXX")"
  hook="$(pwd -P)/hooks/no-skip-tests"
  if ! HOME="$sandbox" scripts/install.sh >"$TMP/install1" 2>&1; then
    fail "1e install" "$(cat "$TMP/install1")"; return
  fi
  [[ -L "$sandbox/.claude/CLAUDE.md" && -e "$sandbox/.claude/CLAUDE.md" ]] \
    || { fail "1e link" "~/.claude/CLAUDE.md"; ok=0; }
  for dir in skills/*/; do
    name="$(basename "$dir")"
    [[ -L "$sandbox/.claude/skills/$name" && -e "$sandbox/.claude/skills/$name/SKILL.md" ]] \
      || { fail "1e link" "~/.claude/skills/$name"; ok=0; }
  done
  count="$(jq --arg cmd "$hook" '[.hooks.PreToolUse[]?.hooks[]? | select(.command == $cmd)] | length' \
    "$sandbox/.claude/settings.json" 2>/dev/null)"
  [[ "$count" == "1" ]] || { fail "1e hook entry" "found ${count:-none}, expected 1"; ok=0; }
  matcher="$(jq -r --arg cmd "$hook" '.hooks.PreToolUse[] | select(any(.hooks[]; .command == $cmd)) | .matcher' \
    "$sandbox/.claude/settings.json" 2>/dev/null)"
  [[ "$matcher" == "Edit|Write|MultiEdit|NotebookEdit" ]] || { fail "1e hook matcher" "got '$matcher'"; ok=0; }
  cp "$sandbox/.claude/settings.json" "$TMP/settings.first"
  if ! HOME="$sandbox" scripts/install.sh >"$TMP/install2" 2>&1; then
    fail "1e second install" "$(cat "$TMP/install2")"; return
  fi
  cmp -s "$TMP/settings.first" "$sandbox/.claude/settings.json" \
    || { fail "1e idempotence" "settings.json changed on second run"; ok=0; }
  (( ok )) && pass "1e sandbox install"
}

check_f() {
  local bad
  bad="$(git ls-files --cached --others --exclude-standard | grep -vxE \
'\.gitignore|README\.md|CLAUDE\.md|global/CLAUDE\.md|skills/(grill|to-goal|go|pi|debug)/SKILL\.md|templates/(spec|REVIEW)\.md|templates/prompts/(oracle|review)\.md|hooks/no-skip-tests|hooks/fixtures/.+|scripts/(pi-ask|pi-ask\.models\.json|install\.sh|check\.sh)|docs/pi-setup\.md')"
  if [[ -z "$bad" ]]; then pass "1f only Layout paths"; else fail "1f paths outside Layout" "$(echo $bad)"; fi
}

check_g() {
  # The pattern is assembled at runtime so this file contains no literal match
  # and the criterion holds for every file, this one included.
  local pattern hits
  pattern="/Us""ers/|/ho""me/"
  hits="$(git grep --untracked -nE "$pattern")"
  if [[ -z "$hits" ]]; then pass "1g no home-directory paths"; else fail "1g home-directory paths" "$hits"; fi
}

check_h() {
  node - <<'EOF' || FAILED=1
const fs = require('fs');
let c;
try { c = JSON.parse(fs.readFileSync('scripts/pi-ask.models.json', 'utf8')); }
catch (e) { console.log(`FAIL 1h invalid JSON: ${e.message}`); process.exit(1); }
const bad = [];
for (const [role, r] of Object.entries(c.roles || {})) {
  for (const m of r.models || []) if (!(c.aliases || {})[m]) bad.push(`${role}:${m}`);
}
if (!(c.aliases || {})[c.default]) bad.push(`default:${c.default}`);
if (bad.length) { console.log(`FAIL 1h undefined aliases: ${bad.join(', ')}`); process.exit(1); }
console.log('PASS 1h models config');
EOF
}

check_i() {
  "$PI_ASK" --dry-run "x" > "$TMP/i.default" 2>&1 || { fail "1i default dry-run" "$(cat "$TMP/i.default")"; return; }
  "$PI_ASK" --dry-run --role oracle "x" > "$TMP/i.oracle" 2>&1 || { fail "1i oracle dry-run" "$(cat "$TMP/i.oracle")"; return; }
  "$PI_ASK" --dry-run --web "x" > "$TMP/i.web" 2>&1 || { fail "1i web dry-run" "$(cat "$TMP/i.web")"; return; }
  "$PI_ASK" --dry-run --role research "x" > "$TMP/i.research" 2>&1 || { fail "1i research dry-run" "$(cat "$TMP/i.research")"; return; }
  TMP="$TMP" node - <<'EOF' || FAILED=1
const fs = require('fs');
const read = (n) => fs.readFileSync(`${process.env.TMP}/i.${n}`, 'utf8').trim().split('\n').map((l) => JSON.parse(l));
const errs = [];
const tools = (argv) => argv[argv.indexOf('--tools') + 1].split(',');
const thinking = (argv) => (argv.includes('--thinking') ? argv[argv.indexOf('--thinking') + 1] : null);
const def = read('default');
if (def.length !== 1 || def[0].alias !== 'glm' || !def[0].argv.includes('ollama-cloud/glm-5.3')) errs.push('default call is not glm');
const oracle = read('oracle');
const by = Object.fromEntries(oracle.map((l) => [l.alias, l.argv]));
if (oracle.map((l) => l.alias).join(',') !== 'kimi,glm,mistral') errs.push('oracle models are not kimi,glm,mistral');
if (by.mistral && thinking(by.mistral) !== null) errs.push('mistral has --thinking');
if (by.kimi && thinking(by.kimi) !== 'xhigh') errs.push('kimi thinking is not xhigh');
const web = read('web');
for (const t of ['ollama_web_search', 'ollama_web_fetch']) if (!tools(web[0].argv).includes(t)) errs.push(`--web lacks ${t}`);
const all = [...def, ...oracle, ...web, ...read('research')];
for (const l of all) {
  const t = tools(l.argv);
  for (const bad of ['bash', 'edit', 'write']) if (t.includes(bad)) errs.push(`${l.alias} gets tool ${bad}`);
  if (!l.argv.includes('-p') || !l.argv.includes('--no-session')) errs.push(`${l.alias} argv lacks -p or --no-session`);
}
if (errs.length) { console.log(`FAIL 1i dry-run: ${errs.join('; ')}`); process.exit(1); }
console.log('PASS 1i dry-run argv');
EOF
}

check_j() {
  local cfg="$TMP/xdg" ok=1 out
  mkdir -p "$cfg/pi-ask"
  echo '{"default":"foo","aliases":{"foo":{"model":"foo-model-1","thinking":null}}}' > "$cfg/pi-ask/models.json"
  out="$(XDG_CONFIG_HOME="$cfg" "$PI_ASK" --dry-run "x" 2>&1)"
  [[ "$out" == *'"model":"foo-model-1"'* && "$out" == *'ollama-cloud/foo-model-1'* ]] \
    || { fail "1j override default" "$out"; ok=0; }
  out="$(XDG_CONFIG_HOME="$cfg" "$PI_ASK" --dry-run --models kimi,glm,mistral,deepseek,flash "x" 2>&1)" \
    || { fail "1j built-in aliases after override" "$out"; ok=0; }
  echo '{ not json' > "$cfg/pi-ask/models.json"
  XDG_CONFIG_HOME="$cfg" "$PI_ASK" --dry-run "x" >"$TMP/j.out" 2>&1
  local code=$?
  [[ $code == 2 ]] || { fail "1j invalid user JSON" "exit $code, expected 2"; ok=0; }
  grep -q "$cfg/pi-ask/models.json" "$TMP/j.out" || { fail "1j invalid user JSON" "error does not name the file"; ok=0; }
  (( ok )) && pass "1j user config override"
}

check_k() {
  local ok=1 code
  "$PI_ASK" --dry-run --thinking ultra "x" >/dev/null 2>&1; code=$?
  [[ $code == 2 ]] || { fail "1k unknown thinking level" "exit $code"; ok=0; }
  "$PI_ASK" --dry-run --prompt-file "$TMP/no-such-file.md" "x" >/dev/null 2>&1; code=$?
  [[ $code == 2 ]] || { fail "1k missing --prompt-file" "exit $code"; ok=0; }
  "$PI_ASK" --models nosuchmodel --dry-run "x" >/dev/null 2>&1; code=$?
  [[ $code == 2 ]] || { fail "1k unknown model" "exit $code"; ok=0; }
  (( ok )) && pass "1k usage errors exit 2"
}

# ------------------------------------------------------------------- live

live_2() {
  local out
  out="$("$PI_ASK" "Reply with exactly: OK" 2>&1)" || { fail "2 default call" "$out"; return; }
  if [[ "$(head -1 <<<"$out")" == "## glm ("* ]] && tail -n +2 <<<"$out" | grep -q 'OK'; then
    pass "2 default call answers OK under ## glm"
  else
    fail "2 default call" "$out"
  fi
}

live_3() {
  local out
  out="$("$PI_ASK" --models kimi,glm,mistral "Reply with exactly: OK" 2>&1)" || { fail "3 three models" "$out"; return; }
  if OUT="$out" node -e '
    const parts = process.env.OUT.split(/^## /m).filter(Boolean);
    const ok = parts.length === 3 && ["kimi", "glm", "mistral"].every((a, i) =>
      parts[i].startsWith(a + " (") && parts[i].split("\n").slice(1).join("\n").includes("OK"));
    process.exit(ok ? 0 : 1);'; then
    pass "3 kimi, glm, mistral sections in order with OK"
  else
    fail "3 three models" "$out"
  fi
}

live_4() {
  local out code ok=1 a
  out="$("$PI_ASK" --models nosuchmodel "x" 2>&1)"; code=$?
  [[ $code == 2 ]] || { fail "4 unknown model" "exit $code: $out"; return; }
  for a in kimi glm mistral deepseek flash; do
    grep -q "^ *$a = " <<<"$out" || ok=0
  done
  if (( ok )); then pass "4 unknown model exits 2 and lists aliases"; else fail "4 alias list" "$out"; fi
}

live_5() {
  local out code probe=/tmp/pi-ask-probe.txt
  rm -f "$probe"
  if [[ -e "$probe" ]]; then fail "5 read-only" "cannot delete $probe first"; return; fi
  out="$("$PI_ASK" "Create the file $probe with any content." 2>&1)"; code=$?
  if [[ $code == 0 && ! -e "$probe" ]]; then
    pass "5 read-only: probe file not created"
  else
    fail "5 read-only" "exit $code, file exists: $([[ -e $probe ]] && echo yes || echo no)"
    rm -f "$probe"
  fi
}

live_6() {
  local out code t0 t1
  t0="$(now_ms)"
  out="$("$PI_ASK" --models glm --timeout 1 "Write a 2000-word essay." 2>&1)"; code=$?
  t1="$(now_ms)"
  local ms=$((t1 - t0))
  if [[ $code == 1 ]] && (( ms < 5000 )) && [[ "$out" == "## glm ("* ]] && grep -qi 'timed out' <<<"$out"; then
    pass "6 timeout exits 1 in ${ms} ms and reports it"
  else
    fail "6 timeout" "exit $code after ${ms} ms: $out"
  fi
}

live_7() {
  local out
  out="$("$PI_ASK" --role research "What is the latest stable Node.js major version? Put the source URL alone on the last line." 2>&1)" \
    || { fail "7 research" "$out"; return; }
  if grep -qE 'https?://' <<<"$out"; then pass "7 research answer cites a URL"; else fail "7 research" "$out"; fi
}

case "${1:-}" in
  "")
    check_a; check_b; check_c; check_d; check_e; check_f
    check_g; check_h; check_i; check_j; check_k
    ;;
  --live)
    command -v pi >/dev/null || { echo "FAIL pi is not on PATH; see docs/pi-setup.md"; exit 1; }
    live_2; live_3; live_4; live_5; live_6; live_7
    ;;
  *)
    echo "usage: scripts/check.sh [--live]" >&2; exit 2
    ;;
esac

if (( FAILED )); then echo "check.sh: FAILED"; exit 1; fi
echo "check.sh: all passed"
