# 《山河有契》RPG 灰盒

这是 Godot 4.7.1 制作的原创单机剧情 RPG 基础。当前灰盒验证数据驱动中文行动、
确定性回合战斗、一次性资源与首次境界突破；不包含外部小说的受保护内容。

```sh
make setup-rpg
make play-rpg
make rpg-asset-check
make test-rpg
make test-rpg-e2e
make test-rpg-input
make check-rpg-package
make play-rpg-package
```

`make package-rpg` writes the cross-platform game-data pack to the ignored path
`build/rpg/covenant-of-the-realm.pck`. `make play-rpg-package` launches that pack with the pinned
Godot entrypoint. The package gate exports twice, requires byte-identical results, and boots the
pack headlessly. A native `.app`/`.exe` is intentionally deferred until platform export templates,
signing identity, product icon, and distribution target are confirmed.

The development window has a 1152×648 minimum because that is the validated readable layout.
Keyboard `E`/`S`, controller A/Start, focus navigation, movement, interaction, battle confirmation,
and pause/resume are exercised as physical input events by `make test-rpg-input`.

启动后可选择新游戏或继续本机的版本化存档。游戏会在成功交互、战斗行动和持续
移动时自动保存；按 `Esc` 或手柄 Start 可暂停、保存并返回标题。损坏或未知版本
的存档不会被静默载入，主文件写入失败时可从安全备份恢复。

环境音默认关闭，可在标题或暂停菜单中开启并循环选择 35%/60%/100% 音量。声音
由项目 GDScript 在运行时合成，不下载或嵌入第三方音频；偏好独立保存在本机，
损坏设置会安全回落为静音与 60% 音量，不影响旅程存档。

当前功能性美术灰盒采用明亮的全屏 RPG 镜头。第一套原创、确定性生成的人物图集
已经锁定 32×56 px 帧、固定脚底锚点、16×20 px 碰撞基准、四方向待机/行走动画、
最近邻过滤与整数像素对齐，并通过 `AnimatedSprite2D` 驱动主角和砚青。在照禾渡口
使用 `WASD` 或方向键移动，靠近金色交互圈后按 `E`、空格或
手柄 A；也可以点击右侧出现的行动。河水、地图边缘和房屋具有确定性碰撞，必须
亲自走到月芽田采集，再沿路抵达藏泉山门。战斗阶段使用鼠标点击，或用方向键
切换焦点并按 `Enter`/手柄 A 确认；可请求一次砚青援护，也可沿预留路线撤退。
战术部署槽可布置一盏引泉石灯，在部署回合与下一回合各削弱一点冲击；气血耗尽
会由同伴救回渡口，不会形成无法继续的死档。地图环境仍保留运行时绘制以便对照；
生产 `TileMapLayer` 地图和后续美术精修将在下一批循环加入。

开场任务采用同一套近距离交互：先在渡碑旁与砚青交谈，任务目标随后切换为采药，
取得月芽草后再指向藏泉山门。砚青会在简报完成前原地等候，之后才跟随主角。

设计合同见 [RPG 基础设计](../docs/design/RPG_FOUNDATION_v0.1.md) 与
[美术方向 v0.2](../docs/design/ART_DIRECTION_v0.2.md)。
