# shellcheck shell=sh
# Shared by install.sh and doctor.sh. Source after setting $root (this repo).
# targets() is the single list of symlinks this repo owns: install creates
# them, doctor verifies them, and anything else pointing into the repo is stale.
pa="$HOME/.pi/agent"
cl="$HOME/.claude"
tab="$(printf '\t')"

# fm_name <file>: the frontmatter `name:` value.
fm_name() { awk '/^---/{n++; next} n==1 && /^name:/{sub(/^name:[ \t]*/,""); print; exit}' "$1"; }

# targets <pi|claude|all>: one "src<TAB>dst" line per owned symlink.
targets() {
  if [ "$1" != claude ]; then
    printf '%s\t%s\n' "$root/pi/APPEND_SYSTEM.md" "$pa/APPEND_SYSTEM.md" \
      "$root/pi/settings.json" "$pa/settings.json" \
      "$root/shared/CORE.md" "$pa/AGENTS.md"
    for d in "$root"/shared/skills/*/ "$root"/pi/skills/*/; do
      [ -d "$d" ] && printf '%s\t%s\n' "${d%/}" "$pa/skills/$(basename "$d")"
    done
    for f in "$root"/pi/agents/*.md; do
      [ -f "$f" ] && printf '%s\t%s\n' "$f" "$pa/agents/$(basename "$f")"
    done
  fi
  if [ "$1" != pi ]; then
    printf '%s\t%s\n' "$root/claude/CLAUDE.md" "$cl/CLAUDE.md"
    for d in "$root"/shared/skills/*/ "$root"/claude/skills/*/; do
      [ -d "$d" ] && printf '%s\t%s\n' "${d%/}" "$cl/skills/$(basename "$d")"
    done
    for f in "$root"/claude/agents/*.md; do
      [ -f "$f" ] && printf '%s\t%s\n' "$f" "$cl/agents/$(basename "$f")"
    done
  fi
  return 0
}

# stray_links <pi|claude|all>: links in the managed dirs that targets() doesn't
# own. Prints "stale<TAB>link" (points into this repo) or "dangling<TAB>link"
# (foreign and broken, e.g. a third-party skill whose install is gone).
stray_links() {
  want="$(targets "$1" | cut -f2)"
  dirs=""
  [ "$1" = claude ] || dirs="$pa/skills $pa/agents $pa/extensions"
  [ "$1" = pi ] || dirs="$dirs $cl/skills $cl/agents"
  for dir in $dirs; do
    for l in "$dir"/* "$dir"/.[!.]*; do
      [ -L "$l" ] || continue
      case "$(readlink "$l")" in
        "$root"/*) printf '%s\n' "$want" | grep -Fxq "$l" || printf 'stale\t%s\n' "$l" ;;
        *) [ -e "$l" ] || printf 'dangling\t%s\n' "$l" ;;
      esac
    done
  done
}
