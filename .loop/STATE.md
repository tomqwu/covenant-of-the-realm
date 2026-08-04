# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- The validated worktree adds the fixed-screen Chinese “照禾临势签”. Its nine stable intent IDs have
  distinct non-colour line marks; current damage is always readable, while next intent and counter
  text remain gated by authoritative enemy intelligence.
- Successful battle actions carry only the pre-resolution enemy ID and announced intent ID in a
  deep-copied presentation context. Journey snapshots, save v17, events, damage, intent advancement,
  replacement enemies, and victory remain authoritative; malformed or reloaded context clears safely.
- The settled snapshot drives the persistent sign after every action. Transient feedback distinguishes
  announced from actually resolved intent, retains the outgoing enemy only as an ID, and hands regular
  victories immediately to the replacement warden. The sign clears on terminal/title/reload paths;
  transient IDs survive only for an active cue and clear on no-feedback transitions, title, reload, or expiry.
- Local `make check` is green: 155 Python tests at 100% statement and branch coverage (621 statements /
  316 branches), 21 Evennia tests plus the real two-client journey, 3,105 Godot rule/scene assertions,
  357 chapter E2E checks, 189 physical-input/focus checks, 122 browser unit tests at 100%, and 53
  Playwright executions. Badges, deterministic builds, documentation links, and hygiene also pass.
- The 20-cycle Godot lifecycle passes in `959.0` ms with 116 static / 126 peak nodes, 125 nodes during
  regular-enemy replacement, and zero root leaks. All domain workloads remain below 2.5 seconds.
- Nine source atlases regenerate twice and match Git. Two independent 42-PNG capture passes reproduce
  aggregate SHA-256 `3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.
- Four macOS/arm64 PCK exports, including two independent fresh-cache project copies, match at 812,608
  bytes and SHA-256 `aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`;
  manifest verification, the 25-required / nine-excluded probe, and packaged boot smoke pass.
- The feature and documentation are locally verified and awaiting an intentional commit, push, Draft PR
  refresh, and hosted confirmation. Remote `main` must not be merged without authorization.

## Next action

Complete the read-only diff audit, commit and push this loop, refresh Draft PR #7, then monitor all
hosted checks before recording the final head and CI evidence.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
