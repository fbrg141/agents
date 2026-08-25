---
name: protocol
description: Full ceremony workflow for high-stakes tasks -- investigate, clarify, recommend, refine until agreement, plan, then code only after explicit approval. User-invoked only.
disable-model-invocation: true
metadata:
  invocation: "manual via /skill:protocol"
---

# PROTOCOL — full ceremony mode

Engaged deliberately by the user for work with real design stakes.
Follow every step. Do not skip to code.

Flow: INVESTIGATE -> CLARIFY -> RECOMMEND -> *LOOP UNTIL AGREEMENT*[REFINE -> CLARIFY -> RECOMMEND] -> PLAN -> CODE

## GATES -- where you MUST stop and wait

- After RECOMMEND: present the recommendation, then STOP. Do not write
  the plan yet. Wait for the user's reaction (that reaction is the REFINE
  loop input).
- After PLAN: present the plan, then STOP. Do not touch any file until
  the user explicitly approves.

RECOMMEND and PLAN are never presented in the same message.

1. INVESTIGATE: Read the relevant code. Understand the problem in context.
   Don't guess from filenames -- check how the codebase actually works.
   Evaluate feasibility before saying anything.

2. CLARIFY: Ask questions if the prompt is ambiguous, incomplete, or
   could mean multiple things. Iterate -- if answers reveal more ambiguity,
   ask again. Ask only what blocks execution; state reasonable assumptions
   for the rest.

3. RECOMMEND: Give a concise summary of the approach you'd take and why.
   One recommendation, not a menu. Flag risks and trade-offs.

4. REFINE: The user reacts -- asks for explanation, suggests changes,
   or pushes back.
   - "Explain X" -> go deeper. Use ASCII diagrams for architecture, data
     flow, control flow, or state transitions when they clarify.
   - "Change Y" -> update the recommendation. If the change creates new
     ambiguity, go back to CLARIFY.
   - REPEAT until both sides agree. After 3 rounds of disagreement,
     present both options with your pick and let the user choose.

5. PLAN: Only after agreement. Concrete steps: which files, what changes,
   what order. Call out risks. Get explicit approval before coding.

6. CODE: Implement exactly what was approved. No scope creep. Verify
   (build, test, lint). After 2 failed fix attempts, stop and report.
