# Decision Log

Use this file for durable decisions. Do not depend on chat transcripts as the only record.

## Confirmed

### 2026-08-04 — Resolved enemy intent leaves a strict, zero-authority foot accent

`MapCanvas` draws an enemy-foot “刚才” accent only when the action-result evidence proves that an
announced old intent actually produced the enemy response. The current phase must be battle; the
transient context must contain valid old enemy and intent IDs; exactly one `enemy_hit` or
`enemy_glanced` event must be present; the intent catalog must bind that pair; the settled enemy
must still match; and no regular victory, boss arrival, final victory, retreat, or rescue fact may
terminate the response. The fixed intent tag independently follows the settled snapshot and can
therefore show the next intent without relabeling it as the attack that just happened. Malformed,
mismatched, stale, multiple-response, lethal, or terminal inputs clear atomically.

The nine stable geometry fingerprints are `probing_charge`, `rending_charge`, `absorb_tide`,
`spore_spray`, `unbalanced_swing`, `rebalance_step`, `pressing_charge`, `stonebreaking_blow`, and
`nest_guard`. Each is drawn from project-authored `CanvasItem` geometry inside a bounded world-space
safe frame, with a contrasting outline and the Chinese equivalent
“刚才 · 势名 · 受到冲击/化开冲势”; color never carries identity alone. Large-text and
high-contrast modes preserve both bounds and meaning. Standard and fast preferences keep the
existing 0.70/0.18-second local clocks. Full motion adds only a short secondary-stroke offset and
fade; reduced motion freezes the complete first frame while retaining the event text.

Expiry, replacement, title, load, replay, leaving battle, and immediate same-enemy re-entry clear
the ID, geometry, label, result, and timer together. The accent adds no node, asset, content field,
or save migration, ignores pointer and focus input, and has explicit false authority for rules,
damage, intent selection, gameplay timing, input, Journey, and save v17.

The local gate is 3,530 Godot unit/scene assertions, 374 chapter E2E checks, 198 physical-input
checks, a 948.09 ms 20-cycle lifecycle sample, 117 static / 127 peak nodes, and zero root leaks.
Two 43-PNG passes reproduce aggregate SHA-256
`153ee23c5cbf0a6208fd9853b2722e7fb032ef2539468a210b47ffa8278568b4`. Four local macOS/arm64
and four hosted Linux/x86_64 PCK exports from run `30879113809`, each including two independent
fresh-cache copies, match at 870,720 bytes and SHA-256
`7959ac89fe6f058b742883cacc04c6b2398b8d72355b8ce9b663e934630fbc98`; the 25-required /
nine-excluded probe, manifest verification, and packaged boot pass locally and hosted. Runs
`30877432459` and `30878257664` exposed 7,075.94 / 7,108.08 ms clean-sample overages without a
functional failure; the budget stayed at 7,000 ms. Removing repeated transition, idle, empty-event,
and second no-state settle work preserved all 20 cycles and assertions, then run `30879113809`
passed at 5,008.02 ms.

### 2026-08-03 — Regular-enemy defeat is an outgoing-only, nonblocking presentation role

The visible defeat beat uses one hidden, persistent `OutgoingEnemySprite`; it never rewinds the
canonical `BattleEnemySprite` to the old profile. `MapCanvas` arms it only for the exact
`regular_enemy_won` + `boss_arrived` pair, a valid pre-action regular-enemy ID, and the already
settled `rock_armor_warden` replacement. Journey, status, the canonical sprite and the fixed intent
tag therefore identify the warden in the same render. Lone events, final boss victory, unknown IDs,
malformed context, or mismatched replacement facts clear safely and cannot guess a profile.

Asset-contract schema v7 expands the original enemy atlas from 384×256 to 512×256. Every stable
64×64 row now contains two defeat frames after idle, attack, and reaction. The validator decodes the
RGBA cells and requires populated, distinct, non-reaction defeat frames with transparent cell
borders. The outgoing role accepts only the three regular profiles, uses integer placement, and
plays for 0.70 seconds or 0.18 seconds in fast mode. Full motion shifts/fades the collapsed form;
reduced motion freezes the readable first frame. The next action replaces or clears the cue without
waiting, and expiry, title, load, retreat, rescue, final victory, replay, and non-battle phases clear
its identity. It owns no damage, intent, timing, camera focus, input, Journey, content, or save data;
save v17 and all migrations remain unchanged.

The former same-phase `boss_arrived` full-screen transition is retired. True phase/map transitions
still use the paper reveal, but regular-to-warden handoff instead shows “灵物退开 · 守巢者现” in
the battle safe frame while both sprites and the new intent are visible. This keeps the cue readable
and lets the already-focused next action accept an independent controller press immediately.

The gate is 159 Python tests at 100% statement/branch coverage, 3,202 Godot unit/scene
assertions, 360 chapter E2E checks, 192 physical-input checks, and a 117 static / 127 peak node
boundary. Two 43-PNG passes are byte-identical at aggregate SHA-256
`80dfb36a14b81a54b0562932a841d2f295f829d3992eec900f079b31a329bc0b`. Four local macOS/arm64
PCK exports and four GitHub-hosted Linux/x86_64 exports from run `30873652565`, each including two
fresh-cache copies, match at 824,432 bytes and SHA-256
`6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`; the 25-required /
nine-excluded resource probe and packaged boot pass locally and hosted.

### 2026-08-03 — Battle presentation uses an ID-only settled-action context

Every successful battle action returns a deep-copied `presentation_context.battle` containing only
`enemy_id_before` and `announced_intent_id`, captured before combat mutates health, round, phase,
or enemy profile. Failed and non-battle results return an empty context. The context is not a second
battle record: semantic `events` decide what resolved, and the settled result `snapshot` remains
authoritative. `enemy_hit` or `enemy_glanced` marks the announced intent as resolved;
`regular_enemy_won` or `battle_won` makes the pre-action profile outgoing; and `boss_arrived`
identifies the settled snapshot's enemy as its replacement. A lethal player action therefore
preserves the interrupted announced intent without claiming that the enemy executed it.

The context contains no name, damage, counter, reward, animation, duration, or callback. Mutating
the returned nested dictionary cannot mutate Journey or its source object. It is absent from
`JourneyState.snapshot()`, restore validation, replay state, and save JSON, so save v17 and all
v1–v16 migrations remain unchanged. Loading reconstructs current intent presentation from the saved
enemy ID and round and clears any previous outgoing/replacement context.

The new `IntentTelegraph` is a fixed 532×90 screen-space paper tag. It draws nine distinct,
code-native silhouettes for the nine stable intent IDs and four profile-specific edges. Every player
sees the current intent name and damage; only a previously investigated enemy profile reveals the
next intent and current counter window. Unknown intel receives the explicit text equivalent
“敌迹未辨”, while unknown or mismatched IDs use a neutral silhouette. Large text, high contrast,
standard/fast cues, and reduced motion preserve the same information. The control ignores mouse and
focus input, never blocks the next action, and has no rule, damage, intent, profile, intelligence,
round, counter, gameplay-timing, or save authority.

