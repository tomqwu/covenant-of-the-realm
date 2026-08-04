# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 160 tests; 100% statements and branches (653 statements / 334 branches); exact 25-resource schema-v2 current-package contract, frozen 22-resource schema-v1 verification, build-host normalization, malformed/missing/noncanonical/extra/wrong-type provenance rejection, package-script wiring, nine source-atlas reproduction, exact 45-capture filename/hash baseline, sunny-cord content locking, populated/distinct/bounded defeat-frame validation, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 3,643 assertions passing, including save-v18 migration/strict dialogue combinations, both sunny-cord results, remote-submit rejection, replay cleanup and zero-authority geometry; all nine color-independent resolved-intent shapes; three-profile outgoing defeat; and route, dialogue, camera, combat, world, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 391 checks: complete chapter/replay and persistence coverage, mid-dialogue sunny-cord resume, high-streamer world/journal/epilogue result, and replay cleanup, plus enemy-intelligence, telegraph, resolved-intent, outgoing-defeat and next-action stability |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 210 checks: title, dialogue, journal, route interactions, landmarks, spring points, movement, camera, battle, pause/accessibility, keyboard, mouse, and controller paths; mouse opens the sunny-cord dialogue, controller chooses the low knot, keyboard repeats the result, and modal route freeze remains exact |
| Godot performance and lifecycle | versioned fixed-clock headless budget | Deterministic collision, patrol, path-keeper, companion-trail, and battle throughput remain capped; the 20-cycle, 17-state lifecycle keeps its 7 s clean-sample ceiling, one confirmation only for a clean timing overage, and zero-leak requirement. The current local sample is 1,020.86 ms with 117 static nodes, a 127-node measured peak, 125 nodes in sunny-cord dialogue, 123 in its result, and zero root leaks. Hosted run `30879113809` remains evidence for the prior input at 5,008.02 ms; current hosted evidence waits for the feature push |
| Godot RPG package and reference captures | warm/fresh export + double capture | Nine source atlases regenerate twice and match their Git-index blobs byte-for-byte. Historical controlled-input evidence for `f5c60e2` remains four local macOS/arm64 outputs and four outputs in each of two independent GitHub-hosted Linux/x86_64 attempts at 709,100 bytes and SHA-256 `e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`. The previous intent-telegraph input has local and hosted evidence from run `30869981829` at 812,608 bytes and SHA-256 `aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`. The previous outgoing-defeat input has local and hosted evidence from run `30873652565` at 824,432 bytes and SHA-256 `6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`. The prior resolved-intent input has local and hosted evidence from run `30879113809` at 870,720 bytes and SHA-256 `7959ac89fe6f058b742883cacc04c6b2398b8d72355b8ce9b663e934630fbc98`. For the current sunny-cord input, four local macOS/arm64 exports, including two fresh-cache copies, match at 890,288 bytes and SHA-256 `948ce1db799ed4639ad8cf47ecc136b49a4d760e36c1fa3c8a77235a76193704`; manifest verification, the unchanged 25-required / nine-excluded probe, and packaged boot pass. Two local 45-PNG passes are byte-identical at aggregate SHA-256 `db9cf2846dc40c8aab617ed097ae944b99f5adfee9afa70d1e147b69a6f9e871` |
| Evennia commands and world bootstrap | Evennia isolated database harness | command, localization, and bootstrap integration tests passing |
| Multiplayer release path | real server, two real Telnet clients | 中文注册 → 登录 → 采药 → 修炼 → 协作 → 突破 → 重连持久化 |
| Browser journey prototype | Vitest and Playwright | 100% unit metrics; 53 Playwright executions passing |

The percentage badge describes the deterministic production rules, not transport code. Adapter behavior is checked at Evennia's real command/database boundary, and transport composition is checked against a live server. This separation keeps the numeric claim honest while still exercising the runtime layers where they actually operate.

Battle presentation tests distinguish an announced intent from an intent that actually resolves.
`enemy_hit` and `enemy_glanced` resolve the announced intent; `regular_enemy_won` and
`battle_won` make the pre-action enemy profile outgoing; and `boss_arrived` uses the settled
snapshot's enemy as the replacement. The settled snapshot is always authoritative.
`presentation_context.battle` contains only `enemy_id_before` and `announced_intent_id`, is
deep-copied, and never enters save v18; restore and load derive current presentation from settled
state and clear the transient context.

Resolved-attack-accent tests cover every one of the nine intent IDs and require nine distinct
geometry fingerprints independent of color. A cue arms only when battle phase, the two-ID old-action
context, exactly one `enemy_hit` / `enemy_glanced`, the intent catalog, and the matching settled enemy
agree, with no terminal fact. The public contract then proves the old intent/result label, enemy-foot
anchor, safe shape and label bounds, 0.70/0.18 lifetime, bounded full-motion offset, fully static
reduced-motion path, input transparency, and false rule/damage/intent/timing/input/save authority.
Malformed or conflicting events, enemy/intent mismatch, lethal actions, expiry, replacement, title,
load, replay, leaving battle, and immediate same-enemy re-entry clear the entire cue atomically.
Large-text and high-contrast paths keep geometry and Chinese result text inside the validated screen.

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
courtesy hysteresis and first chooses one of five higher-priority progress echoes: setback, basket
returned, basket left on the trail, basket found but unresolved, or enemy spoor noted. Otherwise it
returns the low-knot/high-streamer sunny-cord result, or the unanswered default route check. All eight
event IDs leave the complete Journey snapshot unchanged. `PathKeeperState`
owns only route position, adjacent target, direction, dwell, and courtesy state; the map sprite has
no collision, quest, battle, reward, or save authority. Save v17 added the top-level `path_keeper`
snapshot and migrated v1–v16 to the authored start; save v18 preserves it and rejects malformed
current route combinations.

The sunny-cord contract uses the existing old-stone-marker anchor. Before selection, inspection must
open the exact four-line companion dialogue and requires the real mountain phase, unanswered
`path_mark_response`, and marker proximity. `low_knot` and `high_streamer` commit atomically, persist
distinct code-native map shapes and repeat-inspection text, add one journal/summary/epilogue result,
and extend only the lowest-priority path-keeper echo. Tests prove unknown/repeated/remote/wrong-phase
rejection, the five old high-priority branches plus original unanswered default, v1–v17 neutral
migration, v17 route preservation, forged-old-ID
rejection, exact active-dialogue resume, and replay cleanup. The visual contract denies collision,
quest, battle, reward, rule, input, gameplay-timing, and save authority.

The dialogue-reveal matrix covers missing settings plus v1/v2/v3 → v4 migration, all three current
enum values, missing/wrong/unknown current values, a failed candidate that must not replace the
known-good file, blocked rotation that preserves the primary, and interrupted rotation recovery. Standard and fast use fixed-step 42/84-character rates; instant, manual full-line,
history, and skip never auto-advance or choose a response. Physical input switches the setting from
title and active-dialogue pause UI, then proves pause/resume does not rewind text. E2E destroys and
recreates the scene mid-dialogue: line identity resumes from save v18 while transient character
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
