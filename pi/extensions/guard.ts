/**
 * Guard extension: applies shared/guard/policy.ts to pi tool calls.
 *  - deny -> blocked
 *  - ask  -> confirm (blocked when there is no UI)
 * Loaded by path from pi/settings.json (`extensions` and
 * `subagents.defaultSubagentOnlyExtensions`), not symlinked: jiti resolves the
 * relative import below from the symlink's location, not the repo.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { checkBash, checkPath } from "../../shared/guard/policy.ts";

export default function (pi: ExtensionAPI) {
    pi.on("tool_call", async (event, ctx) => {
        const input = event.input as Record<string, unknown>;
        let verdict;
        if (["read", "write", "edit"].includes(event.toolName)) verdict = checkPath(String(input.path ?? ""));
        else if (event.toolName === "bash") verdict = checkBash(String(input.command ?? ""));
        else return undefined;

        if (verdict.decision === "deny") return { block: true, reason: verdict.reason };
        if (verdict.decision === "ask") {
            if (!ctx.hasUI) return { block: true, reason: `${verdict.reason} (no UI)` };
            const ok = await ctx.ui.confirm("Git write", `Allow?\n\n  ${String(input.command ?? "")}`);
            if (!ok) return { block: true, reason: "guard: declined by user" };
        }
        return undefined;
    });
}
