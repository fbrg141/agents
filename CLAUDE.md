# Working in this repo

This repo is a Claude Code setup: skills, one hook, and `pi-ask`. It is
installed by symlinks (`scripts/install.sh`), so edits here are live for
anyone who installed from this clone.

- Run `scripts/check.sh` after every change; `scripts/check.sh --live` when
  `scripts/pi-ask`, its config, or the prompt templates change (calls pi).
- Keep the file layout as listed in `scripts/check.sh` (check 1f); a new
  file needs a reason and an update to that list and the README.
- No home-directory paths or personal identifiers in any file. Derive paths
  from `$HOME` or the repo location.
- Node (>= 22) and bash only, no npm dependencies. `scripts/install.sh` may use jq.
  macOS ships bash 3.2 and has no `timeout`: write scripts for that.
- Skills and prompts: English, short, imperative. Say what to do, not why.
- `global/CLAUDE.md` max 60 lines; `skills/debug/SKILL.md` max 80.
- Do not run `scripts/install.sh` without a sandbox `HOME` unless asked.
