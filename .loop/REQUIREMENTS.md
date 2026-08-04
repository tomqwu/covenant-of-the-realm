# Loop Requirements

## Product boundary

- The primary deliverable is the original Chinese single-player Godot RPG under `rpg/`.
- It must remain playable from title through exploration, battle, first-breath ritual, ending,
  continue, and replay with keyboard, mouse, and controller parity.
- Story, characters, maps, code, and shipped assets must remain project-authored. Do not copy or
  closely adapt protected novels, game scripts, characters, locations, art, or music.
- Domain rules, saves, patrols, combat, camera framing, captures, and packages must be deterministic.
- The current save format must reject malformed or future state safely and migrate documented older
  versions explicitly. Presentation-only work must not create a second gameplay authority.
- Accessibility, readable Chinese at 1152×648, fixed screen-space HUD/modals, and recoverable progress
  are release requirements rather than optional polish.

## Engineering boundary

- Work on a `codex/` feature branch, add behavior tests, run `make check`, commit an independently
  reviewable loop, push it, and keep the Draft PR current. Do not merge `main` without authorization.
- Keep the repository command contract authoritative: `make setup`, `make lint`, `make test`, and
  `make check`. New runtime gates extend these commands rather than creating prose-only alternatives.
- Python production rules retain at least 99% statement and branch coverage; the current gate is
  100%. Godot changes require public-behavior unit/scene coverage plus relevant input, E2E,
  performance/lifecycle, deterministic-capture, and package checks.
- Generated source atlases must rebuild byte-for-byte from project code and match Git. Runtime packs
  must be reproducible, content-probed, and boot-smoked with development resources excluded.
- Never commit credentials, local saves, runtime databases, editor state, ignored build output, or
  an unreviewed third-party/generated asset.

## Decision boundaries

Do not infer the first native release platform, signing identity, public license, asset-production
budget, voice scope, monetization, or final distribution target. Record and stop at any point where
one of those choices is necessary.
