#!/usr/bin/env bash
# ledger.sh — the coverage ledger notes-call reads, built by a script instead of a writer.
#
#   bash ledger.sh                 whole review range: working tree vs merge-base with the base branch
#   bash ledger.sh -- <file>...    one fan-out chunk: only these files
#   bash ledger.sh -C <repo> ...   run against that repo (when the cwd is a workspace root above it)
#
# Reads the nearest .claude/house.md walking up from the cwd — the project root may sit above
# several git repos, so the repo root is not where it is looked for. HOUSE_MD=<path> overrides.
#   base-branch:          default origin/HEAD, else main
#   review-floor-lines:   150   at or under this (and <= 5 files) the review collapses to the floor
#   review-fanout-lines:  800   above this (or > 15 files) the review fans out into chunks
#   review-chunk-lines:   400   most lines one chunk may hold
#   review-max-chunks:    unset a fan-out needing more chunks than this prints OVER BUDGET
#
# Output, in order: LEDGER line · MODE line · one block per changed file (numstat, hunk ranges,
# then every symbol the file declares or re-declares, with its repo-wide hit count and the hits
# that sit outside the diff listed first). Nothing here is the writer's word: rerun it to check it.
set -u

if [ "${1:-}" = "-C" ]; then cd "${2:?-C needs a directory}" || exit 1; shift 2; fi

find_house() {
  local d; d=$(pwd -P)
  while :; do
    [ -f "$d/.claude/house.md" ] && { printf '%s\n' "$d/.claude/house.md"; return; }
    [ "$d" = / ] && return
    d=$(dirname "$d")
  done
}
house=${HOUSE_MD:-$(find_house)}
[ -n "$house" ] && [ ! -f "$house" ] && house=""
key() { [ -n "$house" ] && sed -n "s/^$1:[[:space:]]*//p" "$house" 2>/dev/null | head -1 | tr -d '[:space:]'; }

base=$(key base-branch)
base=${base:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}
base=${base:-main}
floor_lines=$(key review-floor-lines);   floor_lines=${floor_lines:-150}
fanout_lines=$(key review-fanout-lines); fanout_lines=${fanout_lines:-800}
chunk_lines=$(key review-chunk-lines);   chunk_lines=${chunk_lines:-400}
max_chunks=$(key review-max-chunks)
floor_files=5
fanout_files=15
paste_cap=8
sym_cap=80

scope=()
if [ "${1:-}" = "--" ]; then shift; scope=("$@"); fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "FAIL not inside a git repo — cd into the repo or pass -C <repo>"; exit 1; }
cd "$root" || exit 1

