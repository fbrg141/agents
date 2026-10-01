---
name: para-procedure
description: >
  Parallel ceremony workflow for multi-seam tasks -- fan out explore agents to
  map the terrain, interview decisions, route the plan through an oracle
  review, implement with worker subagents (one per seam), then fan out
  fresh-context reviewers before reporting. Use for tasks with several
  independent parts (schema + endpoint + UI, multi-service changes) or heavy
  recon needs, e.g. when the user asks for parallel/delegated work or says
  they installed subagents and wants them used. Skip for single-seam tasks
  such as a typical bugfix -- the parent implements directly instead.
---

# PARA-PROCEDURE — ceremony with parallel lanes

Ceremony discipline (STOP gates everywhere) executed through subagent lanes.
The parent keeps intent, decisions, arbitration, and final acceptance.
Children do bounded work. Follow every step; do not skip to code.

Flow: SCOUT -> INTERVIEW -> RECOMMEND -> ORACLE REVIEW -> PLAN -> APPROVAL ->
CODE (parallel workers) -> REVIEW FANOUT -> REPORT

Gates (where you MUST stop and wait):
- After each INTERVIEW round: wait for the user's answers.
- After ORACLE REVIEW: present recommendation + oracle verdict, then STOP.
  Wait for explicit approval of the recommendation before planning further.
- After PLAN: present the plan, then STOP. Do not touch any file until the
  user explicitly approves.

RECOMMEND and PLAN are never presented in the same message.

## 1. SCOUT — parallel terrain mapping, fan out by default

Identify the task's seams (schema, API, frontend, tests, build, docs). For
each seam needing recon, launch a `scout` subagent via
`subagent({ action: "list" })` agents or a workflow script with
`runs.run(...)` fanout — e.g. one scout to explore the database
(schema, migrations, access patterns), one for existing code paths, one for
test/CI landscape. Scouts are read-only, fast, and return compressed context.

Databases count as recon: ask the scout for schemas, table relationships,
row-volume/traffic conventions, and existing access code — never guess them.
If a seam is small, read it directly in the parent instead of spawning;
scout only earns tokens on breadth or unfamiliarity.

Synthesize scout outputs yourself into a single shared picture; hand that
picture to every later lane. Scouts never re-read each other's work.

## 2. INTERVIEW — decision rounds (same discipline as protocol)

Model the task as a decision tree. Each round: ask the whole frontier at
once, numbered, each with your recommended answer. Facts are your job --
scouts already gathered them; only decisions go to the user. Recompute the
frontier as answers settle. After 3 rounds of disagreement on one point,
present both options with your pick; this is the one exception to
"one recommendation, not a menu". Done when the frontier is empty.

## 3. RECOMMEND — one approach, then oracle cross-check

Write the single recommendation (one approach, not a menu; risks and
trade-offs flagged). Then submit it as ONE text to an `oracle` subagent (read
only, async) with this context: user objective, settled decisions,
scout-derived facts, the recommendation, and the task: challenge assumptions,
find missed risks or cheaper shapes. Use the oracle's exact suggestions
before adopting them.

## 4. PLAN

Fold in whatever the oracle and the user's approval changed. Concrete steps:
which seams, which files, what order, which steps are parallelizable. Assign
each parallel step one writer and one exclusive file/area (one writer per
seam; never two writers sharing a file). Call out integration seams and
their owner.

## 5. CODE — parallel workers, isolated if needed

Launch `worker` subagents with a compact meta-prompt each: objective; repo +
cwd; authority boundary (their files only); relevant contracts and scout
facts; success criteria; how to validate (build/test/lint); expected report;
stop-and-ask conditions. Parallel writers on overlapping files need managed
worktree isolation (`isolation: worktree`), then the integration owner merges
sequentially. Never launch overlapping writers in one shared cwd. After 2
failed fix attempts in a lane, stop it and reroute -- you own arbitration.

## 6. REVIEW FANOUT — fresh eyes, then fix in parent

With 2-3 `reviewer` subagents (fresh context, read-only, in parallel):
one per risky seam or one diff-level + one spec-level. Give each the scope,
the approved plan, and what to check. Add an `oracle` pass only when the
reviewers disagree materially or the change is high-stakes. Synthesize their
findings yourself; the parent (or a rerouted writer) applies validated
fixes. Never let a reviewer edit code.

## 7. REPORT

List every change -- file path, what changed, why, tied to the approved plan
or a decision. Flag deviations and justify them. Include review findings
accepted vs rejected, and per-lane validation results.

## Anti-ceremony rules

- Single-seam task, small diff, or user just wants speed: do not use this
  skill; implement directly in the parent.
- Every lane must earn its token/time cost (independence, specialization,
  isolation, or parallelism). No lane exists to look thorough.
- Stop gates are real waits, not formality. Parallelism never replaces the
  user's decision authority.