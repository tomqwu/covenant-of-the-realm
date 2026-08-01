# Covenant of the Realm

[![Checks](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml/badge.svg)](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml)
[![Deterministic rules coverage](https://img.shields.io/badge/rules%20coverage-100%25-brightgreen)](docs/TESTING.md)
[![Playable slice](https://img.shields.io/badge/multiplayer%20slice-playable-8a5cf5)](docs/VERTICAL_SLICE.md)

**Covenant of the Realm**（中文工作名：**《山河有契》**）是一个原创、多人在线、持续演化的修仙 MUD。 The current build is a playable, bilingual, server-authoritative multiplayer vertical slice.

Two cultivators can enter the same persistent world, gather a spirit herb, refine local qi, complete a shared formation, advance from `凡身` to `引息境一层`, and reconnect to the state recorded by the server. It runs in Evennia's browser client over WebSocket or in a Telnet client.

## Play the multiplayer slice

Requires [uv](https://docs.astral.sh/uv/) and Python 3.13. Node.js 22.12+ is only needed for the preserved journey prototype and its complete repository check (`make setup-prototype`).

```sh
make setup
make play
```

Open `http://127.0.0.1:4001/webclient/`. Create an account with:

```text
create YourName YourLongLocalPassword
yes
connect YourName YourLongLocalPassword
```

Use two browser profiles or one browser plus `telnet 127.0.0.1 4000` for the cooperative step. Enter `path` at any time for the five-step route. Stop the local server with `make stop`.

## Player path

1. Go `east` from 照禾渡口 and `forage` a moonleaf herb.
2. Go `west`, then `north` to the hidden spring.
3. `cultivate`; the herb increases the deterministic qi gain.
4. One player uses `prepare`; another player in the room uses `witness`.
5. Use `status` to see realm, qi, insight, karma, and lifespan.

Chinese aliases such as `东`, `采药`, `修炼`, `布阵`, `见证`, and `状态` are supported.

## Engineering

```sh
make test                    # rules, Evennia integration, real two-client E2E
make lint                    # Ruff and documentation integrity
make check                   # all MUD gates plus the preserved prototype matrix
make test-multiplayer-e2e    # live server + real two-client journey only
```

The deterministic domain rules have an enforced 99% statement/branch minimum and currently reach 100%. The MUD adapter has isolated Evennia tests, and the release path is exercised through two real concurrent Telnet clients. The preserved browser prototype retains its own 100% unit result and 53-execution Playwright matrix. See [testing](docs/TESTING.md), [architecture](docs/ARCHITECTURE.md), and the [vertical-slice contract](docs/VERTICAL_SLICE.md).

## Repository map

- `mud/` — Evennia game, commands, typeclasses, world bootstrap, and server settings.
- `mud/world/rules.py` — deterministic, transport-free cultivation domain rules.
- `tests/` — exhaustive rules tests.
- `prototypes/journey/` — the earlier single-player PWA, preserved as a narrative/accessibility study rather than multiplayer architecture or canon.
- `docs/` — product context, decisions, architecture, testing, and design bible.

Read [AGENTS.md](AGENTS.md), [Project Context](docs/PROJECT_CONTEXT.md), and the [Decision Log](docs/DECISIONS.md) before changing durable product behavior.

## Originality and license

This is an original cultivation world, not an adaptation of any existing novel. Reference fiction may inform high-level genre research only; protected prose, characters, locations, treasures, distinctive sequences, or plot combinations must not enter the product.

A public-use license has not been selected. Visibility of the repository does not grant permission to copy, redistribute, or commercially reuse its code, writing, or assets. See [asset provenance](docs/ASSET_PROVENANCE.md).
