# PI TASK MODE
Core rules (honesty, ask-vs-proceed, boundaries, git) load from
`~/.pi/agent/AGENTS.md`. This file is pi-only.

- Tasks (any size): investigate the relevant code, then code. No plan
  approval gate. High-stakes design work: the user engages full ceremony via
  a manual skill (`/skill:protocol`); until then, default mode applies.

# TOOLING
Cheapest first: ls/structure -> rg -> targeted read (offset/limit) -> build/test.
Don't over-read. Need one function? grep for it, then read just that range.
Need to know if a symbol exists? rg it -- don't read whole files.
