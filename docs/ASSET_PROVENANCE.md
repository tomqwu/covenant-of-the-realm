# Asset Provenance

The multiplayer MUD currently ships no third-party art, fonts, music, maps, or sound. Its browser presentation is Evennia's bundled client plus original project text and code.

The preserved single-player study under `prototypes/journey/` contains:

- `public/assets/journey-scroll.jpg`, derived from the project-owned ImageGen source documented in [its art direction](../prototypes/journey/docs/ART_DIRECTION.md);
- `public/assets/mountain-wind.ogg`, an original project-local procedural ambient loop documented in the same file;
- project-created application icons derived from that visual direction.

No public-use license has been selected for the repository or these assets. They remain under their creators' default copyright. Before any public release, the owner must choose a repository license, verify every dependency and generated-asset term, complete name/trademark clearance, and record any new asset's source, author, date, transformation, and allowed use here.

The Godot RPG graybox under `rpg/` currently uses only project-authored code, text, deterministic
pixel atlases, remaining vector-like runtime effects, runtime-synthesized ambience, and Godot's default
theme/font behavior. It commits no third-party font, music, map, sound file, or plugin. Godot 4.7.1 is an external MIT-licensed development/runtime
dependency resolved separately from the repository; its official Linux build is checksum-pinned
by `scripts/setup_rpg`.

## 2026-08-02–03 · Deterministic character and ferry pixel atlases

`rpg/assets/pixel/protagonist.png`, `yanqing.png`, `liangshu.png`, `huishen.png`,
`tao_xiaoman.png`, and `cenwei.png` are original 128×224 RGBA atlases generated
by the project-authored `rpg/tools/generate_pixel_assets.gd`. No model, input image, stock asset,
external palette, commercial sprite, font, or third-party art library is used. The generator draws
two idle and two walking frames in four directions from rectangles and the confirmed project
palette. `asset_contract.json` records the 32×56 frame, foot anchor, collision, animation, nearest-
filter, and pixel-snap contract; `scripts/check_rpg_assets.py` verifies metadata and fully decodes
each image as CRC-valid, non-interlaced RGBA8 PNG data.
梁叔's broad reed hat, measuring staff, rain-dark cape, and short grey beard are likewise drawn
only by that deterministic project-local generator; no external character or image input was used.
蕙婶's head wrap, low bun, leaf pin, woven apron, and carrying basket use the same deterministic
rectangles-and-palette pipeline without an external character, costume, or image reference.
陶小满's sunny short jacket, river-blue cropped scarf, wedge satchel, and quick working silhouette
were authored directly in the same project-local rectangle generator. No external character,
costume, game screenshot, stock sprite, model image, or third-party drawing code informed the
atlas. Her matching bright painted-paper dialogue portrait is drawn at runtime by
`dialogue_portrait.gd` from the recorded project palette and contains no embedded image asset.
岑苇's river-jade short jacket, fresh-celadon accent, bamboo route tube, two route slips, and tied
route band were added on 2026-08-03 through the same deterministic rectangle-and-palette generator.
No model, input image, game screenshot, stock sprite, external character or costume reference, or
third-party drawing code informed this atlas. Its fixed four-point route, feet position, courtesy
yielding, and interaction are runtime state and presentation contracts rather than pixels; the
atlas grants no collision, quest, battle, reward, or save authority.

The same generator creates `ferry_tiles.png`, an original 256×64 RGBA atlas. Row zero preserves
eight opaque 32 px ground tiles for grass, water, bank, road, moonleaf field, stone, deep grass,
and water glints. Row one contains eight transparent project-authored overlays for reeds, bank
grass, path pebbles, wildflowers, stone cracks, moss, fallen leaves, and water foam.
`ferry_tile_layer.gd` composes the ground into deterministic 48×27 layers, while
`map_detail_layer.gd` places a bounded sparse overlay for the ferry and mountain path without any
physics or navigation layer. No model, external map, texture, pattern, photograph, or third-party
tile-design input is used.

