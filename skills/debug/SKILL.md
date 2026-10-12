---
name: debug
description: Diagnosis loop for hard bugs and performance regressions - build a red-capable repro first, then ranked falsifiable hypotheses, one-variable probes, a regression test at a real seam, and cleanup. Use when the user says "debug this" or "diagnose", or reports something broken, throwing, flaky, or slow. Not for trivial one-line fixes.
---

# Debug

Redact secrets in every command output you show (`<REDACTED>`).

## 1. Build a feedback loop
Get one command that goes red on THIS bug before reading code for theories.
Options, roughly in order: failing test at the seam that reaches the bug;
HTTP/curl script against a running server; CLI run with a fixture input
diffed against known-good output; headless browser script; replay of a
captured payload or log; minimal throwaway harness; property/fuzz loop;
`git bisect run` script; old-vs-new differential run; scripted human steps
as a last resort.

Tighten it: assert the user's exact symptom (not "didn't crash"), make it
deterministic (pin time, seed RNG, stub network), make it take seconds.
Flaky bugs: loop the trigger until the repro rate is high enough to measure.

Done when you have run the command once and it is red-capable,
deterministic (or a pinned repro rate), fast, and runs unattended.
If you cannot build one: stop, list what you tried, and ask for access,
an artifact, or permission to instrument.

## 2. Reproduce and minimise
- Run the loop; confirm it fails the way the user described, not a nearby bug.
- Capture the symptom (message, wrong output, timing).
- Cut inputs, config, and steps one at a time, re-running after each cut,
  until every remaining part is needed. This becomes the regression test.

## 3. Hypothesise
- Write 3-5 ranked hypotheses. Each states a prediction:
  "if X is the cause, changing Y makes it pass / changing Z makes it worse".
- Show the list to the user; continue on your ranking if they do not answer.

## 4. Probe
- One probe per prediction, one variable changed at a time.
- Debugger or REPL first; then targeted logs at the boundaries that
  separate hypotheses. Never log everything and grep.
- Tag temporary logs with a unique prefix, e.g. `[DEBUG-a4f2]`.
- Performance: measure a baseline (timer, profiler, query plan), then
  bisect. Measure before fixing.

## 5. Fix with a regression test
- Find a seam where a test exercises the real bug pattern as it occurs at
  the call site. No such seam: report that as a finding; do not write a
  shallow test that cannot fail on this bug.
- Write the test, watch it fail, fix, watch it pass, then re-run the
  original un-minimised loop from step 1.

## 6. Clean up
- [ ] Original repro no longer reproduces.
- [ ] Regression test passes, or the missing seam is reported.
- [ ] No `[DEBUG-...]` lines remain (grep the prefix).
- [ ] Throwaway harnesses deleted.
- [ ] Report which hypothesis was right and the evidence for it.
