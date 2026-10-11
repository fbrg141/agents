# agents

Personal agent configuration for two harnesses — **pi** (Ollama models) and
**Claude Code** — in one repo. Live config is symlinks into this repo; edit
here, never through `~/.pi/agent/` or `~/.claude/`. The repo must live at
`~/code/agents`: `claude/CLAUDE.md`, `pi/settings.json` and the Claude guard
hook reference that path (`doctor.sh` checks it).

## Layout

```
shared/                    loaded by both harnesses
  CORE.md                  rules: honesty, ask-vs-proceed, testing, safety, git, format
  skills/                  debug, protocol, review-axes (one copy, linked into both)
  guard/policy.ts          git/secret guard policy + policy.test.ts
pi/                        pi harness
  APPEND_SYSTEM.md         pi-only: task mode, tooling (loads every request; keep small)
  settings.json            models, subagent tiering, watchdog, guard extension
  skills/                  para-procedure
  agents/                  axis-reviewer, debugger   (new names only; never shadow builtins)
  extensions/guard.ts      pi adapter for the guard policy (loaded by path, not linked)
claude/                    Claude Code harness
  CLAUDE.md                global instructions (@-imports shared/CORE.md)
  skills/                  para-procedure
  agents/                  scout, oracle, reviewer, worker, researcher
  hooks/guard.ts           PreToolUse adapter for the guard policy
  settings.merge.json      permissions + hook merged into ~/.claude/settings.json
install.sh [pi|claude|all]   symlink everything; prune stale links into this repo
scripts/lib.sh               targets(): the one list of owned links (install + doctor)
scripts/lint.sh              repo-only checks (CI): syntax, JSON, frontmatter, guard tests
scripts/doctor.sh            live-config checks on this machine, then lint.sh
scripts/merge-claude-settings.sh   union permissions + hook into ~/.claude/settings.json
```

## Harness differences

- Shared skills exist once in `shared/skills/` and are linked into both
  harnesses. `para-procedure` is written per harness because subagent support
  differs. The review skill is `review-axes` because Claude Code ships a
  built-in `code-review`.
- The guard policy (`shared/guard/policy.ts`) runs in both: pi loads
  `pi/extensions/guard.ts` via `extensions` and, for subagents running in the
  foreground (which skip ambient extensions),
  `subagents.defaultSubagentOnlyExtensions`. Claude runs `claude/hooks/guard.ts`
  as a PreToolUse hook, which also fires inside subagents. The Claude deny rules
  stay as a backstop.
- pi agents use pi-subagents roles; models come from `pi/settings.json`
  (`agentOverrides`): scout/researcher on deepseek flash, worker/delegate/
  reviewer/axis-reviewer/debugger on glm-5.3 high, oracle on kimi-k3 xhigh.
  Writers and the custom agents set `inheritGlobalContext` so CORE.md reaches
  them. The pi watchdog (kimi-k3 high) reviews edit turns. Needs an
  ollama-cloud account with access to those models.
- Claude agents mirror the pi role names with Claude tiers: scout=haiku,
  worker/reviewer/researcher=sonnet, oracle=opus.
- **Never shadow an existing agent.** In pi, a user agent with a builtin's name
  replaces it wholesale. `install.sh`, `lint.sh` and `doctor.sh` refuse this.

## Workflow

- After any change: `scripts/doctor.sh` (runs `scripts/lint.sh`). CI runs
  `lint.sh` on every push and PR.
- New or renamed skill/agent: `./install.sh <harness>`; it links new targets
  and prunes links to removed ones.
- New machine: `./install.sh all` then `scripts/merge-claude-settings.sh`.
  `install.sh` moves an existing `~/.claude/CLAUDE.md` to `CLAUDE.md.bak` once.
- `~/.claude/settings.json` is NOT symlinked (Claude Code and plugins write
  machine state into it); only our permission rules and guard hook are merged,
  matched by value, so re-runs are no-ops. `.env*` read/edit denies also block `.env.example`.
- pi rewrites `pi/settings.json` (e.g. `lastChangelogVersion`, `/model`
  scoping); review and commit those changes like any other.

## Not versioned here

Third-party skills and plugins are managed by their own installers (e.g.
Claude marketplace plugins, pi npm packages); `install.sh` and `doctor.sh`
only warn about broken links they don't own. Also not versioned:
`~/.pi/agent/models.json` (machine-specific) and everything else in
`~/.claude/settings.json` besides the merged rules and hook.
