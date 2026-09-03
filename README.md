<h1 align="center">prompt-corner</h1>

<p align="center">
  <em>The corner in the wings where the stage manager stands with the book and calls the show.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/skills-6-111111?style=flat-square" alt="6 skills">
  <img src="https://img.shields.io/badge/install-npx%20skills-111111?style=flat-square" alt="npx skills">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT">
</p>

---

A feature that takes more than one session does not fail on the code. It fails on the things
nobody wrote down: the assumption phase 1 made about someone else's API, the contract phase 2
owed phase 3, the repo that merged while its counterpart PR sat open, the review that ticked
twelve files it never opened.

prompt-corner is six skills that hold those seams. They drive a feature from design to the last
merged PR — and stop for you at every gate, every time, including when you tell them not to.

## Before / after

**Without.** Phase 3 discovers the partner API sends `merchantId`, not `merchant_id`. Phase 1
assumed otherwise, and built a mapper on it. Nobody wrote the assumption down, so nothing caught
it — two phases get re-scoped, in the session that can least afford it.

**With.** That assumption was a row in the map before phase 1 started:

```
| P4 | LM sends merchant_id (snake) in the order webhook | external-api | ❓ | partners/lineman/gotchas.md#L88 | LM team |
```

`❓` means blocked, and blocked means phase 1 does not build on it. The verify script prints
`ASK P4` at the top of every session until a human settles it.

## The cast

| Skill | Calls the... | Job |
|---|---|---|
| **`stage-manager`** | cues | Drives a multi-phase feature end to end. Sequences the others, stops at every gate, never writes code itself. |
| **`prompt-book`** | book | Before phase 1: locks the rules, the contracts each phase owes the next, and every premise, each with a `file:line` and a status marker. |
| **`notes-call`** | notes | After a chunk: a coverage ledger where every changed hunk gets a row, then fix-it-here or escalate. |
| **`call-board`** | board | Where every feature stands across every repo — with the half-merge warning that a PR list alone can't give you. |
| **`curtain-hold`** | hold | A premise turned out false. Map the blast radius by grep, classify patch vs structural, stop for the human. |
| **`dress-run`** | dress rehearsal | Craft review of a diff: smell, over-engineering, comment noise, branch shape, cost, blast radius. |

## How it works

```
"build feature X"  →  stage-manager
                          │
                          ├─ 1. brainstorming              only if the design is still fuzzy
                          │
                          ├─ 2. prompt-book                ── STOP ── every ❓/🔒 premise, batched
                          │                                ── STOP ── confirm the finished map
                          │
                          └─ 3. per phase, in order:
                                 writing-plans             this phase only, never the whole feature
                                 implement
                                 notes-call ──┬─ type A ── fixes it itself, max 3 rounds
                                              └─ type B ── curtain-hold ── STOP ── patch or structural?
                                 smoke                     you drive what you can; the rest is a
                                                           blocking checklist for the human
                                 ── STOP ──                report and wait
                                 "push and pr"             one PR per repo, never a merge
```

Every `STOP` waits for a person. There is no flag, mode, or phrasing that walks through one.

### What the ledger is for

`notes-call` builds one row per changed hunk, and each row carries the output of a grep the
**rule** picked — not one the writer picked:

```
| internal/service/order.go (hunk 214–224) | +42/-8 | ✅ | signature changed: ApplyDiscount —
  git grep -n ApplyDiscount -- . ':(exclude)vendor' → report/daily.go:88 · order.go:214
  (2 hits, unexcluded) |
```

It guarantees **completeness**, not depth: every hunk has a row and the line total has to match
`--numstat`. Depth is someone else's job — the second reviewer re-runs two rows verbatim and
reports `ตรง` / `ไม่ตรง`. An attestation you write about your own reading is free, so nothing
here asks for one.

### What a stop looks like

`curtain-hold` never fixes anything. It returns exactly this and waits:

```
ข้อเท็จจริง : voucher_id is nullable in online orders — internal/entity/order.go:88
ขัดกับ      : §3 contract "phase 2 always supplies voucher_id"
กระทบ       : receipt print (print/receipt.go:214) · KDS summary (kds/summary.go:66)
จำแนก       : structural — เข้าเกณฑ์ข้อ C2
A (patch)      : null-guard at the mapper · 20 min · debt: two more readers stay unguarded
B (structural) : fix §3, re-scope phase 3 · half a day
แนะนำ       : B — A leaves the same bug in two places nobody is tracking
```

## Install

### Claude Code — as a plugin (recommended)

A plugin namespaces every skill, so they read as `prompt-corner:stage-manager` in the skill list
and are easy to find next to your other sets:

```bash
claude plugin marketplace add Hin-Nattapat/prompt-corner
claude plugin install prompt-corner@prompt-corner
```

Or from inside a session, as two separate prompts:

```
/plugin marketplace add Hin-Nattapat/prompt-corner
```
```
/plugin install prompt-corner@prompt-corner
```

Skills load on the next session. `claude plugin details prompt-corner` shows the inventory and its
token cost (~1k always-on for all six).

### Claude Code — as plain skills

Same skills, no namespace — they appear under their bare names. Use this if you'd rather not add a
marketplace:

```bash
npx skills add Hin-Nattapat/prompt-corner -g -a claude-code --skill '*' -y   # every project
npx skills add Hin-Nattapat/prompt-corner -a claude-code --skill '*' -y      # this project only
```

Pick one or the other. Installing both leaves two copies of every skill in the list.

### Other agents

