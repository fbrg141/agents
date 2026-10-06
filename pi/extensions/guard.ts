/**
 * Guard extension: enforces the git/secret rules from shared/CORE.md in code.
 *  - git commit / git push        -> confirm (blocked when there is no UI)
 *  - force-push, --no-verify      -> blocked
 *  - read/write/edit of .env*     -> blocked (templates like .env.example allowed)
 *  - bash commands that touch .env* -> blocked
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TEMPLATE = /\.(example|sample|template|dist)$/i;
const isSecretPath = (p: string) => {
	const base = p.split("/").pop() ?? "";
	return /^\.env(\..+)?$/i.test(base) && !TEMPLATE.test(base);
};
const bashTouchesEnv = (cmd: string) =>
	(cmd.match(/(?:^|[\s"'=/])\.env(?:\.[\w.-]+)?(?=$|[\s"';|&)])/gi) ?? []).some((m) => !TEMPLATE.test(m.trim()));

const FORCE_PUSH = /\bgit\b[^;&|\n]*\bpush\b[^;&|\n]*(\s--force\b|\s--force-with-lease\b|\s-f\b|\s\+\S)/i;
const NO_VERIFY = /\bgit\b[^;&|\n]*\s(--no-verify|--no-gpg-sign)\b/i;
const COMMIT_OR_PUSH = /\bgit\b[^;&|\n]*\b(commit|push)\b/i;

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		const input = event.input as Record<string, unknown>;

		if (["read", "write", "edit"].includes(event.toolName)) {
			const path = String(input.path ?? "");
			if (isSecretPath(path)) return { block: true, reason: `guard: "${path}" is a secrets file` };
			return undefined;
		}

		if (event.toolName !== "bash") return undefined;
		const command = String(input.command ?? "");

		if (bashTouchesEnv(command)) return { block: true, reason: "guard: command touches a .env secrets file" };
		if (FORCE_PUSH.test(command)) return { block: true, reason: "guard: force-push is not allowed" };
		if (NO_VERIFY.test(command)) return { block: true, reason: "guard: --no-verify/--no-gpg-sign is not allowed" };

		if (COMMIT_OR_PUSH.test(command)) {
			if (!ctx.hasUI) return { block: true, reason: "guard: git commit/push needs confirmation (no UI)" };
			const ok = await ctx.ui.confirm("Git write", `Allow?\n\n  ${command}`);
			if (!ok) return { block: true, reason: "guard: declined by user" };
		}
		return undefined;
	});
}
