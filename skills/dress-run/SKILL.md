---
name: dress-run
description: Use when reviewing a diff for craft quality — code smell, dirty code, over-engineering, comment noise, branch shape, edge cases, performance regressions leaked through shared functions, and blast radius. Runs alongside /code-review at the review step. Also for "รีวิวโค้ด", "โค้ดสะอาดมั้ย", "ตรวจ style", "code smell", "over-engineer", "เช็ค performance".
---

# dress-run

Full dress rehearsal: the run where you stop asking whether it works and start asking whether it holds up. `/code-review` catches correctness bugs, a spec pass catches spec gaps — this catches **craft**: code that works but is dirty, over-built, over-commented, or quietly expensive.

You are READ-ONLY until the report is delivered. Never edit, never run a global formatter, never touch code outside the diff. Fix only after the user picks findings.

## 1. Scope

The argument is a repo (default: current) plus a free-text description of the work. There are no sub-commands — anything else in the argument is context, not a mode.

Resolve the base branch once, then get the diff yourself. Always pass `-M` so a renamed file reads as a rename instead of a whole-file delete + add:

```bash
base=$(sed -n 's/^base-branch: *//p' .claude/house.md 2>/dev/null)
base=${base:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}
base=${base:-main}

git diff -M HEAD --stat && git diff -M HEAD          # uncommitted (plain `git diff` misses what is staged)
git diff -M "origin/$base...HEAD"                    # branch work, already committed
```

Always `origin/$base`, never the bare local branch — the local one goes stale and you would review the wrong range with no sign anything was off.

Read every **newly added file in full**, not just as diff lines — a new file has no surrounding context to judge it against otherwise.

**Pick packs by file extension present in the diff.** Every pack whose extensions appear runs, on top of the universal groups below:

| Extension in diff | Pack |
|---|---|
| `*.go` | `packs/go.md` |
| `*.ts *.tsx *.js *.jsx` | `packs/react.md` |

No pack matches the language in front of you → the universal groups still run in full, and say so in the report's opening line. A project adds its own rows — component names, entity names, layer contracts — under `## Review additions` in `.claude/house.md`; read it if present and fold its rows into the matching group.

**Mode:** count the range you just picked, whichever it was:

```bash
git diff -M --numstat <range> | awk '{a+=$1;b+=$2} END{print a+b}'   # <range> = HEAD | origin/$base...HEAD
```

Not `grep -cE '^[-+]'` — the `--- a/…` and `+++ b/…` headers match it too and inflate the count by 2 per file. ≤ 300 → walk the checklist inline. > 300 → dispatch one reviewer subagent per pack (**Opus, never Sonnet/Haiku**) with that pack's checklist + the diff, then merge their findings. Say which mode you picked.

**Under `notes-call` this file is a checklist, not a dispatch.** `notes-call` runs one reviewer per chunk — you, inline, or one Opus subagent for a fan-out chunk — and that reviewer walks the groups and packs below **and** the correctness bar `/code-review` sets, in one pass. The invocation says "this is a `notes-call` chunk, review it inline, no self-escalation": the 300-line rule above is off for that chunk, and splitting it again is the one thing not to do. The reviewer's first output is `ledger.sh -- <files>` run on the chunk, unedited — `notes-call`'s §7.1 says what to do with it. Called on a whole diff with no such line, the 300-line rule applies as normal.

## 2. Universal groups

Every group is a pass over the diff. A group with nothing to say gets no output. These run in every language; the packs add to them, never replace them.

### G3 — comment noise
- doc comment on an exported type, DTO, validator, or helper that only restates the name (`// FooRequest - API body request for ...`, `// ValidateCanX validates that X`)
- multi-line / multi-paragraph comment block
- narration of WHAT (`// Build updates map`, `// Get user ID from context`)
- `// added for X`, `// used by Y`, `// fixes #N`

Keep a one-line non-obvious WHY (hidden invariant, surprising divergence from a sibling, bug workaround). A **multi-line** comment survives only when every line is WHY and no single line can carry it — say so instead of flagging it.

**Report G3 as one finding per file with a count**, listing the line numbers: `[G3] path/file.go — 4 comment blocks to trim (11, 32, 63, 98)`. G3 never leads the report; it is the last section. If G3 would be more than half the findings, that is the signal that the rest of the review was thin — go back and look harder at G6/G7/G8 before reporting — and if there is still nothing, report G3 alone and say the rest was clean. "Nothing found" is an allowed answer; a padded G6 is not.

### G3.5 — branch shape
ทางออกของ logic เดียวกันถูกเขียนคนละระดับ จน fast-screen แล้วไม่รู้ว่าเข้าทางไหน

