# Architecture

## Vertical-slice shape

The first implementation is an Evennia 6 modular monolith on Python 3.13. Evennia owns accounts, characters, rooms, command routing, persistence, Telnet, and the browser WebSocket client. This keeps one authoritative process responsible for every game-state transition while the team validates the game loop.

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