The generator also creates `enemy_profiles.png`, an original 384×256 RGBA atlas with six 64×64
frames for each of the four project-authored enemy profiles: 岩甲兽幼体、泉苔寄壳、
失衡石傀 and 岩甲兽守巢者. Each stable row contains two idle, two attack, and two reaction
frames. The silhouettes, short motion marks, and impact sparks are assembled only from project-authored pixel
rectangles and the recorded palette; no model, reference image, commercial sprite, external game
asset, or third-party drawing code is used. `enemy_sprite.gd` maps the same stable IDs used by the
deterministic battle domain to fixed atlas rows and consumes semantic event IDs for presentation.
The asset gate verifies dimensions, row order, animation columns, loop and frame-rate metadata,
event groups, foot anchor, local file name, and exact profile list before package export.

These are reproducible first-production placeholders intended to validate the `AnimatedSprite2D`
pipeline. They may be regenerated with the pinned Godot runtime and should be replaced or refined
through the same provenance and in-engine readability review before public release.

## 2026-08-03 · Bright painted-paper portrait v2

`rpg/src/ui/dialogue_portrait.gd` draws all six dialogue presentation IDs directly through Godot
CanvasItem primitives: the traveller, 砚青, 梁叔, 蕙婶, 陶小满, and the unpeopled journey journal.
Revision 2 adds project-authored profile data, fixed center-aligned facial marks, silhouette and
carried-object cues, deterministic paper fibers, and a restrained Morning Peach wash from the
recorded v0.2 palette. It uses no raster input, concept-board crop, model output, stock texture,
external character reference, commercial sprite, font, plugin, random source, or third-party
drawing code.