The current gate is 3,105 Godot unit/scene assertions, 357 chapter E2E checks, and 189
physical-input checks. The structural boundary is 116 static / 126 peak nodes. The package contract
is 25 required / nine excluded resources. Four local macOS/arm64 exports and four GitHub-hosted
Linux/x86_64 exports from run `30869981829`, each including two fresh-cache copies, match at 812,608
bytes and SHA-256
`aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`; manifest verification,
the resource probe, and packaged boot pass locally and hosted. Two 42-PNG capture passes reproduce aggregate SHA-256
`3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.
The same run is green across RPG quality, MUD quality, Multiplayer E2E, and Journey prototype.

### 2026-08-03 — Cen Wei is a saved path presence, not a quest authority

岑苇 follows four authored, publicly walkable points on 藏泉山道 at 0.075 normalized units per
second. Endpoints dwell for 1.5 seconds and middle points for 0.25 seconds. The same 0.080/0.100
enter/exit courtesy hysteresis used for readable moving interactions pauses him before the player
selects the 0.065-radius action and releases him only after the player leaves. Dialogue, journal,
pause, title, transitions, and non-path phases freeze the complete route snapshot. The route uses a
dedicated deterministic `PathKeeperState`; it does not read wall-clock time, randomness,
`NavigationAgent2D`, or a second collision system.

The repeatable “问问岑苇” action selects exactly one original event in fixed precedence:
setback, basket returned, basket left on the trail, basket found but unresolved, enemy spoor noted,
then the default route check. These are progression-aware echoes, not additional progression. Every
branch leaves the complete Journey snapshot unchanged and adds no item, statistic, relationship,
journal entry, chapter echo, combat modifier, reward, or mainline gate. `MapCanvas` only maps the
saved normalized feet to the original `cenwei.png` atlas, walking animation, integer placement, and
Y depth; its visual contract explicitly denies collision, quest, battle, reward, and save authority.

Save v17 adds one top-level `path_keeper` snapshot containing normalized position, adjacent target,
route direction, dwell remaining, and courtesy-yield state. V1–v16 files migrate to the authored
start rather than inventing elapsed movement; current files reject missing, off-route, inconsistent,
or oversized-dwell state. Explicit chapter replay restores the same start. The route action remains
selectable through keyboard, mouse, and controller, and modal presentation cannot advance it.

The implementation gate is 2,906 Godot rule/scene assertions, 350 chapter E2E checks, and 185
physical-input/focus checks. The latest 100,000-advance path-keeper sample is 55.46 ms. The scene
contract is 115 static nodes, 125 peak, 121 on the mountain path, 123 with the ferry patrol, 125 in
worksite dialogue, 116 in each spring state, 118 at completion, 123 at title, and 125 with dialogue
plus journal; the latest 20-cycle lifecycle sample is 928.60 ms with zero root leaks. Nine source
atlases and two 42-PNG capture passes reproduce, including `02-path-keeper-route.png`; the capture
aggregate is `f56422804793b50d4ee20e5b9a733bb7a5d61a4599771648a0a3028f2fb51bb7`.

### 2026-08-03 — Text scenes stay textual after controlled clean-cache identity proof

The former same-cache double-export gate hid a Godot 4.7.1 clean-import instability. Equal packaged RPG
inputs on three Linux CI runs produced the same 697,160-byte size but different hashes, while each run's
two sequential exports matched. Two independent local worktrees reproduced the drift. A PCK entry-level
comparison found 60 identical entries and one changing generated entry:
`.godot/exported/133200997/export-…-main.scn`. Godot's export conversion instantiates and repacks the
text scene, assigning fresh internal node identities when no export cache exists. This mechanism is
visible in Godot 4.7.1's [export pipeline](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/editor/export/editor_export_platform.cpp#L1020-L1095),
[`PackedScene` packing](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/scene/resources/packed_scene.cpp#L1099-L1123),
and [random resource-ID creation](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/core/io/resource_uid.cpp#L113-L130).

The project therefore sets `editor/export/convert_text_resources_to_binary=false`. Runtime still loads
the authored `main.tscn`, and the package no longer depends on a generated binary-scene identity. The
package gate now compares four outputs: two normal exports and two exports from independent project
copies with empty `.godot` caches. For the packaged runtime inputs committed in `f5c60e2`, all four
local macOS/arm64 outputs and all four outputs in each of two independent GitHub-hosted Linux/x86_64
RPG job attempts are 709,100 bytes at SHA-256
`e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`.
Both hosted attempts passed the 22-required / nine-excluded resource probe, manifest verification,
and headless boot; their lifecycle samples were 5,771.41 ms and 5,912.40 ms. Keeping the scene
textual adds 11,940 bytes (1.71% relative to the former 697,160-byte pack). This is a controlled
same-input observation, not a future cross-platform guarantee, and is not inferred from an
OS/architecture tuple. Only the PCK bytes are equal across OSes; each manifest separately records
and verifies its own build tuple.

Manifest schema v2 records normalized `build_os` (`macos` or `linux`) and `build_architecture`
(`arm64` or `x86_64`) beside the existing source, engine, preset, resource, size, and hash fields.
Generation derives these values from Python's build environment and fails closed on empty, partial,
unknown, non-string, noncanonical, or wrong-type values. Verification accepts an exact legacy
schema-v1 artifact and rejects future schemas or unexpected fields. Host names, runner IDs, OS/kernel
versions, CPU models, user paths, timestamps, and environment variables remain absent, so the tuple is
coarse privacy-preserving provenance rather than a machine identity or canonical-hash key.

These fields describe where a PCK was built, not the executable ABI or a selected release platform.
Native preset, templates, signing, notarization, icon, license, and distribution decisions remain at
the existing owner boundary.

### 2026-08-03 — Painted-paper portrait v2 is deterministic presentation, not a second character model

The exact stable order remains `protagonist`, `yanqing`, `liangshu`, `huishen`, `tao_xiaoman`,
and `journal`; unknown IDs still fall back to the journal. Revision 2 keeps the approved warm-paper,
mineral-pigment palette while adding a restrained Morning Peach dawn wash, integer-centered faces,
single expression paths, and profile-specific silhouette, expression, and carried-object cues. The
traveller has a high tie and straw cape, 砚青 a herb pin and medicine case, 梁叔 a reed hat and water
gauge, 蕙婶 a head wrap and woven apron, 陶小满 a cropped scarf and wedge satchel, and the journal a
mountain line and morning seal. These cues improve identity at the real 134×154 dialogue size without
making every face share an exaggerated smile.

All six remain code-native `CanvasItem` primitives at fixed coordinates. They use no imported image,
model output, random value, animation, timer, additional runtime scene node, input handler, content ID,
save field, or gameplay rule. The runtime visual contract explicitly reports revision, rendering
method, deterministic status, empty asset dependencies, profile cue, motion-free behavior, and zero
rule/save authority. A
capture-only 3×2 Chinese comparison board instantiates the same runtime control at its real size; it is
development evidence, not a packaged scene or alternate portrait implementation.

### 2026-08-03 — Hosted-runner lifecycle timing confirms a clean overage before failing

The lifecycle benchmark still requires one complete 20-cycle sample under 7 seconds. Every cycle
executes the same 13-state create/destroy route, dialogue progression and save writes, static/peak
node checks, map-detail and camera contracts, and root-child cleanup. Any correctness, structure,
node, or leak failure remains an immediate gate failure and is never retried.

The first cycle in every complete sample additionally executes the full standard → fast → instant
→ standard → fast reveal profile with four real settings writes. The other 19 cycles still start
standard reveal, complete and advance a line, save, and traverse the same dialogue response and
remaining 13-state route; they do not multiply an already-covered settings flush, verification,
backup rotation, and full accessibility-theme refresh by 20. Unit, E2E, and physical-input suites
remain the exhaustive owners of reveal and settings semantics. The lifecycle result reports the
actual probe-cycle and settings-write counts so a future edit cannot silently remove this coverage.

Wall-clock timing also includes awaited tree frames, local file-system work, and shared-runner VM
preemption that fixed FPS and a disabled render loop cannot remove. A first sample that is otherwise
clean but exceeds 7 seconds therefore triggers exactly one complete confirmation sample in the same
Godot process. The lower of the two complete timings is the accepted low-contention measurement;
both must exceed 7 seconds for a timing failure. The runner reports every sample, sample count, total
cycles, probe/write counts, and the maximum structural observations across both runs. The 20-cycle
workload, 7-second ceiling, exact 114 static nodes, 124 peak cap, 13 states, and zero-leak contract
are not relaxed.

### 2026-08-03 — Dialogue reveal speed is a presentation preference, not a reading timer

Settings v4 adds the stable `dialogue_speed` enum: `standard`, `fast`, or `instant`. Standard keeps
the existing 42 Unicode characters-per-second reveal; fast uses 84; instant shows every newly
rendered line in full. None of the modes auto-advances a line, chooses a response, removes the
full-line/history/skip controls, or imposes a reading timeout. Switching to instant completes the
current line; switching back never conceals text already shown. Negative, non-finite, and oversized
frame deltas cannot advance structured dialogue or overflow the reveal accumulator.

The preference is deliberately independent from battle-feedback speed and reduced motion. It is
written only through the validated settings store after a complete candidate succeeds; a failed
candidate leaves the current UI and existing settings file unchanged. V1–v3 settings preserve every
field valid in their source schema and migrate to standard reveal speed. Current v4 files require a
valid enum and otherwise fall back as one whole object rather than leaking partially parsed values.
Promotion first rotates a known-good primary to a short-lived backup; backup failure leaves the
primary untouched, promotion failure rolls it back, and a missing primary after interruption is
restored from that validated backup on the next read.

Dialogue ID and line index remain the only resumable dialogue authority. Character-level reveal
progress is transient: loading an active line starts it according to the current local preference.
Journey, Patrol, combat, content, rewards, and save v16 are unchanged. Pausing hides rather than
re-renders the current dialogue presentation, so changing the preference in the pause menu cannot
rewind already-read text. The paired title/pause controls add two static scene nodes; the measured
lifecycle boundary is 114 static / 124 peak with zero root leaks.

### 2026-08-03 — Enemy action animation consumes semantic events without gameplay authority

The four stable enemy profiles now share one original 384×256 RGBA atlas. Every 64×64 profile
row has two idle frames, two attack frames, and two reaction frames. The committed generator and
asset-contract schema v5 fix those six columns, frame rates, loop behavior, nearest filtering,
integer placement, foot anchor, profile order, and battle-event groups. The three mountain-path
warning sprites continue to use only their idle animation; only the existing battle sprite consumes
combat events, so the feature adds no scene node, timer, tween, collision shape, or save field.

`weakness_exposed`, `art_hit`, and `talisman_hit` select the reaction pose in that fixed priority;
`enemy_hit` and `enemy_glanced` select the attack pose. The latter names mean that the enemy hit or
glanced the player, not that the enemy was struck. One resolved action selects at most one pose,
and a newer action replaces it from frame zero without blocking input. Regular-enemy victory plus
warden arrival, final victory, retreat, and companion rescue suppress transient poses and reset the
already-synchronized profile to idle. This prevents the incoming warden from acting out the
departed regular enemy's hit reaction after the resolver has replaced the profile.

The standard 0.70-second and fast 0.18-second cue lifetimes are presentation-only clocks. Reduced
motion freezes a readable semantic first frame; invalid deltas and unknown events reject atomically,
and expiration returns to the profile's idle animation. No animation callback decides or delays
damage, intent, round progression, input, phase transition, persistence, or available actions.
Journey and save remained v15 at that decision point, and loading derived an idle pose solely from
the saved stable enemy ID. Intent-specific attacks and visible outgoing-enemy death sequences were
deferred because semantic event IDs intentionally did not carry the resolved intent or replaced
enemy profile. The later ID-only action-result context closes that presentation-data gap without
changing the event IDs or this rule/timing boundary.

### 2026-08-03 — Expanded maps use one deterministic bounded world camera

照禾渡口 and 藏泉山道 now use 48×27 32 px ground grids, giving each explored world a
1536×864 authored extent behind the validated 1152×648 presentation. Its 12 px inset leaves a
1128×624 `MapFrame` as the actual camera viewport. Ground, sparse details,
`MapCanvas`, actors, enemies, and landmarks live under one `WorldRoot`; HUD, dialogue, journal,
pause, title, transition, and other modal layers stay outside that transform. This keeps every
world-space element aligned while screen-space reading and input surfaces remain fixed.

`WorldCamera` derives exploration focus from the existing normalized player coordinate; battle and
completion use the instantaneous mean of their visible actor feet so the whole cast stays between
the fixed HUD and story panel. Neither presentation focus is persisted or becomes authoritative
game state. The camera rounds actor focus and viewport anchor through the same integer-pixel rule,
clamps independently at all four world edges, and reports a stable safe
frame with 32 px horizontal, 96 px top, and 192 px bottom margins around a 50%/47% anchor. Spawn,
transition, load, retreat, rescue, replay, and physical movement reframe immediately. Invalid,
non-finite, out-of-range focus or invalid viewport input rejects atomically; a viewport larger than
either world axis safely pins that axis to zero. There is no smoothing, wall-clock time, randomness,
collision, navigation, story, or save authority in the camera policy.

Save v15 remains unchanged: maps still persist stable IDs plus normalized coordinates, so existing
saves reframe without migration or serialized camera state. The scene cost is one structural node:
the lifecycle contract moves from 111 static / 121 peak to 112 static / 122 peak with zero root
leaks. Unit, physical-input, full-chapter E2E, deterministic capture, package-content, and boot gates
all cover the expanded world boundary.

### 2026-08-03 — Automated Godot gates treat fatal script diagnostics as failures

Godot 4.7.1 can return process status zero after a GDScript parse/load failure, which would make a
plain shell invocation report a false-green test or package gate. Every automated Godot path now
runs through `scripts/godot_checked`: it streams combined output, preserves a real nonzero engine
or `tee` status, and converts `SCRIPT ERROR`, `Failed to load script`, or `Parse Error:` emitted with
status zero into failure. Resource import, deterministic captures, all four test runners, export,
packed-content probing, and packaged boot use the checked path. Interactive play continues to use
the direct launcher so ordinary runtime diagnostics remain visible without changing play behavior.

The wrapper has isolated fake-runner tests for argument/output forwarding, genuine nonzero status,
zero-status fatal diagnostics, unrelated engine warnings, and Make/package wiring. A real malformed
GDScript reproduction confirms the engine returns zero while the checked gate returns one.

### 2026-08-03 — Ferry-runner worksite reactions are spatial payoff, not progression

陶小满 now has one original repeatable reaction at each end of her route for each delivery order:
boat priority, boat follow-up, herbs priority, and herbs follow-up. The corresponding action exists
only while her feet are exactly at the authored endpoint, endpoint dwell remains positive, and the
player is inside the normal interaction radius. A waiting player never stops her one step short:
endpoint arrival resolves before courtesy yielding. Dialogue then freezes the complete patrol
snapshot. Finishing either response immediately clears the current endpoint dwell while preserving
the existing courtesy-yield state. If the player remains nearby, yielding continues; the route
resumes only after the player leaves the exit hysteresis radius.

Each reaction contains two ordinary-work responses. Securing the boat cloth, checking the wedge
measure, steadying the herb tray, or checking the light produces authored event prose only. The
four reactions are repeatable and add no item, statistic, relationship value, journal entry,
chapter echo, route mutation, reward, or mainline gate. The Journey snapshot remains field-for-field unchanged;
`PatrolState` remains the sole owner of endpoint, dwell, and courtesy eligibility, while the
dialogue layer owns only resumable presentation progress.

Save v16 changes no payload field. It is an explicit schema boundary because the set of valid
serialized active dialogue IDs now includes the four worksite reactions. V1–v15 files migrate
conservatively through the existing validated state, without inventing a reaction or response.
An older runtime sees v16 as a future-version barrier and therefore cannot silently accept or
overwrite an active worksite dialogue whose enum value it does not understand.

### 2026-08-03 — The ferry runner patrol is deterministic, saved, and socially consequential

陶小满 is an original ferry runner who appears only after the player completes 砚青's risk
briefing. She follows a six-waypoint, publicly walkable route between the boat frame and drying rack at 0.09
normalized units per second; the player remains more than three times faster. A 0.080/0.100
enter/exit courtesy radius freezes and releases the route with hysteresis so an interaction cannot
vanish while the player reaches for keyboard, mouse, or controller input. Dialogue, journal,
pause, title, transitions, and non-ferry phases also freeze the patrol clock.

The route is owned by a dedicated deterministic `PatrolState`, not by `MapCanvas`, wall-clock time,
randomness, `NavigationAgent2D`, or a second collision system. Its authored segments stay inside the
existing ferry walkability contract. Its endpoints remain visibly beside, but outside the action
radii of, the two destination landmarks. Where the public road crosses another static interaction
radius, the nearby unanswered runner temporarily has priority so courtesy yielding cannot strand
her behind a fixed action; after the one-shot conversation or her departure, the fixed action
immediately returns. The UI only maps
normalized feet to the generated actor atlas, animation, marker, and Y depth. Dynamic navigation is
deferred until an NPC actually needs to avoid changing obstacles or choose among unbounded paths.

The player may set today's delivery order once: protect the damp-sensitive boat wedges first, or
turn the drying herbs before the sun shifts. Both choices are original, reward-free life-story
decisions. They change 陶小满's next route direction plus the journal, chapter summary, and epilogue
reflection, but never combat, inventory, cultivation, relationship numbers, or mainline access.
Save v15 stores the stable journey response and the exact patrol position, adjacent target,
direction, dwell time, and courtesy-pause state. Runtime restore rejects off-route coordinates,
mid-segment dwell, inconsistent target/direction pairs, and oversized waypoint dwell. Idle patrol
ticks do not rotate the disk save; established interaction, movement, pause, and title checkpoints
persist the latest route. V1–v14 migration restores the neutral starting
route and `unanswered` response rather than inventing a choice; malformed or future patrol states
are rejected under the existing crash-consistent and anti-downgrade rules.

### 2026-08-03 — Repeatable Zhaohe life landmarks are spatial prose, not progression

The ferry boat-repair rack, ferry drying rack, and mountain-path rain shelter are three original,
always-repeatable proximity interactions. Each provides a short Chinese observation about ordinary
work and mutual aid, with no item, statistic, journal entry, ending echo, hidden relationship value,
or other reward. Repeating an action returns the same semantic event while leaving the Journey
snapshot byte-for-byte equivalent; the existing save schema remains v14. Ordinary movement may
still autosave the player's coordinate under the existing persistence contract.

Keyboard, mouse, and controller all enter the same domain action path. The three authored anchors
are publicly reachable through `move()`, stay separated from other interaction radii, and are paired
with three new 192×128 regions in the original Zhaohe landmark atlas. That atlas is now 2112×128
with 11 fixed profiles under asset contract v3; MapCanvas visual contract v2 binds each visual feet
position to its phase, interaction anchor, and action ID without granting collision, story, or save
authority. Seven generated atlases still reproduce twice against their Git-index blobs. The scene
remains 110 static nodes with a 120-node peak and zero lifecycle leaks.

### 2026-08-03 — Zhaohe landmarks use one reproducible pixel atlas

The ferry, mountain path, and battle view now consume one original 2112×128 RGBA atlas with eleven
fixed 192×128 regions: celadon tree, three ferry houses, dock, mountain rock, spring cave, spring
gate, boat-repair rack, drying rack, and rain shelter. The project-authored Godot generator can target an isolated directory; the asset gate
regenerates all seven committed atlases twice and requires both runs, the worktree, and Git index
to match byte for byte. The contract fixes profile order, foot anchor, nearest filtering, integer snapping,
transparent bounds, and `collision_authority: false`.

The existing three-house/four-tree ferry, five-tree path, and four-tree battle occluder nodes now
render atlas regions directly, so Y-depth behavior gains real pixel assets without a child-node or
budget increase. Dock, rocks, cave, and gates are drawn as regions from the same atlas through the
existing map canvas. Their former runtime geometry helpers were removed. Domain obstacles,
interaction radii, story state, and save v14 remain authoritative and unchanged.

The mountain return coordinate previously sat over a water tile even though the deterministic
domain allowed it. A fixed 5×5 stone bridge now covers that authored gate approach while preserving
the stable coordinate and old saves; all path spawn and interaction anchors are tested against
non-water ground. The scene remains 110 static nodes with a 120-node peak and zero leaks. Two
34-PNG capture passes are byte-identical, and that gate invocation produced two matching 559,676-byte
packages with
SHA-256 `482485ac5610f7d9157461b4d178fcac0712a23674980e131d6a2a9bfd3d4f1d` and 15 explicit
runtime-resource probes.

### 2026-08-03 — First breath is a saved three-point spatial ritual

The chapter now enters a third micro-map, `cangquan_spring`, after the mountain path. Three fixed,
reachable points remain present in the chamber and express one ordered ritual: listen at the spring
to distinguish its pulse, warm the meridians with moonleaf at the stone bed, then sit at the breath
stone to draw in the first breath (`听泉辨脉 → 月芽温脉 → 静坐引息`). Keyboard, mouse, and
controller interaction all reach the same domain actions. Presentation may show every point, but the
domain alone owns the order. A repeated or out-of-order action returns
`first_breath_out_of_order` atomically: the journey snapshot, inventory, save generation, and scene
position do not change; presentation changes only to show the Chinese recovery hint. Only the
warming step consumes the moonleaf.

Save v14 records one of four stable stages — `unstarted`, `listened`, `warmed`, or `completed` —
plus the stable map and normalized coordinate. Every successful ritual step autosaves, so scene
destruction, title return, and continuation restore the exact stage and location. Current saves
strictly pair riverbank with `zhaohe_ferry`, mountain-path/battle with `cangquan_path`, and
spring/complete with `cangquan_spring`; contradictory stage, phase, map, inventory, or realm states
fail validation. V1–v13 migration preserves a completed chapter as `completed`, resets every other
legacy snapshot to `unstarted`, and normalizes spring/complete saves to their authored spring
positions rather than inventing intermediate progress. Explicit chapter replay clears the ritual
stage with the rest of the route state.

The lifecycle evidence remains inside the existing budget: 110 static nodes, 120 maximum, 111 in
each of the three spring states, 113 at completion, and zero root-child leaks. Two consecutive
34-PNG reference-capture runs produce identical SHA-256 sets, including the three ritual states and
the completed scene.

### 2026-08-03 — Sparse map details remain deterministic presentation

The existing 256×32 ferry atlas now keeps its original eight ground tiles unchanged in row zero
and adds a second transparent row for reeds, bank grass, path pebbles, wildflowers, stone cracks,
moss, fallen leaves, and water foam. One shared `TileMapLayer` places finite, explicit integer
cells for the ferry and mountain path. It rebuilds only when the rendered map kind changes and is
hidden, without rebuilding, during battle, spring, and completion scenes.

The detail TileSet deliberately owns zero physics and navigation layers and exposes
`collision_authority: false`; normalized ExplorationState obstacles, interaction radii, saves, and
story rules remain authoritative. The redundant full-screen background node was replaced rather
than increasing the scene tree, preserving 110 static nodes and the existing 120-node immediate
and stable peak. The generator, atlas row order, exact cell layouts, package resources, same-cache PCK
comparison, and two consecutive 32-image capture sets were deterministic quality gates at that stage.

### 2026-08-02 — Three studied spoors reveal timing without changing combat truth

The mountain path contains three optional, one-time investigations: a rock-armor scrape, a
wind-scattered moss spray, and an off-centre puppet drag mark. They record exactly three stable
enemy-intelligence IDs, leave shape-readable studied residues on the map, and populate a separate
`灵物志` journal page. Unknown entries expose no enemy name, technique, location, or counter.
The rock-armor entry also explains the related warden; the boss does not create a fictitious fourth
mountain trace.

Every enemy intent now has a stable ID, and each material counter applies only during its authored
intent window: talisman against the juvenile's rending charge, art against the moss shell while it
absorbs moisture, guard against the puppet's unbalanced swing, and guard against the warden's
stone-breaking blow. The current intent and damage remain visible to every player. Studied
intelligence additionally previews the following intent and names the counter, but never changes
health, damage, resources, turn order, routes, or rewards. Accidentally choosing the right counter
without studying a trace resolves identically and does not silently unlock the journal.

Save v13 stores only the ordered unique `enemy_intel` IDs. v1–v12 migrate to an empty list rather
than inferring knowledge from a past encounter. Retreat, rescue, and chapter completion preserve
the list; explicit chapter replay clears it. Intent previews are always derived from enemy ID,
round, and current content, so no redundant future-turn state enters the save schema.

### 2026-08-02 — Journey saves keep a validated recovery generation

The journey transaction keeps three deliberate candidates without changing save v12: the committed
primary file, a fully written interrupted temporary file, and the previous committed primary as a
long-lived backup. A valid primary wins; when it is missing, malformed, or domain-invalid, recovery
tries a valid temporary candidate before the older backup. Every v1–v11 migration now passes the
same current Journey, Exploration, and Dialogue restoration checks before it can be selected.
The UI may reject a structurally valid candidate whose dialogue position no longer maps to current
authored content and continue to the next validated candidate. Successful recovery immediately
rewrites the selected state as the primary file.

An unsupported-version or different-story artifact in the primary, `.tmp`, `.repair`, or `.bak`
slot is an anti-downgrade barrier: an older runtime neither falls back past it nor overwrites it
during autosave. A normal save replaces any stale `.tmp` before rotating the committed primary, so
an abandoned branch cannot outrank the last committed generation after a second interruption.
`.repair` is never a read candidate; it is scratch space used only while healing from a selected
temporary or backup source, which remains byte-for-byte intact until promotion succeeds. A second
and every later successful write retains the prior valid primary at `.bak`; invalid candidates never
replace a known-good backup. Read failure does not modify any candidate bytes. These are transaction
and validation semantics only, so the payload schema remains save v12 and scene/node budgets are
unchanged.

### 2026-08-02 — A found public basket becomes a bounded cross-map choice

After identifying the abandoned basket's public herb-garden mark on the mountain path, the player
may carry it back to the reachable herbkeeper 蕙婶 at the ferry. Her four-line original dialogue
offers exactly two non-power outcomes: return the repaired basket to the herb garden, or leave it
under the trail's rain shelter for later travellers. Both preserve health, items, combat strength,
companion resources, routes, discoveries, and ending access. The chosen outcome instead selects a
visible basket residue, one journal entry, one chapter-summary label, and one epilogue reflection.
The interaction is proximity-bound, can be interrupted and restored, disappears after one answer,
and replay clears it. Save v12 stores only `unanswered`, `return`, or `trail`; v1–v11 migrate to
`unanswered`. A fourth project-generated actor atlas and fifth motion-free painted-paper portrait use
the stable presentation ID `huishen`, add exactly one scene node, and keep the measured peak at the
existing 120-node lifecycle ceiling.

### 2026-08-02 — Starting over never destroys local progress in one activation

When any primary, backup, or interrupted-write journey artifact exists, the title's first
`重新开始` activation changes the existing two primary buttons into an explicit confirmation:
cancel and preserve the files, or confirm deletion and begin again. Cancel receives default focus;
controller Start and Escape also cancel, while unrelated title preferences are temporarily disabled.
No journey object or file byte changes before the second confirmation. Invalid or future-version
artifacts receive the same protection so a player retains the option of manual recovery. The flow
reuses existing nodes to stay within the 120-node lifecycle budget and owns no rule or save-schema
state. Reference capture tooling separately freezes animation frames, feedback phase, and transition
time only while writing PNGs, making two consecutive full capture runs byte-identical without
changing runtime presentation.

### 2026-08-02 — Text size and contrast are player settings, not rule inputs

Settings v3 adds `text_scale` (`standard`/`large`) and `high_contrast` (boolean), toggled from
paired title and pause buttons like every earlier preference and persisted through the same
validated store. Large text multiplies each captured baseline reading-label size by 1.25 and
never edits scene-authored values; standard restores the exact captured baseline. High contrast
maps each reading label to one of two fixed opaque palette anchors by luminance — deep ink on
paper surfaces, paper white on dark surfaces — so both text polarities strengthen instead of
inverting the painted-paper art. Both options touch presentation labels only: rules, saves,
combat pacing, and content are unaffected, and `accessibility_contract()` exposes the applied
state for headless assertions. v1/v2 settings migrate conservatively to standard size and
normal contrast.

### 2026-08-02 — The ferryman side story leaves public evidence without a power reward

梁叔 now waits at a fixed reachable ferry coordinate as the chapter's third animated map actor.
His four-line original dialogue offers exactly two bounded outcomes: help set the flooded water
gauge upright, or record the retreat time and mud height for the levee log. Both outcomes preserve
all health, items, combat strength, relationship values, discovery count, routes, and ending access.
They instead choose a persistent map residue, one content-driven journal entry, one chapter-summary
label, and one epilogue reflection. The interaction disappears after the response and chapter replay
clears it. Save v11 stores only `unanswered`, `repair`, or `record`; v1–v10 migrate conservatively to
`unanswered`. A third project-generated 32×56 atlas and a fourth motion-free painted-paper portrait
use the stable presentation ID `liangshu`; neither presentation layer owns the side-story result.

### 2026-08-02 — Chapter epilogue reuses structured dialogue and reflects the played route

`回顾此行` now starts the stable `chapter_epilogue` dialogue only after the first breakthrough.
Its five original lines resolve bounded presentation tokens from the deterministic snapshot:
whole-plant/cutting harvest, discovery count, setback count, and careful/trusting briefing
response, plus the ferryman and public-basket outcomes when present. The existing save-v10 dialogue object can already store dialogue ID and line index, so
this compatible content expansion needs no schema bump; restoration additionally requires the
journey to remain complete. Two closing responses emit independently tested semantic events but
grant no resource, reward, relationship score, or new permanent state, and the review may be
repeated. Content-declared choice event IDs must match the domain event returned at runtime.

### 2026-08-02 — The journey journal reviews known history without revealing unknown history

The in-game `行旅札记` reads the current objective and save-v10 discovery IDs but owns no
progress. J, controller Y, and a visible map button open the same z-90 paper modal; closing returns
the prior focus, while movement, interaction, and battle input cannot pass through it. Each known
ID resolves through validated original `journal_entries` content. Undiscovered slots show only a
numbered `未记之事` prompt, never their title, location, reward, or summary. The journal remains
available across exploration, battle, spring, completion, and save restoration, but cannot open
over a scene transition, dialogue, title, or pause modal. It does not add a save field because the
deterministic discovery list already contains all persistent truth.

### 2026-08-02 — Dialogue portraits are finite motion-free painted-paper presentation

The prologue dialogue uses five stable presentation IDs: `protagonist`, `yanqing`, `liangshu`,
`huishen`, and `journal`. Project-authored Godot drawing code renders the protagonist in clear
indigo, 砚青 in warm ochre, 梁叔 in levee-shadow teal, 蕙婶 in herb-garden celadon with a woven
apron, and history mode as an unpeopled travel journal over the same bright paper landscape.
The current speaker, player responses, and dialogue history select those IDs; an unknown ID falls
back to the journal instead of inventing a person. A visible Chinese caption remains beside the
art for identity and accessibility. Portraits ignore pointer input, contain no animation, do not
enter saves, and never decide dialogue or journey rules. They are an auditable production
placeholder, not a generated concept image or imported external asset.

### 2026-08-02 — Environmental discoveries are finite history, not hidden power

The prologue now has three stable optional discovery IDs: the ferry flood marks, a branching
spring seam, and an abandoned herb basket. Each requires proximity, emits original authored
history, saves once, changes its map residue, disappears from available actions, and contributes
one point to the `见闻 n/3` chapter summary. Discoveries do not change health, damage, resources,
routes, or ending access, so players are not mechanically punished for missing optional reading.
Unknown, duplicate, or phase-impossible IDs fail domain restoration. Replay clears the list.
Save v10 stores only those stable IDs; v1–v9 migrate to an empty list rather than inventing history
that older builds never recorded.

### 2026-08-02 — Chapter companions follow bounded player footprints

After the ferry briefing, 砚青 follows the player's already-traversed normalized positions rather
than snapping to a fixed offset or introducing a second navigation authority. The presentation
keeps a maximum of 96 points and resolves a target 0.058 map units behind the player, so corners
follow the proven route instead of cutting diagonally through buildings. A phase change, context
change, or jump over 0.14 units rebuilds two seed points beside the current player; the trail is
deliberately not serialized. Battle and cultivation keep authored stage positions. This affects
animation, placement, Y-depth, and screenshots only; deterministic player collision, interactions,
quests, and saves remain authoritative. A 50,000-update performance workload enforces the point
cap. Godot 2D navigation remains reserved for actors that need routes the player has not walked,
such as independent patrols.

### 2026-08-02 — Scene transitions are content-driven presentation with an instant fallback

Changes between ferry, mountain path, battle, spring, and completion use a 0.48-second bright
paper-and-ink reveal at z 70; the warden arrival can trigger the same presentation without a
domain phase change. Labels live in validated original story content and reference existing node
or semantic-message IDs. While active, a transparent focus sink blocks mouse, keyboard, and
controller confirmation so the input that entered a scene cannot also select its first action;
battle focus is restored when the reveal ends. Reduced-motion mode records the same transition
label but displays the destination instantly. The transition never delays or changes deterministic
resolution, autosave, available actions, or journey snapshots. Dialogue/title/pause remain above
it at z 80/100/110. The lifecycle budget now observes 96 nodes, below the existing cap of 120.

### 2026-08-02 — Map occlusion sorts by feet Y below modal UI

Runtime-drawn roofs and tree canopies now have independent foreground nodes while their base forms
remain in the map drawing. Actors, enemy sprites, roofs, and canopies map their feet/base Y into
the bounded z band 10–60: an actor behind a base is occluded, and an actor below it renders in
front. Ferry, path, and battle rebuild only their own seven, five, or four occluders; the spring and
completion scenes clear them. Dialogue remains at z 80, title at 100, and pause at 110, so no map
depth can cross a modal paper surface. The performance gate now observes 88 main-scene nodes,
within the existing 120-node budget, and still requires zero root-child residue after destruction.

### 2026-08-02 — Moonleaf harvesting has two non-blocking persisted methods

At the moonleaf field, the existing `gather_moonleaf` action remains the stable one-button default
and means taking one whole plant under the field rule. A second explicit action cuts mature leaves
and leaves roots and new growth visible. Both yield the one quest herb required for the first-breath
route and neither creates a hidden optimal combat reward; the authored consequence is stewardship,
map residue, event prose, and chapter-summary echo. Save v9 records `whole_plant` or `cutting`.
V1–v8 snapshots with an herb or completed chapter conservatively migrate to `whole_plant`; an
unharvested old snapshot migrates to `unselected`. Invalid or phase-inconsistent methods fail closed.

### 2026-08-02 — Performance evidence uses broad versioned workloads

The CI performance gate measures deterministic work rather than presentation frame timing: 100,000
normalized movement/collision steps, 50,000 bounded companion-trail updates, 2,000 complete
regular-enemy-to-warden rule loops, and 20 main-scene create/destroy cycles. The three pure-domain
workloads keep independent 2.5-second ceilings. The lifecycle workload originally sampled six UI
states under 5 seconds; it now samples 11 states per cycle, including the three spring stages and
completion, and executes the two added crash-consistent ritual autosaves. Its documented ceiling is
therefore 7 seconds while the 20-cycle count, 120-node cap, map-detail rebuild assertions, and
per-cycle root-child baseline remain unchanged. This is a tighter per-state allowance than the
original workload, not a release-device claim.

Budgets live in excluded test data and remain far above current local measurements so shared CI
detects order-of-magnitude regressions. The lifecycle runner uses Godot's fixed 60 FPS clock and
preserves every required focus/deferred-tree settle frame; transitions explicitly completed in the
test need one frame before stable sampling. Automatic rendering is disabled because pixels are
covered by the deterministic capture gate and software-renderer variance is not a scene-lifecycle
signal. Animation speed and combat outcomes remain outside these wall-clock thresholds.

### 2026-08-02 — Stable enemy IDs select reproducible pixel-atlas rows

The three regular profiles and the rock-armor warden share one original 128×256 RGBA atlas. Each
stable enemy ID owns one 64×64 row with two looping idle frames, a fixed 32×56 foot anchor,
nearest filtering, and integer node placement. Mountain-path warning silhouettes and the active
battle enemy are separate presentation nodes consuming that same atlas; only the battle node
switches rows when the deterministic resolver replaces a regular profile with the warden. Unknown
IDs are rejected by the presentation adapter and remain rejected by save validation. Runtime
enemy-shape drawing has been removed so screenshots, packaged play, and the asset validator inspect
the same committed source image.

### 2026-08-02 — Mountain-path warning has three recoverable routes

The visible rock-beast warning supports three player-authored outcomes before the spring chamber:
approach and fight, inspect/retreat and return later, or follow the upper creek edge to bypass the
encounter. The bypass reaches the spring without consuming health, talismans, deployables, support,
or combat rounds; the direct route retains the deterministic battle. Replay E2E covers the bypass
separately from the primary combat route so neither can silently become cosmetic or mandatory.

### 2026-08-02 — Explorable mountain-path transition and retreat semantics

Entering the spring gate now transitions from `zhaohe_ferry` to the independently saved
`cangquan_path` map before combat. The player may inspect an old route marker, approach the visible
warning zone, or walk back to the ferry. Battle retreat returns to a safe mountain-path marker and
resets the enemy attempt; only health depletion triggers companion rescue all the way to the ferry.
Both map transitions use the same semantic interaction path, persist map identity and normalized
coordinates, and are included in new-scene save/resume E2E coverage.

### 2026-08-02 — TileMapLayer ferry-ground baseline

照禾渡口 now composes its ground from a 36×20 grid of original 32 px tiles through Godot's
`TileMapLayer`. Water, bank, road, moonleaf field, grass, and gate stone are explicit map cells;
the existing vector-drawn buildings, trees, dock, actors, and interaction markers remain a
temporary foreground comparison layer. The deterministic normalized exploration domain remains
authoritative for collision and interactions, preventing display tiles from becoming a second
gameplay rule set. Every cell, semantic region count, atlas dimension, filter mode, and packed boot
is covered by the existing quality gates.

### 2026-08-02 — Reproducible pixel-character production contract

The first in-engine character contract uses a 32 px map grid, 32×56 px actor frames, a fixed
16×52 px foot anchor, a 16×20 px collision baseline, and two-frame idle and walk cycles in four
directions. `AnimatedSprite2D` consumes original lossless atlases with nearest filtering and
integer-position snapping; deterministic exploration remains authoritative for collision. The
initial protagonist and 砚青 atlases are generated by project-authored Godot code and validated
as intentional production placeholders. Animation frames may change during art refinement, but
their visual bounds cannot silently change collision or save behavior.

### 2026-08-01 — Playable-slice exploration baseline

Use normalized world coordinates for the first playable map so rendering resolution does not
change traversal, collision, or interaction outcomes. Keep exploration state and collision in a
deterministic domain object rather than the scene tree. The 1152×648 development viewport and
56 px actor height are accepted for this slice; the collision footprint is intentionally smaller
than the visible silhouette. Keyboard, mouse, and controller input converge on semantic move and
interact actions, and world interactions require proximity rather than remote menu selection.

This is an implementation baseline for the overnight playable slice, not a release-platform or
final-sprite commitment.

### 2026-08-01 — Versioned local save boundary

Save only versioned deterministic journey snapshots and normalized exploration coordinates as
JSON under `user://`; never serialize the scene tree or executable objects. Validate domain
invariants before restoring, reject unknown versions without modifying memory, and preserve a
last-known-good backup while promoting a verified temporary file. Starting a new game is the
explicit operation that replaces an existing or unreadable local save.

