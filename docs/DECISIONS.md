# Decision Log

Use this file for durable decisions. Do not depend on chat transcripts as the only record.

## Confirmed

### 2026-08-01 — Chinese-first player experience

All ordinary player-facing login, room, movement, chat, help, cultivation, and status
text uses Simplified Chinese. Chinese command names are the documented/default path;
English command names remain compatibility aliases. A runtime language switch is not
part of this vertical slice.

### 2026-08-01 — Selectable actions remain commands

Browser choices use Evennia's server-authored MXP command links rather than a parallel client
state machine. Links degrade to readable text in Telnet and assistive clients, and clicking a
choice follows the same authoritative command path as keyboard input.

### 2026-08-01 — Repository workflow

Implementation work proceeds on `codex/` feature branches. The complete relevant
local test suite must pass before commit and push; GitHub Actions must pass on the
pull request before merge to `main`. Direct implementation commits to `main` are
not part of the normal workflow.

### 2026-08-01 — Vertical-slice implementation

Use Evennia 6.0 on Python 3.13 for the first server-authoritative multiplayer slice. It
provides persistent accounts, characters, rooms, commands, Telnet, and a WebSocket web
client without committing the project to distributed infrastructure prematurely. The
slice uses SQLite for disposable local development and CI; PostgreSQL remains required
before persistent public operation. Gameplay rules remain isolated from transport and
display prose so they can be tested deterministically.

The existing single-player journey implementation is retained under
`prototypes/journey/` as an accessibility, PWA, and narrative interaction study. It is
not the multiplayer MUD architecture and does not define cultivation canon.

### 2026-07-31 — Product category

The project is a complete, original, multiplayer online cultivation MUD with a persistent world, deep history, and full game framework.

### 2026-07-31 — Copyright boundary

The project is not an adaptation of `凡人修仙传`. The reference may inform abstract genre and narrative research only. Protected expression and distinctive combinations must not enter the product.

### 2026-07-31 — Working names

- Chinese: `山河有契`
- English: `Covenant of the Realm`
- Repository: `covenant-of-the-realm`

These are working names pending formal clearance.

### 2026-07-31 — Direction correction

The player-facing design must be recognizably and comprehensively cultivation-based. The initial covenant framework is optional deep metaphysics, not a replacement for cultivation systems.

## Proposed, not yet confirmed

### Content structure

Develop a vertical slice before expanding into the complete multi-realm world.

## Pending

- Launch market and languages
- Open-source scope and license
- Monetization
- PvP and permanent-loss policy
- Combat cadence
- Server/shard/season model
- Target concurrency and hosting budget
