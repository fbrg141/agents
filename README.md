# agents

Personal pi/agent configuration repo — single source of truth for global
agent behavior. The live config is symlinks into this repo.

## Layout

- `AGENTS.md` — repo-specific instructions loaded when working in this repo.
- `APPEND_SYSTEM.md` → `~/.pi/agent/APPEND_SYSTEM.md` — appended to pi's
  system prompt: philosophy, task mode, tooling, git/safety boundaries.
  Keep it small; it loads on every pi request.
- `skills/` — ONLY self-authored skills, each symlinked into
  `~/.pi/agent/skills/<name>`:
  - `code-review` — two-axis review (Standards / Spec) of changes since a fixed point
  - `debug` — diagnosis loop discipline for hard bugs and perf regressions
  - `protocol` — full-ceremony manual workflow for high-stakes work (`/skill:protocol`)
  - `para-procedure` — parallel ceremony: scout fanout, oracle-checked plan,
    worker subagents per seam, reviewer fanout before report
- `settings.json` → `~/.pi/agent/settings.json` — live pi settings including
  the subagents model-tiering overrides (scout/researcher on flash,
  worker/delegate/reviewer on glm-5.3 `thinking: high`, oracle on kimi-k3
  `thinking: xhigh`). No secrets inside; tool writes go through the symlink.

Third-party skills (e.g. orca-cli, orchestration) live in `~/.agents/skills/`
as real directories managed by their own installers — they are NOT versioned
here.

## Working in this repo

Edit files here, never through the `~/.pi/agent/` symlinks — this repo is
the truth and gets pushed to GitHub. Third-party skills in
`~/.agents/skills/` are real directories; their updates come from their own
installers, not git.

Keep `APPEND_SYSTEM.md` small; it loads on every pi request. Detail that
only matters for one kind of task belongs in a skill under `skills/`
(progressive disclosure), not in the always-loaded system prompt.

New skill: create `skills/<name>/SKILL.md` with frontmatter (name,
description), then symlink it into `~/.pi/agent/skills/`.

## Not versioned here (yet)

`~/.pi/agent/models.json` (machine-specific local provider) and the
Orca-managed extensions under `~/.pi/agent/extensions/`.