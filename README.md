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

Third-party skills (e.g. orca-cli, orchestration) live in `~/.agents/skills/`
as real directories managed by their own installers — they are NOT versioned
here.
