# Covenant of the Realm

[![Checks](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml/badge.svg)](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml)
[![Deterministic rules coverage](https://img.shields.io/badge/rules%20coverage-100%25-brightgreen)](docs/TESTING.md)
[![Playable slice](https://img.shields.io/badge/multiplayer%20slice-playable-8a5cf5)](docs/VERTICAL_SLICE.md)
[![Godot chapter](https://img.shields.io/badge/Godot%20chapter-playable-4b8f8c)](rpg/README.md)

**《山河有契》**（英文工作名：**Covenant of the Realm**）正在发展为一款原创、
中文优先、章节式的 2D 修仙剧情 RPG。Godot 可玩章节已经串联自由移动、碰撞、
双地图地表、第三张藏泉石室微地图与原创像素细节层、可恢复分支与章节余波对话、明亮纸绘头像、可选择“见闻/灵物志”的行旅札记、脚印式同伴跟随、陶小满六点送件巡路、持久环境见闻、三痕辨势、守堤与药篓双结果支线、补船木架/晾晒竹架/避雨石棚三处可重复生活叙事、近距离采集、三类意图窗口敌人、守巢首领、可撤退回合战斗、同伴援护、版本化存档和“听泉辨脉 → 月芽温脉 → 静坐引息”的首次境界突破；现有多人
MUD 与单人 PWA 作为可运行研究原型保留。

## Play the RPG graybox

Requires Godot 4.7.1. On macOS, `make setup-rpg` verifies an existing Homebrew install；
on Linux x86_64 it resolves the checksum-pinned official build into the ignored `.tools/`
directory.

```sh
make setup-rpg
make play-rpg
```

To build and launch the same reproducible resource pack used by the package gate:

```sh
make play-rpg-package
```

The current graybox uses original project locations and characters only. It is playable from a
Chinese title screen through exploration, preparation, a recoverable deterministic battle, the
three-point spatial ritual `听泉辨脉 → 月芽温脉 → 静坐引息`, `引息境一层`, chapter settlement,
save resume, and replay. Keyboard, mouse, and controller
share semantic actions. Expanding this tested short chapter toward the complete 90-minute content
target is the next production milestone. See the [RPG foundation](docs/design/RPG_FOUNDATION_v0.1.md).

## Play the preserved multiplayer slice

两位修行者可以进入同一个持久世界，采集灵草、炼化灵气、合力完成阵式，从 `凡身` 突破到 `引息境一层`，并在重新登录后读取服务器保存的进度。游戏可通过 Evennia 的 WebSocket 浏览器客户端或 Telnet 客户端游玩。

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

中文是所有常规界面、世界文字和命令的默认语言。浏览器客户端中的出口、当前可选行动、帮助与修行指引均可直接点击；已经完成的采药、修炼或布阵步骤不会继续作为可选行动出现。历史记录中的旧方向链接若已不适用于当前地点，会回显当前可用出口。键盘和 Telnet 玩家仍可输入同一命令。`east`、`forage`、`cultivate`、`prepare`、`witness` 和 `status` 等英文命令仅作为兼容别名保留。

## Engineering

```sh
make test-rpg                # Godot domain and scene tests
make test-rpg-e2e            # complete Godot new-game → ending → resume → replay path
make test-rpg-input          # keyboard/controller events, focus, movement, interact, pause
make test-rpg-performance    # movement/combat throughput and scene-lifecycle leak budget
make check-rpg-package       # reproducible PCK/manifest, content probe, SHA-256, and boot smoke
make rpg-content-check       # original story-graph integrity
make test                    # rules, Evennia integration, real two-client E2E
make lint                    # Ruff and documentation integrity
make check                   # RPG, MUD, and preserved PWA gates
make test-multiplayer-e2e    # live server + real two-client journey only
```

The repository pytest gate passes 116 tests at 100% statement and branch coverage (545 statements /
272 branches). Godot behavior is covered by 2,052 headless rule/scene assertions plus an independent
238-check chapter E2E and 132-check physical-input/focus path. Eight committed pixel atlases are
regenerated twice and must match the Git index byte for byte. The reproducible 630,040-byte PCK has SHA-256
`c67c77cfd32219a48803b67326705c21bf0b1739118b766c71f8924db7202e50`; its probe requires
18 runtime resources, excludes nine development resources, and two consecutive 36-PNG capture runs
produce identical SHA-256 sets. The MUD adapter has
isolated Evennia tests, and its release path
is exercised through two real concurrent Telnet clients. The preserved browser prototype retains
its own 100% unit result and 53-execution Playwright matrix. See [testing](docs/TESTING.md),
[architecture](docs/ARCHITECTURE.md), and the [vertical-slice contract](docs/VERTICAL_SLICE.md).

## Repository map

- `mud/` — Evennia game, commands, typeclasses, world bootstrap, and server settings.
- `mud/world/rules.py` — deterministic, transport-free cultivation domain rules.
- `rpg/` — primary Godot RPG, original story content, domain rules, UI, and headless tests.
- `tests/` — exhaustive rules tests.
- `prototypes/journey/` — the earlier single-player PWA, preserved as a narrative/accessibility study rather than multiplayer architecture or canon.
- `docs/` — product context, decisions, architecture, testing, and design bible.

Read [AGENTS.md](AGENTS.md), [Project Context](docs/PROJECT_CONTEXT.md), and the [Decision Log](docs/DECISIONS.md) before changing durable product behavior.

## Originality and license

This is an original cultivation world, not an adaptation of any existing novel. Reference fiction may inform high-level genre and game-structure research only; protected prose, characters, locations, treasures, distinctive sequences, or plot combinations must not enter the product.

A public-use license has not been selected. Visibility of the repository does not grant permission to copy, redistribute, or commercially reuse its code, writing, or assets. See [asset provenance](docs/ASSET_PROVENANCE.md).
