# Why the ledger is a script

Read this when changing `assets/ledger.sh` or §7.1. It is not injected into a session.

## What the ledger guarantees

**Completeness, not depth.** Every changed hunk has a row and the line total matches `--numstat`. That is mechanically checkable, and it is the one thing the pre-script ledger was actually for: the failure it replaced was a review that ticked twelve files it never opened, not a review that read them shallowly. Depth is enforced by the second pass in §7.2 — reading the outside-diff callers, and the reviewer's own checklist — never by the writer's account of their own reading.

## Why the writer stopped building it

Three versions of the hand-built ledger tried to make it prove the code was *read*. Each failed the same way: the party being checked writes the evidence.

- An attestation ("✅ read") is free.
- A narrative of what a grep returned is free.
- The writer choosing **which symbol** to grep is a hole — a hunk touching six identifiers can grep the one nobody calls.
- The writer choosing **where** to grep is a hole that outlives symbol choice — `-- internal/` while the caller sits in `report/`.
- A paste cap is a hiding place — ten in-diff lines and a truncation note bury every external hit.
- A hit count only required on truncation dies in the one case it exists for — add exclusions until nothing truncates.

Every one of those got a rule, and every rule cost every reviewer tokens on every row: grep each identifier, paste ten lines sorted outside-first, count unexcluded, and have a second party re-run two rows verbatim. Measured across one program's twelve chunks, that was 30–40% of each reviewer's budget, and the ledger itself never surfaced a finding — findings came from reading the code the ledger pointed at.

The script closes every hole at once by removing the chooser. It picks the symbols (every declaration on a `+` or `-` line, plus whole untracked files), the scope (the whole repo, `--untracked`), the order (outside-diff first), and the count (unexcluded), and it prints them deterministically. Doubt it → rerun it. That retires the second-party re-run, the sorted-paste rule, the two-command count rule and the exclusion rules, which is most of what the old §7.1 was.

## What the script deliberately does not do

- **Exclude paths from the count.** Exclusions (`vendor`, `node_modules`, lockfiles, generated code) apply to what is *pasted*, never to `N`. A caller hidden behind an exclusion still shows in the count, so hiding one gains nothing.
- **Judge.** A symbol with outside-diff hits is a lead. The reviewer opens each hit and decides. The script's job ends at "here is who else reads this".
- **Know every language.** The declaration regex covers `func/function/def/class/type/interface/enum/struct/trait/fn/fun/impl`, column-0 `const/let/var/val`, a Go receiver, and SQL `CREATE/ALTER/DROP`. Grouped Go blocks and keyword-less class methods are missed on purpose rather than guessed at; §7.1 has the reviewer add those by the same command, so the addition is still checkable.
- **Measure two ranges.** The old union (uncommitted + committed, summed) double-counted a line changed in both. Working tree against the merge-base is the true net change, one range, and it includes untracked files the old `git diff HEAD` never saw.

## Thresholds

They were fixed numbers in the skill body — 5 files / 150 lines for the floor, 800 / 15 for fan-out, 400 per chunk — and collided with per-project budgets every phase. They now live in `house.md` frontmatter with those numbers as defaults, plus `review-max-chunks` so a fan-out that would blow a budget stops for the user instead of dispatching.
