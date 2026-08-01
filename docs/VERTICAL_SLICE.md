# Multiplayer Vertical Slice

## Product question

Can two people enter one original cultivation world, understand a short xianxia progression loop, make server-validated progress together, and see a persistent consequence within ten minutes?

The implemented slice answers that question with 照禾县 / Zhahe County: a river crossing, a cultivated moonleaf terrace, and a hidden spiritual spring.

## Complete loop

| Step | Player intent | Server input | Success and persistence | Safe failure |
| --- | --- | --- | --- | --- |
| Gather | `forage` at the terrace | character, authored resource, per-site history | +1 moonleaf and `resource_gathered` event | wrong site or repeat grants nothing |
| Refine | `cultivate` at the spring | character and authored ambient qi | +1 qi, plus +1 and herb consumption when held | thin local qi grants nothing |
| Prepare | `prepare` at the spring | authenticated leader and stable room | pending room formation | wrong site grants nothing |
| Cooperate | another character uses `witness` | leader, witness, same room, pending formation | both gain 2 qi and 1 insight; event appended to both | self, moved, missing, corrupt, or absent-leader cases grant nothing |
| Advance | automatic after a gain reaches 3 qi | validated character state | realm becomes 引息境一层, 3 qi consumed, +1 insight, +8 lifespan, audit event | malformed stored state raises instead of silently repairing rewards |

The cooperative rite is not cosmetic: a second authenticated character is necessary, both receive durable state, and the leader can cross the realm threshold because of it.

## Commands

- `path` / `指引` — show the route.
- `status` / `状态` / `修为` — show cultivation state.
- `forage` / `gather` / `采药` — gather the local authored herb once.
- `cultivate` / `meditate` / `修炼` — refine authored ambient qi.
- `prepare` / `布阵` — bind a formation to the hidden spring.
- `witness` / `见证` — complete another present player's formation.

Movement uses `east`, `west`, `north`, and `south`, with Chinese aliases.

## Abuse and consistency boundaries

- The command caller supplies no reward amount or target realm.
- Resource availability and ambient qi belong to server-authored rooms.
- Per-character gathering prevents command repetition from minting herbs.
- A leader cannot witness their own formation.
- The leader must still be physically present and the formation must still match the room.
- Corrupt formation state is cleared without reward.
- Deterministic rules reject booleans, negative resources, unknown realms, incomplete records, and invalid ritual identities.

This slice deliberately excludes combat, PvP, trading, item transfer, death, sect membership, scheduled regrowth, public hosting, and monetization. Those features require explicit design and operations decisions before implementation.

## Acceptance evidence

The automated live-server test creates two accounts over Telnet, moves both through the authored world, gathers and consumes a herb, completes the shared formation, advances both characters, and reads the persisted results back through player commands. The same server and command set are playable through Evennia's WebSocket browser client.
