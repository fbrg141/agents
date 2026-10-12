#!/usr/bin/env bash
# Link this repo's global instructions and skills into ~/.claude and register
# the no-skip-tests hook. Safe to re-run. Uses $HOME, so
# `HOME=$(mktemp -d) scripts/install.sh` installs into a sandbox.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_CMD="$REPO/hooks/no-skip-tests"
HOOK_MATCHER="Edit|Write|MultiEdit|NotebookEdit"

command -v jq >/dev/null || { echo "install.sh: jq is required" >&2; exit 1; }

# An existing link is replaced only when it is dangling (e.g. the repo moved).
# A working link to anywhere else is skipped.
link() {
  local src="$1" dst="$2" old
  if [[ -L "$dst" ]]; then
    old="$(readlink "$dst")"
    if [[ "$old" == "$src" ]]; then
      echo "ok    $dst"
      return
    fi
    if [[ -e "$dst" ]]; then
      echo "SKIP  $dst (link to $old, not from this repo; move it away and re-run)"
      return
    fi
    echo "relink $dst (was $old)"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "SKIP  $dst (real file or folder; move it away and re-run)"
    return
  else
    echo "link  $dst"
  fi
  ln -s "$src" "$dst"
}

prune() {
  local dst target
  for dst in "$@"; do
    [[ -L "$dst" ]] || continue
    target="$(readlink "$dst")"
    if [[ "$target" == "$REPO"/* && ! -e "$dst" ]]; then
      echo "prune $dst (target gone)"
      rm "$dst"
    fi
  done
}

mkdir -p "$CLAUDE_DIR/skills"

link "$REPO/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
for dir in "$REPO"/skills/*/; do
  name="$(basename "$dir")"
  link "$REPO/skills/$name" "$CLAUDE_DIR/skills/$name"
done
shopt -s nullglob
prune "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR"/skills/*
shopt -u nullglob

# Hook entry, matched by exact command path so re-runs are no-ops; an existing
# entry gets the current matcher. Entries for
# a no-skip-tests hook whose file no longer exists (a moved clone) are pruned.
if [[ -e "$SETTINGS" ]]; then
  jq empty "$SETTINGS" 2>/dev/null || { echo "install.sh: $SETTINGS is not valid JSON; not touching it" >&2; exit 1; }
else
  echo '{}' > "$SETTINGS"
  echo "create $SETTINGS"
fi
stale=()
while IFS= read -r cmd; do
  [[ -n "$cmd" && "$cmd" != "$HOOK_CMD" && ! -e "$cmd" ]] && stale+=("$cmd")
done < <(jq -r '.hooks.PreToolUse // [] | .[].hooks // [] | .[].command // empty
                | select(endswith("/hooks/no-skip-tests"))' "$SETTINGS")
for cmd in ${stale[@]+"${stale[@]}"}; do echo "prune hook $cmd (file gone)"; done
stale_json="$(printf '%s\n' ${stale[@]+"${stale[@]}"} | jq -R 'select(length > 0)' | jq -s .)"
tmp="$(mktemp "$SETTINGS.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
jq --arg cmd "$HOOK_CMD" --arg matcher "$HOOK_MATCHER" --argjson stale "$stale_json" '
  .hooks.PreToolUse = [(.hooks.PreToolUse // [])[]
                         | .hooks = ((.hooks // []) | map(select(.command as $c | $stale | index($c) | not)))
                         | select(.hooks | length > 0)]
  | if any(.hooks.PreToolUse[].hooks[]; .command == $cmd)
    then .hooks.PreToolUse |= map(if any(.hooks[]; .command == $cmd) then .matcher = $matcher else . end)
    else .hooks.PreToolUse += [{ matcher: $matcher, hooks: [{ type: "command", command: $cmd }] }]
    end
' "$SETTINGS" > "$tmp"
if [[ ! -s "$tmp" ]] || ! jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
  echo "install.sh: merge produced no valid settings; $SETTINGS unchanged" >&2
  exit 1
fi
if cmp -s "$tmp" "$SETTINGS"; then
  echo "ok    hook $HOOK_CMD"
else
  mv "$tmp" "$SETTINGS"
  echo "hook  $HOOK_CMD -> $SETTINGS"
fi

if ! command -v pi >/dev/null; then
  echo "WARN  pi is not on PATH; pi-ask, to-goal, go and /pi need it. See $REPO/docs/pi-setup.md"
fi