Schema changes use explicit forward migrations. Save v2 adds companion-support and setback
state; save v3 adds the companion-briefing quest flag. V1/v2 files are migrated in memory,
validated, then rewritten only after the player chooses to continue. Mid-chapter legacy saves
infer that the required briefing already occurred; ferry saves expose the new conversation.

Save v4 adds the tactical-deployable slot and remaining effect turns. V1–v3 migrations initialize
an unused lamp and no invented active effect.

Save v5 adds a stable `map_id` beside normalized coordinates. V1–v4 files migrate to
`zhaohe_ferry`; current-version files with missing or unknown map identities are rejected before
domain restoration. This prevents a valid coordinate pair from being silently loaded into the
wrong scene as the explorable mountain path and later regions are added.

Save v6 adds a separate dialogue snapshot with active dialogue ID and line index. V1–v5 files
migrate to an idle dialogue and infer the conservative briefing response only when an old snapshot
already completed that mandatory quest beat. The loader validates dialogue structure, current
content bounds, and its consistency with journey progress before replacing live state.

Save v7 adds a stable enemy profile ID. V1–v6 files migrate to the rock-armor juvenile profile;
inactive legacy phases normalize that profile to full health, while an in-progress old battle keeps
its earned damage. Current files with an unknown enemy ID are rejected before domain restoration.

