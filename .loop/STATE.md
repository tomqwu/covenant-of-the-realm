# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Clean implementation head: `30ed41ad82906a1bf382968b24f43108240b3f69` (`feat(rpg): refine
  painted-paper portraits`), pushed to the feature branch. Draft PR #7 remains OPEN, Draft,
  MERGEABLE/CLEAN, and unmerged; remote `main` remains
  `7256ade54792ff481ffc30517ca2c693f78be198`.
- [GitHub Actions run 30859844869](https://github.com/tomqwu/covenant-of-the-realm/actions/runs/30859844869)
  is green across MUD quality, real Multiplayer E2E, Journey prototype, and RPG quality. Linux RPG
  passes 2,716 / 330 / 169 assertions, one `6,076.61` ms 20-cycle lifecycle sample, one reveal probe,
  four verified settings writes, 114 static / 124 peak nodes, and zero leaks.
- The completed portrait loop keeps the stable six-ID order
  `protagonist`, `yanqing`, `liangshu`, `huishen`, `tao_xiaoman`, `journal`; unknown IDs still fall
  back to `journal`. It adds no external asset, runtime node, input surface, save field, content ID,
  or rule authority.
- Portrait visual contract revision 2, all six silhouette/expression/prop profiles, and the
  capture-only 3×2 Chinese comparison board are implemented. `make test-rpg` passes 2,716 assertions.
  Two complete 41-PNG capture passes are byte-identical at aggregate SHA-256
  `6e1c0f5b3bca174f25726bfec6de61c86bb9962e57641ca29de90717dc68f4b7`.
- The ignored local playable package is refreshed from clean head `30ed41a`: 697,160 bytes, macOS
  SHA-256 `2f1c122199227f9c9a02537a4b9311c44f8ed03285c8b87267c995b6e45cf5a5`, 22 required resources,
  nine development resources excluded, content/boot smoke complete, and a clean manifest. Linux CI
  independently double-exports the same size at SHA-256
  `1b8a4a14b9e72fb5352711bda70794203627b476221abdc789f31da38c605713`; current evidence is
  intentionally host-scoped rather than a cross-OS byte-identity claim.

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

Commit and push this portrait closeout, monitor its docs-only run, update Draft PR #7, then implement
the host-scoped package-manifest contract recorded in `.loop/PLAN.md`.

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
