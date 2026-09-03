# program map format

A program map tracks one multi-session feature end to end. It lives in the project's
programs dir (`programs-dir` in `.claude/house.md`, default `.claude/programs/`).
File name: `YYYY-MM-DD-<topic>.md` (topic is free-form, not read by tooling).

## Frontmatter (verbatim keys)

```yaml
  ---
  program: <slug>
  status: active|done|parked
  phases: [...]
  repos: [...]
  last-touched: YYYY-MM-DD
  ---
```

The keys above MUST start at column 0 in a real map file — a session hook that injects
the active map matches `^program:` / `^status:` at line start; the two-space indent here
only keeps this reference from self-matching.

## Headings (verbatim, a hook parses `## §N` at line start)

```
  ## §0 reference locations
  ## §1 กฎของโครง
  ## §2 phase map
  ## §3 สัญญาระหว่าง phase
  ## §4 premises
  ## §5 verify
```

The six headings above MUST be written exactly as shown, each at the start of its own
line in the real map file.

## Rules

1. Drift log: separate file `<topic>.drift.md`; map file ceiling is 150 lines (drift log not counted).
   The line ceiling does not bound bytes, and a session hook that injects the map pays for bytes:
   §1 and §4 together should stay under ~8 KB, or every session of every phase carries the excess.
   A §4 that overflows its injection cap is not a formatting problem — it means that many premises
   are still open, and the answer is to close them, never to trim the table.
   What may occupy a §4 row at all is `prompt-book`'s step 5, not this file: a premise a `git grep`
   settles on demand belongs in the phase plan instead.
2. The verify script MUST be named `verify-<program>.sh`, where `<program>` is the exact
   value of the map's `program:` frontmatter field — NOT derived from the map's filename
   (map files are named `YYYY-MM-DD-<topic>.md`, so a filename-derived name is never found).
   Example: `program: grabfood-activation` → `verify-grabfood-activation.sh`.
   It must `source chk.sh` and be `chmod +x`.
3. `chk.sh` auto-prints the summary via an EXIT trap on the sourcing shell, always ending it
   with a `CHK-DONE <fails>/<asks>` terminator line (a hook strips this line, but its absence
   means FAILs were swallowed, not that the script passed); this collides both ways: a trap the
   script set *before* sourcing is silently overwritten by ours (e.g. a temp-dir cleanup trap
   never runs), and a trap the script sets *after* sourcing overwrites ours, so that script must
   call `chk_summary` itself.
   **สิ่งที่ terminator พิสูจน์ได้มีแค่ว่า `chk_summary` เคยรัน ไม่ได้พิสูจน์ว่า `chk` ทุกตัวเคยรัน** — สคริปต์ที่ `return`/`exit`
   กลางทาง, ห่อ `chk` ไว้ใน `if` ที่ไม่เคยเป็นจริง, วนลูปบน glob ที่ไม่ match อะไรเลย, หรือเรียก `chk_summary`
   ก่อนเช็คตัวหลัง ๆ ล้วนได้ `rc0:completed` เหมือนสคริปต์ที่ผ่านจริงทุกประการ · ทางเดียวคือกฎในขั้นที่ 7 ของ
   `prompt-book`: พัง anchor สักตัวชั่วคราวจนเห็น `FAIL` ออกมาจริงก่อนจะเชื่อว่าเขียว
