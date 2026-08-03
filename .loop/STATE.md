# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Clean head: `87e5e5d297ac5b14318deeb0bd4f3ac675555d1b` (`docs(loop): close
  lifecycle stability cycle`), pushed to the feature branch. Draft PR #7 remains OPEN, Draft,
  MERGEABLE/CLEAN, and unmerged; remote `main` remains
  `7256ade54792ff481ffc30517ca2c693f78be198`.
- The implementation and docs-only closeout runs are both green across all four jobs:
  [30857633042](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30857633042) and
  [30858287644](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30858287644). Their Linux
  lifecycle samples pass once at `5,878.46` and `6,159.13` ms with 20 cycles, one probe, four verified
  settings writes, 114 static / 124 peak nodes, and zero leaks.
- The active portrait loop is presentation-only. It must keep the stable six-ID order
  `protagonist`, `yanqing`, `liangshu`, `huishen`, `tao_xiaoman`, `journal`; unknown IDs still fall
  back to `journal`. No external asset, runtime node, input surface, save field, content ID, or rule
  authority may be added.
- Portrait visual contract revision 2, all six silhouette/expression/prop profiles, and the
  capture-only 3×2 Chinese comparison board are implemented. `make test-rpg` passes 2,716 assertions.
  Two complete 41-PNG capture passes are byte-identical at aggregate SHA-256
  `6e1c0f5b3bca174f25726bfec6de61c86bb9962e57641ca29de90717dc68f4b7`.
- The dirty-tree package gate passes two exports, manifest verification, content probing, and boot
  smoke: 697,160 bytes, SHA-256
  `2f1c122199227f9c9a02537a4b9311c44f8ed03285c8b87267c995b6e45cf5a5`, 22 required resources,
  and nine development resources excluded. Refresh the ignored manifest from the final clean head.

## Verified baseline

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
- `make check-rpg` passes the portrait candidate: 2,716 Godot rule/scene assertions, 330 chapter E2E
  checks, 169 physical input/focus checks, one `1,037.19` ms lifecycle sample, deterministic assets,
  and reproducible package/content/boot gates. PCK is 697,160 bytes with SHA-256
  `2f1c122199227f9c9a02537a4b9311c44f8ed03285c8b87267c995b6e45cf5a5`.
- Repository-wide `make check` passes with another `1,049.49` ms lifecycle sample, 136 Python tests
  at 100% statement/branch coverage, the real two-client MUD journey, all Godot gates, 122 browser
  unit tests at 100% coverage, 53 Playwright executions, badges, and a reproducible browser build.

## Next action

Review the intentional PNG/code/docs diff, then commit, push, monitor Draft PR #7, and refresh the
ignored playable-package manifest from the clean head.

## Blockers

No product blocker. Native platform packaging remains intentionally blocked on the owner decisions
recorded in `.loop/PLAN.md` and `docs/PROJECT_CONTEXT.md`.

## Exact verification

```sh
make test-rpg-performance
make check-rpg
make check
make capture-rpg-ui
shasum -a 256 docs/concepts/gameplay-ui-v1/*.png | shasum -a 256
```
