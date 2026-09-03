#!/usr/bin/env bash
# handoff-list.sh — run by the SessionStart hook with matcher "compact", after a compaction.
# Prints one line per handoff file found, so the fresh context knows they exist; the harness
# summary does not promise to mention them. Silent when there is nothing to list.
set -u

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
programs=$( [ -n "$house" ] && sed -n 's/^programs-dir:[[:space:]]*//p' "$house" | head -1 | tr -d '[:space:]' )
programs=${programs:-.claude/programs}

age() { # minutes since the file's mtime
  local m; m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || { echo '?'; return; }
  echo $(( ( $(date +%s) - m ) / 60 ))
}

found=""
for f in "$root/$programs"/*.handoff.md "$root/$programs"/*.handoff.auto.md "$root/.claude/handoff.md" "$root/.claude/handoff.auto.md"; do
  [ -f "$f" ] || continue
  step=$(sed -n 's/^step:[[:space:]]*//p' "$f" | head -1)
  found="$found- $f · ${step:-mechanical only} · $(age "$f") min ago
"
done

[ -z "$found" ] && exit 0
printf 'handoff files written before this compact — read them before continuing; `/call-board` lists them with their branch check:\n%s' "$found"
exit 0
