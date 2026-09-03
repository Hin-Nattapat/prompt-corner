---
name: notes-call
description: Use when an implementation chunk is finished and needs reviewing before commits are grouped — builds a coverage ledger accounting for every changed hunk, classifies each finding as a code fix it repairs itself or a broken premise it escalates, and reports what it fixed and what still needs a decision. Triggers on "รีวิว", "เช็คให้หน่อย", "implement เสร็จแล้ว", "ตรวจ diff", "review the diff". Small diffs collapse to a one-line ledger.
---

# notes-call

The session after the run where every note is given: what was missed, who fixes it, what waits for a decision.

**diff ≤ 5 ไฟล์ และ ≤ 150 บรรทัด → ยุบ:** ledger เหลือบรรทัดเดียว · ไม่มีตาราง A/B · ไม่มีรายงานตายตัว · อ่าน diff, `/dress-run`, `/code-review` แล้วรายงานสั้น ๆ
**ขนาดที่ใช้ตัดสินพื้นล่าง = union ของสองช่วง diff ตัดไฟล์ซ้ำออก** — 100 บรรทัดที่ commit แล้ว + 100 ที่ยังไม่ commit = 200 ไม่ใช่ 100 · กฎนี้ต้องอยู่ตรงนี้ ไม่ใช่ใน §7.1 เพราะคนที่ยุบตามพื้นล่างไม่มีวันอ่าน §7.1
**พื้นล่างยกเว้นเฉพาะ §7.1–§7.5 เท่านั้น — ข้อห้ามใน §7.5 และการส่งต่อไป smoke ใช้เสมอทุกขนาด**
เครื่องจักรทั้งหมดใน §7.1–§7.5 **เริ่มทำงานเหนือเส้นนี้เท่านั้น**

## Base branch

Every range below is measured against the base branch, never a local one — a local branch goes stale and you would review the wrong range with no sign anything was off. Resolve it once:

```bash
base=$(sed -n 's/^base-branch: *//p' .claude/house.md 2>/dev/null)
base=${base:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}
base=${base:-main}
```

Measure the union with this — both ranges into one stream, folded by filename, so it yields the file count and the line total together:

```bash
git fetch origin
{ git diff -M --numstat HEAD; git diff -M --numstat "origin/$base...HEAD"; } \
  | awk '{a[$NF]+=$1+$2} END{n=0;t=0; for(k in a){n++;t+=a[k]; print a[k], k} print n" files "t" lines"}'
```

A file changed in both ranges folds to one key and its lines add — 100 committed + 100 uncommitted in the same file is `1 files 200 lines`. Binary (`-  -`) and pure-rename (`0  0`) rows coerce to 0 and add nothing. It prints one `<lines> <file>` row per file and then the aggregate, because the thresholds need both: the aggregate pair drives the floor's 5 files / 150 lines, the 800-line / 15-file fan-out gate and the total the ledger must equal, while the per-file rows drive the 150-line hunk split and the 400-line chunk cap, which measures a subset. **Every threshold in this file reads one of these two outputs** — never a single range on its own.

Fires at the end of a finished chunk, before commits are grouped, or when the user says "review", "check it", "done implementing". It replaces whatever single review step the project's default flow names.

A **chunk** is a finished unit that builds on its own. Lean work: the whole task is one chunk. Work under a program map: one phase, or the step-group the plan already split out. A phase running past 800 lines gets split now — don't wait for the phase to finish.

## §7.1 Coverage ledger — mandatory above the floor

```bash
git fetch origin                              # always first — a stale base widens the range
git diff -M --numstat HEAD                    # not yet committed, includes staged
git diff -M --numstat "origin/$base...HEAD"   # already committed on this branch
```

Sizes come from the floor gate's union command, not from either range alone — `dress-run` counts one range at a time to pick its own mode, which is not the number that decides anything here.

Build a table, one row per file — or per hunk, see below:

| File (or hunk) | +/- | Status | Observation |
|---|---|---|---|

