/**
 * Guard policy shared by the pi extension (pi/extensions/guard.ts) and the
 * Claude Code PreToolUse hook (claude/hooks/guard.ts). Enforces the git and
 * secret rules from shared/CORE.md. Pure: no I/O, erasable TypeScript only so
 * Node strips it natively and pi's jiti loads it unchanged.
 *  - git commit / git push                       -> ask
 *  - force-push, --no-verify, --no-gpg-sign,
 *    `-c` overrides that disable hooks or signing -> deny
 *  - .env* files (templates like .env.example allowed) -> deny
 * Best effort: a determined command can evade text matching. Defense in depth
 * comes from the Claude permission rules and the user confirming git writes.
 */

export type Decision = { decision: "allow" | "ask" | "deny"; reason?: string };

const ALLOW: Decision = { decision: "allow" };
const deny = (reason: string): Decision => ({ decision: "deny", reason: `guard: ${reason}` });
const ask = (reason: string): Decision => ({ decision: "ask", reason: `guard: ${reason}` });

const TEMPLATE = /\.(example|sample|template|dist)$/i;
// A word that is a .env path (`./.env.local`, `--env-file=.env`, `<.env`),
// or a quoted .env literal inside code (`python -c "open('.env')"`).
const ENV_WORD = /^(?:.*[/=<>])?(\.env(?:\.[\w.-]+)?)$/i;
const ENV_LITERAL = /['"](\.env(?:\.[\w.-]+)?)['"]/i;

export function checkPath(path: string): Decision {
    const base = path.split(/[\\/]/).pop() ?? "";
    if (/^\.env(\..+)?$/i.test(base) && !TEMPLATE.test(base)) return deny(`"${path}" is a secrets file`);
    return ALLOW;
}

// git global options that consume the next token (`git -C dir push`).
const GIT_GLOBAL_ARG = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix", "--config-env"]);
// `-c key=value` overrides that switch off hooks or signing.
const GIT_BYPASS_CONFIG = /^(core\.hookspath=|(commit|tag)\.gpgsign=(false|no|off|0)$)/i;
// git commit options whose value is the next token or the rest of a short cluster.
const COMMIT_SHORT_ARG = "mFCctS";
const COMMIT_LONG_ARG = new Set([
    "--message", "--file", "--author", "--date", "--reuse-message", "--reedit-message",
    "--fixup", "--squash", "--template", "--cleanup", "--trailer", "--pathspec-from-file",
]);

const unquote = (t: string) => t.replace(/^(['"])(.*)\1$/s, "$2");
const tokenize = (segment: string) => (segment.match(/"[^"]*"|'[^']*'|\S+/g) ?? []).map(unquote);
const isGit = (t: string) => t === "git" || t.endsWith("/git");
const isSecretWord = (w: string) =>
    [ENV_WORD.exec(w)?.[1], ENV_LITERAL.exec(w)?.[1]].some((m) => m !== undefined && !TEMPLATE.test(m));

// A heredoc body is data unless its line hands it to a shell.
const FEEDS_SHELL = /(^|[\s|;&(])(sh|bash|zsh|dash|ksh|eval|source)(\s|$)/;

/**
 * Split a shell command into the simple commands that would execute, so that
 * quoted text and heredoc bodies (commit messages, file content) are never
 * mistaken for commands. Command substitutions `$(…)` and backticks, inside
 * or outside double quotes, are split recursively; subshells, pipes and
 * `; & | newline` end a command. Returns the commands and where it stopped
 * (an unmatched `)` when called for a substitution).
 */
function lex(src: string, i = 0, inSub = false): { commands: string[]; end: number } {
    const commands: string[] = [];
    let cur = "";
    let depth = 0;
    let lineStart = i;
    const heredocs: Array<{ delim: string; strip: boolean }> = [];
    const cut = () => { if (cur.trim()) commands.push(cur); cur = ""; };
    const substitute = (start: number) => { // start is just past `$(`
        const sub = lex(src, start, true);
        commands.push(...sub.commands);
        return sub.end + 1;
    };
    const backtick = (start: number) => { // start is the opening backtick
        let k = start + 1;
        while (k < src.length && src[k] !== "`") k += src[k] === "\\" ? 2 : 1;
        commands.push(...lex(src.slice(start + 1, k)).commands);
        return k + 1;
    };

    while (i < src.length) {
        const c = src[i];
        if (c === "\\") { cur += src.slice(i, i + 2); i += 2; }
        else if (c === "'") {
            const k = src.indexOf("'", i + 1);
            const end = k === -1 ? src.length : k + 1;
            cur += src.slice(i, end); i = end;
        } else if (c === '"') {
            let k = i + 1;
            let text = '"';
            while (k < src.length && src[k] !== '"') {
                if (src[k] === "\\") { text += src.slice(k, k + 2); k += 2; }
                else if (src.startsWith("$(", k)) { text += "$(…)"; k = substitute(k + 2); }
                else if (src[k] === "`") { text += "`…`"; k = backtick(k); }
                else { text += src[k]; k++; }
            }
            cur += text + '"'; i = k + 1;
        } else if (src.startsWith("$(", i)) { cur += "$(…)"; i = substitute(i + 2); }
        else if (c === "`") { cur += "`…`"; i = backtick(i); }
        else if (src.startsWith("<<<", i)) { cur += "<<<"; i += 3; }
        else if (src.startsWith("<<", i)) {
            let k = i + 2;
            const strip = src[k] === "-";
            if (strip) k++;
            while (src[k] === " " || src[k] === "\t") k++;
            const m = /^(?:'([^']*)'|"([^"]*)"|([^\s;&|<>()]+))/.exec(src.slice(k)) ?? ["", ""];
            heredocs.push({ delim: (m[1] ?? m[2] ?? m[3] ?? "").replace(/\\/g, ""), strip });
            cur += src.slice(i, k + m[0].length); i = k + m[0].length;
        } else if (c === ")" && depth === 0 && inSub) { cut(); return { commands, end: i }; }
        else if (c === "(" || c === ")") { depth = Math.max(0, depth + (c === "(" ? 1 : -1)); cut(); i++; }
        else if (c === ";" || c === "&" || c === "|") { cut(); i++; }
        else if (c === "\n") {
            cut();
            const line = src.slice(lineStart, i);
            i++;
            for (const h of heredocs) {
                const body: string[] = [];
                while (i < src.length) {
                    const nl = src.indexOf("\n", i);
                    const end = nl === -1 ? src.length : nl;
                    const text = src.slice(i, end);
                    i = end + 1;
                    if ((h.strip ? text.replace(/^\t+/, "") : text) === h.delim) break;
                    body.push(text);
                }
                if (FEEDS_SHELL.test(line)) commands.push(...lex(body.join("\n")).commands);
            }
            heredocs.length = 0;
            lineStart = i;
        } else { cur += c; i++; }
    }
    cut();
    return { commands, end: src.length };
}

function commitSkipsHooks(args: string[]): boolean {
    for (let i = 0; i < args.length; i++) {
        const a = args[i];
        if (a === "--") return false;
        if (a === "--no-verify") return true;
        if (COMMIT_LONG_ARG.has(a)) { i++; continue; }
        if (/^-[a-zA-Z]+$/.test(a)) {
            for (let j = 1; j < a.length; j++) {
                if (a[j] === "n") return true;
                if (COMMIT_SHORT_ARG.includes(a[j])) {
                    if (j === a.length - 1) i++; // value is the next token
                    break;
                }
            }
        }
    }
    return false;
}

function pushForces(args: string[]): boolean {
    return args.some((a) =>
        a.startsWith("--force") || (/^-[a-zA-Z]+$/.test(a) && a.includes("f")) || /^\+\S/.test(a));
}

function checkGit(tokens: string[]): Decision {
    let i = 0;
    while (i < tokens.length && tokens[i].startsWith("-")) {
        const opt = tokens[i];
        if (opt === "-c" && GIT_BYPASS_CONFIG.test(tokens[i + 1] ?? "")) return deny(`git -c ${tokens[i + 1]} bypasses hooks or signing`);
        i += GIT_GLOBAL_ARG.has(opt) ? 2 : 1;
    }
    const sub = tokens[i];
    const args = tokens.slice(i + 1);
    if (args.includes("--no-gpg-sign")) return deny("--no-gpg-sign is not allowed");
    if (args.includes("--no-verify")) return deny("--no-verify is not allowed");
    if (sub === "push") return pushForces(args) ? deny("force-push is not allowed") : ask("git push needs confirmation");
    if (sub === "commit") return commitSkipsHooks(args) ? deny("git commit -n skips hooks") : ask("git commit needs confirmation");
    return ALLOW;
}

export function checkBash(command: string): Decision {
    let verdict = ALLOW;
    for (const segment of lex(command).commands) {
        const tokens = tokenize(segment);
        if (tokens.some(isSecretWord)) return deny("command touches a .env secrets file");
        const g = tokens.findIndex(isGit);
        if (g === -1) continue;
        const d = checkGit(tokens.slice(g + 1));
        if (d.decision === "deny") return d;
        if (d.decision === "ask") verdict = d;
    }
    return verdict;
}
