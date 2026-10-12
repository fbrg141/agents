# agents

A minimal [Claude Code](https://claude.com/claude-code) setup: global
instructions, five skills, one safety hook, and `pi-ask`, a script that asks
other models (through [pi](https://github.com/badlogic/pi-mono)) for
read-only second opinions.

## The workflow

| Step | Command | What happens |
|---|---|---|
| 1 | `/grill` | Claude interviews you until every decision for the task is settled, looking up facts itself. Writes `grill.md` into a new task folder. |
| 2 | `/to-goal` | Claude writes `spec.md` with machine-checkable acceptance commands. Three pi models critique it in parallel; Claude synthesizes, revises, and stops for your approval. This is the only human gate. |
| 3 | `/goal ...` | Built into Claude Code. `/to-goal` prints the exact line: Claude works until the spec's acceptance commands pass. |
| 4 | `/go` | Re-runs the acceptance commands, runs `/simplify`, has three pi models review the diff against the spec (stops if the diff is empty), fixes small findings, has one pi model review the fixes, and writes `report.md`. You commit. |

Small tasks skip steps 1-2. Task folders live outside your project repos, in
`~/.claude/specs/<project>/<date>-<slug>/` (`grill.md`, `spec.md`,
`reviews/`, `diff.patch`, `report.md`).

Other skills:
- `/pi [models][+web]: question` asks pi models directly, e.g.
  `/pi kimi,glm: is this migration safe?` or `/pi deepseek+web: latest Node LTS?`.
  Claude also uses it when you say "ask glm" or "get a second opinion".
- `debug` is a diagnosis loop for hard bugs; Claude picks it up when you
  report something broken or say "debug this".

**Privacy:** `/to-goal`, `/go`, and `/pi` send specs, diffs, and file
contents to the hosted models configured in pi (by default via
ollama-cloud). Do not use them on code you may not share with that provider.

## Requirements
- Claude Code (skills, hooks, `/goal`, `/simplify`).
- Node 22 or newer, bash, jq.
- For `pi-ask` and the workflow's reviews: pi with the `pi-ollama-cloud`
  package and an ollama-cloud account. See [docs/pi-setup.md](docs/pi-setup.md).
  Without pi, `grill`, `debug`, and the hook still work.

## Install
```bash
git clone <this repo> && cd agents
scripts/install.sh
```
`install.sh` links `global/CLAUDE.md` to `~/.claude/CLAUDE.md` and each
`skills/<name>` to `~/.claude/skills/<name>`, removes stale links into this
repo, and adds the `no-skip-tests` hook to `~/.claude/settings.json` (other
settings are untouched). It never replaces a real file: it prints `SKIP`
and the path, so move your own `~/.claude/CLAUDE.md` away first if you
have one. Re-running is safe. It does not touch `~/.pi/`.

Try it in a sandbox first:
```bash
HOME="$(mktemp -d)" scripts/install.sh
```

Because the files are links, `git pull` updates your setup; re-run
`install.sh` when skills are added or removed.

## The hook
`hooks/no-skip-tests` runs before `Edit`, `Write`, `MultiEdit`, and
`NotebookEdit`. When an edit to a test file adds a skip marker (`.skip(`,
`xit(`, `@pytest.mark.skip`, `t.Skip(`, `#[ignore]`, `@Disabled`, ...), Claude
Code asks you before applying it. It also asks before an edit to the active
approved `spec.md` or to a git-tracked file its acceptance commands run
(files they only read, and untracked files, stay editable). A spec stops
being active once its task folder has a `report.md`.

## Review standards per project
Copy [templates/REVIEW.md](templates/REVIEW.md) to the root of a project as
`REVIEW.md` and edit it. `/go` passes it to the reviewing models, which
check the diff against it. Without it, reviewers report only obvious defects.

## pi-ask
```bash
scripts/pi-ask "question"                       # default model (glm)
scripts/pi-ask --models kimi,glm,mistral "..."  # in parallel
scripts/pi-ask --role research "..."            # deepseek with web search
scripts/pi-ask --help
```
Models get read-only tools only (`read`, `grep`, `find`, `ls`, plus web
search/fetch with `--web`). Aliases and role presets are in
`scripts/pi-ask.models.json`; override them in
`~/.config/pi-ask/models.json` (see [docs/pi-setup.md](docs/pi-setup.md)).

## Checks
```bash
scripts/check.sh          # offline: skills, hook fixtures, sandbox install, pi-ask dry runs
scripts/check.sh --live   # calls pi models
```

## Uninstall
Remove the links (only those pointing into this repo) and the hook entry:
```bash
REPO="$(pwd -P)"
for l in ~/.claude/CLAUDE.md ~/.claude/skills/*; do
  [ -L "$l" ] && case "$(readlink "$l")" in "$REPO"/*) rm "$l";; esac
done
jq --arg cmd "$REPO/hooks/no-skip-tests" \
  'if .hooks.PreToolUse then .hooks.PreToolUse |= map(select(([.hooks[]?.command] | index($cmd)) == null)) else . end' \
  ~/.claude/settings.json > ~/.claude/settings.json.new \
  && mv ~/.claude/settings.json.new ~/.claude/settings.json
```
Run it from the repo root. Task folders in `~/.claude/specs/` are left in place.
