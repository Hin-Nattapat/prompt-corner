---
name: notes-call
description: Use when an implementation chunk is finished and needs reviewing before commits are grouped — accounts for every changed hunk, then sorts each finding into a fix it makes itself, a call only the owner can make, or a structural break it escalates. Triggers on "รีวิว", "เช็คให้หน่อย", "implement เสร็จแล้ว", "ตรวจ diff", "review the diff". Small diffs collapse to a few lines.
---

# notes-call

The session after the run where every note is given: what was missed, who fixes it, what waits for a decision.

Fires at the end of a finished chunk, before commits are grouped, or on "review", "check it", "done implementing". It replaces whatever single review step the project's default flow names. A **chunk** is a unit that builds on its own: lean work → the whole task; under a program map → one phase, or the step-group the plan split out. A phase that crosses the fan-out line mid-way is reviewed as chunks as that happens, not held to one call at the end.

## §7.0 Measure — the script, never by hand

`assets/ledger.sh` ships beside this file; the "Base directory for this skill" line above says where. Run it from anywhere inside the repo:

```bash
bash "<skill-dir>/assets/ledger.sh"                 # the whole review range
bash "<skill-dir>/assets/ledger.sh" -- <file>...    # one fan-out chunk
```

It fetches, resolves the base branch, measures the working tree against the merge-base — committed, staged, unstaged and untracked in one range — and prints three things: a `LEDGER` line (files, lines, untracked, symbols), a `MODE` line, and one block per changed file. Thresholds come from `.claude/house.md` frontmatter; every key is optional:

| key | default | effect |
|---|---|---|
| `base-branch` | `origin/HEAD`, else `main` | the branch the merge-base is taken against |
| `review-floor-lines` | 150 | at or under this, and ≤ 5 files → `floor` |
| `review-fanout-lines` | 800 | above this, or > 15 files → `fan-out` |
| `review-chunk-lines` | 400 | most lines one chunk may hold |
| `review-max-chunks` | none | more chunks than this → the `MODE` line says `OVER BUDGET`; stop and ask the user before dispatching anything |

`FAIL` on the first line → paste it and stop; do not measure around it with your own `git diff`. Every number below reads the script's output, never a range you picked.

**`MODE floor`** → no ledger table, no grid, no fixed report. Read the diff, run §7.2's two passes yourself, report in a few lines. §7.3's bins, §7.5's never-list and the smoke handoff still apply.

## §7.1 Coverage ledger — above the floor

The script's output **is** the ledger: one block per file with its `+/-`, its hunk ranges, and every symbol the hunks declare or re-declare, each with its repo-wide hit count and the hits that sit **outside the diff** listed first. It is not the writer's word about their own reading, so nobody re-runs rows to check it — anyone who doubts it re-runs the script. Paste it whole, unedited; §7.5 says where it sits.

Two things the script cannot do are yours:

1. **Read every listed file at its hunk ranges**, and the whole of every `untracked` file — a new file has no surrounding context to judge it against.
2. **Add the declarations the regex misses** — names inside a grouped Go `const (`/`var (`/`type (` block, class methods, anything the language spells without a keyword the script knows. Each gets one line in the same shape, produced by the same command the script uses:

   ```bash
   git grep -n -w --untracked -e <sym> -- .
   ```

   appended under the file's block as `+ <sym>  <N> hits · <k> outside diff`. Count them on the report's `เพิ่มมือ` field. Zero is a normal answer.

Every symbol with outside-diff hits is a lead, not a finding: open each hit and decide whether that caller is still right after this change. That is where the ledger earns its cost. A symbol with `0 outside diff` needs nothing further.

## §7.2 Review — two passes, one reviewer

