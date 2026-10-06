#!/bin/sh
# Fail if skills shared between pi/ and claude/ drift apart (frontmatter ignored).
# para-procedure is intentionally divergent and not compared.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
body() { awk 'BEGIN{n=0} n>=2{print; next} /^---[[:space:]]*$/{n++}' "$1"; }
rc=0
# pi skill : claude skill
for pair in code-review:review-axes debug:debug protocol:protocol; do
  p="$root/pi/skills/${pair%%:*}/SKILL.md"; c="$root/claude/skills/${pair##*:}/SKILL.md"
  for f in "$p" "$c"; do [ -f "$f" ] || { echo "MISSING $f" >&2; rc=1; }; done
  [ -f "$p" ] && [ -f "$c" ] || continue
  if body "$p" | diff -u - "$(body "$c" > "${TMPDIR:-/tmp}/check.$$"; echo "${TMPDIR:-/tmp}/check.$$")" >/dev/null; then
    echo "ok    ${pair%%:*} <-> ${pair##*:}"
  else
    echo "DRIFT ${pair%%:*} <-> ${pair##*:}" >&2; rc=1
  fi
  rm -f "${TMPDIR:-/tmp}/check.$$"
done
exit $rc
