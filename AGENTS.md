# Covenant of the Realm — Project Guidance

## Required context

Before proposing designs or changing implementation, read:

- `docs/PROJECT_CONTEXT.md`
- `docs/DECISIONS.md`

Keep durable product decisions in `docs/DECISIONS.md` so future Codex tasks do not depend on chat history.

## Product objective

Build an original, Chinese-first, story-driven 2D cultivation RPG with:

- a complete and recognizably xianxia cultivation experience;
- a coherent deep history, cosmology, geography, ecology, economy, and social order;
- long-term progression from mortal life through cultivation and ascension;
- chapter-based companions, exploration, preparation, deterministic turn-based combat,
  cultivation professions, inheritance, failure, and ascension;
- fixed, testable main-story progression with bounded side branches;
- a clean intellectual-property boundary from all reference novels.

This must feel like a complete cultivation world, not merely an abstract Eastern fantasy system wearing cultivation terminology.

The Evennia MUD and Journey PWA remain playable research prototypes. Preserve them, but
do not treat their transport or client architecture as the primary RPG architecture.

## Naming

- Chinese title: `山河有契`
- English title: `Covenant of the Realm`
- Repository: `covenant-of-the-realm`

Treat these as working decisions until trademark and market clearance is complete.

## Copyright and originality rules

- Do not reproduce or closely paraphrase text from any reference novel.
- Do not reuse distinctive characters, names, locations, factions, treasures, cultivation manuals, realm sequences, creatures, scenes, or plot combinations.
- Extract only high-level genre and narrative principles such as resource scarcity, information asymmetry, geographic escalation, institutional incentives, and risk/reward pacing.
- Do not copy the supplied novel file into this repository, commit it, redistribute it, use it as a production retrieval corpus, or train a model on it.
- Record the source and license for every external code, font, image, sound, text, and public-domain reference used by the project.
- Before commercial release, require professional copyright and trademark clearance in each target market.

## Design direction

The player-facing game must include a full cultivation framework: spiritual energy and environments, aptitude and body, lifespan, mind and karma, realms, tribulations, techniques, alchemy, artifacts, formations, talismans, spirit beasts, medicine and poison, sects, clans, dynasties, demons, ghosts, other peoples, secret realms, inheritance, death, reincarnation, and ascension.

The earlier “covenant and cost” idea may survive as deep metaphysics, but it must support rather than replace recognizable cultivation play.

## Technical principles

- Use Godot 4.7.1 for the first graphical RPG slice.
- Prefer a modular, offline-first application for the first playable version.
- Keep gameplay rules deterministic and independent of UI scenes.
- Separate rules and structured content from display prose.
- Use versioned local saves and semantic event summaries; do not serialize scene trees.
- LLM-generated text may vary presentation, but must never decide combat, rewards, ownership, economic state, law, or permanent history.
- Keep keyboard, mouse, and future controller actions on one semantic command path.
- Add infrastructure only after measurement demonstrates the need.

## Working practice

- Lead with a playable vertical slice rather than attempting the whole universe at once.
- Every major mechanic must state its player purpose, inputs, outputs, failure modes, abuse cases, persistence behavior, and multiplayer consequences.
- Explicitly test new-player protection, offline safety, time-zone fairness, alternate-account abuse, real-money trading, inflation, monopoly, harassment, accessibility, moderation, backup, and recovery.
- Do not silently turn open design questions into permanent canon. Record assumptions and alternatives in `docs/DECISIONS.md`.
