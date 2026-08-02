# Asset Provenance

The multiplayer MUD currently ships no third-party art, fonts, music, maps, or sound. Its browser presentation is Evennia's bundled client plus original project text and code.

The preserved single-player study under `prototypes/journey/` contains:

- `public/assets/journey-scroll.jpg`, derived from the project-owned ImageGen source documented in [its art direction](../prototypes/journey/docs/ART_DIRECTION.md);
- `public/assets/mountain-wind.ogg`, an original project-local procedural ambient loop documented in the same file;
- project-created application icons derived from that visual direction.

No public-use license has been selected for the repository or these assets. They remain under their creators' default copyright. Before any public release, the owner must choose a repository license, verify every dependency and generated-asset term, complete name/trademark clearance, and record any new asset's source, author, date, transformation, and allowed use here.

The Godot RPG graybox under `rpg/` currently uses only project-authored code, text, vector-like
runtime drawing, runtime-synthesized ambience, and Godot's default theme/font behavior. It
commits no third-party art, font, music, map, sound file, or plugin. Godot 4.7.1 is an external MIT-licensed development/runtime
dependency resolved separately from the repository; its official Linux build is checksum-pinned
by `scripts/setup_rpg`.

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

The five PNG files under `docs/concepts/gameplay-ui-v1/` are direct screenshots of the project's
Godot 4.7.1 functional-art graybox. The scene is drawn at runtime from project-authored GDScript,
validated original story content, Godot's default font behavior, and the project's v0.2 palette.
No generated concept image, external image, font, sound, map, UI kit, or plugin is embedded in
these screenshots.

The screenshots can be rebuilt with `make capture-rpg-ui`. They document layout, scale, input,
and readability decisions; the runtime-drawn shapes are placeholders rather than final sprites,
tiles, portraits, textures, or promotional art.
