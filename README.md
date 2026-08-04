# Covenant of the Realm

[![Checks](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml/badge.svg)](https://github.com/tomqwu/covenant-of-the-realm/actions/workflows/check.yml)
[![Deterministic rules coverage](https://img.shields.io/badge/rules%20coverage-100%25-brightgreen)](docs/TESTING.md)
[![Playable slice](https://img.shields.io/badge/multiplayer%20slice-playable-8a5cf5)](docs/VERTICAL_SLICE.md)
[![Godot chapter](https://img.shields.io/badge/Godot%20chapter-playable-4b8f8c)](rpg/README.md)

**《山河有契》**（英文工作名：**Covenant of the Realm**）正在发展为一款原创、
中文优先、章节式的 2D 修仙剧情 RPG。Godot 可玩章节已经串联自由移动、碰撞、
双地图地表、第三张藏泉石室微地图与原创像素细节层、可恢复分支与章节余波对话、明亮纸绘头像、可选择“见闻/灵物志”的行旅札记、脚印式同伴跟随、陶小满六点送件巡路及船架/竹架两端点回响、岑苇四点巡山与六类进度回声、持久环境见闻、三痕辨势、守堤与药篓双结果支线、补船木架/晾晒竹架/避雨石棚三处可重复生活叙事、近距离采集、三类意图窗口敌人、守巢首领、事件驱动的四敌攻击/受击/败退像素动画、可撤退回合战斗、同伴援护、save v17 版本化存档和“听泉辨脉 → 月芽温脉 → 静坐引息”的首次境界突破；现有多人
MUD 与单人 PWA 作为可运行研究原型保留。标题与暂停页还提供标准、快速、整句三档
对话显字偏好；整句模式只关闭逐字揭示，不会自动推进或代选回应。

战斗中另有固定屏幕“照禾临势签”：九项稳定敌势分别使用不同线形，当前伤害始终
可读，已调查敌迹才显示后一势与破绽；动作前敌人与意图只进入瞬时表现上下文，
不会写入 save v17 或成为第二套战斗权威。敌方回应真正结算时，敌人脚下会留下
九形之一的“刚才”势痕，明确区分旧势与临势签中的下一势；普通敌致命回合则只在
守巢者已成为当前规则敌人的同一帧留下短暂败退旧影。两种表现都不阻断下一次
键盘、鼠标或手柄行动。

## Play the RPG graybox

Requires Godot 4.7.1. On macOS, `make setup-rpg` verifies an existing Homebrew install；
on Linux x86_64 it resolves the checksum-pinned official build into the ignored `.tools/`
directory.

```sh
make setup-rpg
make play-rpg
```

To build and launch a local resource pack through the same export path used by the package gate:

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
make check-rpg-package       # warm/fresh PCK identity, manifest, content probe, and boot smoke
make rpg-content-check       # original story-graph integrity
make test                    # rules, Evennia integration, real two-client E2E
make lint                    # Ruff and documentation integrity
make check                   # RPG, MUD, and preserved PWA gates
make test-multiplayer-e2e    # live server + real two-client journey only
```

The repository pytest gate passes 159 tests at 100% statement and branch coverage (621 statements /
316 branches). Godot behavior is covered by 3,530 headless rule/scene assertions plus an independent
374-check chapter E2E and 198-check physical-input/focus path. Nine committed pixel atlases are
regenerated twice and must match the Git index byte for byte. With pinned Godot 4.7.1 and export-time
text-to-binary scene conversion disabled, the package gate compares two normal exports plus exports
from two independent clean import caches. As historical controlled-input evidence, for the packaged runtime inputs committed in `f5c60e2`,
four local macOS/arm64 exports and four exports in each of two independent GitHub-hosted Linux/x86_64
RPG job attempts all match at 709,100 bytes and SHA-256
`e8308c22cda27e45b73fcf35e4fbb37587a266ead18d7be5c277c0864d74d351`.
This is controlled same-input evidence, not a future cross-platform guarantee: the normalized build
tuple remains provenance rather than a canonical-hash key or executable ABI. The probe requires 22
runtime resources for that historical input. For the previous intent-telegraph input, four local
macOS/arm64 exports and four GitHub-hosted Linux/x86_64 exports from run `30869981829`, each including
two fresh-cache project copies, all match at 812,608 bytes and SHA-256
`aa952662231cb0911197b538defd19a65ef9ee15b72ce62a10bd664054e4c895`; manifest verification,
the 25-required / nine-excluded resource probe, and packaged boot smoke pass locally and hosted.
For the previous outgoing-defeat input, four local macOS/arm64 exports and four GitHub-hosted
Linux/x86_64 exports from run `30873652565`, each including two fresh-cache project copies, all
match at 824,432 bytes and SHA-256
`6865587823cf2c69a4ed706d959f80f3a827edfe39a796c52882ba4edb5f7ada`; manifest verification,
the unchanged 25/9 probe, and packaged boot pass locally and hosted. For the current resolved-intent
accent input, four local macOS/arm64 exports, including two independent fresh-cache project copies,
match at 870,304 bytes and SHA-256
`009689da1eea0005e492e747928a5401c9fc7395962f61c16dae14e9d627caa1`; manifest verification,
the unchanged 25-required / nine-excluded probe, and packaged boot pass locally. Hosted run
`30877432459` passed all RPG functional suites at feature commit `02dc402` but its lifecycle
confirmation measured 7,075.94 ms against the unchanged 7,000 ms ceiling, before packaging. The
current allocation follow-up preserves that ceiling and has no hosted Linux package result yet.
Two consecutive 43-PNG capture runs are
byte-identical and produce aggregate SHA-256
`153ee23c5cbf0a6208fd9853b2722e7fb032ef2539468a210b47ffa8278568b4`.
The MUD adapter has
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
