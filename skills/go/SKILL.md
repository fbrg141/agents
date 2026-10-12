---
name: go
description: Finish a /goal run - re-run the spec's acceptance commands, simplify, have two pi models review the diff against the spec, fix small findings, and write report.md. Never commits.
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
   If `diff.patch` is empty: write `report.md` saying the diff is empty, with
   the output of `git status --short` and `git log --oneline -5`. Say that if
   the work was committed, the user can reset and rerun `/go`, or review the
   commits manually. Stop; do not run the reviewers.
4. From the task folder, run (add `--prompt-file <git root>/REVIEW.md` if it exists):
   ```bash
   "$REPO/scripts/pi-ask" --role review --out reviews --name diff \
     --prompt-file spec.md --prompt-file diff.patch
   ```
   Write `reviews/diff.synthesis.md`: Spec and Standards findings, each with
   the models that raised it, accepted/rejected and why. Verify each finding
   against the code before accepting it; findings raised by two or more
   models first.
5. Snapshot the tree from the git root, without touching the index or HEAD:
   ```bash
   d="$(mktemp -d)"; GIT_INDEX_FILE="$d/i" git add -A &&
     GIT_INDEX_FILE="$d/i" git write-tree > "<task folder>/pre-fix.tree"; rm -rf "$d"
   ```
   Fix accepted small findings: no design change, under ~50 changed lines
   in total. Larger ones go to the report.
6. If any fix was applied: repeat the step 5 snapshot into `post-fix.tree`,
   then from the git root run
   `git diff "$(cat <task folder>/pre-fix.tree)" "$(cat <task folder>/post-fix.tree)" > <task folder>/fixes.patch`.
   From the task folder, run one reviewer once (add
   `--prompt-file <git root>/REVIEW.md` if it exists):
   ```bash
   "$REPO/scripts/pi-ask" --role review --models glm --out reviews --name fixes \
     --prompt-file spec.md --prompt-file fixes.patch
   ```
   Verify its findings against the code. Fix only trivial ones; the rest are
   open issues. Do not review again.
7. Re-run the acceptance commands. Any failure is an open issue.
8. Write `<task folder>/report.md`:
   - acceptance commands with results (before and after fixes);
   - `/simplify` outcome;
   - findings accepted (with the fix) and rejected (with the reason);
   - fix review: findings fixed and left open, or "no fixes applied";
   - open issues;
   - for large findings: one follow-up `/goal` line.
9. Tell the user the report path and a three-line summary.

Never commit, push, create a branch, or open a PR. The user commits.
