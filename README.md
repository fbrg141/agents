# agents

Personal agent configuration for two harnesses — **pi** (Ollama models) and
**Claude Code** — in one repo. Live config is symlinks into this repo; edit
here, never through `~/.pi/agent/` or `~/.claude/`.

## Layout

```
shared/CORE.md             rules both harnesses load (honesty, ask-vs-proceed, boundaries, git)
pi/                        pi harness
  APPEND_SYSTEM.md         pi-only: task mode, tooling (loads every request; keep small)
  settings.json            models, subagent tiering, watchdog
  skills/                  code-review, debug, protocol, para-procedure
  agents/                  axis-reviewer, debugger   (new names only; never shadow builtins)
  extensions/guard.ts      blocks force-push/--no-verify/.env, confirms git commit/push
claude/                    Claude Code harness
  CLAUDE.md                global instructions (@-imports shared/CORE.md)
  skills/                  review-axes, debug, protocol, para-procedure
  agents/                  scout, oracle, reviewer, worker, researcher
  settings.permissions.json  ask/deny rules merged into ~/.claude/settings.json
install.sh [pi|claude|all]   symlink everything into the live config
scripts/check.sh             fail if shared skills drift between pi/ and claude/
scripts/doctor.sh            verify live links, JSON, agent-name collisions, drift
scripts/merge-claude-permissions.sh   union the permission rules (backs up first)
```

## Harness differences

- Subagent support differs, so `para-procedure` is written per harness. `debug`,
  `protocol` and the review skill are copies; `check.sh` enforces they stay
  identical (frontmatter ignored). Claude's review skill is `review-axes`
  because Claude Code ships a built-in `code-review`.
- pi agents use pi-subagents roles; models come from `pi/settings.json`
  (`agentOverrides`): scout/researcher on deepseek flash, worker/delegate/
  reviewer/axis-reviewer/debugger on glm-5.3 high, oracle on kimi-k3 xhigh.
  The pi watchdog (kimi-k3 high) reviews edit turns. Needs an ollama-cloud
  account with access to those models.
- Claude agents mirror the pi role names with Claude tiers: scout=haiku,
  worker/reviewer/researcher=sonnet, oracle=opus.
- **Never shadow an existing agent.** In pi, a user agent with a builtin's name
  replaces it wholesale. `install.sh` and `doctor.sh` refuse this.

## Workflow

- Edit a shared skill in `pi/skills/` and mirror it into `claude/skills/`,
  then run `scripts/check.sh`.
- After any change: `scripts/doctor.sh`.
- New machine: `./install.sh all` then `scripts/merge-claude-permissions.sh`.
  `install.sh` moves an existing `~/.claude/CLAUDE.md` to `CLAUDE.md.bak` once.
- `~/.claude/settings.json` is NOT symlinked (Orca manages hooks in it); only
  the permission rules are merged. `.env*` read/edit denies also block
  `.env.example`.

## Not versioned here

Third-party skills (orca-cli, orchestration, find-skills) live in
`~/.agents/skills/`, managed by their own installers. Also not versioned:
`~/.pi/agent/models.json` (machine-specific), Orca-managed pi extensions
(`orca-*.ts`), and Orca's hooks inside `~/.claude/settings.json`.
