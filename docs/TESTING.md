# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 134 tests; 100% statements and branches (545 statements / 272 branches); five-actor metadata, exact six-column enemy semantic-animation contract and negative cases, exact patrol dialogue/choice prose, eleven-profile landmarks, complete RGBA8 decoding, package probes, Godot checked-runner failure modes, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 2,348 assertions passing, including strict save-v15 phase/map/dialogue/patrol validation and v1–v14 migration, all 24 four-profile idle/attack/reaction frames' non-empty transparent-border contract, deterministic event priority, terminal suppression, all fast/reduced-motion preference combinations, invalid-delta rejection, zero animation authority and unchanged Journey snapshots, a six-waypoint publicly walkable ferry-runner route with courtesy hysteresis, overlap priority, and atomic route-order choices, a 48×27 world with integer-pixel four-edge camera clamping, safe-frame contracts, atomic invalid-input rejection, oversized-axis handling, stable follow rounding, base-HUD depth isolation, and phase-aware battle/completion framing, three repeatable life landmarks with unchanged Journey snapshots, the ordered three-point first-breath ritual, exact four-enemy intent/counter windows, crash-consistent recovery, anti-downgrade barriers, side stories, journal pages, companion footprints, transitions, asset-backed Y-depth occlusion, deterministic map details, boss resolution, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 246 checks: protected new game → public pursuit and resumable 陶小满 dialogue → first movement toward the selected boat/herb endpoint → repeatable life observations → side stories and journal → persistent discoveries and `灵物志 3/3` → enemy save/restore with idle-only restoration, attack/reaction semantics, terminal warden suppression and counter window → three-step spring ritual with exact restore → route-aware ending/epilogue → completed-save resume → replay with the alternate patrol choice → 0/3 bypass ending; world actors share one camera root while HUD remains fixed, transition/load restoration is immediate, and battle/completion casts stay inside the safe frame |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 133 checks: genuine mouse opens the patrol dialogue, keyboard selects its non-default response, controller confirms it, save v15 restores it exactly; the same physical-event path also covers all three repeatable landmarks and spring points, journal paging/scrolling, modal blocking, title/dialogue/portrait focus safety, physical movement with camera/HUD assertions, companion trail, pause/accessibility round-trip, cross-map return, battle focus, and semantic enemy reaction through real focus/confirm input |
| Godot performance and lifecycle | versioned fixed-clock headless budget | 100,000 collision moves, 100,000 patrol advances, 50,000 bounded companion-trail updates, and 2,000 complete battle-rule loops each under 2.5 s; 20 fixed-60-FPS scene create/destroy cycles sampling 12 states under 7 s with automatic rendering disabled; static scene is 112 nodes, measured peak is 122, patrol state is 120, each spring state is 113, completion is 115, camera/world invariants and map-bounded detail rebuilds hold, and root-child leaks remain zero |
| Godot RPG package and reference captures | double export/capture | eight source atlases regenerate twice and match their Git-index blobs byte-for-byte; byte-reproducible 642,328-byte PCK with SHA-256 `c12fbb5088b92c4107c78d2be544a7b67974ed00381d98279284c1da75ca4340` explicitly probes 20 required runtime resources, including the enemy semantic adapter/catalog and camera policy, while excluding nine `tests/`/`tools/` resources; two consecutive 37-PNG capture runs have identical aggregate SHA-256 `b12520a21ddd256bb9555060885a21ed55620ea629b19e1549669b8d0a890813`, including the expanded ferry/path framing, semantic battle poses, ferry-runner map/choice states, all three life landmarks, and all three spring ritual states |
| Evennia commands and world bootstrap | Evennia isolated database harness | command, localization, and bootstrap integration tests passing |
| Multiplayer release path | real server, two real Telnet clients | 中文注册 → 登录 → 采药 → 修炼 → 协作 → 突破 → 重连持久化 |
| Browser journey prototype | Vitest and Playwright | 100% unit metrics; 53 Playwright executions passing |

The percentage badge describes the deterministic production rules, not transport code. Adapter behavior is checked at Evennia's real command/database boundary, and transport composition is checked against a live server. This separation keeps the numeric claim honest while still exercising the runtime layers where they actually operate.

## Commands

```sh
make test-unit              # rules and coverage gate
make test-integration       # Evennia command/database fixtures
make test-multiplayer-e2e   # migrate, boot, two clients, stop
make test-rpg               # Godot rules and scene integration
make rpg-asset-check        # pixel dimensions, animation layout, and source metadata
make test-rpg-e2e           # complete Godot chapter path and persistence
make test-rpg-input         # raw keyboard/controller events and focus navigation
make test-rpg-performance   # deterministic throughput, node budget, and lifecycle cleanup
make check-rpg-package      # compare PCK/manifest, probe content exclusions, verify SHA-256, boot
make lint                   # Ruff and local Markdown links
make check-mud              # all multiplayer gates
make check-prototype        # preserved PWA's complete evidence suite
make check                  # entire repository
```

`make test-multiplayer-e2e` uses randomized account names and loopback-only ports. It always attempts to stop the server it started. Runtime databases, process IDs, static collections, logs, reports, virtual environments, dependencies, and coverage output are ignored by Git.

## CI

GitHub Actions runs four pinned, least-privilege jobs:

1. deterministic coverage, lint, docs, and Evennia integration;
2. live two-player multiplayer E2E;
3. Godot content, rule/scene, and complete chapter E2E;
4. the preserved prototype's full browser/unit/build matrix.

Dependency updates are monitored separately for the root uv lock and the nested npm lock. A pull request must pass all four jobs before merge.

## Adding behavior

For every permanent mechanic, add:

1. pure success, failure, boundary, and malformed-state rule tests;
2. adapter tests proving authenticated caller, authored environment, persistence, and player prose;
3. a live-server journey when transport, concurrency, or composition changes;
4. corresponding contract and decision documentation when behavior is durable.
