---
name: debug
description: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow. Skip phases only when explicitly justified.
---

# Debug — a discipline for hard bugs

This skill has you show commands, outputs and captured artifacts. **Redact every secret first**: write `<REDACTED>` in its place. If redacted output is not enough to diagnose, say so and ask the user.

## Phase 1: Build a feedback loop

**This is the skill.** If you have a tight pass/fail signal for the bug (one that goes red on THIS bug), you will find the cause; everything else just consumes it. If you don't, no amount of staring at code will save you. Spend disproportionate effort here. Be aggressive. Be creative. Refuse to give up.

Ways to construct one, roughly in order:

1. Failing test at whatever seam reaches the bug.
2. Curl / HTTP script against a running dev server.
3. CLI invocation with a fixture input, diffing stdout against known-good.
4. Headless browser script asserting on DOM/console/network.
5. Replay a captured trace (request/payload/event log saved to disk).
6. Throwaway harness: minimal subset of the system exercised with one call.
7. Property/fuzz loop for "sometimes wrong output".
8. Bisection harness so `git bisect run` can consume it.
9. Differential loop: old version vs new version, diff outputs.
10. HITL bash script. Last resort: drive the human, keep the loop mechanical.

Then tighten the loop: faster? sharper signal (assert the exact symptom, not "didn't crash")? more deterministic (pin time, seed RNG, freeze network)? A 2-second deterministic loop is a superpower; a 30-second flaky one is barely better than none.

**Non-deterministic bugs**: goal is a higher reproduction rate, not a clean repro. Loop the trigger 100x, parallelise, add stress. A 50%-flake is debuggable; 1% is not.

**If you genuinely cannot build a loop**: stop and say so, list what you tried, ask the user for environment access, a redacted artifact, or permission to add temporary instrumentation. Do NOT hypothesise without a loop.

### Phase 1 done when

You can name ONE command you have already run once (show invocation + redacted output) that is:

- [ ] Red-capable: drives the actual bug path and asserts the user's exact symptom
- [ ] Deterministic (or pinned high repro rate)
- [ ] Fast: seconds
- [ ] Agent-runnable unattended

Reading code to build a theory before this command exists is the exact failure this skill prevents. No red-capable command, no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop; watch it go red.

- [ ] The failure mode is the one the USER described, not a nearby different bug
- [ ] Symptom captured (error message, wrong output, timing) for later verification

Then minimise: cut inputs, callers, config, data, steps ONE at a time, re-running after each cut. Done when every remaining element is load-bearing. The minimal repro becomes the regression test in Phase 5.

## Phase 3: Hypothesise

Generate 3-5 RANKED hypotheses before testing any. Each must be falsifiable:

> "If X is the cause, then changing Y will make the bug disappear / changing Z will make it worse."

No prediction = vibe; discard or sharpen. Show the ranked list to the user before testing -- their domain knowledge re-ranks instantly. Don't block if they're AFK.

## Phase 4: Instrument

Each probe maps to a specific Phase 3 prediction. Change one variable at a time.

1. Debugger / REPL inspection first. One breakpoint beats ten logs.
2. Targeted logs at hypothesis-distinguishing boundaries.
3. Never "log everything and grep".

Tag every debug log with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup becomes a single grep.

**Perf branch**: logs are usually wrong for regressions. Establish a baseline measurement (timing harness, profiler, query plan), then bisect. Measure first, fix second.

## Phase 5: Fix + regression test

Regression test BEFORE the fix, but only at a correct seam: one where the test exercises the real bug pattern as it occurs at the call site.

If no correct seam exists, THAT is a finding -- the architecture is preventing the bug from being locked down. Flag it; don't fake confidence with a shallow test.

If a seam exists: turn the minimised repro into a failing test -> watch it fail -> fix -> watch it pass -> re-run the Phase 1 loop against the original un-minimised scenario.

## Phase 6: Cleanup

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or missing seam documented)
- [ ] All `[DEBUG-...]` instrumentation removed (grep the prefix)
- [ ] Throwaway harnesses deleted or moved to a marked debug location
- [ ] Final report states which hypothesis was correct and why -- the next debugger (human or agent) learns from it
