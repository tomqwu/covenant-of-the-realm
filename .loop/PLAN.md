# Loop Plan

## Current loop — accessible dialogue reveal speed

- [x] Upgrade only the independent settings store to v4 with `dialogue_speed` set to `standard`,
  `fast`, or `instant`. Preserve every valid v1–v3 preference while migrating to `standard`; reject
  missing, wrong-type, unknown, malformed, and future values atomically without changing save v16.
- [x] Add paired, focusable title and pause controls labelled `对话显字：标准/快速/整句`. Keep them
  independent from battle speed and reduced motion, synchronized after a successful settings write,
  disabled during destructive-new-game confirmation, and persistent across new, continue, and replay.
- [x] Make reveal behavior deterministic at 42 or 84 Unicode characters per second, with `instant`
  showing each new line in full but never auto-advancing or choosing a response. Invalid deltas are
  no-ops; switching speed never hides read text, while switching to `instant` completes the current
  line without changing Dialogue, Journey, Patrol, or game-save authority.
- [x] Cover settings migration and failed writes, fixed-step and oversized-delta reveal, manual full
  line/history/skip semantics, mouse/keyboard/controller input, active-dialogue resume, new/replay,
  lifecycle budgets, readable deterministic captures, reproducible package contents, and boot behavior.
- [ ] Run the repository-wide `make check`, review the complete diff, update durable decisions and
  exact metrics, commit, push, and monitor Draft PR #7 without merging it.

## Recently completed

- [x] Add route-aware, repeatable ferry-runner worksite echoes at both exact patrol endpoints while
  keeping the complete Journey snapshot unchanged and migrating active dialogue safely to save v16.
- [x] Add generated two-frame idle, attack, and reaction animation for all four stable enemy
  profiles without giving presentation any rule, timing, or save authority.
- [x] Expand both exploration maps to 48×27 under one bounded integer-pixel `WorldRoot` transform
  while preserving fixed UI, normalized save coordinates, edge framing, and lifecycle budgets.

## Next unblocked loops

1. Continue painted-paper portrait refinement and denser original NPC schedules after the semantic
   animation pipeline is stable.
2. Add intent-specific telegraphs or visible outgoing-enemy defeat only after structured presentation
   context can identify the resolved intent and replaced profile without entering the domain save.

## Blocked production boundary

Native `.app`/`.exe` packaging waits for the owner to select the first platform, export templates,
signing approach, icon, license, and distribution target. The reproducible PCK remains the daily
playable-package gate until that decision is made.