Save v8 adds bounded remaining-turn counters for armor break and focused breath. V1–v7 files
migrate both to zero. Non-battle snapshots cannot retain either status, and leaving battle through
victory, retreat, rescue, bypass, or chapter reset clears them explicitly.

Save v9 adds the explicit moonleaf harvest method. V1–v8 infer the conservative whole-plant method
only when their existing state proves the herb was already gathered or consumed. Save v10 adds the
bounded environmental-discovery list. V1–v9 migrate that list to empty; current snapshots reject
unknown, duplicate, or journey-inconsistent discovery IDs before replacing live state.

### 2026-08-02 — Enemy profiles share one deterministic resolver

岩甲兽幼体、泉苔寄壳 and 失衡石傀 differ through data: maximum health, a two-intent damage
cycle, one weakness action, bonus damage, name, and short description. The journey state stores
only the selected stable ID and mutable battle values. Player actions, guard, lamp, companion,
retreat, rescue, and victory continue through one resolver; the UI reads the same profile and next
round index to announce intent before input. Frame timing never selects or advances an intent.

The rock-armor warden is a fourth profile consumed by that resolver, not a boss-specific combat
class. Defeating a regular profile swaps to the warden, restores only the explicitly documented
inter-encounter resources, and preserves spent talismans. Guarding its heavy attack applies two
armor-break charges; companion support applies two focused-breath charges. Each later offensive
action consumes one applicable charge for one bonus damage. Both counters are snapshot state and
are exercised by an E2E scene teardown and restore.

