# Testing and Quality Gates

## Current evidence

| Boundary | Gate | Current result |
| --- | --- | --- |
| Deterministic cultivation rules, assets, and package manifest | pytest + branch coverage, minimum 99% | 155 tests; 100% statements and branches (621 statements / 316 branches); manifest-v2 build-host normalization, malformed/missing/noncanonical/extra/wrong-type provenance rejection, exact schema-v1 verification and package-script wiring; six-actor metadata, exact six-column enemy semantic-animation contract and negative cases, exact route-aware patrol/path-keeper dialogue prose, eleven-profile landmarks, complete RGBA8 decoding, package probes, Godot checked-runner failure modes, exact 42-capture filename/hash baseline, and other failure paths covered |
| Godot RPG rules and scenes | headless GDScript harness | 2,906 assertions passing, including the exact six-ID deterministic painted-paper portrait-v2 contract and per-profile silhouette/expression/prop cues with no external asset, save, or rule authority; settings-v4 default/round-trip/failed-write behavior, blocked-rotation preservation, interrupted-backup recovery, and conservative v1–v3 migration; deterministic 42/84/instant dialogue reveal with invalid/oversized-delta protection and no Journey/save authority; strict save-v17 phase/map/dialogue/patrol/path-keeper validation and explicit v1–v16 migration; all 24 four-profile idle/attack/reaction frames' non-empty transparent-border contract, deterministic event priority, terminal suppression, all fast/reduced-motion preference combinations, zero animation authority and unchanged Journey snapshots; a six-waypoint publicly walkable ferry-runner route with courtesy hysteresis, overlap priority, atomic route-order choices, and four route-aware endpoint dialogue variants; a four-point mountain path-keeper route with courtesy hysteresis, exact forward/reverse mid-route save/restore, six progression-aware repeatable echoes, repeat determinism, Journey snapshot equivalence, and frame-slicing equivalence; a 48×27 world with integer-pixel four-edge camera clamping, safe-frame contracts, atomic invalid-input rejection, oversized-axis handling, stable follow rounding, base-HUD depth isolation, and phase-aware battle/completion framing; three repeatable life landmarks with unchanged Journey snapshots; the ordered three-point first-breath ritual; exact four-enemy intent/counter windows; crash-consistent recovery, anti-downgrade barriers, side stories, journal pages, companion footprints, transitions, asset-backed Y-depth occlusion, deterministic map details, boss resolution, and exploration contracts |
| Godot RPG chapter path | independent headless E2E | 350 checks: settings-v4 standard → fast → instant, active-line resume without character-progress persistence, and preference retention across completion/replay/new game; protected new game → public pursuit and resumable 陶小满 dialogue → first movement toward the selected boat/herb endpoint → priority and follow-up worksite reactions at both endpoints across replay → repeatable life observations → side stories and journal → persistent discoveries and `灵物志 3/3` → 岑苇's progression-aware mountain-path interaction with save/replay continuity → enemy save/restore with idle-only restoration, attack/reaction semantics, terminal warden suppression and counter window → three-step spring ritual with exact restore → route-aware ending/epilogue → completed-save resume → replay with the alternate patrol choice → 0/3 bypass ending; world actors share one camera root while HUD remains fixed, transition/load restoration is immediate, and battle/completion casts stay inside the safe frame |
| Godot keyboard/controller/mouse path | physical events + focus assertions | 185 checks: real keyboard and mouse select fast/instant on the title, controller returns to standard in an active-dialogue pause, resuming never conceals the completed line, the next line uses the selected rate, and settings writes leave Journey/Dialogue/save-v17 bytes unchanged. The same path covers patrol dialogue and a representative endpoint reaction, real mouse plus keyboard activation of the selectable 岑苇 proximity action and modal freeze/resume, all repeatable landmarks and spring points, journal paging/scrolling, modal blocking, title/dialogue/portrait focus safety, physical movement with camera/HUD assertions, companion trail, pause/accessibility round-trip, cross-map return, battle focus, and semantic enemy reaction through real focus/confirm input |
| Godot performance and lifecycle | versioned fixed-clock headless budget | 100,000 collision moves, 100,000 patrol advances, 100,000 path-keeper advances, 50,000 bounded companion-trail updates, and 2,000 complete battle-rule loops each under 2.5 s; the latest path-keeper sample is 55.79 ms; one complete 20-cycle, 13-state lifecycle sample must finish under 7 s, every cycle advances and saves dialogue while the first cycle also probes all reveal modes through four real settings writes, and an otherwise-clean time-only overage receives exactly one complete confirmation whose first cycle repeats that probe; both samples must exceed 7 s to fail; structure, node, camera/map, and leak failures never retry; the latest lifecycle sample is 920.40 ms; static scene is 115 nodes, measured peak is 125, mountain-path exploration is 121, active patrol is 123, worksite dialogue is 125, each spring state is 116, completion is 118, title is 123, dialogue plus journal is 125, automatic rendering is disabled, and root-child leaks remain zero |
| Godot RPG package and reference captures | warm/fresh export + double capture | nine source atlases regenerate twice and match their Git-index blobs byte-for-byte; with pinned Godot 4.7.1 and export-time text-scene conversion disabled, two normal PCK exports plus two independent clean-cache project copies must all match byte-for-byte; historical controlled-input evidence for `f5c60e2` remains four local macOS/arm64 outputs and four outputs in each of two independent GitHub-hosted Linux/x86_64 RPG job attempts at 709,100 bytes and SHA-256 `e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`; for the current local feature worktree, four macOS/arm64 outputs, including two fresh-cache copies, match at 746,180 bytes and SHA-256 `16fbb0098326c58d4a651f90e03ab20eb8a53a7dd98b896b79c089e1af974573`, with manifest, 24-required / nine-excluded resource probe, and packaged boot smoke passing locally while hosted confirmation remains pending; controlled observations do not promise future cross-platform identity, and normalized build tuples remain per-build provenance rather than canonical-hash keys or executable ABIs; two consecutive 42-PNG capture runs have identical aggregate SHA-256 `f56422804793b50d4ee20e5b9a733bb7a5d61a4599771648a0a3028f2fb51bb7`, including the 3×2 portrait comparison board, readable standard/instant title-pause controls, expanded ferry/path framing, semantic battle poses, ferry-runner map/choice/worksite states, the 岑苇 mountain-route capture, all three life landmarks, and all three spring ritual states |
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
