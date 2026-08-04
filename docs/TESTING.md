# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 155 tests; 100% statements and branches (621 statements / 316 branches); exact 25-resource schema-v2 current-package contract, frozen 22-resource schema-v1 verification, build-host normalization, malformed/missing/noncanonical/extra/wrong-type provenance rejection, package-script wiring, nine source-atlas reproduction, exact 42-capture filename/hash baseline, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 3,105 assertions passing, including the ID-only battle presentation context, deep-copy and mutation isolation, malformed-context safe fallback, failed/non-battle emptiness, all three regular-enemy replacements, boss arrival, retreat, resource failure, and snapshot/save exclusion; the fixed-screen intent tag's nine unique silhouettes, profile-specific edges, intelligence gating, neutral fallback, text equivalents, accessibility modes, non-blocking behavior, settled-state reconstruction, and absence of rule/save authority; plus save-v17 validation and migration, deterministic routes, dialogue, camera, combat, world, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 357 checks: complete chapter/replay and persistence coverage plus unknown-intelligence current-only telegraphing, investigated next-intent/counter disclosure, non-default enemy restore, old/new enemy replacement presentation, and transient-context clearing; world actors share one camera root while HUD and the intent tag remain fixed, transition/load restoration is immediate, and battle/completion casts stay inside the safe frame |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 189 checks: title, dialogue, journal, route interactions, landmarks, spring points, movement, camera, battle, pause/accessibility, keyboard, mouse, and controller paths; the intent tag remains visible, current-only without intelligence, text-equivalent, non-focusable, and non-blocking during real confirm input |
| Godot performance and lifecycle | versioned fixed-clock headless budget | Deterministic collision, patrol, path-keeper, companion-trail, and battle throughput remain capped; the 20-cycle, 15-state lifecycle keeps its 7 s clean-sample ceiling, one confirmation only for a clean timing overage, and zero-leak requirement. The current structural contract is 116 static nodes and a 126-node measured peak, including the fixed-screen intent tag |
| Godot RPG package and reference captures | warm/fresh export + double capture | Nine source atlases regenerate twice and match their Git-index blobs byte-for-byte. Historical controlled-input evidence for `f5c60e2` remains four local macOS/arm64 outputs and four outputs in each of two independent GitHub-hosted Linux/x86_64 attempts at 709,100 bytes and SHA-256 `e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`. The completed path-keeper loop at `9d8ae1ffec1b42dbe8d619b0aadd8d4c3244e7df` produced four 746,180-byte local outputs at SHA-256 `16fbb0098326c58d4a651f90e03ab20eb8a53a7dd98b896b79c089e1af974573`; GitHub run `30866425747` also passed. For the current intent-telegraph input, four local macOS/arm64 outputs and four GitHub-hosted Linux/x86_64 outputs from run `30869981829`, each including two fresh-cache copies, match at 812,608 bytes and SHA-256 `aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`; manifest verification, the 25-required / nine-excluded resource probe, and packaged boot pass locally and hosted. Two local 42-PNG passes reproduce aggregate SHA-256 `3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`. The same hosted run passes RPG quality, MUD quality, Multiplayer E2E, and Journey prototype |
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