### 2026-08-02 — Resumable dialogue owns presentation progress

Long-form dialogue advances in a small domain state rather than mutating the story node on every
line. Content JSON owns speakers, original Chinese text, and exactly two response records; the
journey domain receives only the final response ID and awards the quest transition once. Fast
display, history, and skip-to-response therefore cannot duplicate rewards. Autosave records every
line advance, and the complete E2E destroys and recreates the scene mid-conversation before
choosing each response on separate playthroughs.

### 2026-08-01 — Spatial briefing starts the quest

The opening objective first asks the player to approach 砚青 at the ferry marker. The companion
stays at the marker until the player receives the risk and retreat briefing, then follows during
exploration. Quest guidance advances from briefing to herb preparation to the spring gate. This
uses the same proximity and semantic-action path as every other world interaction.

### 2026-08-01 — Opt-in procedural ambience

The functional slice defaults to silence. A player may enable project-authored ambience and
choose 35%, 60%, or 100% volume from either title or pause UI. GDScript synthesizes the placeholder
sound at runtime through `AudioStreamGenerator`, so no third-party or generated sound asset enters
the repository. Versioned settings are stored separately from journey progress; invalid settings
fall back to silence without affecting the save game.

Settings v2 adds `battle_speed` and `reduced_motion`. V1 audio-only settings migrate to standard
speed and full motion. Fast mode shortens only the lifetime of semantic feedback; reduced motion
uses the same static label and border without pulsing. Neither preference is passed into the
journey domain. A scene test resolves the same action through a feedback-enabled scene and a pure
domain mirror, then requires byte-for-byte equivalent snapshots.

