---
name: para-procedure
description: >
  Parallel ceremony workflow for multi-seam tasks -- fan out scouts to map the
  terrain, interview decisions, cross-check the plan with an oracle, implement
  one seam per worker, then fan out fresh-context reviewers before reporting.
  Use for tasks with several independent parts (schema + endpoint + UI,
  multi-service changes) or heavy recon needs, when the user asks for
  parallel or delegated work. Skip for single-seam tasks such as a
  typical bugfix -- implement directly instead.
disable-model-invocation: true
---

# PARA-PROCEDURE — ceremony with parallel lanes

Ceremony discipline (STOP gates) executed through subagent lanes. The main
agent keeps intent, decisions, arbitration, and final acceptance. Subagents
do bounded work and return compressed results.

Flow: SCOUT -> INTERVIEW -> RECOMMEND -> CROSS-CHECK -> PLAN -> APPROVAL ->
CODE (parallel agents) -> REVIEW FANOUT -> REPORT

Gates (STOP and wait for the user):
- After each INTERVIEW round: wait for answers.
- After CROSS-CHECK: present recommendation + critique verdict, then STOP
  until the user approves the recommendation.
- After PLAN: present the plan, then STOP. Touch no file until approved.

RECOMMEND and PLAN are never in the same message.

Agents (custom, from this repo's `claude/agents/`): `scout` (haiku, read-only
recon), `oracle` (opus, read-only critique), `worker` (sonnet, one seam),
`reviewer` (sonnet, read-only, review-axes), `researcher` (web facts).

Agent rules: launch 2+ agents or none, all in ONE response so they run in
parallel. Never exactly one. Every prompt states a concrete return format.
Subagents start cold: pass everything they need; they cannot see this chat.

## 1. SCOUT

Split recon into seams (schema, API, frontend, tests/CI, docs). Read small
seams yourself first. For 2+ seams needing breadth, launch `scout` agents
in one response, one per seam (e.g. DB schema + access code; existing code
paths; test/CI landscape). Ask each for: file paths, key symbols, conventions,
and open risks -- no file dumps. Databases count as recon: schemas, relations,
access code -- never guess.

Synthesize into one shared picture; hand it to every later lane.

## 2. INTERVIEW

Model the task as a decision tree. Each round: ask the whole frontier at
once, numbered, each with your recommended answer (use AskUserQuestion when
options are discrete). Facts are your job -- scouts gathered them; only
decisions go to the user. After 3 rounds of disagreement on one point,
present both options with your pick. Done when the frontier is empty.

## 3. RECOMMEND + CROSS-CHECK

Write one recommendation (not a menu; risks flagged). Then launch the `oracle`
alongside a `reviewer` (spec axis: does the recommendation meet the stated
objective?) in the same response, each given: objective, settled decisions,
scout facts, the recommendation. Task: challenge assumptions, find missed
risks or cheaper shapes; return a ranked list with evidence. Verify their claims against the
code yourself; adopt what holds.

## 4. PLAN

Concrete steps: seams, files, order, which steps are parallel. One writer and
one exclusive file area per parallel step. Name integration seams and owner.

## 5. CODE

Launch `worker` agents, one per seam, with a compact brief:
objective; cwd; files they own (and may not leave); contracts and scout
facts; success criteria; validation command; report format; stop-and-ask
conditions. Writers on overlapping files need `isolation: "worktree"`; the
integration owner merges sequentially. Never share a cwd between overlapping
writers. After 2 failed fixes in a lane, stop it and reroute.

## 6. REVIEW FANOUT

Launch 2-3 `reviewer` agents in one response: one per risky seam, or one
diff-level + one spec-level (they follow the `review-axes` skill). Give
scope, the approved plan, what to check; require findings with file:line.
Synthesize yourself; apply validated fixes in the main agent. Reviewers never
edit code.

## 7. REPORT

Every change: file, what, why, tied to plan or decision. Flag deviations.
Findings accepted vs rejected. Per-lane validation results.

## Anti-ceremony

- Single-seam or small diff: don't use this skill.
- Every lane must earn its cost (independence, isolation, or parallelism).
- Stop gates are real waits. No commits unless explicitly requested.