The skills are plain [Agent Skills](https://agentskills.io) — swap `-a claude-code` for `-a codex`,
`-a cursor`, `-a opencode`, or any other host the [`skills`](https://github.com/vercel-labs/skills)
CLI supports. The workflow assumes a git repo and, for `call-board`, the `gh` CLI.

### Update

```bash
claude plugin update prompt-corner                 # plugin install (restart to apply)
npx skills update -g                               # plain-skill install
```

### Uninstall

```bash
claude plugin uninstall prompt-corner@prompt-corner
claude plugin marketplace remove prompt-corner
# or, for a plain-skill install:
npx skills remove stage-manager prompt-book notes-call call-board curtain-hold dress-run
```

## Per-project settings — `.claude/house.md`

Every skill reads this file if it exists and falls back to a default if it doesn't. Nothing breaks
in a project that has never seen it. **Never edit a skill to hold something project-specific — that
is what this file is for.** Copy [`house.example.md`](house.example.md) to get started.

```yaml
---
repos: [service-a, service-b, ../other-workspace/web]
base-branch: develop
programs-dir: docs/programs
---
```

| Key / section | Read by | Default when absent |
|---|---|---|
| `repos:` | `call-board` | every git repo at the root and one level down |
| `base-branch:` | `notes-call`, `dress-run` | `origin/HEAD`, else `main` |
| `programs-dir:` | `prompt-book`, `call-board` | `.claude/programs/` |
| `## Default flow` | `stage-manager`, `curtain-hold` | the sequence above |
| `## Git tail` | `stage-manager` | branch → group → rebase → push → PR, never merge |
| `## Smoke` | `stage-manager` | drive what you can, hand the rest over as a blocking checklist |
| `## Reference locations` | `prompt-book` | nothing to sweep |
| `## Known consumers` | `curtain-hold`, `dress-run` | grep only |
| `## Shared modules` | `dress-run` | callers are in-repo only |
| `## Hot paths` | `dress-run` | per-request paths, polls and webhooks |
| `## Extra warnings` | `call-board` | the three built-in warnings only |
| `## Review additions` | `dress-run` | the packs alone |

## Language packs

`dress-run` picks packs by the file extensions in the diff, on top of its universal groups
(comment noise, branch shape, over-engineering, dirty code, edge cases, blast radius, cost):

| Extension | Pack |
|---|---|
| `*.go` | [`packs/go.md`](skills/dress-run/packs/go.md) |
| `*.ts *.tsx *.js *.jsx` | [`packs/react.md`](skills/dress-run/packs/react.md) |

A language with no pack still gets every universal group — the review says so in its opening line.
**Adding a language is one file**, no change to the skill.

## The program map

`prompt-book` writes one file per multi-session feature, in `programs-dir`, with six fixed
headings and a frontmatter block. [`reference/map-format.md`](skills/prompt-book/reference/map-format.md)
is the authority; the short version:

```yaml
---
program: <slug>
status: active|done|parked
phases: [...]
repos: [...]
last-touched: YYYY-MM-DD
---
## §0 reference locations   ## §1 rules + a metric that can fail
## §2 phase map             ## §3 contracts between phases
## §4 premises              ## §5 verify
```

Every §4 premise carries a status marker, and they are not decoration:

| | Meaning |
|---|---|
| ✅ | confirmed, with a `file:line` |
| ❓ | unverified — **do not plan past it** |
| 🔒 | only a human can settle it — **do not design over it** |
| 🔓 | waived on a date, with the assumption it rests on written down |
| ❌ | turned out false |

§5 points at a `verify-<program>.sh` built on the shipped
[`chk.sh`](skills/prompt-book/assets/chk.sh) — one `chk` line per premise a grep can settle, one
`ask` line per premise only a person can. `prompt-book` will not call it done until it has watched
the script actually print `FAIL` with an anchor deliberately broken. A script that has never failed
proves nothing.

## Design rules

- **A claim without a `file:line` gets cut, not softened.** A comment in the code is the previous
  author's belief, not evidence. The shape of our own code proves what we read, never what the
  other side sends.
- **Stops are not advisory.** Every gate ends by waiting for a human. "Auto mode" is not an
  exception, and neither is a stop that arrives when the work is nearly done — that is the most
  expensive moment to skip one, not the cheapest.
- **Reviews find edge cases; more assertions do not.** These skills weight reading and grepping
  over test volume on purpose.
- **A rule with no way to fail is not a rule.** Map rules carry the command that would go red.

## Development

Both install shapes copy the files rather than symlinking them, so an edit needs a refresh:

```bash
git clone https://github.com/Hin-Nattapat/prompt-corner && cd prompt-corner
$EDITOR skills/dress-run/packs/go.md
git push

claude plugin update prompt-corner                      # plugin install, then restart the session
npx skills add . -g -a claude-code --skill '*' -y       # plain-skill install, straight from the working copy
```

The second form takes a local path, so it picks up an edit without a push — handy while iterating.

**`claude plugin update` compares the `version` in `.claude-plugin/plugin.json`, not the commit.**
A push without a version bump reports "already at the latest version" and installs nothing. Bump the
version in the same commit as the change, every time.

Layout:

```
skills/<name>/SKILL.md          the skill; frontmatter description is what makes it fire
skills/prompt-book/assets/      chk.sh, seeded into a project's programs dir
skills/prompt-book/reference/   the program-map format authority
skills/dress-run/packs/         one file per language
house.example.md                the per-project settings template
```

## FAQ

**Do I have to use all six?** No. `dress-run` and `call-board` stand alone. `stage-manager` is the
one that assumes the others.

**Does it work in a repo with no program map?** Yes — that is the lean path, and it is where most
work stays. `notes-call` collapses to a one-line ledger under 5 files / 150 lines, and
`prompt-book` refuses to write a map for single-phase work.

**Will it commit or push for me?** No. Committing, pushing, merging and running a project-wide
formatter are refused at every diff size.

**Why is some of it in Thai?** The report formats are fixed strings the author reads at a glance.
They are transcribed verbatim, not translated, so they stay diffable.

## License

MIT
