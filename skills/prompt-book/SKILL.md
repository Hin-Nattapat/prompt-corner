---
name: prompt-book
description: Use before phase 1 of any feature that needs more than one phase — locks the architecture invariants, the contracts each phase owes the next, and the premises every phase depends on, so later phases do not collide. Triggers when work spans more than one repo and cannot finish in one session, when a migration a later phase depends on is involved, or on "แบ่ง phase", "เฟสแรก", "ทำเป็นตอน ๆ", "วางโครงก่อน", "phase map". Not for single-phase work.
---

# prompt-book

The book the whole show is called from: every cue written down before opening night, so whoever holds it next can run the show without asking the person who wrote it.

## Trigger gate

Fires only when the Flow Summary reveals: >1 repo **and** cannot finish in one session · or a migration a later phase depends on · or the user says "แบ่ง phase", "เฟสแรก", "ทำเป็นตอน ๆ", "วางโครงก่อน", or "phase map". If none of these hold, tell the user this work doesn't need a map and stop — don't write one anyway.

## Location and format

Location: the `programs-dir` named in `.claude/house.md`, default `.claude/programs/` at the project root — always one directory for the whole project, even when the work lives in another repo (reference out via `../`).

Format authority: `reference/map-format.md` shipped beside this file. A project that already has its own `README.md` in its programs dir wins for maps written against it — where the two disagree in that project, the local README wins. This skill names sections, headings, and keys only to say what to do with them, never to define them.

`assets/chk.sh` ships beside this file. The programs dir has no `chk.sh` → copy it there before step 7; never rewrite one that is already present.

## Steps

1. **Check the trigger gate above.** Fails → tell the user, stop.
2. **Sweep reference locations → map's §0.** Paths relative (`../`), what's there, whether it's editable, plus any URL only a human can reach. Start from `house.md`'s `## Reference locations` if the project lists any — an integration's gotchas file belongs here whenever the work touches it. You will read every one of these in full in step 5 — this pass only has to find them.
3. **Write map's §1 — rules + a metric that can actually fail.** Each rule gets a testable sentence, not a slogan — e.g. "adding the 3rd partner must not touch `<service>`." State the exact command or file path that would go red if the rule were violated; a rule with no way to fail it is not done. Mark each rule ✅ (already holds), ⬜ (not yet), or ❓ (unverified).
4. **Write map's §2 phase map + §3 contracts.** §2: per phase — what it delivers, which repo, the contract it sets for later phases, what it must NOT touch, prerequisites, `blocked` label where relevant. §3: per contract — which phase sets it, which phase consumes it, its concrete form, ✅/❓.
5. **Write map's §4 premises** — six columns: id (`P<n>`) | premise | type (`internal`/`external-doc`/`external-api`) | status (✅ / ❌ เท็จ / 🔒 / 🔓 waived / ❓ unverified — treat like 🔒, don't plan past it) | evidence/anchor | who can confirm. Source every row from the §0 sweep: open each doc you listed there and read it in full — a gotchas file especially, they are premises end to end — and lift every claim this work depends on into its own row with that doc's path and a grep-able text anchor. Every `internal` row also needs a real `file:line`. Never write a premise from memory; if it isn't backed by something you just read or grepped, it doesn't get a row. The id assigned here is the same id the verify script uses for that row's `chk`/`ask` line — nothing else ties a script's `FAIL P3` back to a row.
6. **Batch every 🔒 and ❓ question and fire it to the user once.** Stop and wait for answers — don't trickle questions in as you hit them. Right timing is now, before phase 1, not mid-phase when blocked.
7. **Write and prove the verify script, next to `chk.sh` in the programs dir.** Name it `verify-<program>.sh`, where `<program>` is the exact value of this map's frontmatter `program:` key — never the map's filename; a filename-derived name is one the session hook never finds, and nothing reports the miss. Make it CWD-independent: open with `cd "$(dirname "$0")" || exit 0` then `. ./chk.sh` — the anchor paths inside `chk` lines are relative to that same directory. Add one line per §4 row: `chk <id> <label> <path> <anchor>` for a row a grep can settle, `ask <id> <question>` for a row only the user can settle (🔒, or an unresolved ❓). End with an explicit `chk_summary` call — `chk.sh`'s own EXIT trap normally calls it for you, but a trap this script sets after sourcing would silently replace that one. **`chmod +x` it — an unexecutable script proves nothing.** Then prove it: break one real anchor on purpose (on a scratch copy if the anchor lives in a file you must not touch), run the script, confirm `FAIL` actually prints. **Restore the anchor before doing anything else** — that was a deliberate mutation to a real file and it is not done until it's undone. Run the script clean once more; silence only counts as green once you've watched it fail first.
8. **Record the verify script's path under this map's `## §5 verify` heading.**
9. **STOP.** Get the user's confirmation on the map before handing phase 1 to `writing-plans`.

## Non-negotiable rules

- 🔒 = never design over it. Any phase in the map's §2 that depends on a 🔒 (or unresolved ❓) premise stays labeled `blocked`, never "can proceed."
- 🔓 waived is the third option: the user explicitly says proceed without an answer. Write `🔓 waived <date> — assumption X · if false, phase N must re-scope`, and log it to the drift file too. Never accept a verbal skip and leave the map still saying `blocked` — a map that lies is worse than no map.
- Not a plan: no steps, no code, no files-to-change. That's `writing-plans`' job for each phase.
- The format reference's line ceiling is non-negotiable — hitting it means the feature needs splitting, not a longer map.
- Any time you touch the map, update `last-touched`.
- `status: done` is set only after the user confirms, during the `push and pr` git tail of the final phase's PR — never set it yourself mid-work. `parked` and `done` both mean the map stops being injected.
