---
name: notes-call
description: Use when an implementation chunk is finished and needs reviewing before commits are grouped — accounts for every changed hunk, then sorts each finding into a fix it makes itself, a call only the owner can make, or a structural break it escalates. Triggers on "รีวิว", "เช็คให้หน่อย", "implement เสร็จแล้ว", "ตรวจ diff", "review the diff". Small diffs collapse to a few lines.
---

# notes-call

The session after the run where every note is given: what was missed, who fixes it, what waits for a decision.

Fires at the end of a finished chunk, before commits are grouped, or on "review", "check it", "done implementing". It replaces whatever single review step the project's default flow names. A **chunk** is a unit that builds on its own: lean work → the whole task; under a program map → one phase, or the step-group the plan split out. A phase that crosses the fan-out line mid-way is reviewed as chunks as that happens, not held to one call at the end.

Every rule below that carries a number was set by a measured gate; `reference/measured.md` beside this file holds the measurements. Read it when changing a rule, not when running one.

## §7.0 Measure — the script, never by hand

`assets/ledger.sh` ships beside this file; the "Base directory for this skill" line above says where.

```bash
bash "<skill-dir>/assets/ledger.sh"                 # the whole review range
bash "<skill-dir>/assets/ledger.sh" -- <file>...    # one fan-out chunk
bash "<skill-dir>/assets/ledger.sh" --leads ...     # only the symbols with outside-diff code hits
bash "<skill-dir>/assets/ledger.sh" -C <repo> ...   # from a workspace root that holds several repos
```

It fetches, resolves the base branch, measures the working tree against the merge-base — committed, staged, unstaged and untracked in one range — and prints a `LEDGER` line (files, lines, untracked, symbols, and which `house.md` it read — `house none` means every default applied, check that before trusting the range), a `MODE` line, and one block per changed file. Thresholds come from the nearest `.claude/house.md` walking up from the cwd; every key is optional:

| key | default | effect |
|---|---|---|
| `base-branch` | `origin/HEAD`, else `main` | the branch the merge-base is taken against |
| `review-floor-lines` | 150 | at or under this, and ≤ 5 files → `floor` |
| `review-fanout-lines` | 800 | above this, or > 15 files → `fan-out` |
| `review-chunk-lines` | 600 | most code lines one chunk may hold; `-- <files>` mode prints `OVER CAP` past it |
| `review-max-chunks` | none | more chunks than this → `OVER BUDGET`; stop and ask the user before dispatching anything |

Every threshold counts **code lines**: prose (`.md .txt .rst .adoc`) gets its block and its symbols but does not size the review. A symbol's outside-diff hits are split the same way (`199 outside diff (4 code · 195 docs)`), code pasted first.

`FAIL` on the first line → paste it and stop; do not measure around it with your own `git diff`. Every number below reads the script's output, never a range you picked.

**`MODE floor`** → no ledger table, no grid, no fixed report. Read the diff, run §7.2's two passes yourself, report in a few lines. §7.3's bins, §7.5's never-list and the smoke handoff still apply.

## §7.1 Coverage ledger — above the floor

The script's output **is** the ledger. It is not the writer's word about their own reading, so nobody re-runs rows to check it; anyone who doubts it re-runs the script. Two things it cannot do are yours:

1. **Read every listed file at its hunk ranges**, and the whole of every `untracked` file.
2. **Add the declarations the regex misses** — grouped Go `const (`/`var (`/`type (` blocks, class methods, anything spelled without a keyword the script knows (column-0 `UPPER_CASE = …` is caught). One line each, in the script's shape, from the script's own command:

   ```bash
   git grep -n -w --untracked -e <sym> -- .
   ```

   appended under the file's block as `+ <sym>  <N> hits · <k> outside diff`; count them on the report's `เพิ่มมือ` field. Zero is a normal answer.

A symbol with outside-diff **code** hits is a lead: open each hit and decide whether that caller is still right. `0 outside diff` needs nothing further.

## §7.2 Review — two passes, one reviewer