git fetch -q origin 2>/dev/null || echo "WARN fetch origin failed — base may be stale"
mb=$(git merge-base "origin/$base" HEAD 2>/dev/null) || { echo "FAIL no merge-base between origin/$base and HEAD — set base-branch: in $house"; exit 1; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/ledger.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# ---- numstat: tracked changes vs merge-base, plus untracked files as pure additions ----------
git diff -M --numstat "$mb" -- ${scope[@]+"${scope[@]}"} > "$tmp/numstat"
git ls-files --others --exclude-standard -- ${scope[@]+"${scope[@]}"} > "$tmp/untracked"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  n=$(wc -l < "$f" | tr -d ' ')
  printf '%s\t0\t%s\n' "$n" "$f"
done < "$tmp/untracked" >> "$tmp/numstat"

if [ ! -s "$tmp/numstat" ]; then
  echo "LEDGER  base origin/$base@$(git rev-parse --short "$mb") · 0 files · 0 lines · house ${house:-none}"
  echo "MODE    nothing to review"
  exit 0
fi

# ---- hunks (new-side ranges) from a zero-context diff -------------------------------------
git diff -M -U0 "$mb" -- ${scope[@]+"${scope[@]}"} > "$tmp/diff"
awk '
  /^\+\+\+ / { path = $2; sub(/^b\//, "", path); if (path == "/dev/null") path = ""; next }
  /^@@ / && path != "" {
    split($3, a, ","); start = substr(a[1], 2) + 0; len = (a[2] == "" ? 1 : a[2] + 0)
    end = (len == 0 ? start : start + len - 1)
    print path "\t" start "\t" end
  }
' "$tmp/diff" > "$tmp/hunks"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  printf '%s\t1\t%s\n' "$f" "$(wc -l < "$f" | tr -d ' ')"
done < "$tmp/untracked" >> "$tmp/hunks"

# ---- declared / re-declared symbols, per file ----------------------------------------------
# One awk for both the diff (+/- lines) and whole untracked files (every line).
decl_awk='
  function strip_mods(s) {
    while (match(s, /^(export|default|pub|pub\([a-z]+\)|async|static|public|private|protected|abstract|readonly|override|final|unsafe|extern|declare|inline)[ \t]+/))
      s = substr(s, RLENGTH + 1)
    return s
  }
  function emit(path, raw,   col0, s, kw, rest, sym, up) {
    col0 = (raw !~ /^[ \t]/)
    s = raw; sub(/^[ \t]+/, "", s)
    s = strip_mods(s)
    sym = ""
    if (match(s, /^(func|function|def|class|type|interface|enum|struct|trait|fun|fn|impl|const|let|var|val)[ \t]+/)) {
      kw = substr(s, 1, RLENGTH); gsub(/[ \t]+$/, "", kw)
      rest = substr(s, RLENGTH + 1)
      if (kw ~ /^(const|let|var|val)$/ && !col0) return
      if (rest ~ /^\(/) sub(/^\([^)]*\)[ \t]*/, "", rest)          # Go receiver
      if (match(rest, /^[A-Za-z_][A-Za-z0-9_]*/)) sym = substr(rest, 1, RLENGTH)
    } else {
      up = toupper(s)
      if (match(up, /^(CREATE|ALTER|DROP)[ \t]+(UNIQUE[ \t]+|OR[ \t]+REPLACE[ \t]+)?(TABLE|INDEX|TYPE|VIEW|FUNCTION|TRIGGER|SEQUENCE|MATERIALIZED[ \t]+VIEW)[ \t]+/)) {
        rest = substr(s, RLENGTH + 1)
        if (match(toupper(rest), /^IF[ \t]+(NOT[ \t]+)?EXISTS[ \t]+/)) rest = substr(rest, RLENGTH + 1)
        gsub(/["`]/, "", rest)
        if (match(rest, /^[A-Za-z_][A-Za-z0-9_.]*/)) { sym = substr(rest, 1, RLENGTH); sub(/^.*\./, "", sym) }
      }
    }
    if (sym == "" && col0 && match(s, /^[A-Z_][A-Z0-9_]*[ \t]*[:=]/) && substr(s, RLENGTH + 1, 1) != "=") {
      sym = s; sub(/[ \t]*[:=].*$/, "", sym)                       # NAME = ... / NAME: Final = ... at column 0
    }
    if (sym == "" || length(sym) < 3) return
    print path "\t" sym
  }
'
awk "$decl_awk"'
  /^\+\+\+ / { path = $2; sub(/^b\//, "", path); if (path == "/dev/null") path = ""; next }
  /^--- /    { next }
  /^[-+]/ && path != "" { emit(path, substr($0, 2)) }
' "$tmp/diff" > "$tmp/syms"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  awk -v p="$f" "$decl_awk"' { emit(p, $0) }' "$f"
done < "$tmp/untracked" >> "$tmp/syms"
sort -u "$tmp/syms" -o "$tmp/syms"

# ---- header ---------------------------------------------------------------------------------
# Prose (.md .txt .rst .adoc) is listed in the ledger like any file but does not size the review:
# MODE, DIRS and the chunk cap read code lines only. Hit counts are never filtered.
prose='\.(md|markdown|txt|rst|adoc)$'
read -r files lines added removed code_files code_lines prose_lines < <(awk -v prosere="$prose" '{
  a = ($1 == "-" ? 0 : $1); d = ($2 == "-" ? 0 : $2); n++; add += a; del += d
  if ($3 ~ prosere) pl += a + d; else { cn++; cl += a + d }
} END { print n+0, add+del, add+0, del+0, cn+0, cl+0, pl+0 }' "$tmp/numstat")
untracked=$(grep -c . "$tmp/untracked" 2>/dev/null || true)
symcount=$(wc -l < "$tmp/syms" | tr -d ' ')

echo "LEDGER  base origin/$base@$(git rev-parse --short "$mb") · $files files · $lines lines (+$added/-$removed · $code_lines code · $prose_lines prose) · $untracked untracked · $symcount symbols · house ${house:-none}"
[ "$symcount" -gt "$sym_cap" ] && echo "WARN    $symcount symbols is past $sym_cap — a generated file is probably in the range; review it as a chunk of its own"
if [ "${#scope[@]}" -gt 0 ]; then
  line="MODE    chunk · ${#scope[@]} files · $code_lines code lines vs cap $chunk_lines"
  [ "$code_lines" -gt "$chunk_lines" ] && line="$line · OVER CAP $code_lines > $chunk_lines — split this chunk before dispatching"
  echo "$line"
elif [ "$code_lines" -le "$floor_lines" ] && [ "$code_files" -le "$floor_files" ]; then
  echo "MODE    floor · ≤$floor_lines code lines and ≤$floor_files code files"
elif [ "$code_lines" -gt "$fanout_lines" ] || [ "$code_files" -gt "$fanout_files" ]; then
  chunks=$(( (code_lines + chunk_lines - 1) / chunk_lines ))
  line="MODE    fan-out · $chunks chunks of ≤$chunk_lines lines"
  if [ -n "$max_chunks" ] && [ "$chunks" -gt "$max_chunks" ]; then
    line="$line · OVER BUDGET $chunks > review-max-chunks $max_chunks — stop and ask before dispatching"
  fi
  echo "$line"
  awk -v prosere="$prose" '$3 !~ prosere { a = ($1 == "-" ? 0 : $1); d = ($2 == "-" ? 0 : $2); p = $3; sub(/\/[^\/]*$/, "", p); if (p == $3) p = "."; t[p] += a + d }
       END { for (p in t) printf "  %6d  %s\n", t[p], p }' "$tmp/numstat" | sort -rn | { echo "DIRS    code lines per directory, to cut chunks along"; cat; }
else
  echo "MODE    inline · floor $floor_lines · fan-out $fanout_lines"
fi

# ---- per-file blocks ------------------------------------------------------------------------
excl='(^|/)(vendor|node_modules|dist|build|testdata|mocks|__snapshots__|\.next|target)/|\.(lock|sum|snap|min\.js|min\.css|pb\.go|gen\.go|gen\.ts)$|_gen\.go$|_generated\.'
while IFS=$'\t' read -r add del f; do
  hunks=$(awk -F'\t' -v f="$f" '$1 == f { printf "%s%d-%d", (n++ ? " " : ""), $2, $3 }' "$tmp/hunks")
  tag=""
  grep -qxF "$f" "$tmp/untracked" && tag=" · untracked"
  [ "$add" = "-" ] && tag=" · binary"
  echo
  echo "$f   +$add/-$del   hunks ${hunks:-—}$tag"
  awk -F'\t' -v f="$f" '$1 == f { print $2 }' "$tmp/syms" | while IFS= read -r sym; do
    git grep -n -w --untracked -e "$sym" -- . > "$tmp/hits" 2>/dev/null
    total=$(grep -c . "$tmp/hits" 2>/dev/null || true)
    # classify each hit: outside the diff unless its path:line falls in a hunk (untracked files are wholly in-diff)
    awk -F: -v hunkfile="$tmp/hunks" -v exclre="$excl" -v prosere="$prose" '
      BEGIN { while ((getline l < hunkfile) > 0) { split(l, h, "\t"); ranges[h[1]] = ranges[h[1]] " " h[2] "-" h[3] } }
      {
        p = $1; ln = $2 + 0; in_diff = 0
        n = split(ranges[p], r, " ")
        for (i = 1; i <= n; i++) if (r[i] != "") { split(r[i], se, "-"); if (ln >= se[1] + 0 && ln <= se[2] + 0) { in_diff = 1; break } }
        if (in_diff) { inside++; next }
        outside++
        if (p ~ exclre) { hidden++; next }
        if (p ~ prosere) { odocs++; if (ndoc < cap) doc[++ndoc] = $0; next }
        ocode++; if (ncode < cap) code[++ncode] = $0
      }
      END {
        # code hits first, then docs, both under one cap — a lead in code outranks a mention in prose
        for (i = 1; i <= ncode && shown < cap; i++) { print "    " code[i]; shown++ }
        for (i = 1; i <= ndoc && shown < cap; i++)  { print "    " doc[i]; shown++ }
        printf "  %-28s %d hits · %d outside diff", SYM, inside + outside, outside > "/dev/stderr"
        if (outside) printf " (%d code · %d docs)", ocode, odocs > "/dev/stderr"
        if (hidden) printf " · %d in excluded paths", hidden > "/dev/stderr"
        if (ocode + odocs > shown) printf " · %d of %d shown", shown, ocode + odocs > "/dev/stderr"
        printf "\n" > "/dev/stderr" }
    ' SYM="$sym" cap="$paste_cap" "$tmp/hits" 2>"$tmp/line" > "$tmp/body"
    cat "$tmp/line" "$tmp/body"
  done
done < <(awk -F'\t' '{ print $1 "\t" $2 "\t" $3 }' "$tmp/numstat")
