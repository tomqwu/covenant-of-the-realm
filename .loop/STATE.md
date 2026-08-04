# Loop State

## Current outcome

- Repository: `/Users/tomwu/Projects/covenant-of-the-realm`
- Branch: `codex/rpg-foundation`
- Draft PR: <https://github.com/tomqwu/covenant-of-the-realm/pull/7>
- The branch adds the fixed-screen Chinese “照禾临势签”. Its nine stable intent IDs have
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
- The 20-cycle Godot lifecycle passes in `957.63` ms with 116 static / 126 peak nodes, 125 nodes during
  regular-enemy replacement, and zero root leaks. All domain workloads remain below 2.5 seconds.
- Nine source atlases regenerate twice and match Git. Two independent 42-PNG capture passes reproduce
  aggregate SHA-256 `3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.
- Four local macOS/arm64 exports and four GitHub-hosted Linux/x86_64 exports, each including two
  independent fresh-cache project copies, match at 812,608 bytes and SHA-256
  `aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`; manifest verification,
  the 25-required / nine-excluded probe, and packaged boot smoke pass in both environments.
- Implementation head `ebb1d200fca9a8d44dcffe179b5e94425da8c838` is committed and pushed.
  GitHub Actions run `30869981829` is green across RPG quality, MUD quality, Multiplayer E2E, and
  Journey prototype. Draft PR #7 remains open, draft, and mergeable; remote `main` remains
  `7256ade54792ff481ffc30517ca2c693f78be198` and must not be merged without authorization.

## Next action

Begin the next unblocked loop with a visible outgoing-enemy defeat beat while keeping the replacement
enemy authoritative and the old profile presentation-only.

## Blockers

No current engineering blocker. Native `.app` / `.exe` packaging remains intentionally blocked on
owner decisions for the first platform, templates, signing, icon, license, and distribution target.

## Exact verification

```sh
make check
```
