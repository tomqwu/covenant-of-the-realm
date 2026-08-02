# Decision Log

Use this file for durable decisions. Do not depend on chat transcripts as the only record.

## Confirmed

### 2026-08-01 — Playable-slice exploration baseline

Use normalized world coordinates for the first playable map so rendering resolution does not
change traversal, collision, or interaction outcomes. Keep exploration state and collision in a
deterministic domain object rather than the scene tree. The 1152×648 development viewport and
56 px actor height are accepted for this slice; the collision footprint is intentionally smaller
than the visible silhouette. Keyboard, mouse, and controller input converge on semantic move and
interact actions, and world interactions require proximity rather than remote menu selection.

This is an implementation baseline for the overnight playable slice, not a release-platform or
final-sprite commitment.

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
