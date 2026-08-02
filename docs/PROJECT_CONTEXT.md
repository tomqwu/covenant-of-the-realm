# Project Context

Last updated: 2026-08-01

## Current direction

The primary future product is now an original, Chinese-first, story-driven 2D cultivation
RPG. Its high-level interaction grammar is the classic single-player party RPG: chapter-based
story, top-down exploration, towns and dungeons, temporary companions, preparation, and
deterministic turn-based combat. This is a genre and structure reference, not permission to
copy another game's presentation or content.

Godot 4.7.1 is the chosen engine for the first 90-minute vertical slice. The Evennia MUD and
Journey PWA remain playable research prototypes and regression suites; they no longer define
the primary client architecture.

The confirmed visual direction uses bright, hand-authored pixel art for ordinary play, warm
painted-paper portraiture for narrative expression, and rare layered-paper scenes for
breakthroughs and major secret-realm reveals. The active lighting and palette contract is
`docs/design/ART_DIRECTION_v0.2.md`.

The content remains original. The user has not established a production license for any
external novel IP, so no protected characters, names, prose, locations, treasures, or plot
combinations may enter this public repository. If formal adaptation rights are obtained later,
licensed content needs a separate repository and legal-review pipeline.

## Origin of the project

The user supplied a local text of the Chinese cultivation novel `凡人修仙传` and asked whether Codex could study it deeply, then help create a non-infringing multiplayer MUD with a complete history, worldview, game framework, name, and analysis of overlooked issues.

The reference file is located outside this project at:

`/Users/tomwu/Downloads/凡人修仙传 (忘语) (z-library.sk, 1lib.sk, z-lib.sk).txt`

It must not be copied into this repository or redistributed.

## What was established about the reference file

A full structural scan found:

- UTF-8 text, approximately 21 MB and 297,000 lines;
- 11 main volumes, ending at chapter number 2446;
- 2451 chapter-heading occurrences but 2443 unique chapter numbers;
- chapters 1747 through 1754 are duplicated at a volume boundary;
- the bodies around chapter numbers 1761, 1834, and 1876 are present but their headings are missing in this copy;
- the file does not contain the full long-form sequel commonly called `仙界篇`; it ends with only short external-story excerpts.

The work completed so far is a full structural pass, volume/chapter indexing, title statistics, targeted close reading, and high-level mechanism analysis. It is not a claim that a model held every sentence of a multi-million-character novel in one context. Any exhaustive semantic study should proceed in batches of 25–50 chapters and output only abstract, non-proprietary lessons.

## Lessons extracted at an abstract level

The useful long-form principles are:

1. Scarce resources should generate exploration, trade, deception, cooperation, crafting, and conflict.
2. Geography should carry difficulty and social scale instead of merely reskinning enemies.
3. Information asymmetry remains interesting longer than raw combat-stat differences.
4. Organizations should exchange protection, knowledge, identity, and market access for obligations.
5. Advancement should change the kind of risk and responsibility, not only increase numbers.
6. Long life must visibly affect families, settlements, institutions, inheritance, and historical memory.
7. Arc endings should change the player's central problem instead of only ending a boss encounter.

These are genre-level principles. They do not authorize copying any protected expression or distinctive combination.

## Cultivation scope retained from the earlier direction

The user clarified that the game must be a **complete cultivation game**, not simply an abstract “covenant-based Eastern fantasy.” It should visibly and mechanically contain the major pillars players expect from cultivation fiction:

- mortal society, cultivation society, higher realms, underworld concepts, and ascension;
- spiritual energy, spiritual geography, aptitude, meridians/body, lifespan, mind, karma, and tribulations;
- a complete original realm progression;
- sword, spell, body, soul, beast, medicine/poison, artifact, and other viable paths;
- alchemy, artifact forging, formations, talismans, spirit plants, puppetry, and cultivation professions;
- sects, families, dynasties, merchant groups, unaffiliated cultivators, other peoples, demons, and ghosts;
- caves, secret realms, ruins, beasts, inheritance, markets, auctions, missions, wars, death, reincarnation, and ascension;
- player sects, masters and disciples, partners, enemies, territory, logistics, politics, and cross-realm multiplayer play.

The earlier concept that all power creates a cost or obligation can remain hidden underneath the world as a metaphysical consistency rule. It must not displace traditional cultivation-facing systems.

## Working name

- Chinese: **山河有契**
- English: **Covenant of the Realm**
- Repository slug: **covenant-of-the-realm**
- Earlier proposed expansion name: **归潮 / Returning Tide**

The names still require trademark, domain, application-store, and market collision checks before public announcement.

## Existing design artifact

An initial design report exists at:

`docs/design/MUD_DESIGN_BIBLE_v0.1.md`

It contains useful work on multiplayer persistence, factions, economy, technical architecture, copyright clean-room procedures, operational risks, and MVP planning. Its metaphysics are a draft, not final canon, because the user later requested a more complete and recognizably traditional cultivation system.

## Previous multiplayer technical direction

The implemented multiplayer prototype used:

- Evennia and Python for the first MUD server;
- PostgreSQL for production persistence;
- WebSocket and a mobile-friendly PWA client;
- a modular monolith for the first playable release;
- deterministic server-authoritative rules;
- append-only audit events for permanent world changes and valuable economic actions;
- no LLM authority over combat, rewards, ownership, law, or permanent world state.

Nakama may be evaluated later if the product grows into match-based content, extensive social SDK features, or multiple graphical clients. It should not be introduced alongside Evennia in the first prototype without a demonstrated need.

## Important risks already identified

- copyright, trademark, asset licensing, and misleading marketing;
- Chinese mainland game approval, real-name systems, anti-addiction rules, and privacy obligations if that becomes a target market;
- persistent-world resets versus player history;
- veteran domination and new-player irrelevance;
- offline attacks and time-zone bias;
- alternate accounts, collusion, real-money trading, inflation, and resource monopoly;
- harassment, consent-sensitive roleplay, moderation, appeals, and administrator abuse;
- player-generated content ownership and infringement complaints;
- accessibility, low-bandwidth play, simplified/traditional Chinese, and screen-reader support;
- backup restoration, economic rollback, auditability, and disaster recovery.

## Next major deliverable

Expand the executable RPG graybox into a complete 90-minute original chapter:

1. top-down movement, collision, and proximity interaction in 照禾渡口 (implemented);
2. dialogue and quest-state presentation;
3. 月芽田 resource choice;
4. 藏泉山道 exploration, warning, and retreat path;
5. three regular enemy profiles and one boss;
6. an active chapter companion and one deployable tactical slot;
7. versioned save/load, title/continue, and safe backup recovery (implemented; chapter replay remains);
8. mouse, keyboard, and controller parity;
9. original visual/audio direction with recorded provenance;
10. new-game-to-chapter-end automated acceptance path.

## Open decisions

Do not assume answers without recording them:

- primary launch market and languages;
- monetization or fully open-source/non-commercial operation;
- PC-only first release versus mobile and console ports;
- degree of main-story branching;
- controller launch requirement;
- voice acting scope;
- whether the codebase, game content, or both will be open source.