Modal UI has an explicit rendering hierarchy: dialogue above map actors, title above dialogue,
and pause above title. This prevents actor sprites and combat feedback from crossing paper panels
or blocking menu labels as new presentation nodes are added.

### 2026-08-01 — Verified PCK as the overnight delivery boundary

The overnight slice exports a cross-platform Godot resource pack and validates it through byte
comparisons plus a headless main-scene boot. Every build emits a canonical provenance manifest with
the exact size, SHA-256, engine and preset, nearest Git revision, clean/dirty source state,
runtime-resource probes, and development-resource exclusions. The current package gate compares two
normal outputs with two independent empty-cache project copies, compares both normal manifests,
recalculates their artifact fields, opens the PCK as the active `res://` namespace, requires 22
production resources, and rejects nine representative files under the excluded `tests/` and `tools/`
trees before booting the main scene. Generated `.gd.uid` files are committed as intentional Godot
resource identity metadata; the `.pck` and export caches stay under ignored `build/` / `.godot/`.
Native macOS, Windows, or Linux executables wait for an owner-selected first platform and public
license, a confirmed distribution target, official export templates, product icon, signing identity,
and platform smoke tests. Local players can
build and launch the validated pack with `make play-rpg-package` using the pinned engine entrypoint.

### 2026-08-01 — Visible two-turn tactical deployable

