# dress-run pack — Python

Runs when the diff contains `*.py`, on top of the universal groups in `SKILL.md`.
Project rules — which modules may import a binding, which layer owns an enum, which constants need a source — live under `## Review additions` in `.claude/house.md`; read it and fold those rows in here. This file knows the language, not the project.

## G1 — method on the model
Logic that belongs on the dataclass / pydantic model but got written where the model is used.
- construction from a file or dict → `Config.from_yaml(path)` / `model_validate`, not a loader function with twelve keyword arguments
- predicate on state → `state.is_terminal` (a property), not `if state.phase in (A, B) and state.t >= state.t_end`
- transition on a frozen model → `state.advanced(dt)` returning `dataclasses.replace(...)`, not a caller assembling the next state field by field
- request / command building → a small named helper

Signal: a function that reads as attribute reads and inline conditions instead of intent-named calls.

## G2 — named payload
- multi-field constructor inlined into a call argument
- result fused into the check: `if (r := run(...)) is None:` or `if run(...).ok:`

Both become: build → capture → check on its own line.

```python
# Bad — literal wall inlined AND fused into the if
if not runner.submit(Job(id=cfg.id, seed=cfg.seed, steps=cfg.horizon_s // cfg.dt_s, out=out_dir / f"{cfg.id}.parquet")).ok:
    ...

# Good
job = Job(id=cfg.id, seed=cfg.seed, steps=cfg.horizon_s // cfg.dt_s, out=out_dir / f"{cfg.id}.parquet")
result = runner.submit(job)
if not result.ok:
    ...
```

## G3.5 — branch shape, in Python

```python
# Bad — arms of unequal depth, the real case buried under else
if phase.is_terminal:
    log.info(...)
else:
    if event.kind == "success":
        state = replace(state, succeeded_at=t)
    elif event.kind == "failure":
        if event.errors:
            state = replace(state, failed_at=t, errors=encode(event.errors))

# Good — one level, every arm calls something named
match (phase.is_terminal, event.kind):
    case (True, _):        log.info(...)
    case (_, "success"):   state = state.succeeded(t)
    case (_, "failure"):   state = state.failed(t, event.errors)
```

A guard that ends early goes at the top as `return` / `raise`, never as the last `else`.

## G5 — dirty code, Python-specific
- a physical quantity with no unit in its name — `speed`, `length`, `timeout` → `speed_mps`, `length_m`, `timeout_s`; the type says float, only the name says what float
- an identifier the domain treats as its own kind passed around as bare `str` where a `NewType` exists — and `str(x)` on a `NewType` value, which silently strips it
- `dict[str, Any]` / `TypedDict` crossing a layer boundary where a model exists
- `# type: ignore` / `# noqa` with no code and no reason
- `assert isinstance(x, T)` used to narrow for mypy → `typing.cast`; the assert is stripped under `-O` and then checks nothing
- a `_private` name imported by several test files → it is public; drop the underscore

## G6 — edge cases, Python-specific
- mutable default: `def f(x, acc=[])`, `field(default={})` → `default_factory`
- float equality on a measured or computed value: `==` → `math.isclose` / a tolerance the domain names
- output that depends on `set` iteration order or on the insertion order of a dict built from unordered input → sort before it leaves the function; a `set` or `dict.keys()` interpolated into a message or log is the same leak
- `functools.reduce(f, seq)` with no initial value → `TypeError` on an empty sequence
- pytest: a registry filled at import time plus `monkeypatch` on the same global → passes in the suite, fails alone (or the reverse)
- **determinism leak** in a function the caller expects to reproduce: `datetime.now()`, `time.time()`, `random.*` with no seed threaded in, `os.urandom`, `uuid4`, iteration over `os.listdir` / `glob` unsorted
- `except:` bare, or `except Exception: pass` — the error has to be typed or re-raised
- `Optional` read without a `None` branch in the same function
- `@dataclass` that holds state without `frozen=True`, or `frozen=True` with a mutable field (`list`, `dict`) that is still mutated in place
- pydantic v2: `.dict()` / `.parse_obj()` (v1 API, deprecated) · `model_validate` result discarded and the raw dict used after · a validator that mutates

## G8 — cost, Python-specific
- polars / pandas: row-wise `apply`, `iter_rows`, `for row in df` where a column expression does it · `.collect()` inside a loop · a DataFrame built by appending in a loop → build once from a list
- polars: `.unique()` does not keep order (`maintain_order=True` when the order is the result) · `in_place=True` on a frame someone else holds
- the same parquet / CSV re-read per metric with no memo on the loader
- a subprocess / simulator step call inside a Python loop where the binding batches it

Caller sweep:
```bash
git grep -n -E "\b<name>\(" -- '*.py' ':(exclude)tests' ':(exclude)*_test.py'
```
Tests are callers for the ledger, not for cost — exclude them here, not there.
