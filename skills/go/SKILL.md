---
name: go
description: Finish a /goal run - re-run the spec's acceptance commands, simplify, have three pi models review the diff against the spec, fix small findings, and write report.md. Never commits.
disable-model-invocation: true
effort: high
argument-hint: "[task folder]"
---

# Go

## Setup
1. `git rev-parse --show-toplevel` must succeed; otherwise stop and say `go`
   needs a git repo. Work from the git root.
2. `REPO="$(cd "$(dirname "$(realpath "${CLAUDE_SKILL_DIR}")")/.." && pwd)"`
3. Task folder: `$ARGUMENTS` if given, else the most recently modified folder
   under `~/.claude/specs/<project>/` (`<project>` = git root folder name).
   Say which one you picked. Read its `spec.md`.
4. Acceptance commands = the lines of the first fenced `bash` block under
   `## Acceptance commands` in `spec.md`.

## Steps
1. Run each acceptance command fresh from the git root. If any fails: write
   `report.md` with each command, exit code and output tail, plus a follow-up
   `/goal` line that names the failures. Stop.
2. Run `/simplify`. If it is unavailable, note that for the report and continue.
3. Write `<task folder>/diff.patch` from the git root, without touching the index:
   ```bash
   { git diff HEAD
     git ls-files --others --exclude-standard -z |
       xargs -0 -I{} git diff --no-index /dev/null {}
   } > "<task folder>/diff.patch"
   ```
   (`git diff --no-index` exits 1 when files differ; that is expected.)
4. From the task folder, run (add `--prompt-file <git root>/REVIEW.md` if it exists):
   ```bash
   "$REPO/scripts/pi-ask" --role review --out reviews --name diff \
     --prompt-file spec.md --prompt-file diff.patch
   ```
   Write `reviews/diff.synthesis.md`: Spec and Standards findings, each with
   the models that raised it, accepted/rejected and why. Verify each finding
   against the code before accepting it; findings raised by two or more
   models first.
5. Fix accepted small findings: no design change, under ~50 changed lines
   in total. Larger ones go to the report.
6. Re-run the acceptance commands. Any failure is an open issue.
7. Write `<task folder>/report.md`:
   - acceptance commands with results (before and after fixes);
   - `/simplify` outcome;
   - findings accepted (with the fix) and rejected (with the reason);
   - open issues;
   - for large findings: one follow-up `/goal` line.
8. Tell the user the report path and a three-line summary.

Never commit, push, create a branch, or open a PR. The user commits.
