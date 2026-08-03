# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 99 tests; 100% statements and branches (511 statements / 252 branches); eleven-profile landmark metadata, exact life-landmark prose, complete RGBA8 decoding, and failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 1,594 assertions passing, including save-v14 strict phase/map validation and v1–v13 migration, three publicly reachable repeatable life landmarks with unchanged Journey snapshots, visual-foot interaction alignment, the third `cangquan_spring` micro-map, a public-`move()` route connecting all three ritual points, ordered `听泉辨脉 → 月芽温脉 → 静坐引息`, atomic wrong-order rejection, exact mid-ritual restoration, replay clearing, exact four-enemy intent/counter windows, three non-overlapping spoor investigations, knowledge-independent battle results, crash-consistent recovery, anti-downgrade barriers, side stories, journal pages, persistent discoveries, companion footprints, transitions, asset-backed Y-depth occlusion, RGBA landmark regions, a non-water mountain return bridge, harvesting, enemy atlases, deterministic non-authoritative map details, boss resolution, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 192 checks: protected new game → repeatable boat-repair/drying-rack/rain-shelter observations without state rewards → resumable side stories and journal → persistent discoveries → three studied spoors and `灵物志 3/3` → non-default enemy save/restore → exact warden counter window → three-step spring ritual with autosave/destroy/restore after each step → ending and route-aware epilogue → completed-save resume → replay clearing ritual and intelligence → 0/3 bypass ending |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 106 checks: genuine keyboard, mouse, and controller interaction across all three repeatable life landmarks and all three spring points → genuine mouse TabBar selection → Q/RB journal paging → large-text PageDown/D-pad scrolling and focus exit → J/Y modal open/close and movement blocking → title/dialogue/portrait focus safety → side-story choices → movement/companion trail → pause/accessibility round-trip → cross-map return → battle focus |
| Godot performance and lifecycle | versioned fixed-clock headless budget | 100,000 collision moves, 50,000 bounded companion-trail updates, and 2,000 complete battle-rule loops each under 2.5 s; 20 fixed-60-FPS scene create/destroy cycles sampling 11 states under 7 s with automatic rendering disabled; static scene is 110 nodes, measured peak is 120, at most seven landmark foreground nodes are reused, each of the three spring states is 111, completion is 113, detail rebuilds remain map-bounded, and root-child leaks remain zero |
| Godot RPG package and reference captures | double export/capture | seven source atlases regenerate twice and match their Git-index blobs byte-for-byte; byte-reproducible 559,676-byte PCK with SHA-256 `482485ac5610f7d9157461b4d178fcac0712a23674980e131d6a2a9bfd3d4f1d`; 15 required runtime resources present and nine `tests/`/`tools/` resources excluded; two consecutive 34-PNG capture runs have identical SHA-256 sets, including the asset-backed ferry/path/battle maps, all three life landmarks, and all three spring ritual states |
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
