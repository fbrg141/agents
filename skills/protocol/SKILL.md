---
name: protocol
description: Full ceremony workflow for high-stakes tasks -- investigate, interview decisions in rounds, recommend, plan, then code only after explicit approval. User-invoked only.
disable-model-invocation: true
metadata:
  invocation: "manual via /skill:protocol"
---

# PROTOCOL — full ceremony mode

Engaged deliberately by the user for work with real design stakes.
Follow every step. Do not skip to code.

Flow: INVESTIGATE -> INTERVIEW -> RECOMMEND -> *ROUNDS UNTIL AGREEMENT* -> PLAN -> CODE

## GATES -- where you MUST stop and wait

- After RECOMMEND: present the recommendation, then STOP. Do not write
  the plan yet. Wait for the user's reaction (that reaction feeds the
  next round).
- After PLAN: present the plan, then STOP. Do not touch any file until
  the user explicitly approves.

RECOMMEND and PLAN are never presented in the same message.

1. INVESTIGATE: Read the relevant code. Understand the problem in context.
   Don't guess from filenames -- check how the codebase actually works.
   Evaluate feasibility before saying anything.

2. INTERVIEW: Model the task as a decision tree: every decision
   branches into the decisions that hang off it. Work the tree in rounds.
   The frontier is every decision whose prerequisites are already settled
   -- the questions you can ask now without guessing at answers you
   haven't heard yet. Each round: ask the whole frontier at once,
   numbered, each with your recommended answer. Then wait.
   Facts are your job, never the user's -- look them up in the code
   yourself; only decisions go to the user.
   Each round of answers reshapes the tree: settled decisions push the
   frontier outward. Recompute the frontier and run the next round. If
   the user pushes back on a recommendation, that's a frontier answer --
   update the tree. "Explain X" rounds: go deeper, use ASCII diagrams for
   architecture, data flow, control flow, or state transitions when they
   clarify. After 3 rounds of disagreement on one point, present both
   options with your pick and let the user choose.
   The interview is done when the frontier is empty: every branch
   visited, nothing left silently assumed. Do not act on it until the
   user confirms shared understanding.

3. RECOMMEND: Give a concise summary of the approach you'd take and why.
   One recommendation, not a menu. Flag risks and trade-offs.

4. PLAN: Only after agreement. Concrete steps: which files, what changes,
   what order. Call out risks. Get explicit approval before coding.

5. CODE: Implement exactly what was approved. No scope creep. Verify
   (build, test, lint). After 2 failed fix attempts, stop and report.
