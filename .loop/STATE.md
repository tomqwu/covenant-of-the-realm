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
- The 20-cycle Godot lifecycle passes locally in `948.09` ms and on GitHub-hosted Linux in
  `5,008.02` ms against the unchanged 7,000 ms ceiling, with 117 static / 127 peak nodes and zero
  root leaks. All domain workloads remain below 2.5 seconds.
- Nine source atlases regenerate twice and match the Git index. Two independent 43-PNG capture passes
  are byte-identical at aggregate SHA-256
  `153ee23c5cbf0a6208fd9853b2722e7fb032ef2539468a210b47ffa8278568b4`.
- Four local macOS/arm64 and four hosted Linux/x86_64 exports from run `30879113809`, each including
  two independent fresh-cache project copies, match at 870,720 bytes and SHA-256
  `7959ac89fe6f058b742883cacc04c6b2398b8d72355b8ce9b663e934630fbc98`; manifest verification,
  the unchanged 25-required / nine-excluded probe, and packaged boot pass locally and hosted.
- Feature commit `02dc402`, allocation commit `7dfdd98`, and hot-path commit `1fe1a8c` are pushed.
  Runs `30877432459` and `30878257664` passed functional RPG gates but exposed strict lifecycle
  overages; no budget or assertion was weakened. Run `30879113809` passed RPG, MUD, Multiplayer,
  and Journey after the hot-path fix, including hosted packaging. Draft PR #7 remains open and
  draft; remote `main` remains `7256ade54792ff481ffc30517ca2c693f78be198` and was not merged.

## Next action

Update Draft PR #7 with the resolved-intent evidence, commit and push this closeout snapshot, and
monitor its hosted checks without merging `main`. Then begin the next bounded original NPC schedule
or side-story content loop.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
