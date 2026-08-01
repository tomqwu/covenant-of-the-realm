# Product requirements

Status: **Playable vertical slice complete**

## Problem

Create a short browser game worthy of the name “山河有契”: emotionally legible,
playable without instructions, and engineered so future narrative additions can
be made through small verified loops.

## Desired outcome

A player completes a meaningful journey through five regions, understands how
choices alter provisions/relationships/knowledge, reaches an authored ending,
and can replay the same or a new deterministic route. The design target is
15–20 minutes, pending the timed external sessions in the playtest protocol.

## Primary user and workflow

The primary player enjoys reflective narrative games and may play on desktop or
mobile. They open the page, begin immediately, resolve five encounters, read an
ending, then replay or request a new route. The interface supports Chinese and
English plus mouse, touch, and keyboard input.

## Acceptance criteria

- [x] Five-region deterministic route with meaningful stateful choices.
- [x] Four reachable authored endings, including a complete failure ending.
- [x] Autosave, reload-resume, same-route replay, and new-route generation.
- [x] Responsive, bilingual, keyboard/touch-accessible browser interface.
- [x] Production build contains no backend or runtime network dependency.
- [x] Unit coverage is at least 99% across all four metrics.
- [x] All named critical desktop/mobile E2E journeys are automated.
- [x] README displays locally verifiable coverage and E2E badges.

## Non-goals

- Accounts, cloud saves, multiplayer, combat, monetization, live services, and a
  long-form content campaign.
- A dedicated game engine, physics loop, or canvas-only interface.

## Constraints

- Static browser deployment; Node.js is required only for development/build.
- No credentials or private player data.
- Visual information cannot be required to understand or operate the game.
- All checks run through `make check` locally and in GitHub Actions.

Full narrative rules and experience principles live in `docs/GAME_DESIGN.md`.
