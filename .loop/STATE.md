# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- The branch adds the original “晴绳路签” scene at the existing mountain old-marker anchor. The
  player chooses a low knot for burden carriers or a high bright streamer for mist and wind. The
  result persists in map geometry, repeat inspection, journal, chapter summary, epilogue, and the
  lowest-priority 岑苇 echo without changing items, statistics, routes, combat, rewards, or mainline.
- Save v18 adds `path_mark_response` plus the resumable `path_mark_briefing`. V1–v17 migrate to
  neutral `unanswered`; v17 preserves the exact path-keeper route. Forged legacy dialogue IDs,
  wrong phase/state/position, and a response submitted after moving away all fail closed. Replay
  clears the choice. The map contract denies collision, quest, battle, reward, rule, input,
  gameplay-timing, and save authority.
- Current local targeted gates are green: 160 Python tests at 100% statement and branch coverage
  (653 statements / 334 branches), 3,643 Godot rule/scene assertions, 391 complete-chapter E2E
  checks, and 210 semantic physical-input/focus checks. The final repository-wide `make check`
  remains to be rerun after the documentation snapshot.
- The 20-cycle, 17-state lifecycle passes locally in `1,020.86` ms against the unchanged 7,000 ms
  ceiling, with 117 static / 127 peak nodes, sunny-cord dialogue/result at 125/123, and zero root
  leaks. All pure-domain workloads remain below 2.5 seconds.
- Nine source atlases remain unchanged. Two independent 45-PNG capture passes are byte-identical at
  aggregate SHA-256 `db9cf2846dc40c8aab617ed097ae944b99f5adfee9afa70d1e147b69a6f9e871`;
  the new choice and high-streamer frames are development evidence, not runtime assets.
- Four local macOS/arm64 exports, including two independent fresh-cache copies, match at 890,288
  bytes and SHA-256 `948ce1db799ed4639ad8cf47ecc136b49a4d760e36c1fa3c8a77235a76193704`;
  manifest verification, the unchanged 25-required / nine-excluded probe, and packaged boot pass.
- The current feature is not yet committed or pushed, so Draft PR #7 and hosted Linux checks do not
  yet contain it. Remote `main` has not been merged.

## Next action

Finish the documentation and hygiene review, run `make check`, commit and push the complete feature,
update Draft PR #7, and monitor current hosted checks without merging `main`.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
