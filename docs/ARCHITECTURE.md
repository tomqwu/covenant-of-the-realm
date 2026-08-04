# Architecture

## Primary Godot RPG

The primary deliverable under `rpg/` keeps deterministic rules in RefCounted domain objects and
treats the scene tree as an adapter. `JourneyState` owns phase, combat, resources, intent
resolution, and the settled action snapshot. `Main`, `MapCanvas`, and screen-space controls may
interpret returned facts, but they cannot delay, replay, or replace the domain result.

### Battle action-result presentation boundary

A successful battle action returns semantic `events`, the settled authoritative `snapshot`, and
one ID-only transient envelope:

```text
presentation_context.battle.enemy_id_before
presentation_context.battle.announced_intent_id
```

The IDs are captured before the resolver mutates HP, round, phase, or enemy profile. Failed and
non-battle actions return an empty presentation context. The envelope is deep-copied and never enters
`JourneyState.snapshot()`, restore validation, save JSON, replay state, or content. The settled
snapshot always identifies the current enemy and round.

Events determine what actually resolved. `enemy_hit` or `enemy_glanced` means the announced
intent produced an enemy response. `regular_enemy_won` or `battle_won` identifies the pre-action
profile as outgoing, while `boss_arrived` pairs that outgoing ID with the replacement enemy in the
settled snapshot. A lethal player action can therefore retain an interrupted announced intent
without falsely presenting it as an executed attack.

### Fixed-screen intent presentation

`IntentTelegraph` is a fixed 532×90 screen-space control outside `WorldRoot`. It implements nine
distinct code-native silhouettes for the nine authored intent IDs across four enemy profiles. The
current intent and damage remain readable to every player. Only investigated enemy intelligence
unlocks the next intent and counter text; unknown intel receives an explicit explanation instead of
leaked counter data. Unknown or mismatched profile/intent pairs use a neutral silhouette.

The tag provides complete text equivalents plus large-text, high-contrast, fast, and reduced-motion
behavior. Its short cue clock is non-blocking and has no damage, intent, profile, intelligence,
round, counter, input, gameplay-timing, or save authority. Save v17 is unchanged: loading derives a
fresh tag from the restored enemy ID and round and never resumes old action-result context.

The current local contract is covered by 3,105 Godot unit/scene assertions, 357 chapter E2E checks,
189 physical-input checks, a 116-node static scene and 126-node peak, a 25-required / nine-excluded
package boundary, and the 42-capture aggregate
`3bb142fb4e31bd4d13c1a5fe96c45183ccf91b5562e168036ff0d69de6054716`.
Four local macOS/arm64 exports, including two fresh-cache copies, match at 812,608 bytes and SHA-256
`aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`; manifest verification,
the 25/9 resource probe, and packaged boot pass. No hosted result is asserted for this loop.

## Preserved multiplayer prototype

The preserved multiplayer implementation is an Evennia 6 modular monolith on Python 3.13. Evennia
owns accounts, characters, rooms, command routing, persistence, Telnet, and the browser WebSocket
client. This keeps one authoritative process responsible for every multiplayer prototype transition.

```text
browser WebSocket / Telnet
            |
      Evennia commands
            |
  deterministic domain rules
            |
 character attributes + append-only events
            |
    SQLite local/CI database
```

SQLite is disposable infrastructure for local development and CI. PostgreSQL is required before a persistent public server opens. Moving databases must not change the rules API or allow clients to submit outcomes.

## Authority boundary

`mud/world/rules.py` is the domain boundary. It accepts explicit stored state plus authored inputs, validates them, and returns immutable new state and facts. It imports no Evennia, database, network, clock, or random source. Consequently, identical inputs always produce identical outputs.

`mud/commands/cultivation.py` is an adapter. It resolves the authenticated character and current room, calls the domain rule, persists the result, appends audit facts, and renders Chinese player-facing prose. Browser and Telnet clients send intentions such as `修炼` (with `cultivate` retained as a compatibility alias); they never send resource deltas, realm changes, or reward values.

## Persistence

Each character stores:

- realm, qi, herb count, insight, karma, and lifespan;
- a set of resource sites already gathered by that character;
- append-only gameplay event dictionaries for significant transitions.

The room owns the pending cooperative formation because it is shared multiplayer state. Invalid, moved, or abandoned formations fail closed and are cleared without granting rewards.

For a public release, permanent transitions must move to transactional PostgreSQL tables with durable actor, cause, and idempotency metadata. The current attribute-backed event list proves the audit shape but is not the final operations model.

## World bootstrap

`mud/world/bootstrap.py` creates or repairs the authored three-room slice by stable `zone_id`. Initial setup and repeated calls are idempotent: they reuse rooms and exits rather than duplicating the world.

## Growth rules

New systems should add pure rule modules first, then thin Evennia adapters. Split services only after profiling identifies an actual load, ownership, or deployment boundary. PvP, trading, scheduled ecology, moderation tools, and permanent-loss mechanics remain out of scope until their policies are explicitly decided.
