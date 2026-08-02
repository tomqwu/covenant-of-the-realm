# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules and package manifest | pytest + branch coverage, minimum 99% | 62 tests; 100% statements and branches |
| Godot RPG rules and scenes | headless GDScript harness | 747 assertions passing, including safe new-game confirmation for valid/corrupt files, settings-v3 large-text/high-contrast accessibility with migration and persistence, the two-result ferryman side story/save v11, resumable/dynamic chapter epilogue, modal journal/no-spoiler content, four stable paper portraits, three persistent discoveries, bounded companion footprints, focus-blocking/reduced-motion transitions, Y-depth occlusion, selectable harvesting, enemy-atlas selection, presentation independence, shared-resolver boss, dialogue, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 104 checks: cancel/confirm new-game protection → ferryman repair/persist/replay-record branches → dynamic epilogue interruption/restore/two responses → saved journal restoration → three character portrait IDs → dialogue interruption → persistent ferry/path discoveries → old-rule harvest → mountain/companion restore → enemy/boss restore → ending → replay cutting/regrowth → bypass |
| Godot keyboard/controller path | physical events + focus assertions | 50 checks: controller cancel/confirm new-game protection → J/Y journal and movement blocking → title/dialogue/portrait focus safety → keyboard ferryman dialogue + controller choice → keyboard discovery → movement/companion trail → stable one-button harvest → pause preferences incl. text-size/contrast round-trip → two-map interaction → battle focus |
| Godot performance and lifecycle | versioned headless budget | 100,000 collision moves, 50,000 bounded companion-trail updates, and 2,000 complete battle-rule loops each under 2.5 s; 20 scene create/destroy cycles under 5 s; ≤120 nodes and zero root-child leaks |
| Godot RPG package and reference captures | double export/capture | byte-reproducible PCK and manifest with SHA-256/size/source state verified; six runtime resources present and nine `tests/`/`tools/` resources absent; consecutive full PNG capture runs have identical SHA-256 sets |
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
