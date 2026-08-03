# Loop Plan

## Current loop — 48×27 bounded rolling camera

- [x] Expand ferry and mountain ground/detail layouts from 36×20 to 48×27 without changing normalized
  save coordinates or gameplay authority.
- [x] Put every world-space visual under one `WorldRoot`; keep HUD, dialogue, journal, pause, title,
  transition, and other modal layers outside it.
- [x] Add an integer-pixel camera policy with four-edge clamping, safe-frame reporting, invalid-input
  rejection, oversized-viewport handling, and immediate reframe on every restore/transition path.
- [x] Cover the policy through scene/unit, physical-input, complete-chapter E2E, lifecycle, asset,
  deterministic screenshot, package-content, and boot checks.
- [x] Run the repository-wide `make check` with all requested checks passing.
- [x] Review the complete diff, commit, push, and monitor Draft PR #7 without merging it.

## Next unblocked loops

1. Give all four enemy profiles deterministic semantic action animations that consume battle events
   without deciding damage, intent, timing, or save state.
2. Pay off the ferry-runner route choice at both work endpoints with original, reward-free spatial
   reactions and resumable prose.
3. Add an accessibility dialogue-speed preference with conservative settings migration and physical
   input coverage.
4. Continue painted-paper portrait refinement and denser original NPC schedules after the semantic
   animation pipeline is stable.

## Blocked production boundary

Native `.app`/`.exe` packaging waits for the owner to select the first platform, export templates,
signing approach, icon, license, and distribution target. The reproducible PCK remains the daily
playable-package gate until that decision is made.