`docs/concepts/gameplay-ui-v1/01-portrait-gallery.png` is a direct Godot capture of those same
runtime controls at the production dialogue size. The capture-only 3×2 board adds no packaged scene,
runtime asset, or alternate art source. It is regenerated with the other functional screenshots;
two complete 42-image passes have aggregate SHA-256
`3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.

## 2026-08-03 · Code-drawn Zhaohe battle-intent telegraph

`rpg/src/ui/intent_telegraph.gd` draws the fixed-screen “照禾临势签” directly through Godot
CanvasItem primitives. Its warm-paper panel, four profile edge patterns, Chinese copy, and nine
distinct silhouettes map the exact nine stable intent IDs exposed by the presentation schema.
Current and next display facts come from Journey-gated presentation data; the action-result context
supplies only the pre-resolution enemy and announced intent IDs. No raster or vector input, model output, concept-image crop, stock UI kit,
external font file, plugin, game screenshot, or third-party drawing code is used.

The control receives already gated display names, damage values, next-intent data, and counter text;
it does not read the enemy catalog, choose or advance an intent, calculate damage, translate an
action ID, or write journey state. Unknown IDs use a neutral shape, and unstudied context discards
any supplied next-intent or counter display fields. The component owns no combat, profile,
intelligence, timing, input, reward, or save authority. High-contrast mode uses the existing paper
and ink anchors, reduced motion preserves the same static text and geometry, and the large-text
capture remains presentation-only.

The five current battle screenshots—`02-cangquan-battle.png`,
`02-cangquan-battle-react.png`, `02-cangquan-moss-battle.png`,
`02-cangquan-puppet-battle.png`, and `02-cangquan-boss.png`—show this same runtime control.
`02-cangquan-puppet-battle.png` is the committed large-text plus high-contrast evidence; it is not a
separate asset or alternate rendering source.

## 2026-08-03 · Deterministic Zhaohe landmark atlas

`rpg/assets/pixel/zhaohe_landmarks.png` is an original 2112×128 RGBA atlas generated by the same
project-authored `rpg/tools/generate_pixel_assets.gd`. Its eleven fixed 192×128 regions contain a
celadon tree, three distinct ferry houses, a timber dock, mountain rock, spring cave, spring gate,
ferry boat-repair rack, drying rack, and mountain rain shelter. Every silhouette is assembled from project-local pixel rectangles and the recorded bright
palette. No model, concept-image crop, photograph, stock texture, commercial tileset, external
game asset, artist imitation, or third-party drawing code was used.

The atlas drives all previously geometric buildings, trees, docks, rocks, cave mouths, gates, and
the three life landmarks in the ferry, mountain-path, and battle views. Houses and trees reuse the existing Y-sorted
foreground nodes; other landmarks are fixed map-canvas regions. These sprites own no collision,
navigation, story, reward, or save authority. The life landmarks provide repeatable original
spatial prose through the same keyboard, mouse, and controller action path while leaving the
Journey snapshot unchanged and add no fields to the current save v17. The adjacent mountain-return bridge is ground data generated
from the existing original tile atlas, not an imported asset.

The landmark fields introduced in `asset_contract.json` schema v4 remain enforced by the current
schema v6: file name, atlas/frame dimensions, foot anchor, profile order, occluding subset, nearest
filtering, integer snapping, and non-authoritative role. Schema v6 also records the sixth actor
atlas, `cenwei.png`, without granting the atlas gameplay authority.
MapCanvas visual contract v2 additionally binds each life-landmark profile to one phase,
interaction anchor, and action ID without creating a second gameplay authority.
`scripts/check_rpg_asset_reproducibility` invokes the pinned Godot generator into two isolated
temporary directories, compares all nine generated atlases byte for byte, and then compares each
with its tracked Git-index blob and working-tree PNG. In CI the index is the committed checkout.
Scene tests additionally load the imported landmark image as RGBA8,
require every region to contain visible pixels and a transparent boundary, and verify that unknown
profile IDs are rejected without partially configuring a node.

## 2026-08-01 · Godot procedural ferry ambience

`rpg/src/ui/audio_manager.gd` synthesizes a quiet three-frequency waterbank chord directly into
Godot's `AudioStreamGenerator`. The frequencies, slow amplitude modulation, stereo balance, and
implementation were authored for this project; no recording, sample, model-generated audio,
external composition, or third-party sound library is embedded. Playback is opt-in and defaults
to off. This functional ambience remains a placeholder for the final authored sound direction.

## 2026-08-01 · RPG style-exploration concept boards

The three images under `docs/concepts/style-exploration/` were generated with Codex's built-in
OpenAI ImageGen workflow from project-authored prompts. No input images, external game assets,
novel illustrations, artist works, or third-party style references were supplied to the model.
The prompt summaries and originality constraints are recorded beside the images in
`docs/concepts/style-exploration/PROMPTS.md`.

These boards are internal visual-development candidates, not production sprites, textures,
marketing art, or evidence of clearance. Before public or commercial use, review the applicable
OpenAI terms, complete similarity and trademark checks, and replace or explicitly approve each
asset through the project's final art pipeline.

## 2026-08-01 · RPG art-direction v1 concept baseline

The five images under `docs/concepts/art-direction-v1/` were generated with Codex's built-in
OpenAI ImageGen workflow. The only image inputs were the project-owned/generated A, B, and C
style-exploration boards recorded above. No external novel illustration, game screenshot, artist
work, stock asset, or third-party visual reference was used.

The images define character identity, a gameplay-map target, a combat-readability target, and the
limited use of a layered breakthrough scene. Their prompt summaries and originality constraints
are recorded in `docs/concepts/art-direction-v1/PROMPTS.md`. They are internal concept references,
not cuttable production art, marketing art, or evidence of clearance. Final sprites, tiles,
portraits, textures, and promotional assets must be separately authored, reviewed for similarity,
and entered in this provenance record before release.

## 2026-08-01 · RPG art-direction v2 bright concept baseline

The five images under `docs/concepts/art-direction-v2-bright/` were created with Codex's built-in
OpenAI ImageGen workflow as non-destructive lighting, palette, and mood edits. Each image used
only its matching project-owned/generated v1 concept image as an edit target. No external novel
illustration, game screenshot, artist work, stock asset, or third-party visual reference was used.

The prompt record is stored in `docs/concepts/art-direction-v2-bright/PROMPTS.md`. These outputs
are internal concept references rather than cuttable production or marketing art. Final sprites,
tiles, portraits, textures, and promotional assets require separate authorship, similarity review,
license review, in-engine readability validation, and a new provenance entry.

## 2026-08-01 · Godot functional-art UI screenshots

The PNG set under `docs/concepts/gameplay-ui-v1/` consists of direct screenshots of the project's
Godot 4.7.1 functional-art graybox. The scene is drawn at runtime from project-authored GDScript,
validated original story content, Godot's default font behavior, and the project's v0.2 palette.
No generated concept image, external image, font, sound, map, UI kit, or plugin is embedded in
these screenshots.

The screenshots can be rebuilt with `make capture-rpg-ui`. They document layout, scale, input,
and readability decisions; the runtime-drawn shapes are placeholders rather than final sprites,
tiles, portraits, textures, or promotional art. The current set includes
`02-path-keeper-route.png`, a direct runtime capture of 岑苇 on the mountain route. Two consecutive
42-image passes have aggregate SHA-256
`3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.