The first deployable slot holds one 引泉石灯 per combat attempt. Deployment consumes the slot,
reduces the current incoming hit by one, and persists for one more enemy response. The active lamp
is visible on the battlefield and in the HUD. Retreat or companion rescue resets the attempt and
restores the lamp; victory records whether it was used in chapter settlement. This establishes a
real tactical-slot contract without introducing a general inventory or equipment framework.

### 2026-08-01 — Physical input and minimum-readable-window gate

The 1152×648 reference viewport is also the minimum development window until a responsive-layout
pass proves something smaller. A dedicated headless acceptance path sends raw keyboard E/S and
controller A/Start events, checks UI focus ownership, moves the character, interacts with world
targets, opens and resumes pause, navigates the combat grid, and confirms an action. Controller A
is explicitly bound to `ui_accept` as well as world interaction so title and pause buttons share
the same physical control as gameplay.

### 2026-08-01 — Recoverable first-combat failure

The first combat teaches preparation without creating a hard fail state. The player may retreat
along the marked route at any time; the enemy recovers, spent consumables remain spent, and a
setback is recorded. If player health reaches zero, the chapter companion rescues the player to
the ferry with a playable health floor. Companion first aid is an explicit once-per-attempt
action, not an invisible damage modifier.

### 2026-08-01 — Explicit chapter closure and replay

