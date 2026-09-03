---
repos: [service-a, service-b, web]
base-branch: develop
programs-dir: docs/programs
---

# house rules

Per-project settings for the `prompt-corner` skills. Every section is optional.

## Default flow
1. Flow Summary → user confirms. 2. Implement on a feature branch. 3. Self-check (scoped
formatter, build passes). 4. Review → `notes-call`. 5. Smoke. 6. STOP, wait for the user.
7. On "push and pr" → the git tail below.

## Git tail
Group into 3–5 logical commits → rebase onto the base branch → `push --force-with-lease -u`
→ open the PR, return the URL. Never merge.

## Smoke
Backend: run it yourself against the local service. UI you cannot drive: write a concrete
checklist and hand it to the user as a blocking gate.

## Reference locations
- `docs/integrations/*/gotchas.md` — read in full when the work touches that integration

## Known consumers
Reports · print · the mobile app · anything reading the events this service emits

## Shared modules
`lib-common` → consumed by service-a, service-b. Downstream repos re-pin after it merges.

## Hot paths
Order placement · payment · terminal sync · any webhook

## Extra warnings
- **Client-release ordering**: a mobile PR merging before its backend counterpart is deployed.
- **Stale shared-module bump**: upstream merged, no downstream bump PR after it.

## Review additions
- FE: number inputs use `FormInput` `min`/`max`; errors route through `showApiErrorToast`.
- BE: a new field must be declared on the Response struct, not only preloaded.
