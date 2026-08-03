# Loop Plan

## Current loop — four-profile semantic enemy animation

- [x] Expand the generated enemy atlas from two to six columns without changing the four stable
  profile rows, 64×64 frame size, foot anchor, nearest filtering, or integer placement.
- [x] Add deterministic idle, attack, and reaction animations; consume one fixed-priority battle
  event per action while terminal/profile-transition events safely reset to idle.
- [x] Keep damage, intent, round timing, input, collision, phase, and save v15 authority outside the
  animation adapter; keep all three mountain-path warning sprites idle-only.
- [x] Cover all profiles, event-order priority, unknown inputs, invalid/oversized presentation deltas,
  fast/reduced motion, terminal suppression, input parity, save restore, lifecycle, assets, captures,
  package contents, and boot behavior.
- [ ] Run the repository-wide `make check`, review the complete diff, commit, push, and monitor Draft
  PR #7 without merging it.

## Recently completed — 48×27 bounded rolling camera

- [x] Expand both exploration maps to 48×27 under one bounded integer-pixel `WorldRoot` transform.
- [x] Keep HUD/modal layers fixed, preserve normalized save coordinates, and cover every edge,
  transition, restore, capture, package, and lifecycle boundary.

## Next unblocked loops

1. Pay off the ferry-runner route choice at both work endpoints with original, reward-free spatial
   reactions and resumable prose.
2. Add an accessibility dialogue-speed preference with conservative settings migration and physical
   input coverage.
3. Continue painted-paper portrait refinement and denser original NPC schedules after the semantic
   animation pipeline is stable.
4. Add intent-specific telegraphs or visible outgoing-enemy defeat only after structured presentation
   context can identify the resolved intent and replaced profile without entering the domain save.

## Blocked production boundary

Native `.app`/`.exe` packaging waits for the owner to select the first platform, export templates,
signing approach, icon, license, and distribution target. The reproducible PCK remains the daily
playable-package gate until that decision is made.
