---
name: grill
description: Interview the user about a task until every open decision is settled, then write grill.md into a new task folder. Run before to-goal for non-trivial work.
disable-model-invocation: true
---

# Grill

Settle the decisions for a task before any spec or code is written.

## Before asking anything
1. Read what the user gave you (`$ARGUMENTS`, the conversation, linked files).
2. Look up every fact yourself: code, config, docs, `--help`, running a
   command. Never ask the user something you can check.
3. List the open decisions: choices only the user can make (scope,
   behavior, interfaces, trade-offs, what is out of scope).

## Interview
- Ask in rounds. Each round: the decisions that block the most other
  decisions first.
- Every question carries your recommended answer and a one-line reason.
- Discrete options: use `AskUserQuestion` (at most 4 questions per call,
  recommended option first). Open questions: plain text.
- After each round, look up any new facts the answers raised, then update
  the list. Stop when no open decision remains or the user says enough.
- Do not write code or a spec during the interview.

## Task folder
1. `<project>` = folder name of `git rev-parse --show-toplevel` (or the
   current folder if not in git).
2. Propose a slug: kebab-case, at most 5 words, from the task title. Confirm
   it with the user in the last round.
3. Folder: `~/.claude/specs/<project>/<YYYY-MM-DD>-<slug>/`, today's date.
   If it exists, append `-2`, `-3`, ... Create it and `reviews/` inside.

## grill.md
Write `<task folder>/grill.md`:
```markdown
# Grill: <title>

Decisions settled in discussion (<date>). Facts checked are marked (verified).

## <topic>
- <decision, stated as a fact about the target>
- (verified) <fact you checked, and how if not obvious>

## Open
- <anything the user deferred; omit the section if empty>
```
Keep each line to one decision or fact. No reasoning transcripts.

## Finish
Print the folder path and suggest `/to-goal <folder>` as the next step.
