---
name: interval-call
description: Use when the context is getting long and work is mid-feature, right before /compact or before ending a session — writes down where the work stands so the next context can resume without the chat. Triggers on "ก่อน compact", "เก็บสถานะ", "จะ compact แล้ว", "บันทึกก่อน", "handoff", "save state", "about to compact", "context is long".
---

# interval-call

The call at the interval: everyone is told where act two starts before the house lights come back up. Nothing here reviews, plans or fixes — it writes down the position and stops.

Everything a skill in this set produces already lives on disk except the position inside a phase, and that is what a compact throws away: which plan task is done, which `notes-call` round is open, which O bullets sit unanswered at the STOP, the Flow Summary of lean work. This skill is invoked by hand, when the context is long or before `/compact` — there is no hook, and it never fires on its own. Anything the user types after the command is the **focus** of the next session ("ต่อ smoke phase 2", "แค่ปิด O ข้อแรก") and goes on the handoff's `focus` line verbatim.

## Where it writes

| work | file |
|---|---|
| under a program map | `<programs-dir>/<program>.handoff.md` — `program` is the map's frontmatter `program:` value, never the filename; `programs-dir` from `.claude/house.md`, default `.claude/programs/` |
| lean, no map | `.claude/handoff.md` |

One file per feature, overwritten every time, and **never committed** — the git tail deletes it when the phase lands and never adds it before. `call-board` reads it back; it is not injected anywhere, so its length costs nothing until someone resumes.

## Steps

1. **Flush what other skills left in the chat.** Each of these is something a skill said it would write and the chat still holds:
   - a drift-log or UNVERIFIED line spoken but not yet written → append it to `<programs-dir>/<program>.drift.md` (map work) as one dated line ending in its `file:line`, or into the Flow Summary block in step 2 (lean)
   - the map's `last-touched` → today
   - a `notes-call` fix round with no commit → commit it now as `fix: review round <n>`, the one commit that skill permits. Nothing else gets committed. Never push.
2. **Write the handoff — fixed format, transcribe exactly.** Every claim carries a `file:line` or a pasted command output; a claim with neither is cut, not softened. Sections with nothing in them keep their heading and say `—`. Point at artifacts that already exist (the plan, the map, a `curtain-hold` report in the drift log) by path; never restate them.

   ```
   ---
   feature: <program slug | lean>
   written: <YYYY-MM-DD HH:MM>
   branch: <branch>@<short sha> · dirty <n> files · unpushed <k> commits
   plan: <path of the phase plan | Flow Summary below>
   phase: <phase name from the map's phases list | lean>
   step: <one of: plan task <k>/<n> · notes-call round <n> · smoke · STOP รอ "<what>" · curtain-hold รอเคาะ>
   focus: <what the user typed after the command, verbatim | —>
   resume-with: <the skill the next session invokes first: stage-manager | notes-call | curtain-hold | call-board | none — with the reason in five words>
   ---
   ## ค้างเคาะ
   - O: <finding> — file:line · ประโยคใน plan ที่ชน
   - B: <curtain-hold report sent | verdict patch/structural received> — file:line
   - ตัดสินใจ: <a pending call no skill produced — an untracked file nobody claimed, a scope question> — file:line
   ## ทำต่อ
   1. <next concrete action> — file:line
   ## Flow Summary
   <verbatim, lean work only; "—" under a map>
   ## เพิ่งทำ
   <paste of `git status --short` and `git log --oneline origin/<base>..HEAD`>
   ```

   The `step` line is the one a resuming session reads first, so it is one of the listed shapes and nothing freer. `เพิ่งทำ` is command output captured **after** step 1's writes, not a narrative of the session.
3. **Say it is safe to compact.** One line with the path, then the suggested command, so the compacted summary points at the file:

   ```
   handoff → <path> · compact ได้
   /compact งานค้างอยู่ใน <path> — อ่านก่อนทำต่อ
   ```

   Then STOP. Do not compact for the user, do not continue the work.

## After the compact

`call-board` lists every handoff it finds, with its age and whether its `branch@sha` still matches HEAD. A handoff older than the branch's newest commit is a warning there, not a plan — the resuming session reads the `step` line, re-runs `git status`, and trusts the working tree over the file wherever they differ. The next `interval-call` overwrites it; a feature's git tail deletes it.

## Red flags

| Thought | Reality |
|---|---|
| "I'll summarise what we did this session" | The next context needs the position, not the story. `step` + `ทำต่อ` + `git log`. |
| "I remember the O bullet, no need for file:line" | You will not remember it — that is the whole reason this file exists. |
| "While I'm here I'll finish the round" | This skill writes the position. Finishing work is the work, and it belongs before or after. |
| "Compact is coming, skip the flush" | The flush is the part that loses data. The handoff can be rewritten; a drift line that was never written cannot. |
