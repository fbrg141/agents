# agents

Personal pi + Claude Code configuration repo. Single source of truth; live
config is symlinks into this repo, which must stay at `~/code/agents`. See
README.md for layout and workflow.

## Rules for working here

- Edit files in this repo, never through `~/.pi/agent/` or `~/.claude/`
  symlinks. Third-party skills and plugins are not versioned here.
- Only self-authored skills and agents live in this repo.
- Never name a pi agent after a pi-subagents builtin (scout, researcher,
  evidence-auditor, worker, reviewer, oracle, delegate, claude-code*, codex-exec*,
  cursor-agent*): it would replace the builtin. Never name a Claude agent
  Explore/Plan/general-purpose/claude/claude-code-guide/statusline-setup.
- Skills used by both harnesses live once in `shared/skills/`; never copy one
  into `pi/` or `claude/`. Only harness-specific skills go there.
- Keep `pi/APPEND_SYSTEM.md` small (loads every pi request). Rules common to
  both harnesses go in `shared/CORE.md`; per-task detail goes in a skill.
- Git and secret rules are enforced in `shared/guard/policy.ts`; change them
  there with a case in `policy.test.ts`, not in the per-harness adapters.
- New skill: `<shared|harness>/skills/<name>/SKILL.md` with frontmatter (name
  = folder), then `./install.sh`. New agent: `<harness>/agents/<name>.md`.
- Run `scripts/doctor.sh` after changes (it runs `scripts/lint.sh`). Do not
  symlink `~/.claude/settings.json`; merge into it with
  `scripts/merge-claude-settings.sh`.
