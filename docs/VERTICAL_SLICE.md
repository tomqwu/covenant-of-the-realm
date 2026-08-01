# Multiplayer Vertical Slice

## Product question

Can two people enter one original cultivation world, understand a short xianxia progression loop, make server-validated progress together, and see a persistent consequence within ten minutes?

The implemented slice answers that question with 照禾县: 照禾渡口, 月芽田, and 藏泉石室. All ordinary player-facing prose is Chinese-first.

## Complete loop

| Step | Player intent | Server input | Success and persistence | Safe failure |
| --- | --- | --- | --- | --- |
| Gather | `采药` at the terrace | character, authored resource, per-site history | +1 moonleaf and `resource_gathered` event | wrong site or repeat grants nothing |
| Refine | `修炼` at the spring | character and authored ambient qi | +1 qi, plus +1 and herb consumption when held | thin local qi grants nothing |
| Prepare | `布阵` at the spring | authenticated leader, stable room, and incomplete trial | one pending room formation | wrong site, duplicate, occupied, or completed-trial attempts grant nothing |
| Cooperate | another character uses `见证` | leader, witness, same room, pending formation | first completion grants 2 qi and 1 insight; event appended to both | self, moved, missing, corrupt, absent-leader, or fully completed cases grant nothing |
| Advance | automatic after a gain reaches 3 qi | validated character state | realm becomes 引息境一层, 3 qi consumed, +1 insight, +8 lifespan, audit event | malformed stored state raises instead of silently repairing rewards |

The cooperative rite is not cosmetic: a second authenticated character is necessary, both receive durable state, and the leader can cross the realm threshold because of it.
The onboarding loop is finite. Once a character reaches `引息境一层`, this shallow
spring no longer grants qi through `修炼`; once the character has completed the formation,
they cannot prepare it for another reward. A completed player may still witness for a new
player as a mentor, but receives no repeated resources. Legacy post-breakthrough overflow is
deterministically capped at the largest remainder this slice can legitimately produce.

## Commands

- `指引` (`path`) — show the route.
- `修为` (`状态`, `status`) — show cultivation state.
- `采药` (`forage`, `gather`) — gather the local authored herb once.
- `修炼` (`cultivate`, `meditate`) — refine authored ambient qi.
- `布阵` (`prepare`) — bind a formation to the hidden spring.
- `见证` (`witness`) — complete another present player's formation.

Movement uses `东`, `西`, `北`, and `南`. English movement and gameplay commands remain compatibility aliases, not the default player experience.

In the browser client, authored exits and context-relevant actions are selectable command
links. Clicking a choice submits the same server command as keyboard entry, so authorization,
location, resource, and cooperation rules stay server-authoritative. Clients without MXP link
support receive the same labels as ordinary text and can type them normally.
Completed actions are replaced by concise state notes such as `灵草已采` or `等待见证`.
Because the client keeps a transcript, an old direction link can outlive its original room;
the server safely rejects it and responds with the exits available at the character's current
location.

## Abuse and consistency boundaries

- The command caller supplies no reward amount or target realm.
- Resource availability and ambient qi belong to server-authored rooms.
- Per-character gathering prevents command repetition from minting herbs.
- Post-breakthrough cultivation is bounded and never displays an infinite target.
- Formation rewards are once per character; completed players can mentor without farming.
- A leader cannot witness their own formation.
- The leader must still be physically present and the formation must still match the room.
- A disconnected leader's pending formation is cleared instead of blocking the spring.
- Corrupt formation state is cleared without reward.
- Deterministic rules reject booleans, negative resources, unknown realms, incomplete records, and invalid ritual identities.

This slice deliberately excludes combat, PvP, trading, item transfer, death, sect membership, scheduled regrowth, public hosting, and monetization. Those features require explicit design and operations decisions before implementation.

## Acceptance evidence

The automated live-server test creates two accounts over Telnet, moves both through the authored world, gathers and consumes a herb, completes the shared formation, advances both characters, and reads the persisted results back through player commands. The same server and command set are playable through Evennia's WebSocket browser client.
