# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- The branch now gives all three regular enemies an explicit outgoing defeat beat. A separate hidden
  presentation role shows the old profile while Journey, status, the canonical enemy sprite, the
  fixed intent tag, and available actions identify the settled 岩甲兽守巢者 in the same render.
- Asset schema v7 expands the original enemy atlas to 512×256 / eight columns. Every profile has two
  bounded defeat frames; the validator proves all eight cells are populated, distinct, not reaction
  duplicates, and surrounded by transparent borders. Two independent generations match byte for byte.
- The cue arms only from valid `regular_enemy_won` + `boss_arrived` facts during battle. Standard and
  fast lifetimes are 0.70/0.18 seconds; reduced motion freezes the first frame. Malformed, lone,
  non-battle, next-action, expiry, title, reload, retreat, rescue, victory, and replay paths clear it.
- Same-phase boss arrival no longer uses the blocking full-screen transition. The safe-frame message
  reads “灵物退开 · 守巢者现”, and the next independent controller A immediately resolves a warden
  round. True phase and map transitions retain the existing paper reveal.
- Local `make check` is green: 159 Python tests at 100% statement and branch coverage (621 statements /
  316 branches), 21 Evennia tests plus the real two-client journey, 3,202 Godot rule/scene assertions,
  360 chapter E2E checks, 192 physical-input/focus checks, 122 browser unit tests at 100%, and 53
  Playwright executions. Badges, deterministic builds, documentation links, and hygiene also pass.
- The 20-cycle Godot lifecycle passes in `953.07` ms with 117 static / 127 peak nodes, 126 nodes during
  regular-enemy replacement, and zero root leaks. All domain workloads remain below 2.5 seconds.
- Nine source atlases regenerate twice and match the Git index. Two independent 43-PNG capture passes
  are byte-identical at aggregate SHA-256
  `80dfb36a14b81a54b0562932a841d2f295f829d3992eec900f079b31a329bc0b`.
- Four local macOS/arm64 exports, including two independent fresh-cache project copies, match at
  824,432 bytes and SHA-256
  `6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`; manifest verification,
  the unchanged 25-required / nine-excluded resource probe, and packaged boot smoke pass.
- The implementation is locally verified but not yet committed or pushed. The current base head is
  `7d925b4d4546df957ca13e9f4e426918c9186eca`; Draft PR #7 remains open and remote `main` must not be
  merged without authorization.

## Next action

Commit and push the verified outgoing-defeat loop, monitor Draft PR #7 to green, refresh this state
with the exact implementation head and hosted evidence, then begin the intent-specific enemy attack
accent loop without changing save v17 or combat authority.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
