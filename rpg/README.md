# 《山河有契》RPG 灰盒

这是 Godot 4.7.1 制作的原创单机剧情 RPG 基础。当前灰盒验证数据驱动中文行动、
确定性回合战斗、一次性资源与首次境界突破；不包含外部小说的受保护内容。

```sh
make setup-rpg
make play-rpg
make test-rpg
```

方向键不参与当前菜单灰盒。使用鼠标点击行动，或用 `Tab`/方向键切换焦点并按
`Enter`/空格确认。完整地图移动将在下一个切片循环加入。

设计合同见 [RPG 基础设计](../docs/design/RPG_FOUNDATION_v0.1.md)。