The vertical slice ends on a settlement state that shows realm, setbacks, remaining consumables,
and companion outcome. From there the player can review, save and return to title, or explicitly
reset the chapter for replay. The release gate includes a separate headless path that starts at
the title, performs proximity gathering and a retreat/re-entry combat route, breaks through,
reloads the completed save in a new scene instance, and resets into replay.

### 2026-08-01 — Brighter and more optimistic visual tone

Refine the confirmed hybrid art direction toward clear daylight, fresh air, visible water,
livelier vegetation, warmer paper, and more approachable character affect. Preserve cool contact
shadows, material wear, tactical readability, and the ability for caves and conflict to become
dark. Bright does not mean neon, childish, uniformly cheerful, or without danger.

`docs/design/ART_DIRECTION_v0.2.md` supersedes v0.1 for palette, lighting, and emotional tone.
The medium split remains unchanged: pixel gameplay, painted narrative art, and rare layered
breakthrough or secret-realm scenes.

### 2026-08-01 — Hybrid pixel, painted, and layered art direction

Use the `像素行旅` direction for ordinary maps, characters, combat, and interaction
readability. Bring the `纸上山河` direction into dialogue portraits, chapter art, subdued
paper texture, and the shared ink/celadon/indigo/rust/gold palette. Reserve the `叠景秘境`
direction for breakthroughs, dreams, major secret-realm reveals, and rare chapter climaxes;
it is not a parallel default world-production pipeline.

The executable rules and constraints are recorded in `docs/design/ART_DIRECTION_v0.1.md`.
Generated boards remain concept references rather than shippable sprites or textures.

### 2026-08-01 — Primary direction becomes an original story-driven RPG

The primary future product is an original, Chinese-first, single-player 2D cultivation RPG.
It uses chapter-based companions, top-down exploration, preparation, deterministic turn-based
combat, and bounded story branches. Classic Chinese party RPGs inform its interaction grammar
only; their protected content, assets, presentation, and distinctive combinations are not
production inputs.

The existing Evennia MUD and Journey PWA remain playable research prototypes and quality
suites. They are preserved but no longer define the primary client architecture.

### 2026-08-01 — Godot 4.7.1 RPG foundation

Use Godot 4.7.1 and GDScript for the first graphical RPG vertical slice. Keep deterministic
rules outside UI scenes, display prose in validated original-content files, and run rule and
scene tests headlessly. The first slice is offline-first and needs no gameplay server. Python
is limited to build-time content validation and repository tooling.

The first content target is a 90-minute original chapter around the already-original 照禾县
region. PC/macOS/Linux is a development assumption, not a confirmed release-platform decision.

### 2026-08-01 — Finite and idempotent onboarding progression

The 照禾县 vertical slice ends at `引息境一层`; it does not imply an infinite local
progression system. After reaching that realm, the shallow spring no longer grants qi through
`修炼`. Gathering and formation rewards are idempotent, completed steps disappear from the
action list, and each character receives the formation reward only once. A completed character
may still witness another player's formation as a mentor without receiving repeated resources.
Legacy post-breakthrough qi overflow is capped during state migration.

### 2026-08-01 — Chinese-first player experience

All ordinary player-facing login, room, movement, chat, help, cultivation, and status
text uses Simplified Chinese. Chinese command names are the documented/default path;
English command names remain compatibility aliases. A runtime language switch is not
part of this vertical slice.

### 2026-08-01 — Selectable actions remain commands

Browser choices use Evennia's server-authored MXP command links rather than a parallel client
state machine. Links degrade to readable text in Telnet and assistive clients, and clicking a
choice follows the same authoritative command path as keyboard input.

### 2026-08-01 — Repository workflow

Implementation work proceeds on `codex/` feature branches. The complete relevant
local test suite must pass before commit and push; GitHub Actions must pass on the
pull request before merge to `main`. Direct implementation commits to `main` are
not part of the normal workflow.

### 2026-08-01 — Vertical-slice implementation

Use Evennia 6.0 on Python 3.13 for the first server-authoritative multiplayer slice. It
provides persistent accounts, characters, rooms, commands, Telnet, and a WebSocket web
client without committing the project to distributed infrastructure prematurely. The
slice uses SQLite for disposable local development and CI; PostgreSQL remains required
before persistent public operation. Gameplay rules remain isolated from transport and
display prose so they can be tested deterministically.

The existing single-player journey implementation is retained under
`prototypes/journey/` as an accessibility, PWA, and narrative interaction study. It is
not the multiplayer MUD architecture and does not define cultivation canon.

### 2026-07-31 — Product category

Historical decision, superseded on 2026-08-01: the project began as a complete, original,
multiplayer online cultivation MUD with a persistent world.

### 2026-07-31 — Copyright boundary

The project is not an adaptation of `凡人修仙传`. The reference may inform abstract genre and narrative research only. Protected expression and distinctive combinations must not enter the product.

### 2026-07-31 — Working names

- Chinese: `山河有契`
- English: `Covenant of the Realm`
- Repository: `covenant-of-the-realm`

These are working names pending formal clearance.

### 2026-07-31 — Direction correction

The player-facing design must be recognizably and comprehensively cultivation-based. The initial covenant framework is optional deep metaphysics, not a replacement for cultivation systems.

## Proposed, not yet confirmed

### 56 px working character scale

Use 56 px as the functional graybox height for ordinary player and companion sprites at the
1152×648 reference viewport. The 48/56/64 comparison keeps 56 px as the best current balance
between identity, world scale, road width, and collision margin. Revalidate this before promotion
to a final production rule after real Sprite Sheets, movement speed, collision boxes, camera zoom,
and controller play are present.

### Unity CLI engine evaluation

Unity CLI `1.0.0-beta.3` and Unity `6000.3.21f1` (6.3 LTS, ARM64) were installed
and evaluated locally. Editor discovery, the Universal 2D template catalog, and the
`pipeline`, `command`, `test`, and `mcp` command surfaces are available. A disposable
Universal 2D project could not yet be created because this machine has no active Unity
Editor license. Activating Unity Personal requires the account owner to accept Unity's
license terms explicitly.

Keep Godot as the confirmed implementation engine until a licensed Unity spike proves
project creation, EditMode and PlayMode tests, headless automation, and the Pipeline/MCP
workflow. Do not maintain both engines as parallel production clients.

### Content structure

Develop a vertical slice before expanding into the complete multi-realm world.

## Pending

- Launch market and languages
- Open-source scope and license
- Monetization
- PvP and permanent-loss policy
- Combat cadence
- Server/shard/season model
- Target concurrency and hosting budget
