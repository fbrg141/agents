# Spec: <title>

Status: DRAFT (not approved)
Repo: <git root, relative to $HOME>
Decisions: see `grill.md` in this folder (if present).

## Objective
<One paragraph: what exists when this is done, and for whom.>

## Non-goals
- <What this work deliberately does not do.>

## Constraints
- <Languages, dependencies, files or systems that must not be touched.>
- Do not commit, push, or create branches.

## Layout and interfaces
<Only as much as the implementer needs: files, commands, flags, formats,
exit codes, error behavior. Delete this section if not needed.>

## Acceptance commands
Run from the repo root. Each command passes when it exits 0.
```bash
<one command per line>
```
<Optional prose: what each command verifies. Every criterion must be able to
fail when the work is wrong.>

## Stop conditions
- A criterion cannot be met as written → stop and report; do not weaken or
  rewrite the criterion.
- Two failed fix attempts on the same criterion → stop and report.
- Anything that needs a decision not covered here or in `grill.md` → stop and ask.

## Settled
1. <Decision> (<who>, <date>).