- **Spec** — inline, in this session. A grid with one row per **task in the phase's plan** (the list `writing-plans` already wrote), or per item in the brief's change-list for lean work: `task → file:line in this diff that satisfies it`, or `❌ absent`. Do not re-derive spec coverage — `writing-plans`' self-review settled plan-versus-spec when the plan was written; this grid settles diff-versus-plan. A task with no diff line is a finding. A changed file that neither a task nor the plan's own file list names is scope drift and a finding. No grid attached means this pass did not run.
- **Code** — craft and correctness in **one pass by one reviewer**: `dress-run`'s groups and packs for craft, `/code-review`'s bar for correctness. `MODE inline` → you, one pass. `MODE fan-out` → one subagent per chunk with `model: opus` set **on the call** (an agent file with no `model:` key silently inherits the main session's tier), carrying: the chunk's file list · the instruction to run `ledger.sh -- <files>` and return its output first · `dress-run`'s groups plus the packs the chunk's extensions pick · the line "this is a `notes-call` chunk, review it inline, no self-escalation". Never dispatch `dress-run` and `/code-review` as two agents on the same chunk. A chunk that returns without ledger output is rerun, not accepted.
- `/code-review high` or `max` as a **separate** call only for a migration, cross-service work, or a multi-layer diff — also with `model: opus` on the call.

## §7.3 Classify every finding — three bins

Check in this order; the first bin that fits wins.

**B — structural** if any one of these holds. Same seven criteria `curtain-hold` runs:

- **C1** — violates a program map §1 rule, or falsifies a metric that rule declares
- **C2** — changes a program map §3 contract
- **C3** — the consumer lives outside the repo you're editing
- **C4** — requires editing more than one repo, or more than one phase
- **C5** — creates a second source of truth
- **C6** — makes the Flow Summary's blast-radius or won't-touch section false
- **C7** — collides with a map §4 premise marked 🔒 or ❓ — only the user can settle it

→ Hand to `curtain-hold`: the fact pinned to `file:line`, the criterion as `C<n>` for its `เข้าเกณฑ์ข้อ` field, entry point **E1** — an escalation from here is always under a plan the user already confirmed, never E2.

**A — code fix** if the written plan, brief or map says X, the code does not do X, and doing X stays inside the files the plan or brief names. An undocumented premise that only this repo consumes and trips none of C1–C7 is also A: fix it, note one line under the Flow Summary's UNVERIFIED section or the map's drift log — neither exists → the note is the `lean-A` bullet itself — and count it on `lean-A`.

**O — owner call** for everything left. The observable test: **the code already achieves the task's outcome, by a route the plan did not name** — a bulk operation routed through the existing mutation hook instead of the endpoint the plan named, a count taken from the rows returned instead of a second query. The honest resolution may be the plan's sentence, not the code. (A task the code does not achieve at all, or achieves wrongly, is A, not O.) Also here: a fix that would leave the plan's named files but trips no C-criterion. Do not fix it, do not escalate it. One line in the drift log or under UNVERIFIED, one bullet on the report's `รอเจ้าของเคาะ` line, and the chunk's STOP is where the user decides. `curtain-hold` is for B only — pulling it for an O finding makes a one-sentence plan edit look like a structural stop.

## §7.4 Type-A loop — cap 3 rounds

1. Fix — only files the plan or brief names. Stepping outside that scope turns the finding into O or B.
2. Build/typecheck passes — **paste the command and its raw output**: the command's own stdout/stderr and exit code, not a wrapper's summary of it. A token-filtering proxy that prints "no issues" over a non-zero exit is the attestation this line exists to forbid; bypass it for this one command. A bare "passes" is an attestation with no artifact.
3. Re-review only the files touched this round, then run C1–C7 **against the fix's own diff** — a fix inside a plan-listed file can still add a field six out-of-repo callers read.
4. Commit the round on the feature branch as `fix: review round <n>`. The git tail groups and squashes it later; a round left uncommitted is the one that has to be untangled from the whole branch afterwards. Never push.

Each round appends one line above the report block; no line means the re-check did not happen:

```
รอบ <n> · <files touched> · build: <command> ✓ · C1–C7: ไม่เข้าเกณฑ์ | C<n> — file:line · commit <sha>
```

**Stop at or before round 3** on whichever comes first: the fix produces a new finding in a different file · round 3 arrives and the original finding still stands · the fix itself meets a C-criterion. Any of these → B, hand to `curtain-hold` as above.

## §7.5 Report — fixed above the floor, transcribe exactly

The script output, the spec grid and the round lines sit directly above this block; they are not fields of it. Fill every field, add none, drop none:

```
Ledger          : script ✓ · <n> ไฟล์ / <m> บรรทัด · mode <floor|inline|fan-out <c> ก้อน, opus> · symbols <s> (+<x> เพิ่มมือ) · outside-diff hits เปิดดูแล้ว <h>/<h> · code-review แยก <—|high|max>
แก้แล้ว (A)     : <k> ข้อ — bullet + file:line · lean-A <j> → UNVERIFIED
รอเจ้าของเคาะ (O) : <j> ข้อ — bullet + file:line + ประโยคใน plan ที่ชนกัน
ค้าง (B)        : <i> ข้อ — ส่ง curtain-hold แล้ว รอเคาะ
จงใจไม่แก้      : finding + เหตุผล 1 บรรทัด
```

**Never:** push, merge, run a project-wide formatter, touch a file outside the diff. The only commits are §7.4's round commits. Applies at every diff size, floor or not.

Done → smoke, per the project's default flow. Smoke starts with the runtime check `call-board` runs from `house.md`'s `## Runtime` section — a migration not yet applied or a service still on old code blocks smoke; it is not a footnote. Applies at every diff size.

## Red flags

| Thought | Reality |
|---|---|
| "I'll just `git diff --stat` it, the script is overkill here" | The script is the ledger. Without it there is no completeness guarantee, only your word. |
| "This 300-line diff is basically floor" | The `MODE` line decides. Not you. |
| "Plan says endpoint, code uses the hook — escalate" | No C-criterion → O. One line, and the user decides at the STOP. |
| "I'll leave the fix uncommitted so the tail stays clean" | The tail squashes. An uncommitted round is what gets lost. |
| "dress-run *and* code-review, to be thorough" | One reviewer, one pass, both checklists. Two agents re-read the same chunk for nothing. |

`reference/ledger-design.md` beside this file holds the reasoning behind the script — read it when changing the ledger, not when running it.
