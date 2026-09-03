# dress-run pack — Go

Runs when the diff contains `*.go`, on top of the universal groups in `SKILL.md`.

## G1 — struct method
Logic that belongs on the type but got dumped in the service layer.
- entity construction from a form → `Form.ToEntity()`
- predicate on state → `entity.IsActive()` / `entity.BelongsTo(id)`
- state mutation → `entity.MarkReleased(at)`
- request building → a small named helper

Signal: a service method reading as a wall of field assignments and inline conditionals instead of a sequence of intent-named calls. Exception: a one-line switch that already reads clearly stays inline — no method for a single trivial caller.

## G2 — named payload
- multi-field struct literal inlined into a client/repo call argument
- result fused into the check: `if err := call(...); err != nil`

Both must become: build payload → capture result → check on its own line.

```go
// Bad — literal wall inlined into the call AND fused into the if
if err := s.client.Notify(ctx, dto.Request{ID: *o.MemberID, Type: dto.TypeX, Title: "…"}); err != nil { log... }

// Good — payload built first, result captured, check separate
req := dto.Request{ID: *o.MemberID, Type: dto.TypeX, Title: "…"}
nErr := s.client.Notify(ctx, req)
if nErr != nil { log... }
```

## G3.5 — branch shape, in Go

```go
// Bad — ต้องจำว่าอยู่ใน else, สอง case ยาวไม่เท่ากัน, if ซ้อน if
if row.IsTerminal() {
    log.Info(…)
} else {
    switch req.Status {
    case StatusSuccess:
        row.SucceededAt = &at
    case StatusFailed:
        row.FailedAt = &at
        if len(req.Errors) > 0 {
            if errs, err := json.Marshal(req.Errors); err == nil { … }
        }
    }
}

// Good — สามทางออก ระดับเดียวกัน แต่ละแขนเรียกของที่มีชื่อ
switch {
case row.IsTerminal():            log.Info(…)
case req.Status == StatusSuccess: row.MarkSucceeded(at)
case req.Status == StatusFailed:  row.MarkFailed(at, encodeSyncErrors(req.Errors))
}
```

## G6 — edge cases, Go-specific
- nil deref on a `*T` field the diff newly reads
- `decimal.Decimal` compared with `==` instead of `.Equal()` / `.Cmp()`
- `time.Time` zero-value check that year-0 parse results slip past
- returning a bare `error` where the layer contract is a typed application error
- ORM many-to-many write not in DELETE → UPDATE → CREATE order
- new unique index missing its soft-delete predicate (`WHERE deleted_at IS NULL`)
- `_ =` swallowing an error

## G8 — caller sweep, Go
```bash
git grep -n "FuncName(" -- '*.go' ':(exclude)vendor' ':(exclude)mocks'
```
Generated mocks are not callers.
