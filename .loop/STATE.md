# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Base before this loop: `a897aeb feat(rpg): add saved ferry runner patrol`
- The uncommitted loop expands ferry/path maps to 48×27 (1536×864), adds a shared deterministic
  `WorldRoot` camera, keeps screen-space UI fixed, and leaves save v15 unchanged.
- Two consecutive 36-image captures match aggregate SHA-256
  `5b173b47176d3db8b8fcc2ebafa8807003a46e45d20b7d037b31bd6455a48b66`.
- Reproducible PCK: 630,040 bytes; SHA-256
  `c67c77cfd32219a48803b67326705c21bf0b1739118b766c71f8924db7202e50`.

## Verified this loop

- `make test-rpg` — 2,052 assertions.
- `make test-rpg-input` — 132 checks.
- `make test-rpg-e2e` — 238 checks.
- `make test-rpg-performance` — fixed-clock workloads and 20 lifecycle cycles pass; 112 static,
  122 peak, 120 patrol, 113 spring, 115 completion, zero root-child leaks.
- `make capture-rpg-ui` twice — identical 36-image aggregate hash.
- `make check-rpg-package` — reproducible pack, manifest verification, 18 required resources,
  nine excluded development resources, content probe, and boot smoke pass.
- `make check` — all requested repository gates pass, including Python coverage, Evennia integration,
  live two-client flow, all Godot gates, 122 browser-prototype unit tests, 53 Playwright executions,
  badge verification, and reproducible browser build.

## Next action

Review the final diff and staged scope, then commit and push this loop to Draft PR #7. Monitor CI
without merging. After CI is green, begin the enemy semantic-animation loop.

## Blockers

No blocker for the current loop. Native platform packaging remains intentionally blocked on the
owner decisions recorded in `.loop/PLAN.md` and `docs/PROJECT_CONTEXT.md`.

## Exact verification

```sh
make check
```
