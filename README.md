# Covenant of the Realm

[![Checks](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml/badge.svg)](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml)
[![Deterministic rules coverage](https://img.shields.io/badge/rules%20coverage-100%25-brightgreen)](docs/TESTING.md)
[![Playable slice](https://img.shields.io/badge/multiplayer%20slice-playable-8a5cf5)](docs/VERTICAL_SLICE.md)

**《山河有契》**（英文工作名：**Covenant of the Realm**）是一个原创、多人在线、持续演化的中文修仙 MUD。当前版本是一段可完整游玩的、服务器权威的双人修行流程。

两位修行者可以进入同一个持久世界，采集灵草、炼化灵气、合力完成阵式，从 `凡身` 突破到 `引息境一层`，并在重新登录后读取服务器保存的进度。游戏可通过 Evennia 的 WebSocket 浏览器客户端或 Telnet 客户端游玩。

## Play the multiplayer slice

Requires [uv](https://docs.astral.sh/uv/) and Python 3.13. Node.js 22.12+ is only needed for the preserved journey prototype and its complete repository check (`make setup-prototype`).

```sh
make setup
make play
```

Open `http://127.0.0.1:4001/webclient/`. Create an account with:

```text
注册 YourName YourLongLocalPassword
是
登录 YourName YourLongLocalPassword
```

协作步骤需要两个浏览器配置文件，或一个浏览器加 `telnet 127.0.0.1 4000`。游戏中随时输入 `指引` 可查看五步路线；输入 `帮助` 可查看中文命令。使用 `make stop` 停止本地服务器。

## Player path

1. 从照禾渡口向 `东` 前往月芽田，输入 `采药` 取得一株月芽草。
2. 向 `西` 返回渡口，再向 `北` 进入藏泉石室。
3. 输入 `修炼`；携带月芽草时会获得额外灵气。
4. 一位玩家输入 `布阵`，同场另一位玩家输入 `见证`。
5. 输入 `修为` 查看境界、灵气、悟性、因果与寿元。

中文是所有常规界面、世界文字和命令的默认语言。`east`、`forage`、`cultivate`、`prepare`、`witness` 和 `status` 等英文命令仅作为兼容别名保留。

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