- `if/else` ที่ครอบ `switch` ไว้ — คนอ่านต้องถือ "ตอนนี้อยู่ใน else" ไว้ในหัวตลอดที่ไล่ case
- เงื่อนไขชุดเดียวกันเขียนสลับรูป (`if` / `switch` / early return) ในฟังก์ชันเดียว
- `if` ซ้อน `if` เพื่อกันเคสเดียว ทั้งที่ยกเป็น guard หรือ helper ที่คืนค่าว่างได้
- แขนของ branch ยาวไม่เท่ากันมาก — อันหนึ่ง log บรรทัดเดียว อีกอันทำงาน 8 บรรทัด

ที่ควรเป็น: **ทางออกทุกทางอยู่ระดับเดียวกัน** — flat switch อันเดียว
แต่ละแขนสั้นและเรียกสิ่งที่มีชื่อ (`row.MarkFailed(at, reason)`) ไม่ใช่ทำงานเองคาที่
เงื่อนไขที่ตัดจบได้ก่อนให้เป็น guard + early return ข้างบน อย่าเก็บไว้เป็น `else` ข้างล่าง

รายงานเป็น 1 finding ต่อฟังก์ชัน ระบุชื่อฟังก์ชันและจำนวนทางออกที่นับได้ · ข้อนี้อยู่กลุ่ม
"costs the next reader" เท่ากับ G1/G2/G4/G5 ไม่ใช่ G3

### G4 — over-engineering
- interface / generic / config option / abstraction with exactly one caller or one implementation today
- helper used once where inlining reads better
- indirection added "for later"

### G5 — dirty code
Dead code, unused vars, names that don't say what they hold, deep nesting an early return would flatten, duplicated block, magic number, a swallowed error, inconsistent naming vs the sibling file.

### G6 — edge cases
Language-independent rows; the packs add the ones that only exist in their language:
- a newly read nullable/optional value dereferenced without a check
- equality on a type whose identity is not its value (money, decimals, wrapped IDs)
- zero-value / empty-collection / zero-quantity path unhandled
- an external call, upload, or event emit inside a transaction body (must be after commit)
- an error returned bare where the layer's contract is a typed error

### G7 — blast radius
- a new field reaching the API: is it declared on the **response type** the handler actually serialises? A mapper, a preload, or a copy helper alone silently drops it.
- changed DTO / event payload / DB column: name who else reads it — `.claude/house.md`'s `## Known consumers` lists the ones this project already knows about — and whether the diff accounted for them.

### G8 — performance
Two passes.

**Local cost** — in the diff itself:
- DB or network call inside a loop → batch it
- N+1 that a join or eager-load removes
- new hot filter column with no index
- full-row fetch where a projection would do
- repeated recomputation inside a loop that is loop-invariant

**Shared-function amplification** — the expensive one. If the diff changes a function, repository method, eager-load chain, or middleware that has more than one caller:

```bash
git grep -n "FuncName(" -- . ':(exclude)vendor' ':(exclude)node_modules' ':(exclude)mocks'
```

If the changed symbol lives in a shared module or library this project publishes to its siblings, callers live in **other repos** — grep the whole tree those repos sit in (`.claude/house.md`'s `## Shared modules` names them and their downstreams where a project has any). Generated mocks are not callers — excluding them keeps the caller count reflecting real traffic.

For each caller ask: does the new cost (extra eager-load, extra query, extra loop, larger payload) apply to it, and is it on a hot path? `house.md`'s `## Hot paths` names this project's; with no list, treat request-per-user paths and anything a poll or webhook drives as hot. A convenience load added for one caller that fires on every fetch is a finding — name the callers it hits.

## 3. Report

One line per finding, ordered by what it costs the product — not by group number:

1. **Costs money, data, or a customer** — G6 edge cases, G7 blast radius
2. **Costs latency on a hot path** — G8
3. **Costs the next reader** — G1, G2, G3.5, G4, G5
4. **G3 last**, one line per file

```
[G8] internal/repository/order.go:88 — Preload("Items.Condiments") added to FindOne — hits 6 callers incl. terminal sync poll; +1 query per order fetch
[G4] internal/service/order.go:212 — PriceStrategy interface has a single implementation — indirection with no second caller; inline the func
[G3] internal/service/order.go — 3 comment blocks to trim (88, 140, 212)
```

**Cap: 12 findings.** Past that, report the 12 that matter and add one line: `+N more, mostly <group>`. A 30-item list is a list nobody acts on.

Two conventions worth using when they apply:

- **fix both or neither** — when the same smell already exists in the sibling code the diff did not touch, say so on the finding. Fixing one half makes the file less consistent, not more.
- **verified clean** — a short closing list of what you checked and found sound (contract matches the producer, the new field does reach the response type, the shared function's other callers are unaffected). It tells the reader which risks are already covered, and it is the only part of the report that earns trust in the silence.

End with `VERDICT: pass` or `VERDICT: N findings`.

No summary of what the diff does — the main session already knows. Never print an empty group heading; a group with no finding adds no line to the list — but the verified-clean list above may still name what it checked.

**After the report, STOP.** Do not fix anything, do not open files to prepare a fix, do not offer a patch — the user picks first. This holds even when a finding looks trivial.
