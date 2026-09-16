# agents

Personal pi/agent configuration repo. Single source of truth for global
agent behavior; the live config is symlinks into this repo.

## Layout

- `APPEND_SYSTEM.md` -> `~/.pi/agent/APPEND_SYSTEM.md` (appended to pi's
  system prompt: philosophy, task mode, tooling, git/safety boundaries)
- `skills/` - agent skills; symlinked into `~/.pi/agent/skills/` (pi-only,
  e.g. `protocol`) and `~/.agents/skills/` (shared cross-agent skills)

## Working in this repo

Edit files here, never in `~/.pi/agent/` or `~/.agents/skills/` -- those
are symlinks, and editing through them works, but this repo is the truth
and gets pushed to GitHub.

Keep `APPEND_SYSTEM.md` small; it loads on every pi request. Detail that
only matters for one kind of task belongs in a skill under `skills/`
(progressive disclosure), not in the always-loaded system prompt.

New skill: create `skills/<name>/SKILL.md` with frontmatter (name,
description), then symlink it into the right global dir.

## Not versioned here (yet)

`~/.pi/agent/settings.json`, `models.json`, and the Orca-managed
extensions under `~/.pi/agent/extensions/`.
