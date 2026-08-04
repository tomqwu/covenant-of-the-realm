# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 159 tests; 100% statements and branches (621 statements / 316 branches); exact 25-resource schema-v2 current-package contract, frozen 22-resource schema-v1 verification, build-host normalization, malformed/missing/noncanonical/extra/wrong-type provenance rejection, package-script wiring, nine source-atlas reproduction, exact 43-capture filename/hash baseline, populated/distinct/bounded defeat-frame validation, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 3,202 assertions passing, including the ID-only battle context; three-profile outgoing defeat role; standard/fast × full/reduced presentation; malformed/profile/anchor rejection; exact expiry, replacement, next-action, rescue, replay, and terminal cleanup; same-frame warden sprite/status/intent authority; and nonblocking same-phase handoff, plus save-v17 migration, deterministic routes, dialogue, camera, combat, world, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 360 checks: complete chapter/replay and persistence coverage plus unknown-intelligence current-only telegraphing, investigated next-intent/counter disclosure, old moss defeat beside the settled warden, reload clearing, and next-warden-action stability; world actors share one camera root while HUD and the intent tag remain fixed |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 192 checks: title, dialogue, journal, route interactions, landmarks, spring points, movement, camera, battle, pause/accessibility, keyboard, mouse, and controller paths; fast/reduced defeat remains static, input-transparent and outside focus, while the next independent controller A immediately resolves a warden round |
| Godot performance and lifecycle | versioned fixed-clock headless budget | Deterministic collision, patrol, path-keeper, companion-trail, and battle throughput remain capped; the 20-cycle, 15-state lifecycle keeps its 7 s clean-sample ceiling, one confirmation only for a clean timing overage, and zero-leak requirement. The current structural contract is 117 static nodes and a 127-node measured peak, including the fixed intent tag and hidden outgoing sprite |
| Godot RPG package and reference captures | warm/fresh export + double capture | Nine source atlases regenerate twice and match their Git-index blobs byte-for-byte. Historical controlled-input evidence for `f5c60e2` remains four local macOS/arm64 outputs and four outputs in each of two independent GitHub-hosted Linux/x86_64 attempts at 709,100 bytes and SHA-256 `e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`. The previous intent-telegraph input has local and hosted evidence from run `30869981829` at 812,608 bytes and SHA-256 `aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`. For the current outgoing-defeat input, four local macOS/arm64 exports and four GitHub-hosted Linux/x86_64 exports from run `30873652565`, each including two fresh-cache project copies, match at 824,432 bytes and SHA-256 `6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`; manifest verification, the unchanged 25-required / nine-excluded resource probe, and packaged boot pass locally and hosted. Two local 43-PNG passes are byte-identical at aggregate SHA-256 `80dfb36a14b81a54b0562932a841d2f295f829d3992eec900f079b31a329bc0b` |
| Evennia commands and world bootstrap | Evennia isolated database harness | command, localization, and bootstrap integration tests passing |
| Multiplayer release path | real server, two real Telnet clients | 中文注册 → 登录 → 采药 → 修炼 → 协作 → 突破 → 重连持久化 |
| Browser journey prototype | Vitest and Playwright | 100% unit metrics; 53 Playwright executions passing |

The percentage badge describes the deterministic production rules, not transport code. Adapter behavior is checked at Evennia's real command/database boundary, and transport composition is checked against a live server. This separation keeps the numeric claim honest while still exercising the runtime layers where they actually operate.

Battle presentation tests distinguish an announced intent from an intent that actually resolves.
`enemy_hit` and `enemy_glanced` resolve the announced intent; `regular_enemy_won` and
`battle_won` make the pre-action enemy profile outgoing; and `boss_arrived` uses the settled
snapshot's enemy as the replacement. The settled snapshot is always authoritative.
`presentation_context.battle` contains only `enemy_id_before` and `announced_intent_id`, is
deep-copied, and never enters save v17; restore and load derive current presentation from settled
state and clear the transient context.

Outgoing-defeat tests require the exact `regular_enemy_won` + `boss_arrived` pair and a valid regular
pre-action profile. They prove that the settled warden drives Journey, status, canonical sprite and
intent in the same render while a separate zero-authority sprite displays only the old profile.
Standard/fast and full/reduced modes, malformed facts, all three regular profiles, exact expiry,
replacement, the next physical controller input, title, reload, retreat, rescue and final victory
all have explicit cleanup assertions. The same-phase handoff has no full-screen transition.

The ferry-runner endpoint matrix covers boat/herbs × priority/follow-up. Eligibility requires the
exact endpoint, positive dwell, and player proximity; a waiting player observes arrival before
courtesy pause. Dialogue freezes patrol state, both responses preserve the complete Journey
snapshot and add no journal result. Closing immediately zeroes the current dwell without clearing
the existing yield; a nearby player keeps the runner yielding until crossing the exit hysteresis
radius. Save fixtures cover all four active dialogue IDs, conservative v1–v15 migration, and the
v16 future-version barrier without adding a payload field.

岑苇 follows a separate four-point mountain route. His interaction uses 0.080/0.100 enter/exit
courtesy hysteresis and chooses one of six repeatable echoes in fixed progression order: setback,
basket returned, basket left on the trail, basket found but unresolved, enemy spoor noted, then the
default route check. Every echo leaves the complete Journey snapshot unchanged. `PathKeeperState`
owns only route position, adjacent target, direction, dwell, and courtesy state; the map sprite has
no collision, quest, battle, reward, or save authority. Save v17 adds the top-level `path_keeper`
snapshot, migrates v1–v16 to the authored start, and rejects malformed current route combinations.

The dialogue-reveal matrix covers missing settings plus v1/v2/v3 → v4 migration, all three current
enum values, missing/wrong/unknown current values, a failed candidate that must not replace the
known-good file, blocked rotation that preserves the primary, and interrupted rotation recovery. Standard and fast use fixed-step 42/84-character rates; instant, manual full-line,
history, and skip never auto-advance or choose a response. Physical input switches the setting from
title and active-dialogue pause UI, then proves pause/resume does not rewind text. E2E destroys and
recreates the scene mid-dialogue: line identity resumes from save v17 while transient character
progress is intentionally derived again from the independent local preference.

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
make check-rpg-package      # compare warm/fresh PCKs and manifests, probe exclusions, boot
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
