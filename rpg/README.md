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
make test-rpg-performance
make check-rpg-package
make play-rpg-package
```

`make package-rpg` writes the cross-platform game-data pack to the ignored path
`build/rpg/covenant-of-the-realm.pck` plus
`build/rpg/covenant-of-the-realm.manifest.json`. The manifest records size, SHA-256, Godot/preset,
nearest Git revision, clean/dirty source state, required runtime resources, and excluded development
resources. `make play-rpg-package` launches that pack with the pinned Godot entrypoint. The package
gate exports the PCK and manifest twice, requires byte-identical results, verifies the manifest,
probes the packed namespace for nine runtime resources and nine excluded `tests/`/`tools/` files,
then boots the pack headlessly. A native `.app`/`.exe` is intentionally deferred until platform export templates,
signing identity, product icon, and distribution target are confirmed.

The development window has a 1152×648 minimum because that is the validated readable layout.
Keyboard `E`/`S`, controller A/Start, focus navigation, movement, interaction, battle confirmation,
and pause/resume are exercised as physical input events by `make test-rpg-input`.

`make test-rpg-performance` executes 100,000 deterministic movement/collision steps, 50,000
bounded companion-footprint updates, 2,000 complete regular-enemy-to-warden rule loops, and 20 main-scene create/destroy cycles. Lifecycle sampling covers title, path, dialogue choices, stable battle, the immediate post-action replacement frame, and the scrollable journal. The checked-in
budget allows 2.5 seconds for each pure-domain workload and 5 seconds for the lifecycle workload,
caps the main scene at 120 nodes, and requires every cycle to return the root to its baseline child
count. Godot runs the lifecycle gate on a fixed 60 FPS clock so awaited settle frames remain covered
without charging shared-runner scheduler sleep to the workload. The runner reports measured times
but does not treat one development machine as a release hardware promise.

启动后可选择新游戏或继续本机的版本化存档。当前 save v13 同时记录稳定地图标识、
归一化坐标、对话行号、敌人标识、战斗状态、月芽采集方式、环境见闻、三项敌情、守堤与药篓选择；v1–v12 自动迁移，未知地图、无效对话、未知敌人、非法采集、见闻、敌情或支线状态不会被静默放进错误场景。游戏会在成功交互、战斗行动和持续
移动时自动保存；按 `Esc` 或手柄 Start 可暂停、保存并返回标题。损坏或未知版本
的存档不会被静默载入。第二次及后续成功保存会长期保留上一代主文件为安全备份；
主文件损坏时依次校验完整的中断写入与备份，恢复后重新落盘。普通保存会先替换废弃的
中断分支，再轮转已提交主文件；恢复专用 `.repair` 只作写入工作区，不会被当作可玩进度。
主文件、临时写入、恢复工作区或备份中只要出现未来版本或不同剧情，就会阻止旧运行时
降级和覆盖；v1–v12 迁移也必须通过当前规则、地图与对话校验。只要主文件、备份或
中断写入文件仍在，第一次选择重新开始只会进入警告态；取消默认获得焦点，第二次
明确确认后才删除旧进度并建立新旅程，异常文件也不会被一次点击覆盖。

环境音默认关闭，可在标题或暂停菜单中开启并循环选择 35%/60%/100% 音量。声音
由项目 GDScript 在运行时合成，不下载或嵌入第三方音频；偏好独立保存在本机，
损坏设置会安全回落为静音与 60% 音量，不影响旅程存档。

settings v2 还保存“标准/快速”战斗表现和“完整/简化”动态效果。快速只把语义事件
反馈从 0.70 秒缩短到 0.18 秒；简化动态保留静态文字与边框，但关闭脉冲。两项设置
不会进入旅程 domain，也不会改变伤害、回合、意图或存档结果。v1 音频设置自动
迁移为标准速度与完整动态，键盘、鼠标和手柄均可在标题或暂停页切换。

settings v3 增加“标准/大字”文字大小和“关闭/开启”高对比文字。大字把全部叙事
阅读文本在场景基准字号上放大 1.25 倍；高对比按明度把每个阅读标签推向不透明的
深墨或纸白锚点，纸面浅色与深底浅字两种极性都只增强、不反转。两项无障碍设置
同样只作用于表现层，v1/v2 设置保守迁移为标准字号与普通对比。

当前功能性美术灰盒采用明亮的全屏 RPG 镜头。第一套原创、确定性生成的人物图集
已经锁定 32×56 px 帧、固定脚底锚点、16×20 px 碰撞基准、四方向待机/行走动画、
最近邻过滤与整数像素对齐，并通过 `AnimatedSprite2D` 驱动主角、砚青、守堤人梁叔和药圃守蕙婶。四类敌人
共用另一张 128×256 RGBA 图集，每类占一行 64×64 双帧待机动画；稳定敌人标识
直接选择图集行，最近邻、脚底锚点和未知标识拒绝行为均由场景测试锁定。在照禾渡口
使用 `WASD` 或方向键移动，靠近金色交互圈后按 `E`、空格或
手柄 A；也可以点击右侧出现的行动。河水、地图边缘和房屋具有确定性碰撞，必须
亲自走到月芽田采集，再沿路抵达藏泉山门。战斗阶段使用鼠标点击，或用方向键
切换焦点并按 `Enter`/手柄 A 确认；可请求一次砚青援护，也可沿预留路线撤退。
战术部署槽可布置一盏引泉石灯，在部署回合与下一回合各削弱一点冲击；气血耗尽
会由同伴救回渡口，不会形成无法继续的死档。渡口与山道地表已由 36×20 个原创
32 px 图块组成真正的 `TileMapLayer`；同一张 256×64 图集的第二行还提供芦苇、
岸草、碎石、野花、石裂、苔痕、落叶与水沫，并由一个无物理/导航权威的稀疏
细节层按地图确定性铺设。建筑、树木、码头和交互标记暂时保留运行时绘制，作为
后续正式前景图块制作时的可复现对照。三处屋檐和四处树冠已拆为按脚底 Y
排序的独立前景节点；山道与战斗镜头分别使用五处和四处树冠。角色走到物体后方
会被遮挡，走到前方则覆盖前景，地图深度不会穿过对话或菜单模态层。

渡口、山道、战斗、泉室和章节结算之间使用 0.48 秒的明亮纸墨转场。转场文字来自
同一份已验证原创内容，活动期间由透明输入接收层临时接管鼠标、键盘和手柄焦点，
结束后战斗重新聚焦第一个合法行动；“动态效果：简化”会立即显示新场景，不播放
渐隐，也不改变规则、存档或可用行动。首领在同一战斗阶段入场时也有独立语义转场。

山门现在进入独立的藏泉山道 TileMapLayer，而不是直接跳到战斗。玩家可以自由
移动、查看旧石标、分别接近岩甲兽幼体、泉苔寄壳或失衡石傀、沿溪上缘无战斗绕行，或沿石阶回到渡口；地图标识与坐标
会自动保存并能在新场景实例中恢复。战斗撤退回到山道安全点，气血耗尽时砚青才
会把主角救回渡口。

月芽田在近距离交互时提供两个明确按钮：“依旧规取一株”保留旧单键流程，
“剪叶留根”取得同样足以护脉的成熟叶，但地图会留下可见新芽。两种方式都不会
锁死主线；采集字段自 save v9 起保存，并由当前 v13 在章节结算中回显。键盘/手柄单键交互采用稳定的
旧规默认项，鼠标或行动按钮可以选择任一方式。

三类敌人共享同一战斗解析器，但生命、两回合意图循环和材质弱点不同。抬头目标
始终会在玩家行动前显示当前敌势与伤害。山道上的岩甲擦痕、泉苔孢痕和石傀拖痕
可分别调查；识别后，界面才会额外预告后一势并指出本轮反制窗口：镇岩符只在裂石
冲撞时压入甲缝，引气术只在吸潮时吹散湿苔，守势只在失衡摆锤时借力反伤。调查
只增加信息，不改变伤害、资源、回合或奖励；未调查时碰巧选对行动仍按同一规则
结算，也不会暗中解锁札记。save v7 会把非默认敌人保存下来；E2E 会在泉苔
战斗中销毁并重建场景，验证敌人和下一意图都没有改变。

普通敌人退场后，岩甲兽守巢者会从泉室石门出现，但不会切换到另一套解析器。
守住首领重击会产生两层破甲，后续攻击逐层获得额外伤害；砚青援护会产生两层
凝息，强化后续术式或符箓。两种状态自 save v8 起明确记录，并由当前 v13 继续保存；完整 E2E 会在
首领战中断并恢复后继续结算；绕行路线仍可避开普通战与首领战。

开场任务采用同一套近距离交互：先在渡碑旁与砚青交谈。七句原创风险简报支持
逐字显示、整句显示、最近四句回顾、跳到回应、两项不会锁死主线的态度选择，以及
关闭场景后的精确续读。玩家回应会在章节结算中获得对应回声；任务目标随后切换
为采药，取得月芽草后再指向藏泉山门。砚青会在简报完成前原地等候，之后沿主角
实际走过的脚印保持约 0.058 个地图单位的距离；拐角不斜切建筑，轨迹固定封顶 96 点。
换图、读档或远距离调试跳转会在主角近旁重建轨迹，同行位置不进入旅程存档，也不
成为第二套碰撞或任务规则。

对话正文、主角回应、梁叔/蕙婶台词与最近四句回顾分别使用砚青、行旅者、守堤人、药圃守和行旅札记五种明亮纸绘
表现。头像由项目代码确定性绘制，不含外部图片或逐帧动态；身份文字始终可见，
表现节点忽略指针输入，未知人物标识安全回退为札记，也不会进入规则或存档。

第一次引息后的“回顾此行”会进入五句章节余波，而不是重复一条结算消息。余波从
同一确定性快照回显整株/留根、见闻数、撤退/无伤和谨慎/信任同行；逐句位置仍由
save v13 中沿用自 v10 的对话对象保存，中途返回标题后可精确续读。两个收束回应各有原创
事件回声，但不发放资源或隐藏奖励；内容声明的事件必须与规则返回值一致。

渡口旧水痕、山道石缝泉纹与弃置药篓是三处可选近距离见闻。调查只补充照禾的
治水、药圃和行旅生活历史，不提供隐藏战斗数值；每处只记一次，读后保留明确地图
余留并从行动列表隐藏。save v13 继续保存 v10 引入的稳定见闻标识，章节结算显示 `见闻 n/3`，重游
才清空；v1–v9 保守迁移为空列表，不虚构旧版本从未记录的探索。

点击地图左上“行旅札记”、按 `J` 或手柄 Y，可在探索、战斗、泉室和结算时查看
当前目标，并在“见闻”与“灵物志”两页间切换。未发现条目只显示编号空位，不提前
泄露地点、敌名、招式或反制；已辨认的三处敌迹按发现结果显示行止循环和时机。
札记打开
期间移动和交互无法穿透纸面，关闭后恢复先前焦点。札记直接读取确定性见闻列表，
灵物志直接读取 save v13 的三项稳定敌情 ID；当前页和滚动位置属于表现状态，不进入存档。

渡口下游的守堤人梁叔提供一项有限支线：玩家只能选择扶正被涨水冲歪的水尺，或
先把退水时刻与泥痕高度写进守堤簿。两项都不改变战斗、资源、关系数值或主线门槛，
但会分别留下直立木尺或纸签地图余留，并进入行旅札记、章节结算与余波对白。
save v11 引入稳定的 `repair`/`record` 结果，当前 v13 继续保存；v1–v10 统一迁移为未回应，不替旧玩家
作出选择。重游章节会清空该结果，键盘 E、鼠标行动与手柄 A 共享同一对话选择路径。

发现山道弃置药篓的双叶公用印后，玩家可以带它返回渡口找药圃守蕙婶。四句原创
对话提供“补绳归圃”或“补绳留在山道避雨石下”两个结果；两者都不会改变气血、
物品、战力、同伴资源、见闻数或主线门槛，只选择地图余留、札记条目、章节结算和
余波对白。save v12 保存稳定的 `return`/`trail` 结果；v1–v11 保守迁移为未回应。
对话可中断续读，重游会清空结果，键盘、鼠标和手柄均经过同一近距离交互路径。

设计合同见 [RPG 基础设计](../docs/design/RPG_FOUNDATION_v0.1.md) 与
[美术方向 v0.2](../docs/design/ART_DIRECTION_v0.2.md)。
