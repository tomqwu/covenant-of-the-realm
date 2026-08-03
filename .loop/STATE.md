# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Current clean head: `9c271dc09a156b8f3a1efb06176c030651521565` (`fix(ci): confirm clean
  lifecycle overages`). It preserves the 20-cycle, 7-second, 114-static, 124-peak, map/camera, and
  zero-leak contracts and gives only an otherwise-clean timing overage one complete confirmation.
- The docs-only closeout run
  [30854940370](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30854940370) passed MUD,
  Multiplayer E2E, and Journey quality but reported one RPG lifecycle timing failure: 7,210.19 ms
  against the existing 7,000 ms ceiling. Its RPG code, scene, budget, Makefile, and workflow blobs
  are identical to the preceding 5,997.67 ms green run; all 2,703 rule/scene, 330 E2E, and 169 input
  assertions completed before the time-only failure.
- Its hosted run
  [30856454063](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30856454063) passed MUD,
  Multiplayer E2E, and Journey quality. RPG completed every assertion and then correctly reported
  two clean but slow lifecycle samples (`7,812.553` and `7,563.640` ms), 40 total cycles, 114/124
  nodes, and zero leaks. Pure workloads on the same host were also 25–35% slower than recent green
  hosts, confirming shared-VM slowdown rather than a structural failure.
- The pending workload refinement keeps all 20 cycles and all 13 states, including dialogue start,
  line completion/advance, autosave, response save, patrol, worksite dialogue, battle, journal,
  spring ritual, completion, map/camera checks, and cleanup. Each complete sample's first cycle runs
  the full reveal profile with four real settings writes; cycles 2–20 no longer multiply settings
  flush/verification/backup rotation and full label-theme refresh by 20.
- Raw elapsed time remains authoritative across the exact boundary. Reports display rounded timing,
  retain every sample, total cycle count, actual probe/write counts, merge structural maxima across
  both samples, and print complete results plus every failure before returning nonzero.

## Verified this loop

- Six deterministic in-run policy checks cover first-sample success, raw just-over-boundary
  confirmation, prior-failure rejection, recovered confirmation, sustained overage, and accepted
  low-contention sample selection.
- Normal `make test-rpg-performance` passes in one `1,043.88` ms sample: 20 cycles, one reveal
  probe, four settings writes, all 13 state peaks, 114 static / 124 peak nodes, and zero root leaks.
- Deliberate test-only 1 ms scene budget: two complete samples (`1,038.53` and `1,013.95` ms), 40
  total cycles, two probes, eight writes, 114/124/zero-leak evidence, and a nonzero result.
- Deliberate 1 ms movement plus scene budgets: movement fails; lifecycle performs only one
  `1,057.52` ms sample with 20 cycles, one probe, and four writes; the result remains nonzero.
- Both temporary budget edits were restored. `rpg/tests/performance_budget.json` has no diff and
  remains at 2,500 ms pure-workload / 7,000 ms lifecycle limits.
- `make check-rpg` passes: 2,703 Godot rule/scene assertions, 330 chapter E2E checks, 169 physical
  input/focus checks, one `1,155.47` ms lifecycle sample, deterministic assets, captures, and
  reproducible package/content/boot gates. PCK remains 681,960 bytes with SHA-256
  `7fbbf9d9d6c634cc7643fc0b9c7b54539e9af5e55bf97ce6f3a114d230aee888`.
- Repository-wide `make check` passes with another `1,065.80` ms lifecycle sample, 136 Python tests
  at 100% statement/branch coverage, the real two-client MUD journey, all Godot gates, 122 browser
  unit tests at 100% coverage, 53 Playwright executions, badges, and a reproducible browser build.

## Next action

Review the complete diff, then commit, push, and monitor Draft PR #7. After the hosted run is green,
refresh the ignored playable package from the clean revision and resume the painted-paper portrait
refinement loop.

## Blockers

No product blocker. Native platform packaging remains intentionally blocked on the owner decisions
recorded in `.loop/PLAN.md` and `docs/PROJECT_CONTEXT.md`.

## Exact verification

```sh
make test-rpg-performance
make check-rpg
make check
```
