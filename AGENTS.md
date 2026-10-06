# agents

Personal pi + Claude Code configuration repo. Single source of truth; live
config is symlinks into this repo. See README.md for layout and workflow.

## Rules for working here

- Edit files in this repo, never through `~/.pi/agent/` or `~/.claude/`
  symlinks. Third-party skills in `~/.agents/skills/` are not versioned here.
- Only self-authored skills and agents live in this repo.
- Never name a pi agent after a pi-subagents builtin (scout, researcher,
  evidence-auditor, worker, reviewer, oracle, delegate, claude-code*, codex-exec*,
  cursor-agent*): it would replace the builtin. Never name a Claude agent
  Explore/Plan/general-purpose/claude/claude-code-guide/statusline-setup.
- Shared skills (`debug`, `protocol`, pi `code-review` = claude `review-axes`)
  must stay identical except frontmatter: run `scripts/check.sh`.
- Keep `pi/APPEND_SYSTEM.md` small (loads every pi request). Rules common to
  both harnesses go in `shared/CORE.md`; per-task detail goes in a skill.
- New skill: `<harness>/skills/<name>/SKILL.md` with frontmatter, then
  `./install.sh <harness>`. New agent: same under `<harness>/agents/`.
- Run `scripts/doctor.sh` after changes. Do not symlink `~/.claude/settings.json`.
