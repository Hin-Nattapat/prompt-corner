# What the numbers in notes-call were set by

Not injected into a session. Each entry names the rule, the gate it was measured on, and what the measurement showed. Change a rule here first, then in `SKILL.md`.

## Ledger built by a script (§7.0, §7.1)

Three hand-built versions tried to make the ledger prove the code was read; each failed because the party being checked wrote the evidence. Across one program's twelve chunks the hand-built rules (grep every identifier, paste ten lines outside-first, count unexcluded, second party re-runs two rows) took 30–40% of each reviewer's budget and the ledger never surfaced a finding itself. The script removes the chooser. `ledger-design.md` has the full argument.

## Code lines only; docs hits split (§7.0)

A range of 200 code lines and 700 lines of plan prose reported `MODE fan-out`, and a symbol named `metrics` showed 199 outside-diff hits, all in `CLAUDE.md`, `README.md` and plan files. The report field "outside-diff hits opened h/h" was filled `59/59` by a controller who had opened none of them — an attestation — and was dropped; each reviewer lists its own `leads:` instead.

## Chunk cap 600, not 400 (§7.0)

Two Python repos: test files of 300–550 lines made a 400 cap fire `OVER BUDGET` on the first run of every gate, and the honest resolution each time was raising the setting, not a smaller review.

## Chunk brief (§7.2) — consistency, not cost

Hypothesis: reviewers spent 25–35k each reading the same instructions, spec and plan; a brief would cut it. Measured on M2 gate 1 (CADENCE): reviewers cost 101–134k *with* the brief, the same as before it. The budget went to execution — mutation runs, simulator probes — not reading. The brief's value was that four reviewers and three implementers cited the same rules and the same measured facts. It stays for that reason. The `fixture` section now carries the measured numbers, not only the path, so a reviewer runs only what the brief cannot answer.

## Run list ≤ 6, mutation once (§7.2, §7.3a, §7.4)

On the same gate the same mutants were run three times: by the reviewer to find holes, by each fix agent to confirm its fix (the dispatch asked for it), and by the re-reviewer to verify every item. Two fix agents so instructed cost 146k + 159k for 22 items; one fix agent on an earlier gate, without re-mutation, cost 160k for 36. The run list is now written, capped, and the mutants run once (reviewer) and are verified once (re-reviewer). A tool-driven mutation run (`house.md` `## Mutation`) replaces hand mutation where the project has one: one command, read the survivors.

## Round brief, split by allowlist, pre-commit (§7.3a)

Three gates with a four-section round brief: one round each, zero scope escapes. Splitting a round into two parallel fix agents worked mechanically but the two shared one working tree; the project's pre-commit hook stashed the other agent's unstaged edits mid-commit and one group had to commit with `--no-verify`. The rule now checks for such a hook first.

## Re-review scoped (§7.4 step 3)

The over-cap re-review on M2 gate 1 cost 157k reading an 891-line round diff and verifying 22 items. It found one thing mutation per chunk cannot — a code path no repository test drives — and disproved a fix agent's "outside my items" note that would otherwise have become a round-2 item. It stays, scoped to item verification by the named tests plus a diff read only for what no item asked for and for C1–C7.

## O in two shapes; Findings reconciled (§7.3, §7.5)

On M2 gate 1 the controller amended the spec in three places before the fix round (a hold rule, a transition rule, two column meanings) and the report said `O: 0`. Those are owner's calls made so the round could proceed; they now appear as `O (ทำไปก่อน)`. Reviewers returned 32 findings; the report accounted for 27. The `Findings` line must add up.

## Tokens per gate, for the record

| gate | code lines | reviewers | fix | re-review | total | per line |
|---|---|---|---|---|---|---|
| M1b C | 1,449 | ~4 × 100k | 166k | — | ~570k | ~390 |
| M1b D | 912 | 81 + 102 + 104k | 159k | — | ~450k | ~490 |
| M2 g1 (first gate on the briefs) | 1,862 | 134 + 120 + 114 + 101k | 146 + 159k | 157k | 931k | ~500 |
