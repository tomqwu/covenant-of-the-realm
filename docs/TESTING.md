# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 136 tests; 100% statements and branches (561 statements / 286 branches); five-actor metadata, exact six-column enemy semantic-animation contract and negative cases, exact route-aware patrol dialogue/choice prose, eleven-profile landmarks, complete RGBA8 decoding, package probes, Godot checked-runner failure modes, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 2,627 assertions passing, including strict save-v16 phase/map/dialogue/patrol validation and v1–v15 migration, all 24 four-profile idle/attack/reaction frames' non-empty transparent-border contract, deterministic event priority, terminal suppression, all fast/reduced-motion preference combinations, invalid-delta rejection, zero animation authority and unchanged Journey snapshots, a six-waypoint publicly walkable ferry-runner route with courtesy hysteresis, overlap priority, atomic route-order choices, and four route-aware endpoint dialogue variants, a 48×27 world with integer-pixel four-edge camera clamping, safe-frame contracts, atomic invalid-input rejection, oversized-axis handling, stable follow rounding, base-HUD depth isolation, and phase-aware battle/completion framing, three repeatable life landmarks with unchanged Journey snapshots, the ordered three-point first-breath ritual, exact four-enemy intent/counter windows, crash-consistent recovery, anti-downgrade barriers, side stories, journal pages, companion footprints, transitions, asset-backed Y-depth occlusion, deterministic map details, boss resolution, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 319 checks: protected new game → public pursuit and resumable 陶小满 dialogue → first movement toward the selected boat/herb endpoint → priority and follow-up worksite reactions at both endpoints across replay → repeatable life observations → side stories and journal → persistent discoveries and `灵物志 3/3` → enemy save/restore with idle-only restoration, attack/reaction semantics, terminal warden suppression and counter window → three-step spring ritual with exact restore → route-aware ending/epilogue → completed-save resume → replay with the alternate patrol choice → 0/3 bypass ending; world actors share one camera root while HUD remains fixed, transition/load restoration is immediate, and battle/completion casts stay inside the safe frame |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 150 checks: genuine mouse opens the patrol dialogue, keyboard selects its non-default response, controller confirms it, and save v16 records the exact route/patrol snapshot; a representative herbs-priority endpoint action shares this mouse/keyboard/controller path without changing Journey state. The same path also covers all three repeatable landmarks and spring points, journal paging/scrolling, modal blocking, title/dialogue/portrait focus safety, physical movement with camera/HUD assertions, companion trail, pause/accessibility round-trip, cross-map return, battle focus, and semantic enemy reaction through real focus/confirm input |
| Godot performance and lifecycle | versioned fixed-clock headless budget | 100,000 collision moves, 100,000 patrol advances, 50,000 bounded companion-trail updates, and 2,000 complete battle-rule loops each under 2.5 s; 20 fixed-60-FPS scene create/destroy cycles sampling 13 states under 7 s with automatic rendering disabled; static scene is 112 nodes, measured peak is 122, patrol state is 120, worksite dialogue is 122, each spring state is 113, completion is 115, camera/world invariants and map-bounded detail rebuilds hold, and root-child leaks remain zero |
| Godot RPG package and reference captures | double export/capture | eight source atlases regenerate twice and match their Git-index blobs byte-for-byte; byte-reproducible 672,056-byte PCK with SHA-256 `ad8a2e042bc085bbdd97ff2f98adadb8345d925fd5276065d410a8413e3ac295` explicitly probes 20 required runtime resources, including the enemy semantic adapter/catalog and camera policy, while excluding nine `tests/`/`tools/` resources; two consecutive 39-PNG capture runs have identical aggregate SHA-256 `427d2448c3ad1f5d2eeefbdfa00b874a86126f7759d78ba875cbdf54138093b6`, including the expanded ferry/path framing, semantic battle poses, ferry-runner map/choice/worksite states, all three life landmarks, and all three spring ritual states |
| Evennia commands and world bootstrap | Evennia isolated database harness | command, localization, and bootstrap integration tests passing |
| Multiplayer release path | real server, two real Telnet clients | 中文注册 → 登录 → 采药 → 修炼 → 协作 → 突破 → 重连持久化 |
| Browser journey prototype | Vitest and Playwright | 100% unit metrics; 53 Playwright executions passing |

The percentage badge describes the deterministic production rules, not transport code. Adapter behavior is checked at Evennia's real command/database boundary, and transport composition is checked against a live server. This separation keeps the numeric claim honest while still exercising the runtime layers where they actually operate.

The ferry-runner endpoint matrix covers boat/herbs × priority/follow-up. Eligibility requires the
exact endpoint, positive dwell, and player proximity; a waiting player observes arrival before
courtesy pause. Dialogue freezes patrol state, both responses preserve the complete Journey
snapshot and add no journal result. Closing immediately zeroes the current dwell without clearing
the existing yield; a nearby player keeps the runner yielding until crossing the exit hysteresis
radius. Save fixtures cover all four active dialogue IDs, conservative v1–v15 migration, and the
v16 future-version barrier without adding a payload field.

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
