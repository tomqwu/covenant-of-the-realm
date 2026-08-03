# Loop Plan

## Current loop — ferry-runner worksite echoes

- [x] Derive a temporary worksite interaction only while 陶小满 is dwelling at the exact boat-frame
  or drying-rack endpoint after the route order is selected; let an endpoint-waiting player observe
  arrival instead of trapping the runner in courtesy yielding.
- [x] Add four route-aware original Chinese prose variants and two genuinely selectable,
  consequence-neutral responses per worksite. Freeze the patrol during dialogue; commit only the
  semantic echo plus the current dwell ending, with the complete Journey snapshot unchanged.
- [x] Upgrade to save v16 because the persisted active-dialogue enum expands; migrate v1–v15
  conservatively and reject wrong route, worksite, range, line, legacy enum, malformed, and future
  combinations without adding a one-shot completion flag.
- [x] Cover both route orders, both endpoints, repeated interaction, fixed-landmark fallback,
  waiting-player and oversized-delta determinism, keyboard/mouse/controller input, continue/replay,
  performance/lifecycle, captures, package contents, and boot behavior.
- [ ] Run the repository-wide `make check`, review the complete diff, commit, push, and monitor Draft
  PR #7 without merging it.

## Recently completed

- [x] Add generated two-frame idle, attack, and reaction animation for all four stable enemy
  profiles without giving presentation any rule, timing, or save authority.
- [x] Expand both exploration maps to 48×27 under one bounded integer-pixel `WorldRoot` transform
  while preserving fixed UI, normalized save coordinates, edge framing, and lifecycle budgets.

## Next unblocked loops

1. Add an accessibility dialogue-speed preference with conservative settings migration and physical
   input coverage.
2. Continue painted-paper portrait refinement and denser original NPC schedules after the semantic
   animation pipeline is stable.
3. Add intent-specific telegraphs or visible outgoing-enemy defeat only after structured presentation
   context can identify the resolved intent and replaced profile without entering the domain save.

## Blocked production boundary

Native `.app`/`.exe` packaging waits for the owner to select the first platform, export templates,
signing approach, icon, license, and distribution target. The reproducible PCK remains the daily
playable-package gate until that decision is made.
