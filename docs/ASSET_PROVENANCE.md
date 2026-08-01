# Asset Provenance

The multiplayer MUD currently ships no third-party art, fonts, music, maps, or sound. Its browser presentation is Evennia's bundled client plus original project text and code.

The preserved single-player study under `prototypes/journey/` contains:

- `public/assets/journey-scroll.jpg`, derived from the project-owned ImageGen source documented in [its art direction](../prototypes/journey/docs/ART_DIRECTION.md);
- `public/assets/mountain-wind.ogg`, an original project-local procedural ambient loop documented in the same file;
- project-created application icons derived from that visual direction.

No public-use license has been selected for the repository or these assets. They remain under their creators' default copyright. Before any public release, the owner must choose a repository license, verify every dependency and generated-asset term, complete name/trademark clearance, and record any new asset's source, author, date, transformation, and allowed use here.

The Godot RPG graybox under `rpg/` currently uses only project-authored code, text, vector-like
runtime drawing, and Godot's default theme/font behavior. It commits no third-party art, font,
music, map, sound, or plugin. Godot 4.7.1 is an external MIT-licensed development/runtime
dependency resolved separately from the repository; its official Linux build is checksum-pinned
by `scripts/setup_rpg`.
