/**
 * Claude Code PreToolUse hook: applies shared/guard/policy.ts to Bash and the
 * file tools. Registered by scripts/merge-claude-settings.sh. Prints only
 * deny/ask; printing nothing leaves the normal permission flow in charge
 * (an "allow" here would skip the user's prompts).
 */
import { readFileSync } from "node:fs";
import { checkBash, checkPath } from "../../shared/guard/policy.ts";
import type { Decision } from "../../shared/guard/policy.ts";

const event = JSON.parse(readFileSync(0, "utf8"));
const input = event.tool_input ?? {};

let verdict: Decision = { decision: "allow" };
if (event.tool_name === "Bash") verdict = checkBash(String(input.command ?? ""));
else if (["Read", "Edit", "Write"].includes(event.tool_name)) verdict = checkPath(String(input.file_path ?? ""));

if (verdict.decision !== "allow") {
    process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: verdict.decision,
            permissionDecisionReason: verdict.reason,
        },
    }) + "\n");
}