- **Spec** — inline, in this session. A grid with one row per **task in the phase's plan** (the list `writing-plans` already wrote), or per item in the brief's change-list for lean work: `task → file:line in this diff that satisfies it`, or `❌ absent`. This grid settles diff-versus-plan; plan-versus-spec was `writing-plans`' self-review, not re-derived here. A task with no diff line is a finding. A changed file that neither a task nor the plan's file list names is scope drift and a finding. No grid means this pass did not run.
- **Code** — craft and correctness in **one pass by one reviewer**: `dress-run`'s groups and packs for craft, `/code-review`'s bar for correctness. `MODE inline` → you. `MODE fan-out` → one subagent per chunk, `model: opus` set **on the call** (an agent file with no `model:` key inherits the main session's tier silently). Never `dress-run` and `/code-review` as two agents on one chunk. A chunk that returns without ledger output is rerun, not accepted.
- `/code-review high` or `max` as a **separate** call only for a migration, cross-service work, or a multi-layer diff — also `model: opus` on the call.

### The chunk dispatch — fixed parts

1. the chunk's file list
2. `ledger.sh -- <files> | tee .claude/review/<feature>.<chunk>.ledger.txt`, then `ledger.sh --leads -- <files>`; return only the leads output
3. the **chunk brief** (below), in place of the project's instructions, spec and plan in full
4. `dress-run`'s groups plus the packs the chunk's extensions pick
5. the **run list**: ≤ 6 things to verify by execution, one sentence each. Mutation only on a chunk that is tests, capped at 20 mutants, run **once** — the fix agent does not re-run them, the re-reviewer verifies each item once. `house.md`'s `## Mutation` names a tool command → the reviewer runs that one command and reads its survivors instead of mutating by hand; no section → hand mutation within the cap. The reviewer never extends the run list on its own.
6. the line "this is a `notes-call` chunk, review it inline, no self-escalation"

**What a reviewer returns, and nothing more:** the `--leads` output · findings ≤ 400 words, one line each in `dress-run`'s shape · `leads:` — every outside-diff code hit it opened, as `<sym> → file:line ✓ | finding #n` · `tokens: <n>k` if it can see its own usage. The `leads:` list is the reviewer's artifact; the controller never restates or totals it.

### Chunk brief — written once, read by every agent on the phase

`.claude/review/<feature>.brief.md`, ≤ 150 lines, never committed:

```
## กฎที่ใช้รีวิว        — the rules from the project's instructions a review actually applies, quoted, with their source line
## interface ที่ก้อนแตะ  — one line per signature the chunks call or change (from ledger.sh's symbols), no bodies
## task ของ phase นี้    — the plan's task list, verbatim, with the files each names
## fixture              — a run dir / sample data already built, by path, AND the numbers already measured from it
                          (a reviewer runs only what this section does not answer)
```

A reviewer that needs more than the brief reads the one file it names, not the corpus. Past 150 lines the brief is carrying the spec — cut it back to what a review applies.

## §7.3 Classify every finding — three bins

Check in this order; the first bin that fits wins.

**B — structural** if any one of these holds (the seven `curtain-hold` runs):

- **C1** — violates a program map §1 rule, or falsifies a metric that rule declares
- **C2** — changes a program map §3 contract
- **C3** — the consumer lives outside the repo you're editing
- **C4** — requires editing more than one repo, or more than one phase
- **C5** — creates a second source of truth
- **C6** — makes the Flow Summary's blast-radius or won't-touch section false
- **C7** — collides with a map §4 premise marked 🔒 or ❓

→ `curtain-hold`: the fact pinned to `file:line`, the criterion as `C<n>`, entry point **E1** — always under a plan the user already confirmed, never E2.

**A — code fix** if the written plan, brief or map says X, the code does not do X, and doing X stays inside the files the plan or brief names. An undocumented premise that only this repo consumes and trips none of C1–C7 is also A: fix it, note one line under the Flow Summary's UNVERIFIED section or the map's drift log — neither exists → the note is the `lean-A` bullet itself — and count it on `lean-A`.

**O — owner call** for everything left. The observable test: **the code already achieves the task's outcome, by a route the plan did not name.** The honest resolution may be the plan's sentence, not the code. (A task the code does not achieve at all, or achieves wrongly, is A.) Also here: a fix that would leave the plan's named files but trips no C-criterion. Do not fix the code, do not escalate; one line in the drift log or under UNVERIFIED, one bullet on the report's `รอเจ้าของเคาะ` line, decided at the chunk's STOP. Two shapes, both counted:

- **`O (รอ)`** — nothing touched; the owner picks.
- **`O (ทำไปก่อน)`** — the controller amended the spec or plan sentence so the fix round could proceed (a fix agent needs a rule that is written); the owner confirms or reverts it at the STOP. A spec edit the controller made and reported nowhere is an owner's call taken by the wrong party.

`curtain-hold` is for B only.

### §7.3a Round brief — the fix agent's lane

Findings from every chunk merge into one numbered list before any fix is dispatched, at `.claude/review/<feature>.round<n>.md` — never committed, referenced from the round commit body — in exactly four sections plus one line:

```
## แก้                 — numbered, every item file:line + the fix stated as an outcome, not a diff
## ไฟล์ที่แตะได้เท่านั้น    — the plan's file list for the tasks under review; anything else is out of lane
## controller ทำเอง     — spec / plan / doc corrections the fix agent must not make
## O รอ STOP            — owner calls; not the agent's either
check: <the targeted check for the allowed files — one test file, one package — never the full suite>
```

The fix agent proves an item by the test the brief names going red then green. It does not re-run the reviewer's mutants.

**Split the round when the allowlist splits — and the working tree allows it.** Disjoint file groups get one brief each (`.round<n>.<g>.md`) and one fix agent each; items that need the same file stay together. Parallel agents share one working tree: a pre-commit hook that stashes unstaged changes will stash the other agent's edits mid-commit, so check `.pre-commit-config.yaml` / `.git/hooks/pre-commit` first. Hook present → groups run **sequentially**, or in parallel with `--no-verify` on the round commits, said so in the brief, the controller's full check standing in for the hook. No hook → parallel.

Inline mode: the same sections, in the chat, before the first fix. Dispatching raw chunk reports — which carry no allowlist — is how a fix agent wanders.

## §7.4 Type-A loop — cap 3 rounds

1. Fix — only files the round brief allows; stepping outside turns the finding into O or B. The fix agent runs the brief's `check:`, never the full suite, and commits **as each group of items passes it** as `fix: review round <n> (<k>/<m>)`, so a hung agent loses one group, not the round. Never resume a hung fix agent; re-dispatch it on the remaining items.
2. The full build/typecheck/test passes once per round, run by the controller after every group has landed — **paste the command and its raw output**: the command's own stdout/stderr and exit code, not a wrapper's summary. A filtering proxy that prints "no issues" over a non-zero exit is the attestation this line forbids; bypass it for this one command.
3. Re-review the round, then run C1–C7 **against the fix's own diff** — a fix inside a plan-listed file can still add a field six out-of-repo callers read. **Who:** the controller, inline; the chunk reviewers are gone and re-dispatching them is a double read. Round diff over `review-chunk-lines` (per `ledger.sh -- <round files>`) → one Opus pass, **scoped**: (a) each item verified by the test its brief names, red then green, or a `cannot fail` verdict · (b) the diff read only for what no item asked for and for C1–C7. It carries the round briefs, not the chunk briefs, and does not re-read the touched files whole.
4. Anything still uncommitted at the end of the round is committed as `fix: review round <n>`. The git tail squashes later. Never push.

Each round appends one line above the report block; no line means the re-check did not happen:

```
รอบ <n> · <files touched> · build: <command> ✓ · C1–C7: ไม่เข้าเกณฑ์ | C<n> — file:line · commit <sha>
```

**Stop at or before round 3** on whichever comes first: the fix produces a new finding in a different file · round 3 arrives and the original finding still stands · the fix itself meets a C-criterion. Any of these → B, to `curtain-hold`.

## §7.5 Report — fixed above the floor, transcribe exactly

The script output, the spec grid, each reviewer's `leads:` list and the round lines sit directly above this block; they are not fields of it. Nothing on the `Ledger` line says what was read. Fill every field, add none, drop none:

```
Ledger          : script ✓ · <n> ไฟล์ / <m> บรรทัด (<c> code) · mode <floor|inline|fan-out <c> ก้อน, opus> · symbols <s> (+<x> เพิ่มมือ) · brief <path|inline> · code-review แยก <—|high|max>
Tokens          : reviewers <r1>+<r2>+… · fix <f1>+… · escalation <e> = <sum>k   (จาก subagent_tokens ที่ harness รายงาน · inline → —)
Findings        : <n> จาก reviewer → A <k> · O <j> · B <i> · ไม่แก้ <x> · ซ้ำ <d>   (ต้องบวกได้ <n>)
แก้แล้ว (A)     : <k> ข้อ — <path ของ round brief ทุกไฟล์ | inline: bullet + file:line> · lean-A <j> → UNVERIFIED
รอเจ้าของเคาะ (O) : <j> ข้อ — O (รอ): bullet + file:line + ประโยคใน plan ที่ชน · O (ทำไปก่อน): spec/plan §<x> แก้แล้ว — ยืนยันหรือ revert
ค้าง (B)        : <i> ข้อ — ส่ง curtain-hold แล้ว รอเคาะ
จงใจไม่แก้      : finding + เหตุผล 1 บรรทัด
```

**Never:** push, merge, run a project-wide formatter, touch a file outside the diff, commit `.claude/review/`. The only commits are §7.4's round commits. Applies at every diff size.

Done → smoke, per the project's default flow, starting with the runtime check `call-board` runs from `house.md`'s `## Runtime` — a migration not applied or a service on old code blocks smoke. Applies at every diff size.

## Red flags

| Thought | Reality |
|---|---|
| "I'll just `git diff --stat` it, the script is overkill here" | The script is the ledger. Without it there is only your word. |
| "This 300-line diff is basically floor" | The `MODE` line decides. |
| "Plan says endpoint, code uses the hook — escalate" | No C-criterion → O. One line, the user decides at the STOP. |
| "I amended the spec so the fix could go; nothing to report" | That is `O (ทำไปก่อน)`. The owner confirms or reverts it. |
| "The fix agent should re-run the mutants to be sure" | Once, by the re-reviewer. A third run is the cost, not the safety. |
| "One more thing for the reviewer to run, it's cheap" | The run list is where the gate's cost is set. Six, written down. |
| "dress-run *and* code-review, to be thorough" | One reviewer, one pass, both checklists. |
