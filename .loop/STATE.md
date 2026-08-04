# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- The branch now draws nine color-independent enemy-foot geometry fingerprints with a Chinese
  “刚才 · 势名 · 受到冲击/化开冲势” equivalent only after a strict old-intent gate proves an
  enemy response resolved. The fixed intent tag independently shows the settled next intent.
- Arming requires battle phase, valid old enemy/intent IDs, exactly one hit/glance event, a catalog
  match, the same settled enemy, and no terminal fact. Malformed, mismatch, lethal, replacement,
  expiry, title, load, replay, leave-battle, and immediate same-enemy re-entry clear atomically.
- Standard/fast timing remains 0.70/0.18 seconds. Full motion uses only a bounded secondary stroke;
  reduced motion freezes the complete first frame and preserves the result text. Large text and high
  contrast remain screen-safe. The cue owns no rules, damage, intent, gameplay timing, input, or save.
- Local `make check` is green: 159 Python tests at 100% statement and branch coverage (621 statements /
  316 branches), 21 Evennia tests plus the real two-client journey, 3,530 Godot rule/scene assertions,
  374 chapter E2E checks, 198 physical-input/focus checks, 122 browser unit tests at 100%, and 53
  Playwright executions. Badges, deterministic builds, documentation links, and hygiene also pass.
- The 20-cycle Godot lifecycle passes in `952.63` ms with 117 static / 127 peak nodes and zero root
  leaks. All domain workloads remain below 2.5 seconds.
- Nine source atlases regenerate twice and match the Git index. Two independent 43-PNG capture passes
  are byte-identical at aggregate SHA-256
  `153ee23c5cbf0a6208fd9853b2722e7fb032ef2539468a210b47ffa8278568b4`.
- Four local macOS/arm64 exports, including two independent fresh-cache project copies, match at
  869,776 bytes and SHA-256
  `fb91ed3c31f80b5cd01f957b54364fc1a96d7f195dbea069e2797e245ee004d3`; manifest verification,
  the unchanged 25-required / nine-excluded probe, and packaged boot pass locally.
- The current attack-accent input is not committed or pushed and has no hosted Linux CI result yet.
  Historical outgoing-defeat run `30873652565` remains green at 824,432 bytes / SHA-256
  `6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`. Draft PR #7 remains open
  and draft; `main` was not merged.

## Next action

Audit the current diff, commit and push the attack-accent loop, update Draft PR #7, and monitor all
hosted checks without merging `main`. After hosted evidence closes, begin the next bounded original
NPC schedule or side-story content loop.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
