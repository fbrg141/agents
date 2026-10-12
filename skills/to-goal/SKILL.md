---
name: to-goal
description: Turn a settled task (grill.md plus conversation) into spec.md with machine-checkable acceptance commands, get a two-model pi critique, revise, and hand back a /goal line for approval.
disable-model-invocation: true
argument-hint: "[task folder]"
---

# To goal

## Setup
1. `REPO="$(cd "$(dirname "$(realpath "${CLAUDE_SKILL_DIR}")")/.." && pwd)"`
2. Task folder: `$ARGUMENTS` if given. Otherwise the most recently modified
   folder under `~/.claude/specs/<project>/` (`<project>` = folder name of the
   git root). Say which folder you picked.
3. No task folder (grill was skipped): propose a kebab-case slug of at most
   5 words, confirm it with the user, and create
   `~/.claude/specs/<project>/<YYYY-MM-DD>-<slug>/reviews/` (append `-2`,
   `-3`, ... if it exists).

## Write the spec
1. Read `grill.md` if present, and the conversation. Decisions there are binding.
2. Copy `$REPO/templates/spec.md` to `<task folder>/spec.md` and fill it:
   objective, non-goals, constraints, layout and interfaces as needed,
   acceptance commands, stop conditions, settled decisions.
3. Acceptance commands: one fenced `bash` block under `## Acceptance commands`,
   one command per line, each passes iff it exits 0. Prefer one script
   (e.g. `scripts/check.sh`) that the implementer writes and the spec defines
   item by item. Every criterion must fail when the work is wrong.
4. Do not restate grill.md reasoning; reference it.

## Critique
1. From the task folder, run:
   ```bash
   "$REPO/scripts/pi-ask" --role oracle --out reviews --name spec \
     --prompt-file spec.md --prompt-file grill.md
   ```
   (omit `--prompt-file grill.md` if it does not exist). It can take
   several minutes; run it in the background if your harness allows.
2. Write `reviews/spec.synthesis.md`:
   - a table of findings raised by two or more models first, then single-model
     findings, then rejected ones;
   - each row: finding, models that raised it, accepted/rejected, reason or change.
   Check every finding against the code or docs before accepting it.
   Note models that failed or broke the output format.
3. Revise `spec.md` with the accepted findings. Bump the status line to the
   next revision and point it at the synthesis.

## Approval gate
1. Show the user: the synthesis summary (counts, the important accepted and
   rejected findings) and anything that needs their decision.
2. STOP and wait for approval. Apply requested changes and ask again.
3. On approval, set the status to `APPROVED (<date>)` and print the exact line:
   ```
   /goal Implement the spec at <spec path> in <repo path>. Done when every command in its "## Acceptance commands" block exits 0 from the repo root and that passing output is shown in the conversation. Follow its Constraints and Stop conditions. Do not edit the spec; do not weaken, skip, or remove any acceptance command or any check the spec defines. Or stop after 30 turns, or when a Stop condition triggers, and report what is unmet.
   ```
