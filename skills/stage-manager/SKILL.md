---
name: stage-manager
description: Use to drive a feature that needs more than one phase from design through to the last merged PR — sequences brainstorming, the program map, per-phase planning, implementation, review and the smoke handoff, stopping for the user at every phase boundary. Triggers on "ทำฟีเจอร์", "งานนี้หลาย phase", "เริ่มฟีเจอร์ใหม่", "แบ่ง phase แล้วทำต่อ", "drive the whole feature". Single-phase work goes down the normal lean path instead.
---

# stage-manager

**Gate first.** Fires only when: work spans more than one repo **and** cannot finish in one session · or a migration a later phase depends on · or the user asked for phases. This is a copy of `prompt-book`'s own trigger gate, kept here only so this skill knows when to start — `prompt-book` owns the gate and wins on any disagreement. None of these hold → this is ordinary work, say so and send it down the project's default flow — do not run anything below this line.

This is a thin orchestrator. It sequences skills that already exist and calls them, it does not restate what they do. Under this skill there is no Flow Summary: the program map's §1/§3/§4 plus each phase's own plan from `writing-plans` stand in for it, and the map's drift log stands in for Flow Summary §9 UNVERIFIED.

## Project settings

Read `.claude/house.md` at the project root if it exists — its `## Git tail`, `## Smoke` and `## Default flow` sections override the defaults named below. No file → the defaults hold and nothing is missing.

## State — the program map, nothing new

No field of its own. On entry or resume, invoke `call-board` and use what it returns rather than re-deriving its ladder yourself — reading only merged/open PRs drops dirty worktrees and unpushed branches, and `implementing (dirty/local)` is the most common state here, ahead of `unpushed branch` → `PR open` → `awaiting batch test round` → `ready to merge` → `merged`. `call-board` also carries the half-merge warning: a phase merged in one repo with its counterpart PR still open must be reported as exactly that, never resolved into "we're on phase N" — that resolution is what buries the orphaned PR. Still ambiguous after `call-board` → ask the user one question, don't guess.

A map found with `status: parked` is not "no map" — this feature already has one; resume against it (flip back to `active`, update `last-touched`) instead of writing a second map for the same feature. No map at all → this is phase 0, go to Sequence.

## Sequence

1. Design still genuinely ambiguous → invoke `superpowers:brainstorming` first. Skip it when the design is already settled.
2. Invoke `prompt-book`. It stops **twice** on its own, not once — its step 6 batches every 🔒/❓ question, its step 9 confirms the finished map. Wait at both.
3. Per phase, in order:
   - Invoke `superpowers:writing-plans` for that phase only — not the whole feature.
   - Implement the plan.
   - Invoke `notes-call` per its own chunking rule — a phase that crosses its fan-out line is split and reviewed chunk by chunk as that happens, not held to a single call at phase end. Its script reads the thresholds from `house.md`; none are restated here. Its round commits (`fix: review round <n>`) are expected on the branch and are squashed by the git tail below.
   - Run the smoke handoff. First the runtime check `call-board` runs from `house.md`'s `## Runtime` section — the running service must be the code just reviewed, with every migration applied; otherwise smoke is blocked and the report says so. Then, default: anything you can drive yourself (a backend endpoint, a CLI, a script) you run yourself; anything you cannot drive (web UI, native app, hardware) becomes a precise checklist handed to the user as a blocking gate. `house.md`'s `## Smoke` section wins where it says otherwise.
   - **STOP.** Report and wait for the user. `notes-call`'s `รอเจ้าของเคาะ (O)` bullets are decided here — each one is a plan sentence the user keeps or changes, not a `curtain-hold` case.
   - On "push and pr" — run the git tail. Default: branch off the base branch, group into logical commits, rebase, push, open the PR, hand back the URL — never merge. `house.md`'s `## Git tail` section wins where it says otherwise, including its own trailing steps. A phase touching more than one repo runs that tail once per repo and lands one PR per repo — never treat one repo's merge as the phase merging.
   - Move to the next phase only after the user has acted on the STOP above.

## Re-entry after curtain-hold

`notes-call` escalates a B finding to `curtain-hold` — never an O finding, which waits at the phase STOP instead. A `structural` verdict there rewrites the map's §1–§4 and re-scopes phases — the plan the current phase was executing, and the `phases` list this skill was iterating, are both stale the moment that happens. Correct the map first, then re-derive the current phase from the rewritten `phases` list; the old phase numbering is never resumed as if the verdict hadn't landed. A `curtain-hold` stop is not one of the phase boundaries above — it interrupts a phase mid-flight — so it falls under "never past a STOP" below too.

## Never past a STOP

Every STOP above — `prompt-book`'s two, each phase's smoke-and-report STOP, and a `curtain-hold` interruption — ends waiting for the user. This skill walks the feature to each gate; it never walks through one on its own, "auto mode" included.

## What this does not do

It does not review a diff, write a plan, classify drift, or author a program map — `notes-call`, `writing-plans`, `curtain-hold`, and `prompt-book` own those respectively. If this file starts explaining how to fill in a premise row or a coverage ledger, it has become the ceremony it exists to prevent.
