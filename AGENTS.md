# agents

Personal pi/agent configuration repo. Single source of truth for global
agent behavior; the live config is symlinks into this repo.

## Layout

- `APPEND_SYSTEM.md` -> `~/.pi/agent/APPEND_SYSTEM.md` (appended to pi's
  system prompt: philosophy, task mode, tooling, git/safety boundaries)
- `skills/` - ONLY self-authored skills; each symlinked into
  `~/.pi/agent/skills/<name>`. Third-party skills (e.g. orca-cli,
  orchestration, find-skills) live in `~/.agents/skills/` as real
  directories managed by their own installers -- do NOT copy them
  into this repo.

## Working in this repo

Edit files here, never in `~/.pi/agent/skills/` -- those are symlinks,
and editing through them works, but this repo is the truth and gets
pushed to GitHub. Third-party skills in `~/.agents/skills/` are real
directories; their updates come from their own installers, not git.

Keep `APPEND_SYSTEM.md` small; it loads on every pi request. Detail that
only matters for one kind of task belongs in a skill under `skills/`
(progressive disclosure), not in the always-loaded system prompt.

New skill: create `skills/<name>/SKILL.md` with frontmatter (name,
description), then symlink it into `~/.pi/agent/skills/`.

## Not versioned here (yet)

`~/.pi/agent/settings.json`, `models.json`, and the Orca-managed
extensions under `~/.pi/agent/extensions/`.
