# dress-run pack — React / TypeScript

Runs when the diff contains `*.ts *.tsx *.js *.jsx`, on top of the universal groups in `SKILL.md`.
A project's own component-library rules (which input clamps, which toast helper, which button props) live under `## Review additions` in `.claude/house.md` — read it and fold those rows in here.

## Findings

- side-effect chained from a user event via `useEffect` → must be inline in the handler (subscribing to external state / cleanup-required effects are fine)
- inline arrow carrying logic passed straight into a prop or callback (`onClick={() => { ... }}`, `onChange`, `map` / `filter` / `sort` bodies) → extract it. Pure logic (format, compute, map, sort, predicate) goes to `utils/`; logic that reads component state/props becomes a named `handleX` above the return. The call site should then read as one line: `onClick={handleConfirm}` / `items.map(toRowVm)`. A straightforward 1–2-line arrow stays inline — don't flag `onClick={() => setOpen(true)}`.
- `.then()` chain → inner `async` fn + `void fn()`
- `any` → `unknown` + type guard, or the real type
- fn/hook taking a destructured object arg with no named `interface`
- a component's colors/sizing overridden via `className` where an existing variant prop says the same thing
- number input reimplementing clamping the shared form input already does
- error handling branching on `error.response.status` instead of the project's error-code path
- imperative modal taking positional args instead of a single props object
- JSX hoisted into a shared variable then rendered in different order per branch (inline it)
- run of 4+ derived `const isX = cond ? a : b` flags keyed off the same state → a module-level config `Record` keyed by that state, or a function returning the view model in `utils.ts`. Independent flags driven by different things are fine — the smell is one branching rule restated across six lines.

Plus the universal G3–G6 and G8 read for TS: comment noise, over-engineering, dirty code, edge cases, cost in a render path or effect.
