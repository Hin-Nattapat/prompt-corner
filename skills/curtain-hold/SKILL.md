---
name: curtain-hold
description: Use the moment a plan's premise turns out false mid-implementation, or right after a bug has been localised and before any fix — maps the blast radius across layers, services and phases, then classifies the problem as a local patch or a structural change and stops for the user to decide. Triggers on "plan ไม่ตรงกับ code", "premise ผิด", "มันกระทบอะไรบ้าง", "แก้ตรงนี้พอมั้ย", "ภาพรวมทั้งระบบ", "zoom out". Never fixes anything itself.
---

# curtain-hold

The show stops mid-scene and nobody moves until the call is made. Never fixes anything itself. Maps blast radius, classifies, stops.

This skill names program map sections (§1/§3/§4) and the `🔒`/`❓` status markers only to say what to do with them — `prompt-book` and its format reference define their format; where this skill and those disagree, they win.

## Two entry points — not symmetric

- **E1 — tripwire mid-implementation.** Fires while executing a plan the user already confirmed.
- **E2 — after a bug has been localised** (by `root-cause`, or by whatever pass found it). Fires before any fix is written.

**The `patch` verdict behaves differently at each.** E1 may continue directly — see §Outcome. E2 may **not** — a `patch` verdict at E2 goes back to the start of the project's default flow (write a Flow Summary, get it confirmed) before any code is touched. The user's call at E2 approves the *classification*, not the start of work.

## Tripwire — fire now vs log and continue

| Fire now | Log and continue |
|---|---|
| Must fix something **outside the current plan**, and that thing is: an inter-phase contract · a program map §1 rule · DB schema · something another service reads · **or something that makes the Flow Summary's blast-radius or won't-touch section false** | Field/method name mismatch · file moved · argument order · something the plan never mentioned but lives in the same file with no reader outside the repo |

If a program map is in play, log the line to its drift log. If there is no program map — lean work has none — there is no drift log to write to: put the line under the Flow Summary's UNVERIFIED section instead.

## Steps

1. **Pin the fact** — one line + `file:line`. Not an interpretation.
2. **What does it collide with** — which program map §4 premise / §3 contract / §1 rule. No map → compare against the Flow Summary instead. Colliding with a `🔒` or `❓` premise is `structural` under C7 below — you can't resolve it from here; carry the marker into the report's `ขัดกับ` line. Any claim you can't back with `file:line` gets tagged `❓`, never asserted plain.
3. **Blast radius by grep, not guess** — who reads/writes this: across layers, across services, across phases, plus the consumers the project already knows about (`.claude/house.md`'s `## Known consumers` lists them where a project has any). **Every item needs `file:line`, or a recorded miss: `grepped <pattern> across <scope>: not found`.**
4. **Classify** — see below.
5. **Propose both paths (A and B) with cost, then STOP.**

## Classification

**Lean default — check this first, but it's a gate, not a shortcut past the criteria below.**

Applies only when *all* of these hold:

- the premise was never written down anywhere
- its consumer lives in a single repo
- the Flow Summary is silent on it
- C5 doesn't fire (this isn't creating a second source of truth)
- C6 doesn't fire (the Flow Summary's blast-radius / won't-touch sections stay true)

All five hold → note the line — to the program map's drift log if one is in play, otherwise to the Flow Summary's UNVERIFIED section — and treat this as ordinary drift type A: the implement-time axis (does this need to stop now, or can it ride along), separate from the patch/structural axis below. Drift type A is fully resolved right here — it never gets a row in the Outcome section, which only covers `patch` and `structural`.

What "continue" means still depends on the entry point:

- At E1: continue immediately, same as any E1 + `patch` call.
- At E2: still go back to the start of the default flow — write a Flow Summary and get it confirmed before touching any code, exactly as `patch` requires at E2 in Outcome below. The lean default shortens the classification step, never the approval gate.

The lean path emits no report from the Report format section below — only the UNVERIFIED line.

Most work is small and single-repo, which is why this gate exists — but C5 and C6 are evaluated every time, lean or not, because they're exactly the two that an undocumented, single-repo premise can still trip.

Otherwise, classify `structural` if **any one** of C1–C7 applies:

- **C1** — Violates a program map §1 rule, or falsifies a metric that rule declares
- **C2** — Changes a program map §3 contract
- **C3** — The consumer lives outside the repo you're editing (cross-service / event bus / a schema another service reads)
- **C4** — Requires editing more than one repo, or more than one phase
- **C5** — Creates a second source of truth — the same data now lives in two places
- **C6** — Makes the Flow Summary's blast-radius or won't-touch section false — this one applies even with no program map in play
- **C7** — Collides with a program map premise marked `🔒` or `❓` — only the user can settle it, so it can't be resolved from here

## Outcome of the call

- **E1 + `patch`** → log one line — to the drift log if a program map is in play, otherwise to the Flow Summary's UNVERIFIED section — then continue immediately. You're still under an already-confirmed plan.
- **E2 + `patch`** → **back to the start of the default flow: write a Flow Summary and get the user to confirm it before touching any code.** `curtain-hold` stands in for diagnose→decide. It does **not** stand in for decide→act.
- **`structural`** (either entry point) → fix the program map's §1/§2/§3/§4 first → update its `last-touched` → trace which phases need re-scoping → only then write code.

## Report format — fixed, transcribe exactly

```
ข้อเท็จจริง : <1 บรรทัด + file:line>
ขัดกับ      : <§ ไหน / Flow Summary ข้อไหน / ไม่เคยเขียนไว้>
กระทบ       : <bullet ทุกอันมี file:line>
จำแนก       : patch | structural — เข้าเกณฑ์ข้อ <N>
A (patch)      : ทำอะไร · ราคา · หนี้ที่ทิ้งไว้
B (structural) : แก้โครงตรงไหน · phase ที่ต้อง re-scope · ราคา
แนะนำ       : A หรือ B + เหตุผล 1 บรรทัด
```

`<N>` is one of C1–C7. This is not a suggested shape — fill every field, add none, drop none. Stays in the chat, no file written. A file gets written only once the user picks `structural`, and then it's the program map that gets edited — not a new report. A diagnosis skill that produces reports nobody reads is the failure mode this format exists to avoid.

## Red flags

| Thought | Reality |
|---|---|
| "Work's almost done, patch it for now" | Almost done is the *highest* cost point for a structural fix, not the lowest |
| "Fix this one spot and it's done" | Until you've grepped for consumers, you don't know it's one spot |
| "Circle back and fix the structure later" | Debt not logged — to the drift log if a program map's in play, to the Flow Summary's UNVERIFIED section if not — doesn't exist in the next phase's eyes |
| "404 means it's not built yet, fix it" | The symptom doesn't tell you the spec's intent — read what the spec designed this endpoint to do |
