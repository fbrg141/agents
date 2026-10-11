// Run: node --test shared/guard/
import { test } from "node:test";
import assert from "node:assert/strict";
import { checkBash, checkPath } from "./policy.ts";

const bash: Array<[string, "allow" | "ask" | "deny"]> = [
    // force-push in every spelling
    ["git push --force", "deny"],
    ["git push origin main --force", "deny"],
    ["git push -f origin main", "deny"],
    ["git push -uf origin main", "deny"],
    ["git push --force-with-lease", "deny"],
    ["git push origin +main", "deny"],
    ["git -C ../repo push --force", "deny"],
    ["/usr/bin/git push --force", "deny"],
    ["cd x && git push --force", "deny"],
    // hook / signing bypass
    ["git commit --no-verify -m x", "deny"],
    ["git commit -n -m x", "deny"],
    ["git commit -anm x", "deny"],
    ["git push --no-verify", "deny"],
    ["git commit --no-gpg-sign -m x", "deny"],
    ["git -c commit.gpgsign=false commit -m x", "deny"],
    ["git -c core.hooksPath=/dev/null commit -m x", "deny"],
    // ordinary git writes ask
    ["git commit -m 'fix -n handling'", "ask"],
    ["git commit -m -n", "ask"],
    ["git commit -am wip", "ask"],
    ["git push origin main", "ask"],
    ["git push -u origin feature", "ask"],
    ["git -C ../repo push", "ask"],
    ["git status && git commit -m x", "ask"],
    // reads and look-alikes allowed
    ["git status", "allow"],
    ["git log --grep=push", "allow"],
    ["git log --oneline -n 5", "allow"],
    ["git push-helper", "allow"],
    ["echo commit", "allow"],
    // quoted text and heredoc bodies are data, not commands
    ["git commit -F - <<'EOF'\nStop `git -C x push --force` (and -uf)\nEOF", "ask"],
    ["git commit -m \"$(cat <<'EOF'\nfix 1) git push --force\nEOF\n)\"", "ask"],
    ["git commit -m \"line one\ngit push --force\"", "ask"],
    ["git commit -m 'block .env reads'", "ask"],
    ["cat > notes.md <<EOF\ngit push -f\nEOF", "allow"],
    // ...unless they execute
    ["bash <<'EOF'\ngit push --force\nEOF", "deny"],
    ["cat <<EOF | sh\ngit push --force\nEOF", "deny"],
    ["echo \"$(git push --force)\"", "deny"],
    ["echo `git push -f`", "deny"],
    ["(cd x && git push --force)", "deny"],
    // secrets
    ["cat .env", "deny"],
    ["python -c \"open('.env')\"", "deny"],
    ["docker run --env-file=.env img", "deny"],
    ["cat ./.env.local", "deny"],
    ["source config/.env", "deny"],
    ["echo $(< .env)", "deny"],
    ["cat .env.example", "allow"],
    ["cat .envrc", "allow"],
];

for (const [command, want] of bash) {
    test(`bash: ${command} -> ${want}`, () => assert.equal(checkBash(command).decision, want));
}

const paths: Array<[string, "allow" | "deny"]> = [
    [".env", "deny"],
    ["/repo/.env.production", "deny"],
    ["C:\\repo\\.env", "deny"],
    ["/repo/.env.example", "allow"],
    ["/repo/.env.sample", "allow"],
    ["/repo/.envrc", "allow"],
    ["/repo/src/env.ts", "allow"],
];

for (const [path, want] of paths) {
    test(`path: ${path} -> ${want}`, () => assert.equal(checkPath(path).decision, want));
}

test("deny reasons are prefixed for the harness UI", () => {
    assert.match(checkBash("git push --force").reason ?? "", /^guard: /);
});
