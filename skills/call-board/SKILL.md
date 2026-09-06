---
name: call-board
description: Use when the user asks where work stands, which phase a feature is in, what is pending push/test/merge, or before starting a merge/test round (/call-board). Also for "มีอะไรค้างบ้าง", "สถานะงาน", half-merged checks.
---

# call-board

The board backstage where the whole company sees, at once, who is called and for what. One consolidated status report across every repo in play, cross-referenced with memory. Scan live — never answer from memory alone (memory status rots; the forge is the source of truth).

## Which repos

`.claude/house.md`'s `repos:` list, if the project has one — it may name repos outside the current tree (a sibling workspace), and those count. No list → every git repo at the project root and one level under it:

```bash
find . -maxdepth 2 -name .git -type d | sed 's#/\.git$##'
```

Same for `programs-dir` (default `.claude/programs/`) and `base-branch` (default: the repo's `origin/HEAD`).

## Gather (run all, in parallel where possible)

1. **Open PRs (ของเราเท่านั้น)**: per repo `gh pr list --state open --author "@me" --json number,title,headRefName` — PR ของคนอื่นในทีมไม่ใช่งานเรา ห้ามรายงาน/ห้าม flag เป็น off-radar
2. **Local state**: per repo `git for-each-ref refs/heads --format='%(refname:short) %(upstream:short) %(upstream:track)'` → collect branches with empty upstream (unpushed) or `[gone]`; plus `git status --porcelain` (dirty = work in progress now) and current branch.
3. **Memory**: the in-flight / unresolved-work section of the session's memory index — known parked/local-only items and merge-order notes.
4. Recently merged (for pairing check): `gh pr list --state merged --limit 15 --json number,title,headRefName,mergedAt` per repo that has open PRs or recent activity.
5. **Program maps**: `grep -E '^(program|status|phases|repos|last-touched):' <programs-dir>/*.md` → per-map frontmatter `program / status / phases / repos / last-touched` — นี่คือแหล่งความจริงของ "ฟีเจอร์นี้อยู่ phase ไหน" ไม่ใช่หน่วยความจำ
6. **Handoffs**: `<programs-dir>/*.handoff.md` and `.claude/handoff.md`, written by `interval-call` before a compact. Read each one's frontmatter (`written`, `branch`, `step`, `focus`, `resume-with`) — the `step` line is the position the last context left the feature at, `resume-with` is the skill it expects to be picked up by.
7. **Runtime**: every command under `## Runtime` in `.claude/house.md`, run as written — which commit the running service was built from, migrations pending, ports held by a stale process. Paste each command's raw output; the section's own `expect:` lines say what green looks like. No section → print `runtime: not checked (no ## Runtime in house.md)` — that line is the gap, never silence.

## Group by feature

Match branch names / PR titles across repos (same feature usually shares a branch slug, e.g. `feat/lucky-draw-*` in two repos at once). Assign each feature a phase:

`implementing (dirty/local)` → `unpushed branch` → `PR open` → `awaiting batch test round` → `ready to merge` → `merged`

ฟีเจอร์ที่มี program map ให้ใช้ชื่อ phase ตามลิสต์ `phases` ใน frontmatter ของแมพนั้น แทน phase ทั่วไปด้านบน

## Completeness check (report as ⚠️ warnings)

1. **Half-merged feature**: one repo's PR merged while its counterpart PR (same feature, other repo) is still open or not yet created → name both sides. This is the highest-severity warning — it is the one a status report exists to catch.
2. **Local-only work at risk**: unpushed branches + dirty worktrees not marked PARKED in memory.
3. **Stale program map**: a program map with `status: active` whose `last-touched` is more than 30 days old → flag it.
4. **Project's own warnings**: every rule under `## Extra warnings` in `.claude/house.md`, run as written. A project with none contributes nothing here — that is not a gap.
5. **Stale handoff**: a handoff whose `branch@sha` is not the branch's current HEAD, or older than 7 days — the working tree has moved past it; report both the handoff's `step` and what `git log` shows since, never merge them into one story.
6. **Runtime drift**: a `## Runtime` command whose output misses its `expect:` line — a service on a commit behind the branch, a migration not applied, a port held by something else. Smoke on a phase does not start while this warning stands; `stage-manager` reads it before its smoke step.

## Output format

```
## งานที่กำลังทำ (phase ปัจจุบัน)
<feature> — <phase> — <repos + PR#s>

## ⚠️ Completeness warnings
<numbered, most severe first; "none" if clean>

## PR เปิดที่ไม่อยู่ในเรดาร์
<own open PRs matching no known feature/memory — flag, don't guess; teammate PRs are excluded by --author "@me">

## Local-only
<unpushed branches / dirty repos, with memory notes (PARKED etc.)>

## Handoff
<per file: path · written <date> · step <step line> · branch match ✓ | ⚠️ HEAD moved; or "none">

## Runtime
<one line per ## Runtime command: ✓ or the raw output that missed expect:; or "not checked (no ## Runtime in house.md)">
```

Keep it scannable — no prose paragraphs. After the user acts on it (merge round done), offer to update memory in-flight entries to match.