**What the ledger guarantees, and what it does not.** Three rounds tried to make it prove the code was *read*, and each failed the same way: the party being checked writes the evidence. An attestation is free. A narrative about what a command returned is free. And the "nothing outside touches this" branch, whose evidence legitimately sits entirely inside the diff, is free *and* indistinguishable from the real thing. Stop chasing it:

- **Guaranteed — completeness.** Every changed hunk has a row, and the line total checks against `--numstat`. That is mechanically verifiable, and it is why the ledger exists: the pain is *not read in full*, not *not read deeply*.
- **Not guaranteed — depth.** Depth is enforced by the **second reviewer** (§7.2's three dimensions, plus the fan-out subagents), never by the writer's own word about their own reading.

**Per-row evidence — the writer does not choose what to grep.** Writer's choice is the hole: a hunk touching six identifiers can grep the one nobody calls and declare itself safe. So the rule is mechanical:

- Grep **every identifier the hunk declares or whose signature it changes** — not the convenient one. None at all (an edit inside a single function) → grep the name of the function enclosing it.
- **The scope is not the writer's either** — search the whole repo and subtract only named noise, every exclusion visible in the pasted command:

  ```bash
  git grep -n <sym> -- . ':(exclude)vendor' ':(exclude)*.lock' ':(exclude)testdata'
  ```

  Narrowing it yourself is the hole that outlives symbol choice: `git grep -n <sym> -- internal/` while the caller sits in `report/` breaks no rule and hides it exactly. The bare-`.` ban applies **only to the command you paste output from** — lockfiles, fixtures and vendor bury the report and the context window in raw content. The command that *counts* `<N>` must use a bare `.` with no exclusions, because it returns a number and no file content. Two different commands, deliberately.
- **You may add exclusions** (`node_modules`, `dist`, generated files) **under two conditions.** The path must be generated or vendored in — **never a directory holding code we wrote**. And **`<N>` is counted with no exclusions at all** (`git grep -n <sym> -- . | wc -l`): exclusions bound how many lines you paste, never the number the reviewer checks against. A caller hidden behind an exclusion still surfaces in `<N>`, so hiding one costs nothing and gains nothing.
- Paste **at most 10 output lines, ordered so every hit whose `path:line` is absent from the diff comes first**. Without that order the cap becomes the hiding place: 10 in-diff lines plus a truncation note buries every external hit while satisfying both rules. Sorted this way, a truncation can only ever drop in-diff hits — the ones carrying no evidentiary weight.
- **Every row states `<N>`, not only truncated ones.** Required only on truncation, the whole measure dies in the one case it was written for: add `':(exclude)mocks'` until the paste is ten lines or fewer and `<N>` never has to be written, so the caller behind the exclusion never surfaces. Untruncated rows close with `(<N> hits, unexcluded)`; over 10 hits close with `… ตัดที่ 10 จาก <N> hits (unexcluded)`.
- Output too long for a table cell goes in a fenced block directly under the table, and the row points at it. Never trimmed to fit — trimming to fit is truncation without the count.
- **The second reviewer re-runs at least 2 sampled rows** and reports match or mismatch (§7.2). It is someone else's assigned step, not a floating property of the table. Nobody re-ran it → the report's `Ledger` line carries `สุ่มรันซ้ำ 0/<rows>` and the ledger stands as a completeness list, not evidence of depth.

**Why the observation column exists:** `--stat` names files without reading a line inside them — a ledger built from `--stat` alone gets ticked ✅ top to bottom by someone who read nothing: the exact failure this replaces, now wearing a compliance artifact. Making every row carry the output of a grep the rule picked — not one the writer picked — is what gives a fake tick a cost.

Two example rows:

| `internal/service/order.go` (hunk 214–224) | +42/-8 | ✅ | signature changed: `ApplyDiscount` — `git grep -n ApplyDiscount -- . ':(exclude)vendor' ':(exclude)*.lock' ':(exclude)testdata'` → `report/daily.go:88:  total := svc.ApplyDiscount(o, nil)` · `internal/service/order.go:214:func (s *service) ApplyDiscount(` (2 hits, complete; out-of-diff hit first) · `git grep -n ApplyDiscount -- . | wc -l` → `(2 hits, unexcluded)` |
| `internal/repo/member.go` (hunk 88–96) | +12/-3 | ✅ | declares: `ErrMemberLocked` — `git grep -n ErrMemberLocked -- . ':(exclude)vendor' ':(exclude)*.lock' ':(exclude)testdata'` → 10 lines in the block under the table, out-of-diff first · `… ตัดที่ 10 จาก 23 hits (unexcluded)` — 23 from `git grep -n ErrMemberLocked -- . | wc -l`, no exclusions |

- A file with more than 150 changed lines splits into one row per hunk — a whole-file row can't show that only half of it got read.
- The reviewed-line total across every row must equal the `--numstat` total (the union, per the floor gate). `--numstat` prints `-  -` for a binary file and `0  0` for a pure rename under `-M` — awk coerces `-` to `0`, so those rows already contribute nothing to either side and the equality check holds without any special exclusion.
- No summarizing findings until every row is ✅. The report must show the ledger.

### Fan-out

More than 800 lines or more than 15 files (union, deduplicated by file) → split into chunks of ≤400 lines along natural boundaries (repo → layer → feature dir). Every dispatch — chunk review or an escalated `/code-review high`/`max` subagent — carries three things: the chunk's file list, the requirement to return a completed ledger, and (for `/dress-run`) the suppression line below. Dispatch every chunk with `model: opus` on the call itself, never by relying on an agent file's `model:` frontmatter key — the vulnerable case isn't a file that already declares a model (precedence is env → per-invocation → frontmatter → main model, so a declared value holds), it's an agent file with **no** `model:` key at all, which silently inherits whatever the main session is running and downgrades the tier with no visible sign. A chunk that comes back with an incomplete ledger gets rerun, not accepted partial.

**`notes-call` is the sole owner of fan-out.** When you hand a pre-sized chunk to `/dress-run`, say so explicitly in the invocation: this diff is already a chunk `notes-call` split, do not run your own self-escalation on it, review it inline. Splitting twice turns one 1600-line diff into eight Opus agents re-reading overlapping context.

## §7.2 Three review dimensions

- **Spec** — compare the diff against this phase's plan, or the Flow Summary (the task brief the user confirmed before implementation) for lean work. Inline, no subagent. **Artifact: a grid, one row per item the plan or the brief's change-list names** — `item → file:line in this diff that satisfies it`, or `❌ absent`. A named item with no diff line is a finding; a changed file no item names is scope drift and also a finding. No grid attached means this dimension did not run — saying "spec checked" is not the dimension.
- **`/dress-run`** — craft quality, dispatched per the fan-out rule above when the chunk is large.
- **`/code-review low/medium`** — high-confidence correctness/reuse findings. Escalate to `high`/`max` on a big/multi-layer diff, cross-service work, or a migration — any reviewer subagent that escalation dispatches also goes out with `model: opus` on the call.

**The §7.1 row re-run is assigned here.** Whoever reviews second — the `/dress-run` or `/code-review` pass, or each fan-out subagent for its own chunk — picks at least 2 ledger rows, re-runs their `git grep` verbatim, and returns the two outputs with `ตรง` / `ไม่ตรง`. A mismatch is a finding about the ledger, not a footnote. No second party at all → `สุ่มรันซ้ำ 0/<rows>` on the `Ledger` line, never a blank.

## §7.3 Classify every finding

The same seven criteria `curtain-hold`'s Classification section runs on, numbered so the hand-off below can cite one:

- **C1** — Violates a program map §1 rule, or falsifies a metric that rule declares
- **C2** — Changes a program map §3 contract
- **C3** — The consumer lives outside the repo you're editing
- **C4** — Requires editing more than one repo, or more than one phase
- **C5** — Creates a second source of truth
- **C6** — Makes the Flow Summary's blast-radius or won't-touch section false
- **C7** — Collides with a premise in the map's §4 marked 🔒 or ❓ — only the user can settle it, so it can't be resolved from here

**Lean default gate — all five parts must hold, checked every time:** the premise was never written down anywhere · its consumer lives in a single repo · the Flow Summary is silent on it · **C5 does not apply** · **C6 does not apply**. C5 and C6 stay in the gate because an undocumented, single-repo premise can still trip either of them — e.g. it creates a second source of truth without ever crossing a repo boundary. All five hold → `A`: note one line under the Flow Summary's UNVERIFIED section, or the program map's drift log if one is in play, count it on the report's `lean-A` field, and move on — don't stop.

Any gate part fails, or any of C1–C7 applies on its own → `B`. Escalate to `curtain-hold`: pin the fact to `file:line`, cite the criterion as `<N>`, one of `C1`–`C7`, for its `เข้าเกณฑ์ข้อ <N>` field, and state the entry point is **E1** — an escalation from `notes-call` is always under a plan the user already confirmed, never E2. `curtain-hold` runs its own blast-radius pass and proposes the two paths from there.

## §7.4 Type-A loop — cap 3 rounds

1. Fix.
2. Build/typecheck passes — **paste the command and its raw output**. A bare "passes" is the same unfalsifiable attestation §7.1 just banned for ledger rows.
3. Re-review **only the files touched this round.**

**Scope:** fix only files/layers the plan or Flow Summary names. Touching anything outside that scope turns the finding into a `B`.

**After every round, run the §7.3 criteria against the fix's own diff — not just against the finding.** A finding like "DTO doesn't match plan" can sit entirely inside a plan-listed file while the fix that repairs it adds a field to a Response struct that six callers outside the repo read — that clears every stop condition below while a cross-repo change has just landed inside a loop that only checks itself.

Each round appends one line, attached above the report block. No line for a round means the re-check did not happen:

```
รอบ <n> · <paste `git diff -M --numstat` of that round's own change> · C1–C7: ไม่เข้าเกณฑ์ | <N> — file:line
```

**Stop at or before round 3** on whichever comes first:
- the fix produces a new finding in a different file
- round 3 arrives and the original finding is still there
- the fix itself meets a `C1`–`C7` criterion

Any of these → stop, hand to `curtain-hold` (§7.3 hand-off shape, always E1).

## §7.5 Report — fixed, above the floor, transcribe exactly

Three artifacts are attached immediately above this block and are not fields of it: the §7.1 ledger table, the §7.2 spec grid, and the §7.4 round lines. "Fill every field, add none, drop none" governs only the four lines below.

The `Ledger` line records rather than asserts — `✅ ครบ (ตรงกับ numstat)` on its own was the same free attestation §7.1 bans two sections up. `fetch ✓`, the subagent tier (fan-out chunks *and* escalation calls) and the lean-A count are on the line for the same reason — an instruction with no field is an instruction nobody can see was skipped. Two instructions still leave no artifact and no field is invented for them: the `dress-run` suppression line (its compliance now shows up in `dress-run`'s own report, not duplicated here) and the rerun of a chunk that returns an incomplete ledger (the controller's action, not the ledger author's).

```
Ledger     : <n> ไฟล์ / <m> บรรทัด (union) · numstat = <n2>/<m2> · สุ่มรันซ้ำ <k>/<rows> ตรง · fetch ✓ · subagents <ไม่มี|<c> ก้อน + <e> escalation, opus ทั้งหมด> · lean-A <j> → UNVERIFIED · มิติที่เดิน: spec inline / craft <inline|fan-out> / code-review <low|medium|high|max>
แก้แล้ว (A) : <k> ข้อ — bullet + file:line
ค้าง (B)    : <j> ข้อ — ส่ง curtain-hold แล้ว รอเคาะ
จงใจไม่แก้  : finding + เหตุผล 1 บรรทัด
```

**Never:** commit, push, run a project-wide formatter, touch a file outside the diff. Applies at every diff size, floor-collapsed or not.

Done → smoke, per the project's default flow. Also applies at every diff size.
