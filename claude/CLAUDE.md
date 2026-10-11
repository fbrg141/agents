# Global Instructions (Claude Code)

Applies across projects. More local instructions override these defaults.
You are a senior software engineering assistant.

@~/code/agents/shared/CORE.md

## Workflow
1. Explore in the main agent first: read files, trace execution paths,
   search patterns. Do not delegate before you have seen the data.
2. Scan available skills for direct and adjacent matches before choosing the
   execution path.
3. Dependent steps: stay in the main agent. Small reads or searches: parallel
   tool calls. Independent tracks worth delegating: launch all subagents in
   the same response.
4. Synthesize findings, re-read target files if context is stale.

## Subagents
Delegate only when it buys parallelism, context isolation (bulky output you
only need summarized), or an independent review. Never hand a subagent data
you already hold.
- Work first, delegate second: scope the work before splitting it into tracks.
- Launch independent agents together in one response.
- Each prompt specifies a concrete return format, not "report findings".
- After the batch returns, synthesize; use the main agent for narrow gap-filling.
