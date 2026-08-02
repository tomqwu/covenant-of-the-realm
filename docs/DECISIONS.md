# Decision Log

Use this file for durable decisions. Do not depend on chat transcripts as the only record.

## Confirmed

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
Its five original lines resolve four bounded presentation tokens from the deterministic snapshot:
whole-plant/cutting harvest, discovery count, setback count, and careful/trusting briefing
response. The existing save-v10 dialogue object can already store dialogue ID and line index, so
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

The prologue dialogue uses four stable presentation IDs: `protagonist`, `yanqing`, `liangshu`, and
`journal`. Project-authored Godot drawing code renders the protagonist in clear indigo, 砚青 in
warm ochre, 梁叔 in levee-shadow teal, and history mode as an unpeopled travel journal over the same bright paper landscape.
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
normalized movement/collision steps, 2,000 complete regular-enemy-to-warden rule loops, and 20
main-scene create/destroy cycles. The first two have independent 2.5-second ceilings; scene
lifecycle has a 5-second ceiling, a 120-node cap, and must restore the root-child baseline after
every cycle. Budgets live in excluded test data and are intentionally far above the current local
measurements so shared CI detects order-of-magnitude regressions without pretending to certify a
release device. Animation speed and combat outcomes remain outside these wall-clock thresholds.

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

### 2026-08-01 — Reproducible PCK as the overnight delivery boundary

The overnight slice exports a cross-platform Godot resource pack and validates it by two
byte-identical builds plus a headless main-scene boot. Every build now also emits a deterministic
JSON manifest containing the exact size, SHA-256, engine and preset, nearest Git revision,
clean/dirty source state, runtime-resource probes, and development-resource exclusions. The package
gate compares two manifests, recalculates their artifact fields, opens the PCK as the active
`res://` namespace, requires four production resources, and rejects nine representative files
under the excluded `tests/` and `tools/` trees before booting the main scene. Generated `.gd.uid` files are committed as
intentional Godot resource identity metadata; the `.pck` itself stays under ignored `build/`.
Native macOS, Windows, or Linux executables wait for a confirmed distribution target, official
export templates, product icon, signing identity, and platform smoke tests. Local players can
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
