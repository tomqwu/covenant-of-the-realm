# 《山河有契》RPG 灰盒

这是 Godot 4.7.1 制作的原创单机剧情 RPG 基础。当前灰盒验证数据驱动中文行动、
确定性回合战斗、一次性资源与首次境界突破；不包含外部小说的受保护内容。

```sh
make setup-rpg
make play-rpg
make test-rpg
```

当前功能性美术灰盒采用明亮的全屏 RPG 镜头，并以 56 px 作为第一轮角色比例
基准。照禾渡口、藏泉山道战斗与藏泉突破会随行动切换不同的原创场景构图。
使用鼠标点击行动，或用 `Tab`/方向键切换焦点并按 `Enter`/空格确认。自由地图
移动与正式 Sprite/Tile 仍将在后续循环加入；运行时绘制只用于验证布局和可读性。

设计合同见 [RPG 基础设计](../docs/design/RPG_FOUNDATION_v0.1.md) 与
[美术方向 v0.2](../docs/design/ART_DIRECTION_v0.2.md)。
