# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- Previous loop head: `78f8843 docs(loop): close ferry worksite cycle`.
- The implemented loop adds independent settings v4 `dialogue_speed`: standard 42 characters/s,
  fast 84 characters/s, or instant full-line display. Instant never auto-advances or selects a
  response; changing back to gradual reveal never conceals already-read text.
- V1–v3 settings migrate conservatively to standard while preserving every field valid in their
  source schema. Missing, wrong-type, unknown, malformed, and future v4 data fail closed as one
  object; a failed candidate or promotion leaves the current UI and known-good settings file
  unchanged, and an interrupted rotation recovers its validated backup.
- Paired full-width title/pause controls share keyboard, mouse, and controller paths. The preference
  remains separate from battle speed and reduced motion, survives new/continue/replay, and does not
  change Journey, Patrol, structured Dialogue, game-save bytes, rewards, or save v16.
- Two consecutive 40-image captures match aggregate SHA-256
  `ce846a88dc3ac3f841f883e5872b3511472a0c69c7a500df2fe2f23763abdf46`; only the title and protected
  new-game views intentionally changed among the prior 39, and the new instant-setting view is
  complete at 1152×648.
- Reproducible PCK: 681,960 bytes; SHA-256
  `7fbbf9d9d6c634cc7643fc0b9c7b54539e9af5e55bf97ce6f3a114d230aee888`; 22 required runtime resources,
  nine excluded development resources, manifest verification and packaged boot pass.

## Verified this loop

- `make test-unit` — 136 tests at 100% statement and branch coverage (561 statements / 286
  branches).
- `make test-rpg` — 2,703 assertions, including settings migration, fixed-step reveal, invalid delta,
  failed validation/rotation, backup recovery, current-line switching, and unchanged rule/save authority.
- `make test-rpg-e2e` — 330 checks, including active-line scene reconstruction and preference
  persistence through completion, replay, and explicit new game.
- `make test-rpg-input` — 169 checks; real keyboard and mouse select fast/instant, controller changes
  the active-dialogue pause setting, and resume/next-line semantics remain exact.
- `make test-rpg-performance` — fixed-clock workloads and 13-state lifecycle cycles pass; 114 static,
  124 peak/worksite/dialogue/battle/journal, 122 active patrol, 115 spring, 117 completion, zero leaks.
- `make capture-rpg-ui` twice — identical 40-image aggregate hash; visual review confirms the title,
  protected-new-game, and instant-setting controls fit the minimum window without clipping.
- `make check-rpg-package` — two identical 681,960-byte packs, manifest verification, 22 required
  runtime resources, nine excluded development resources, content probe, and boot smoke pass.
- `make check` — all requested repository gates pass, including Python coverage, Evennia integration,
  live two-client flow, all Godot gates, 122 browser-prototype unit tests, 53 Playwright executions,
  badge verification, and reproducible browser build.

## Next action

Commit and push this feature, monitor Draft PR #7, then refresh the ignored playable package from
the committed revision. The next unblocked product loop is painted-paper portrait refinement and a
denser original NPC schedule.

## Blockers

No blocker for the next loop. Native platform packaging remains intentionally blocked on the owner
decisions recorded in `.loop/PLAN.md` and `docs/PROJECT_CONTEXT.md`.

## Exact verification

```sh
make check
make capture-rpg-ui
shasum -a 256 docs/concepts/gameplay-ui-v1/*.png | shasum -a 256
make capture-rpg-ui
shasum -a 256 docs/concepts/gameplay-ui-v1/*.png | shasum -a 256
```
