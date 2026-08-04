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

### Outgoing regular-enemy presentation

`MapCanvas` owns one hidden `OutgoingEnemySprite` beside the canonical `BattleEnemySprite`. It arms
only when `regular_enemy_won` and `boss_arrived` arrive together, the transient pre-action ID is one
of the three regular profiles, and the settled enemy is `rock_armor_warden`. The settled snapshot is
synchronized first, so Journey, status, the canonical sprite, and `IntentTelegraph` all identify the
warden while the old profile is visible only through the outgoing role. Unknown, malformed, lone,
boss-victory, or mismatched facts cannot arm it.

The shared schema-v7 512×256 atlas has two explicit defeat frames after idle, attack, and reaction
for every profile. The outgoing role accepts only regular profiles, starts from an integer anchor,
and uses a local 0.70/0.18-second clock. Full motion shifts and fades the debris; reduced motion
freezes the first defeat frame. Expiry, the next action, title, load, retreat, rescue, final victory,
replay, or any non-battle phase hides the node and clears its ID. It never enters camera focus,
Journey, save v17, content, damage, round timing, or input. Boss arrival no longer starts a same-phase
full-screen transition, so the cue cannot be hidden and the next focused action remains available.

The current contract is covered by 3,202 Godot unit/scene assertions, 360 chapter E2E checks,
192 physical-input checks, a 117-node static scene and 127-node peak, a 25-required / nine-excluded
package boundary, and the 43-capture aggregate
`80dfb36a14b81a54b0562932a841d2f295f829d3992eec900f079b31a329bc0b`.
Four local macOS/arm64 exports and four GitHub-hosted Linux/x86_64 exports from run `30873652565`,
each including two fresh-cache copies, match at 824,432 bytes and SHA-256
`6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`; manifest verification,
the 25/9 resource probe, and packaged boot pass locally and hosted.

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
