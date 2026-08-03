# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Previous clean head: `6cc272e129113f6c36e635eccf793931bf185468` (`docs(loop): close
  dialogue reveal cycle`). The accessible dialogue feature commit `d3eb951` passed all four jobs in
  GitHub Actions run
  [30854348421](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30854348421).
- The docs-only closeout run
  [30854940370](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30854940370) passed MUD,
  Multiplayer E2E, and Journey quality but reported one RPG lifecycle timing failure: 7,210.19 ms
  against the existing 7,000 ms ceiling. Its RPG code, scene, budget, Makefile, and workflow blobs
  are identical to the preceding 5,997.67 ms green run; all 2,703 rule/scene, 330 E2E, and 169 input
  assertions completed before the time-only failure.
- The local fix keeps the first complete 20-cycle, 13-state sample and every existing 7-second,
  114-static, 124-peak, map/camera, and zero-leak contract. Only an otherwise-clean time overage
  receives one second complete sample in the same process; any prior or structural failure prevents
  confirmation, and both samples must exceed 7 seconds to fail.
- Raw elapsed time remains authoritative across the exact boundary. Reports display rounded timing,
  retain every sample and total cycle count, merge structural maxima across both samples, and print
  complete results plus every failure before returning nonzero.

## Verified this loop

- Six deterministic in-run policy checks cover first-sample success, raw just-over-boundary
  confirmation, prior-failure rejection, recovered confirmation, sustained overage, and accepted
  low-contention sample selection.
- Normal `make test-rpg-performance` passes in one 20-cycle sample with 114 static nodes, 124 peak,
  all 13 state peaks, and zero root leaks.
- Deliberate test-only 1 ms scene budget: two complete samples (`1,138.95` and `1,110.84` ms), 40
  total cycles, 114/124/zero-leak evidence retained, and the gate returns nonzero. The checked-in
  7,000 ms budget was restored immediately afterward.
- Deliberate 1 ms movement plus scene budgets: movement fails, lifecycle performs only one 20-cycle
  sample, the failure report remains nonzero, and both checked-in budgets were restored afterward.
- `make check-rpg` passes: 2,703 Godot assertions, 330 chapter E2E checks, 169 physical input/focus
  checks, one 1,141.70 ms lifecycle sample, deterministic assets, and reproducible package/content/
  boot gates. PCK bytes remain 681,960 with SHA-256
  `7fbbf9d9d6c634cc7643fc0b9c7b54539e9af5e55bf97ce6f3a114d230aee888`.
- Repository-wide `make check` passes, including 136 Python tests at 100% statement/branch coverage,
  all Godot gates, 122 browser unit tests at 100% coverage, 53 Playwright executions, badges, and a
  reproducible browser build.

## Next action

Review the complete diff, commit and push the focused CI hardening, then monitor Draft PR #7. After
the run is green, refresh the ignored playable package from the clean revision and resume the
painted-paper portrait refinement loop.

## Blockers

No product blocker. Native platform packaging remains intentionally blocked on the owner decisions
recorded in `.loop/PLAN.md` and `docs/PROJECT_CONTEXT.md`.

## Exact verification

```sh
make test-rpg-performance
make check-rpg
make check
```
