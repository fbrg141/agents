---
name: code-review
description: Review changes since a fixed point (commit, branch, tag, or merge-base) along two axes -- Standards (does the code follow the repo's documented conventions and a fixed smell baseline?) and Spec (does the code do what was asked, nothing more?). Use when the user wants a branch, PR, or work-in-progress reviewed, or asks to "review since X". Reports findings, never rewrites code.
---

# Code Review — two axes, reported separately

Review the diff between `HEAD` and a fixed point along two axes:

- **Standards**: does the code conform to this repo's documented conventions, plus the smell baseline below?
- **Spec**: does the code do exactly what was asked? No missing requirements, no scope creep.

Report the axes separately and never merge or rerank findings across them: a change can pass one and fail the other (perfectly styled code implementing the wrong thing; correct behavior breaking every convention). Separation stops one axis masking the other.

## Process

### 1. Pin the fixed point

Whatever the user named (SHA, branch, tag, `main`, `HEAD~5`). If unspecified, ask. Capture `git diff <fixed-point>...HEAD` (three-dot = merge-base) and `git log <fixed-point>..HEAD --oneline`. Verify the ref resolves and the diff is non-empty before reviewing -- fail here, not mid-review.

### 2. Find the spec

In order: the user's description of what the change should do; a path passed as argument; issue references in commit messages; spec/plan files under `docs/`, `specs/`, or similar matching the branch or feature. If none exists, note "no spec available" and run Standards only.

### 3. Find the standards

Anything in the repo documenting how code should be written: `CONTRIBUTING.md`, lint configs, a conventions doc, established patterns in neighboring code. On top of that, ALWAYS apply the smell baseline below, bound by two rules:

- **The repo overrides.** A documented repo convention wins over the baseline; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic, never a hard violation. Skip anything tooling already enforces.

### Smell baseline

Match each against the diff (what it is -> how to fix):

- **Mysterious Name**: name doesn't reveal what it does or holds. -> rename; if no honest name comes, the design's murky.
- **Duplicated Code**: same logic shape in multiple hunks/files. -> extract the shared shape.
- **Feature Envy**: a function reaching into another object's data more than its own. -> move it onto the data it envies.
- **Data Clumps**: same few fields/params travelling together. -> bundle into one type.
- **Primitive Obsession**: a string/number standing in for a domain concept. -> give the concept a small type.
- **Repeated Switches**: same switch/if-cascade on the same type recurring. -> polymorphism, or one shared map.
- **Shotgun Surgery**: one logical change forced edits across many files. -> gather what changes together.
- **Divergent Change**: one file edited for several unrelated reasons. -> split by reason to change.
- **Speculative Generality**: abstraction/parameters for needs the spec doesn't have. -> delete; inline until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation. -> hide the walk behind one method on the first object.
- **Middle Man**: a function that mostly delegates onward. -> cut it, call the real target.
- **Refused Bequest**: a subclass ignoring/overriding most of what it inherits. -> drop inheritance, compose.

### 4. Report

Present under `## Standards` and `## Spec` headings.

Standards findings: cite the documented convention (file + rule) or name the smell and quote the hunk. Distinguish hard violations from judgement calls.

Spec findings: (a) requirements missing or partial, (b) behavior in the diff that wasn't asked for, (c) requirements implemented wrongly. Quote the spec line for each.

End with a one-line summary: total findings per axis and the worst issue within each. Don't pick a single winner across axes.

## Stance

No sycophancy, no hedging padding. Every finding cites its evidence (diff hunk, spec line, convention file). If the change is clean on an axis, say CLEAN in one line and move on -- don't manufacture findings. This skill reports; it does not edit code. Fixes are a separate, explicitly requested task.
