#!/usr/bin/env bash
# handoff-auto.sh — the mechanical half of an interval-call handoff, written by the PreCompact hook.
#
# Runs before every compaction, manual or automatic. Writes the position a script can know —
# branch@sha, dirty and unpushed counts, git status/log, the paths of the map, plan, drift log and
# questions file — to <programs-dir>/<program>.handoff.auto.md for every active program map, or to
# .claude/handoff.auto.md when no map is active. Never commits, never touches anything else.
# The judgement half (ค้างเคาะ, ทำต่อ) is still interval-call's, by hand.
#
# stdin: the hook's JSON (trigger: manual|auto). cwd: the project directory.
set -u

trigger=$(sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' 2>/dev/null | head -1)
trigger=${trigger:-unknown}

find_house() {
  local d; d=$(pwd -P)
  while :; do
    [ -f "$d/.claude/house.md" ] && { printf '%s\n' "$d/.claude/house.md"; return; }
    [ "$d" = / ] && return
    d=$(dirname "$d")
  done
}
house=$(find_house)
root=${house:+$(dirname "$(dirname "$house")")}
root=${root:-$(pwd -P)}
key() { [ -n "$house" ] && sed -n "s/^$1:[[:space:]]*//p" "$house" 2>/dev/null | head -1; }

base=$(key base-branch | tr -d '[:space:]')
programs=$(key programs-dir | tr -d '[:space:]'); programs=${programs:-.claude/programs}
repos=$(key repos | tr -d '[]' | tr ',' ' ')
[ -z "$repos" ] && repos=.

now=$(date '+%Y-%m-%d %H:%M')

repo_block() { # repo_block <dir>
  local r="$1" b sha dirty unpushed rbase
  git -C "$r" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '%s: not a git repo\n' "$r"; return; }
  b=$(git -C "$r" branch --show-current 2>/dev/null)
  sha=$(git -C "$r" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$r" status --porcelain 2>/dev/null | grep -c . || true)
  rbase=${base:-$(git -C "$r" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}
  rbase=${rbase:-main}
  unpushed=$(git -C "$r" rev-list --count "origin/$rbase..HEAD" 2>/dev/null || echo '?')
  printf '### %s\nbranch: %s@%s · dirty %s files · unpushed %s commits vs origin/%s\n' "$r" "${b:-?}" "${sha:-?}" "$dirty" "$unpushed" "$rbase"
  printf '```\n$ git status --short\n'; git -C "$r" status --short 2>/dev/null | head -40
  printf '\n$ git log --oneline origin/%s..HEAD\n' "$rbase"; git -C "$r" log --oneline "origin/$rbase..HEAD" 2>/dev/null | head -20
  printf '```\n'
}

write_handoff() { # write_handoff <path> <feature> <map-or-empty>
  local out="$1" feature="$2" map="$3" dir
  dir=$(dirname "$out"); mkdir -p "$dir" 2>/dev/null || return
  {
    printf -- '---\nfeature: %s\nwritten: %s\nwritten-by: PreCompact hook (%s) — mechanical; ค้างเคาะ/ทำต่อ need interval-call\n' "$feature" "$now" "$trigger"
    if [ -n "$map" ]; then
      printf 'map: %s\n' "$map"
      sed -n 's/^phases:[[:space:]]*/phases: /p; s/^last-touched:[[:space:]]*/last-touched: /p' "$map"
      for f in "$dir/$feature.drift.md" "$dir/$feature.questions.md" "$dir/$feature.handoff.md"; do
        [ -f "$f" ] && printf '%s: %s\n' "$(basename "$f" .md | sed "s/^$feature\.//")" "$f"
      done
      ls "$root"/docs/superpowers/plans/*"$feature"* 2>/dev/null | head -3 | sed 's/^/plan: /'
    fi
    printf -- '---\n## เพิ่งทำ\n'
    for r in $repos; do repo_block "$root/$r"; done
  } > "$out"
  printf 'handoff-auto → %s\n' "$out"
}

wrote=0
if [ -d "$root/$programs" ]; then
  for map in "$root/$programs"/*.md; do
    [ -f "$map" ] || continue
    grep -q '^status:[[:space:]]*active' "$map" || continue
    prog=$(sed -n 's/^program:[[:space:]]*//p' "$map" | head -1 | tr -d '[:space:]')
    [ -n "$prog" ] || continue
    write_handoff "$root/$programs/$prog.handoff.auto.md" "$prog" "$map"
    wrote=1
  done
fi
if [ "$wrote" -eq 0 ]; then write_handoff "$root/.claude/handoff.auto.md" lean ""; else rm -f "$root/.claude/handoff.auto.md"; fi
exit 0
