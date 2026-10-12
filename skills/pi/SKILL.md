---
name: pi
description: Ask other models (kimi, glm, mistral, deepseek, flash) through pi for a second opinion, a quick answer, or web research. Use when the user says "ask kimi", "ask glm", "second opinion from mistral/deepseek", "what does glm think", "/pi", or wants another model to check something.
argument-hint: "[models][+web]: question"
---

# pi

## Parse the request
`$ARGUMENTS` has the form `[models][+web]: question`, e.g. `kimi,glm: ...`,
`deepseek+web: ...`, or just a question.
- models: comma-separated aliases (`kimi`, `glm`, `mistral`, `deepseek`,
  `flash`) or full model ids. None given: omit `--models` (default model).
- `+web`: add `--web`.
- "second opinion" without models: use `--models kimi,glm`.

## Build the prompt
The models see nothing of this conversation. Write a self-contained prompt:
- the question, with the context needed to answer it;
- relevant file paths (they can read files under the current folder) or
  short excerpts; for code changes, save `git diff` to a file under the
  scratchpad and pass it with `--prompt-file`;
- the answer shape you want (e.g. "list issues as severity | claim | evidence",
  "answer in under 150 words").
Never include secrets.

## Run
```bash
REPO="$(cd "$(dirname "$(realpath "${CLAUDE_SKILL_DIR}")")/.." && pwd)"
"$REPO/scripts/pi-ask" [--models a,b] [--web] [--prompt-file FILE]... "prompt"
```
Calls can take minutes (default timeout 600 s); run in the background when
your harness allows. Exit 2 = usage error (read the message); exit 1 = all
models failed.

## Report
Show each model's answer under its own heading, trimmed of filler. Mark
where models agree and disagree. Merge into one answer only if the user
asks. Say plainly if a model failed or timed out.
