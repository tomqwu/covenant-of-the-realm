extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const DialogueStateScript := preload("res://src/domain/dialogue_state.gd")
const EnemyCatalogScript := preload("res://src/domain/enemy_catalog.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const PathKeeperStateScript := preload("res://src/domain/path_keeper_state.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const DialoguePortraitScript := preload("res://src/ui/dialogue_portrait.gd")
const MapOccluderScript := preload("res://src/ui/map_occluder.gd")
const WorldCameraScript := preload("res://src/ui/world_camera.gd")
const TEST_SAVE_PATH := "user://automated-test-save.json"
const TEST_SCENE_SAVE_PATH := "user://automated-scene-save.json"
const TEST_SETTINGS_PATH := "user://automated-test-settings.json"
const TEST_SCENE_SETTINGS_PATH := "user://automated-scene-settings.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_initial_state()
	_test_enemy_catalog()
	_test_exploration_rules()
	_test_patrol_state()
	_test_patrol_endpoint_work()
	_test_path_keeper_state()
	_test_path_keeper_echoes()
	_test_life_landmark_observations()
	_test_state_restore()
	_test_dialogue_state()
	_test_versioned_save()
	_test_patrol_work_save_validation()
	_test_crash_consistent_save_recovery()
	_test_stale_temporary_branch_replacement()
	_test_all_save_artifact_barriers()
	_test_settings_store()
	_test_world_camera()
	_test_companion_trail()
	_test_dialogue_portraits()
	_test_map_landmark_adapter()
	_test_ferryman_side_story()
	_test_basket_side_story()
	_test_patrol_side_story()
	_test_environment_discoveries()
	_test_enemy_intel()
	_test_gathering_and_gate()
	_test_combat_paths()
	_test_enemy_profile_combat()
	_test_boss_and_statuses()
	_test_companion_retreat_and_rescue()
	_test_first_breath_ritual_and_completion()
	await _test_visual_scale_scene()
	await _test_scene_smoke()
	await _test_scene_save_recovery()
	if failures.is_empty():
		print("RPG tests passed: %d assertions." % assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_initial_state() -> void:
	var state = JourneyStateScript.new()
	_expect_equal(state.phase_id(), "riverbank", "初始地点")
	_expect_equal(state.snapshot()["realm"], "凡身", "初始境界")
	_expect_true(state.available_actions().has("talk_to_companion"), "初始可与同伴交谈")
	_expect_true(state.available_actions().has("gather_moonleaf"), "初始可采集")
	_expect_true(state.available_actions().has("gather_moonleaf_cutting"), "初始可选择剪叶留根")
	_expect_true(state.available_actions().has("inspect_ferry_watermark"), "初始渡口包含可选环境调查")
	_expect_true(state.available_actions().has("talk_to_ferryman"), "初始渡口包含可选守堤交谈")
	_expect_equal(state.snapshot()["ferryman_response"], "unanswered", "新旅程不替玩家决定守堤办法")
	_expect_equal(state.snapshot()["basket_response"], "unanswered", "新旅程不替玩家决定公用药篓去向")
	_expect_equal(state.snapshot()["patrol_response"], "unanswered", "新旅程不替玩家决定陶小满的巡路先后")
	_expect_false(state.available_actions().has("talk_to_patrol_runner"), "同伴简报前不会提前出现巡路委托")
	_expect_false(state.available_actions().has("talk_to_herbkeeper"), "发现山道药篓前不会提前出现归还行动")
	_expect_equal(state.snapshot()["discoveries"], [], "新旅程没有伪造已读见闻")
	_expect_equal(state.snapshot()["enemy_intel"], [], "新旅程没有伪造已识别敌情")
	_expect_equal(state.snapshot()["moonleaf_method"], "unselected", "采集前没有伪造取药方式")
	_expect_equal(state.snapshot()["first_breath_stage"], "unstarted", "新旅程尚未开始第一次引息仪轨")
	_expect_true(state.available_actions().has("enter_spring"), "初始可尝试进山")
	_expect_false(state.choose("unknown")["ok"], "未知行动不改变状态")


func _test_world_camera() -> void:
	var camera = WorldCameraScript.new()
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2(1128, 624)), Vector2(204, 139), "世界镜头把中央脚点锁到稳定取景锚点")
	var centered: Dictionary = camera.camera_contract()
	_expect_equal(centered["world_size"], Vector2(1536, 864), "滚动世界冻结为 48×27 个 32 px 图块")
	_expect_equal(centered["world_offset"], -centered["origin"], "世界根节点使用镜头原点的反向偏移")
	_expect_true(centered["pixel_snap"], "镜头原点与世界偏移始终落在整数像素")
	_expect_equal(centered["safe_frame"]["rect"], Rect2(32, 96, 1064, 336), "安全取景区为顶部 HUD 与底部纸面保留空间")
	var centered_screen_focus: Vector2 = centered["world_focus"] - centered["origin"]
	_expect_true(centered["safe_frame"]["rect"].has_point(centered_screen_focus), "中央角色脚点位于 HUD 之外的安全取景区")
	camera.update_focus(Vector2(0.5, 0.51), Vector2(1128, 624))
	var first_follow_screen_position: Vector2 = camera.camera_contract()["world_focus"] - camera.camera_contract()["origin"]
	camera.update_focus(Vector2(0.5, 0.515), Vector2(1128, 624))
	_expect_equal(camera.camera_contract()["world_focus"] - camera.camera_contract()["origin"], first_follow_screen_position, "连续纵向移动使用同一像素取整规则而不让跟随脚点上下抖动")

	_expect_equal(camera.update_focus(Vector2(0.13, 0.13), Vector2(1128, 624)), Vector2.ZERO, "左上地图边界夹紧且不露出世界外空白")
	var top_left: Dictionary = camera.camera_contract()
	_expect_true(top_left["clamped_sides"]["left"] and top_left["clamped_sides"]["top"], "镜头合同明确记录左上夹紧")
	_expect_equal(camera.update_focus(Vector2(0.95, 0.72), Vector2(1128, 624)), Vector2(408, 240), "右下地图边界夹紧到最大合法原点")
	var bottom_right: Dictionary = camera.camera_contract()
	_expect_true(bottom_right["clamped_sides"]["right"] and bottom_right["clamped_sides"]["bottom"], "镜头合同明确记录右下夹紧")
	var edge_screen_focus: Vector2 = bottom_right["world_focus"] - bottom_right["origin"]
	_expect_true(bottom_right["safe_frame"]["rect"].has_point(edge_screen_focus), "可走区域右下脚点仍留在纸面上方")

	var stable_contract := camera.camera_contract()
	_expect_equal(camera.update_focus(Vector2(-0.01, 0.5), Vector2(1128, 624)), stable_contract["origin"], "越界归一化焦点被原子拒绝")
	_expect_equal(camera.camera_contract()["normalized_focus"], stable_contract["normalized_focus"], "非法焦点不部分覆盖现有镜头状态")
	_expect_equal(camera.update_focus(Vector2(1.01, 0.5), Vector2(1128, 624)), stable_contract["origin"], "超过右界的归一化焦点被拒绝")
	_expect_equal(camera.update_focus(Vector2(0.5, -0.01), Vector2(1128, 624)), stable_contract["origin"], "超过上界的归一化焦点被拒绝")
	_expect_equal(camera.update_focus(Vector2(0.5, 1.01), Vector2(1128, 624)), stable_contract["origin"], "超过下界的归一化焦点被拒绝")
	_expect_equal(camera.update_focus(Vector2(NAN, 0.5), Vector2(1128, 624)), stable_contract["origin"], "非有限焦点被拒绝")
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2.ZERO), stable_contract["origin"], "非正视口尺寸被原子拒绝")
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2(INF, 624)), stable_contract["origin"], "非有限视口尺寸被原子拒绝")
	_expect_equal(camera.position, -stable_contract["origin"], "全部非法更新都不移动世界根节点")
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2(1800, 624)), Vector2(0, 139), "仅横向大于世界时只固定横向原点")
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2(1128, 1000)), Vector2(204, 0), "仅纵向大于世界时只固定纵向原点")
	_expect_equal(camera.update_focus(Vector2(0.5, 0.5), Vector2(1800, 1000)), Vector2.ZERO, "视口大于世界时固定原点而不制造负边界")
	camera.free()


func _test_map_landmark_adapter() -> void:
	var occluder = MapOccluderScript.new()
	_expect_false(
		occluder.configure("invalid", "tree", "unknown_landmark", Vector2(10.5, 20.5), 20.5, 12),
		"地标前景拒绝未知图集标识"
	)
	_expect_equal(occluder.profile_id, "", "非法地标标识不会部分配置表现节点")
	_expect_true(
		occluder.configure("test_tree", "tree", "tree_celadon", Vector2(10.5, 20.5), 20.5, 12),
		"已声明树木图集标识可配置前景"
	)
	var contract: Dictionary = occluder.visual_contract()
	_expect_equal(contract["atlas_path"], "res://assets/pixel/zhaohe_landmarks.png", "前景读取提交的照禾地标图集")
	_expect_equal(contract["frame_size"], Vector2i(192, 128), "地标使用固定 192×128 像素帧")
	_expect_equal(contract["frame_column"], 0, "青叶树稳定映射图集首列")
	_expect_equal(contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "像素前景使用最近邻过滤")
	_expect_true(contract["asset_backed"], "前景由图集区域而非即时矢量绘制")
	_expect_true(contract["pixel_snapped"], "前景脚点对齐整数像素")
	_expect_false(contract["collision_authority"], "地标表现不成为第二套碰撞权威")
	var landmark_image: Image = occluder.texture.get_image()
	_expect_equal(landmark_image.get_format(), Image.FORMAT_RGBA8, "地标源图导入后保留 RGBA8 像素格式")
	_expect_equal(landmark_image.get_size(), Vector2i(2112, 128), "地标源图完整包含十一个固定帧")
	for column in range(11):
		_expect_true(
			_image_region_has_opaque_pixel(landmark_image, Rect2i(column * 192, 0, 192, 128)),
			"地标图集第 %d 列包含可见像素" % column
		)
		_expect_equal(landmark_image.get_pixel(column * 192, 0).a, 0.0, "地标图集第 %d 列保留透明边界" % column)
	occluder.free()


func _test_enemy_catalog() -> void:
	_expect_equal(EnemyCatalogScript.REGULAR_ENEMY_IDS.size(), 3, "山道配置三种原创普通敌人")
	_expect_equal(EnemyCatalogScript.ENEMY_IDS.size(), 4, "普通敌人与首领共用一个配置目录")
	_expect_true(EnemyCatalogScript.supports("rock_armor_young"), "稳定敌人标识可识别")
	_expect_false(EnemyCatalogScript.supports(3), "非文本敌人标识被拒绝")
	var rock: Dictionary = EnemyCatalogScript.profile("rock_armor_young")
	_expect_equal(rock["name"], "岩甲兽幼体", "岩甲幼兽配置中文名称")
	_expect_equal(rock["max_hp"], 12, "岩甲幼兽生命值由配置提供")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 1)["id"], "rock_probing_charge", "第一回合意图使用稳定标识")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 1)["name"], "试探冲撞", "第一回合意图稳定")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 2)["damage"], 4, "第二回合意图伤害稳定")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 2)["id"], "rock_rending_charge", "裂石冲撞使用稳定意图标识")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 3)["name"], "试探冲撞", "意图序列确定性循环")
	_expect_equal(EnemyCatalogScript.intent("missing", 1), {}, "未知敌人没有伪造意图")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 0), {}, "无效回合没有意图")
	_expect_equal(EnemyCatalogScript.player_damage("rock_armor_young", "use_talisman", 1), 5, "试探冲撞期间符箓只造成基础伤害")
	_expect_equal(EnemyCatalogScript.player_damage("rock_armor_young", "use_talisman", 2), 6, "裂石冲撞期间符压增加一点伤害")
	_expect_equal(EnemyCatalogScript.player_damage("spring_moss_shell", "use_art", 1), 4, "吸潮期间泉息命中泉苔弱点")
	_expect_equal(EnemyCatalogScript.player_damage("spring_moss_shell", "use_art", 2), 3, "喷雾期间术式不误触相克")
	_expect_equal(EnemyCatalogScript.player_damage("unbalanced_stone_puppet", "guard", 1), 2, "摆锤期间守势借力令石傀受创")
	_expect_equal(EnemyCatalogScript.player_damage("unbalanced_stone_puppet", "guard", 2), 0, "回正期间守势没有反伤")
	_expect_equal(EnemyCatalogScript.player_damage("rock_armor_warden", "guard", 1), 0, "首领压阵肩撞期间守势不破甲")
	_expect_equal(EnemyCatalogScript.player_damage("rock_armor_warden", "guard", 2), 2, "首领崩石重击期间守势反伤")
	_expect_equal(EnemyCatalogScript.player_damage("missing", "unknown"), 0, "未知组合不产生伤害")
	_expect_equal(EnemyCatalogScript.player_damage("missing", "use_art", 1), 0, "未知敌人不会取得玩家基础伤害")
	_expect_true(EnemyCatalogScript.exposes_weakness("spring_moss_shell", "use_art", 1), "配置可判断当前意图的材质相克")
	_expect_false(EnemyCatalogScript.exposes_weakness("spring_moss_shell", "use_art", 2), "相同行动在错误意图窗口不误报相克")
	_expect_false(EnemyCatalogScript.exposes_weakness("spring_moss_shell", "guard", 1), "非弱点行动不误报相克")
	_expect_true(EnemyCatalogScript.supports_intel("spring_moss_shell"), "普通敌人标识可作为敌情条目")
	_expect_false(EnemyCatalogScript.supports_intel("rock_armor_warden"), "首领不伪造第四条敌情")
	_expect_equal(EnemyCatalogScript.intel_id("rock_armor_warden"), "rock_armor_young", "守巢者复用岩甲兽敌情")
	_expect_equal(EnemyCatalogScript.intel_id("missing"), "", "未知敌人不映射敌情")
	_expect_true(EnemyCatalogScript.is_boss("rock_armor_warden"), "守巢者配置被标记为首领")
	_expect_false(EnemyCatalogScript.is_boss("rock_armor_young"), "普通岩甲幼兽不误判为首领")


func _test_exploration_rules() -> void:
	var state = ExplorationStateScript.new()
	_expect_equal(state.player_position, ExplorationStateScript.START_POSITION, "探索使用确定的起点")
	_expect_true(state.is_walkable(state.player_position), "初始位置可以行走")
	_expect_equal(state.interaction_action(false), "talk_to_companion", "出生点可与等待的同伴交谈")
	_expect_equal(state.interaction_action(false, true), "", "交谈完成后同伴不重复阻挡交互")

	var start: Vector2 = state.player_position
	var idle_position: Vector2 = state.move(Vector2.ZERO, 1.0)
	_expect_equal(idle_position, start, "无方向输入不移动")
	state.move(Vector2.LEFT, 5.0)
	_expect_true(state.player_position.x >= 0.37, "河岸边界阻止角色进入水面")
	_expect_false(state.is_walkable(Vector2(0.2, 0.5)), "水域不可行走")
	_expect_false(state.is_walkable(Vector2(0.56, 0.26)), "建筑占用区不可行走")

	_expect_true(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.69, "player_y": 0.62}), "可恢复到合法月芽田位置")
	_expect_equal(state.interaction_action(false), "gather_moonleaf", "靠近月芽草出现采集交互")
	_expect_equal(state.interaction_action(true), "", "采集后月芽草不再交互")
	_expect_true(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "可恢复到合法山门位置")
	_expect_equal(state.interaction_action(false), "enter_spring", "靠近山门出现进山交互")
	var gate_position: Vector2 = state.player_position
	_expect_false(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.2, "player_y": 0.5}), "拒绝恢复到碰撞区")
	_expect_equal(state.player_position, gate_position, "无效恢复保留原位置")
	_expect_false(state.restore({"player_x": 0.5}), "缺失坐标的快照被拒绝")
	_expect_false(state.restore({"map_id": "unknown_map", "player_x": 0.69, "player_y": 0.62}), "未知地图标识被探索规则拒绝")
	_expect_equal(state.snapshot().keys(), ["map_id", "player_x", "player_y"], "探索快照只含稳定地图标识与坐标")
	_expect_true(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42}), "渡口旧水痕坐标可达")
	_expect_equal(state.interaction_action(false, true), "inspect_ferry_watermark", "未读旧水痕提供近距离调查")
	_expect_equal(state.interaction_action(false, true, ["ferry_watermark"]), "", "已读旧水痕不重复占用交互")
	_expect_true(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "渡口守堤人坐标可达")
	_expect_equal(state.interaction_action(false, true), "talk_to_ferryman", "靠近梁叔出现独立交谈行动")
	_expect_equal(state.interaction_action(false, true, [], "repair"), "", "守堤选择完成后不重复占用交互")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "山道坐标按山道碰撞而非渡口建筑恢复")
	_expect_equal(state.map_id, "cangquan_path", "恢复后切换稳定地图标识")
	_expect_equal(state.interaction_action(true, true), "approach_enemy", "岩甲幼兽有独立接近行动")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.56, "player_y": 0.48}), "泉苔寄壳坐标可达")
	_expect_equal(state.interaction_action(true, true), "approach_moss_shell", "泉苔寄壳有独立接近行动")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.64, "player_y": 0.44}), "旧石标撤退点可达")
	_expect_equal(state.interaction_action(true, true), "", "撤退安全点不落在任一敌人交互半径内")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30}), "石缝泉纹坐标可达")
	_expect_equal(state.interaction_action(true, true), "inspect_spring_seam", "未读泉纹提供近距离调查")
	_expect_equal(state.interaction_action(true, true, ["spring_seam"]), "", "已读泉纹不重复占用交互")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "弃置药篓坐标可达")
	_expect_equal(state.interaction_action(true, true), "inspect_abandoned_basket", "未读药篓提供近距离调查")
	_expect_equal(state.interaction_action(true, true, ["abandoned_basket"]), "", "已读药篓不重复占用交互")
	_expect_true(state.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "药圃守蕙婶坐标可达")
	_expect_equal(state.interaction_action(true, true, ["abandoned_basket"], "repair"), "talk_to_herbkeeper", "带回药篓后靠近蕙婶出现交还行动")
	_expect_equal(state.interaction_action(true, true, ["abandoned_basket"], "repair", "return"), "", "药篓安置后不重复占用交互")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.80, "player_y": 0.25}), "失衡石傀坐标可达")
	_expect_equal(state.interaction_action(true, true), "approach_stone_puppet", "失衡石傀有独立接近行动")
	var trace_positions := [
		ExplorationStateScript.PATH_ROCK_SPOOR_POSITION,
		ExplorationStateScript.PATH_MOSS_SPOOR_POSITION,
		ExplorationStateScript.PATH_PUPPET_SPOOR_POSITION,
	]
	var existing_path_interactions := [
		ExplorationStateScript.PATH_RETURN_POSITION,
		ExplorationStateScript.PATH_MARKER_POSITION,
		ExplorationStateScript.PATH_SPRING_SEAM_POSITION,
		ExplorationStateScript.PATH_ABANDONED_BASKET_POSITION,
		ExplorationStateScript.PATH_ENEMY_POSITION,
		ExplorationStateScript.PATH_MOSS_POSITION,
		ExplorationStateScript.PATH_PUPPET_POSITION,
		ExplorationStateScript.PATH_BYPASS_POSITION,
		ExplorationStateScript.PATH_RETREAT_POSITION,
	]
	for trace_position in trace_positions:
		_expect_true(state.is_walkable(trace_position), "敌踪调查点位于可行走山道")
		for existing_position in existing_path_interactions:
			_expect_true(trace_position.distance_to(existing_position) > ExplorationStateScript.INTERACTION_RADIUS * 2.0, "敌踪调查点不与既有交互半径重叠")
	for left_index in range(trace_positions.size()):
		for right_index in range(left_index + 1, trace_positions.size()):
			_expect_true(trace_positions[left_index].distance_to(trace_positions[right_index]) > ExplorationStateScript.INTERACTION_RADIUS * 2.0, "三处敌踪交互彼此分离")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.65, "player_y": 0.22}), "岩甲擦痕坐标可达")
	_expect_equal(state.interaction_action(true, true), "inspect_rock_spoor", "未识别岩甲敌情时提供擦痕调查")
	_expect_equal(state.interaction_action(true, true, [], "unanswered", "unanswered", ["rock_armor_young"]), "", "已识别岩甲敌情后擦痕不重复交互")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.36, "player_y": 0.43}), "泉苔湿痕坐标可达")
	_expect_equal(state.interaction_action(true, true), "inspect_moss_spoor", "未识别泉苔敌情时提供湿痕调查")
	_expect_equal(state.interaction_action(true, true, [], "unanswered", "unanswered", ["spring_moss_shell"]), "", "已识别泉苔敌情后湿痕不重复交互")
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.91, "player_y": 0.34}), "石傀拖痕坐标可达")
	_expect_equal(state.interaction_action(true, true), "inspect_puppet_spoor", "未识别石傀敌情时提供拖痕调查")
	_expect_equal(state.interaction_action(true, true, [], "unanswered", "unanswered", ["unbalanced_stone_puppet"]), "", "已识别石傀敌情后拖痕不重复交互")

	_expect_true(state.transition_to(ExplorationStateScript.CANGQUAN_SPRING_MAP_ID), "可进入藏泉石室独立探索地图")
	_expect_equal(state.map_id, "cangquan_spring", "泉室使用稳定地图标识")
	_expect_equal(state.player_position, ExplorationStateScript.SPRING_START_POSITION, "泉室从洞口内侧安全点开始")
	_expect_equal(state.interaction_action(true, true), "", "泉室出生点不直接触发任一仪轨")
	_expect_false(state.is_walkable(Vector2(0.53, 0.60)), "泉池水面不可行走")
	var spring_points := [
		{"position": ExplorationStateScript.SPRING_LISTEN_POSITION, "action": "listen_to_spring"},
		{"position": ExplorationStateScript.SPRING_WARM_POSITION, "action": "warm_meridians"},
		{"position": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION, "action": "breakthrough"},
	]
	for spring_case in spring_points:
		var spring_position: Vector2 = spring_case["position"]
		_expect_true(state.is_walkable(spring_position), "泉室仪轨点位于可行走区域")
		_expect_true(state.restore({"map_id": "cangquan_spring", "player_x": spring_position.x, "player_y": spring_position.y}), "泉室仪轨点可从存档恢复")
		_expect_equal(state.interaction_action(true, true), spring_case["action"], "泉室仪轨点映射到稳定语义行动")
	for left_index in range(spring_points.size()):
		for right_index in range(left_index + 1, spring_points.size()):
			_expect_true(
				spring_points[left_index]["position"].distance_to(spring_points[right_index]["position"]) > ExplorationStateScript.INTERACTION_RADIUS * 2.0,
				"三处引息仪轨的交互半径彼此分离"
			)
	var walked_spring = ExplorationStateScript.new()
	walked_spring.transition_to(ExplorationStateScript.CANGQUAN_SPRING_MAP_ID)
	walked_spring.move(Vector2.UP, 0.70)
	walked_spring.move(Vector2.LEFT, 1.20)
	walked_spring.move(Vector2.DOWN, 0.70)
	_expect_equal(walked_spring.interaction_action(true, true), "listen_to_spring", "可从泉室出生点绕泉池上缘走到听泉点")
	walked_spring.move(Vector2.UP, 0.70)
	walked_spring.move(Vector2.RIGHT, 0.92)
	walked_spring.move(Vector2.DOWN, 0.37)
	_expect_equal(walked_spring.interaction_action(true, true), "warm_meridians", "可从听泉点继续步行到温脉石床")
	walked_spring.move(Vector2.UP, 0.67)
	walked_spring.move(Vector2.LEFT, 0.55)
	_expect_equal(walked_spring.interaction_action(true, true), "breakthrough", "可从温脉石床继续步行到静坐息石")


func _test_patrol_state() -> void:
	var initial = PatrolStateScript.new()
	_expect_equal(initial.snapshot(), PatrolStateScript.default_snapshot(), "巡路状态从唯一默认快照开始")
	_expect_equal(initial.position, PatrolStateScript.START_POSITION, "陶小满从渡口中央公开路面出发")
	_expect_equal(initial.target_index, PatrolStateScript.START_TARGET_INDEX, "默认巡路指向下一处稳定路点")
	var runtime: Dictionary = initial.runtime_contract()
	_expect_equal(runtime["route_points"], PatrolStateScript.WAYPOINTS, "巡路合同公开完整有序路点")
	_expect_false(runtime["collision_authority"], "巡路表现不建立第二套碰撞权威")
	_expect_false(runtime["quest_authority"], "巡路表现不建立第二套任务权威")
	_expect_true(runtime["persistent"], "巡路状态明确进入持久化合同")
	var ferry = ExplorationStateScript.new()
	for waypoint in PatrolStateScript.WAYPOINTS:
		_expect_true(ferry.is_walkable(waypoint), "陶小满路点位于玩家可公开行走的渡口地面")
	for index in range(PatrolStateScript.WAYPOINTS.size() - 1):
		for sample_index in range(21):
			var sample: Vector2 = PatrolStateScript.WAYPOINTS[index].lerp(PatrolStateScript.WAYPOINTS[index + 1], float(sample_index) / 20.0)
			_expect_true(ferry.is_walkable(sample), "陶小满相邻路点之间不穿越不可走场景")
	_expect_true(
		PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].distance_to(ExplorationStateScript.BOAT_REPAIR_POSITION) < 0.11,
		"巡路西端实际抵达补船木架旁"
	)
	_expect_true(
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].distance_to(ExplorationStateScript.DRYING_RACK_POSITION) < 0.08,
		"巡路东端实际抵达晾晒竹架旁"
	)
	_expect_true(
		PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].distance_to(ExplorationStateScript.BOAT_REPAIR_POSITION) > ExplorationStateScript.INTERACTION_RADIUS,
		"补船端点不被固定地标行动永久遮蔽"
	)
	_expect_true(
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].distance_to(ExplorationStateScript.DRYING_RACK_POSITION) > ExplorationStateScript.INTERACTION_RADIUS,
		"晾晒端点不被固定地标行动永久遮蔽"
	)

	var start: Vector2 = initial.position
	_expect_equal(initial.advance(0.5), start, "中央起步停留前半段不提前滑动")
	_expect_true(is_equal_approx(initial.dwell_remaining, 0.5), "起步停留时间按确定增量消耗")
	_expect_equal(initial.advance(0.5), start, "完整一秒起步停留保持原位便于发现")
	initial.advance(0.5)
	_expect_true(initial.position.distance_to(start) > 0.0, "起步停留结束后沿中央路段移动")
	_expect_equal(initial.motion_direction().sign(), (PatrolStateScript.WAYPOINTS[2] - start).normalized().sign(), "移动朝向由当前目标路点推导")
	var endpoint_dwell = PatrolStateScript.new()
	_expect_true(endpoint_dwell.restore({
		"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
		"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
		"target_index": PatrolStateScript.BOAT_WAYPOINT + 1,
		"route_step": 1,
		"dwell_remaining": PatrolStateScript.ENDPOINT_DWELL_SECONDS,
		"yielding_to_player": false,
	}), "船架端点停留是严格可恢复的运行时状态")
	var boat_endpoint: Vector2 = endpoint_dwell.position
	_expect_equal(endpoint_dwell.advance(1.0), boat_endpoint, "端点停留前半段不提前滑动")
	_expect_true(is_equal_approx(endpoint_dwell.dwell_remaining, 1.0), "端点停留时间按确定增量消耗")
	_expect_equal(endpoint_dwell.advance(1.0), boat_endpoint, "完整两秒端点停留保持原位")
	endpoint_dwell.advance(0.5)
	_expect_true(endpoint_dwell.position.distance_to(boat_endpoint) > 0.0, "停留结束后沿公开路线继续移动")

	var whole_delta = PatrolStateScript.new()
	var sliced_delta = PatrolStateScript.new()
	whole_delta.advance(13.75)
	for _step in range(275):
		sliced_delta.advance(0.05)
	_expect_true(whole_delta.position.distance_to(sliced_delta.position) <= PatrolStateScript.POSITION_EPSILON, "大步与小切片推进得到同一巡路位置")
	_expect_equal(whole_delta.target_index, sliced_delta.target_index, "大步与小切片推进得到同一目标路点")
	_expect_equal(whole_delta.route_step, sliced_delta.route_step, "大步与小切片推进得到同一路线方向")
	_expect_true(
		absf(whole_delta.dwell_remaining - sliced_delta.dwell_remaining) <= PatrolStateScript.POSITION_EPSILON * 4.0,
		"大步与小切片推进得到同一停留余量（整步 %.8f / 切片 %.8f）" % [whole_delta.dwell_remaining, sliced_delta.dwell_remaining]
	)
	_expect_equal(whole_delta.yielding_to_player, sliced_delta.yielding_to_player, "切片方式不改变让路状态")
	var repeated_delta = PatrolStateScript.new()
	repeated_delta.advance(13.75)
	_expect_equal(repeated_delta.snapshot(), whole_delta.snapshot(), "相同初态与增量逐字段复现同一巡路快照")

	var yielding = PatrolStateScript.new()
	var moving_snapshot := PatrolStateScript.default_snapshot()
	moving_snapshot["dwell_remaining"] = 0.0
	_expect_true(yielding.restore(moving_snapshot), "让路测试可恢复到合法移动快照")
	var yield_origin: Vector2 = yielding.position
	yielding.advance(0.2, yield_origin + Vector2(0.079, 0.0))
	_expect_true(yielding.yielding_to_player, "玩家进入八分路宽时陶小满确定让路")
	_expect_equal(yielding.position, yield_origin, "让路期间巡路位置保持不变")
	yielding.advance(0.2, yield_origin + Vector2(0.09, 0.0))
	_expect_true(yielding.yielding_to_player, "玩家处于迟滞带时不会反复启停")
	_expect_equal(yielding.position, yield_origin, "迟滞带内继续保持让路")
	yielding.advance(0.2, yield_origin + Vector2(0.101, 0.0))
	_expect_false(yielding.yielding_to_player, "玩家退出十分路宽后巡路恢复")
	_expect_true(yielding.position.distance_to(yield_origin) > 0.0, "退出让路半径后同一增量恢复移动")

	var strict = PatrolStateScript.new()
	strict.advance(2.75)
	var valid_midroute: Dictionary = strict.snapshot()
	var restored = PatrolStateScript.new()
	_expect_true(restored.restore(valid_midroute), "合法路线中段快照可以严格恢复")
	_expect_equal(restored.snapshot(), valid_midroute, "巡路恢复逐字段保持中段进度")
	var before_invalid: Dictionary = restored.snapshot()
	var missing_field := valid_midroute.duplicate(true)
	missing_field.erase("target_index")
	_expect_false(restored.restore(missing_field), "巡路恢复拒绝缺失字段")
	var invalid_cases := [
		{"key": "position_x", "value": NAN, "label": "非有限横坐标"},
		{"key": "position_y", "value": INF, "label": "非有限纵坐标"},
		{"key": "target_index", "value": 1.5, "label": "小数目标路点"},
		{"key": "target_index", "value": PatrolStateScript.WAYPOINTS.size(), "label": "越界目标路点"},
		{"key": "route_step", "value": 0, "label": "零路线方向"},
		{"key": "dwell_remaining", "value": -0.01, "label": "负停留余量"},
		{"key": "dwell_remaining", "value": PatrolStateScript.ENDPOINT_DWELL_SECONDS + 0.01, "label": "超限停留余量"},
		{"key": "yielding_to_player", "value": 1, "label": "非布尔让路标记"},
	]
	for invalid_case in invalid_cases:
		var invalid_snapshot := valid_midroute.duplicate(true)
		invalid_snapshot[invalid_case["key"]] = invalid_case["value"]
		_expect_false(restored.restore(invalid_snapshot), "%s被巡路恢复严格拒绝" % invalid_case["label"])
		_expect_equal(restored.snapshot(), before_invalid, "%s不会部分修改巡路状态" % invalid_case["label"])
	var off_route := valid_midroute.duplicate(true)
	off_route["position_x"] = 0.50
	off_route["position_y"] = 0.50
	_expect_false(restored.restore(off_route), "不在巡路折线上的坐标被拒绝")
	var unreachable_target := valid_midroute.duplicate(true)
	unreachable_target["target_index"] = PatrolStateScript.HERBS_WAYPOINT
	_expect_false(restored.restore(unreachable_target), "无法从当前线段抵达的目标路点被拒绝")
	var impossible_midroute_dwell := valid_midroute.duplicate(true)
	impossible_midroute_dwell["dwell_remaining"] = 0.1
	_expect_false(restored.restore(impossible_midroute_dwell), "路线中段不能伪造到站停留")
	var inconsistent_direction := valid_midroute.duplicate(true)
	inconsistent_direction["route_step"] = -1
	_expect_false(restored.restore(inconsistent_direction), "目标与折返方向不一致的快照被拒绝")
	var excessive_middle_dwell := {
		"position_x": PatrolStateScript.WAYPOINTS[1].x,
		"position_y": PatrolStateScript.WAYPOINTS[1].y,
		"target_index": 2,
		"route_step": 1,
		"dwell_remaining": PatrolStateScript.WAYPOINT_DWELL_SECONDS + 0.01,
		"yielding_to_player": false,
	}
	_expect_false(restored.restore(excessive_middle_dwell), "中间路点不能伪造端点级停留")
	_expect_equal(restored.snapshot(), before_invalid, "全部非法路线快照保持恢复原子性")

	var segment_position: Vector2 = PatrolStateScript.WAYPOINTS[1].lerp(PatrolStateScript.WAYPOINTS[2], 0.5)
	var priority_snapshot := {
		"position_x": segment_position.x,
		"position_y": segment_position.y,
		"target_index": 2,
		"route_step": 1,
		"dwell_remaining": 0.0,
		"yielding_to_player": false,
	}
	var boat_first = PatrolStateScript.new()
	_expect_true(boat_first.restore(priority_snapshot), "船架优先测试从合法路线中段开始")
	_expect_true(boat_first.apply_priority("boat_first"), "木楔优先把当前巡路转向船架")
	_expect_equal(boat_first.target_index, 1, "木楔优先先回到当前线段西端")
	_expect_equal(boat_first.route_step, -1, "木楔优先使用向西路线方向")
	_expect_true(boat_first.motion_direction().dot((PatrolStateScript.WAYPOINTS[1] - segment_position).normalized()) > 0.999, "木楔优先运动朝船架一侧")
	var boat_distance_before: float = boat_first.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT])
	boat_first.advance(0.2)
	_expect_true(boat_first.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT]) < boat_distance_before, "木楔优先的首次位移确实接近补船端点")
	var herbs_first = PatrolStateScript.new()
	_expect_true(herbs_first.restore(priority_snapshot), "药叶优先测试复用同一合法路线中段")
	_expect_true(herbs_first.apply_priority("herbs_first"), "药叶优先把当前巡路转向竹架")
	_expect_equal(herbs_first.target_index, 2, "药叶优先先到当前线段东端")
	_expect_equal(herbs_first.route_step, 1, "药叶优先使用向东路线方向")
	_expect_true(herbs_first.motion_direction().dot((PatrolStateScript.WAYPOINTS[2] - segment_position).normalized()) > 0.999, "药叶优先运动朝竹架一侧")
	var herbs_distance_before: float = herbs_first.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT])
	herbs_first.advance(0.2)
	_expect_true(herbs_first.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT]) < herbs_distance_before, "药叶优先的首次位移确实接近晾晒端点")
	var before_unknown_priority := herbs_first.snapshot()
	_expect_false(herbs_first.apply_priority("licensed_route"), "未知巡路先后被原子拒绝")
	_expect_equal(herbs_first.snapshot(), before_unknown_priority, "非法巡路先后不改变运动状态")
	_expect_equal(herbs_first.interaction_action(herbs_first.position + Vector2(0.06, 0.0), "unanswered"), "talk_to_patrol_runner", "未回应且近距离时提供陶小满交谈")
	_expect_equal(herbs_first.interaction_action(herbs_first.position + Vector2(0.07, 0.0), "unanswered"), "", "交互半径外不远程开启巡路对话")
	_expect_equal(herbs_first.interaction_action(herbs_first.position, "boat_first"), "", "已有选择后巡路对话不重复出现")
	_expect_equal(herbs_first.interaction_action(herbs_first.position, "unanswered", false), "", "未激活巡路人时不伪造交互")


func _test_patrol_endpoint_work() -> void:
	var endpoint_cases := [
		{
			"worksite_id": PatrolStateScript.WORKSITE_BOAT,
			"action_id": PatrolStateScript.TALK_AT_BOAT_WORKSITE,
			"position": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT],
		},
		{
			"worksite_id": PatrolStateScript.WORKSITE_HERBS,
			"action_id": PatrolStateScript.TALK_AT_HERBS_WORKSITE,
			"position": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT],
		},
	]
	var route_cases := [
		{"response": PatrolStateScript.RESPONSE_BOAT_FIRST, "priority": PatrolStateScript.WORKSITE_BOAT},
		{"response": PatrolStateScript.RESPONSE_HERBS_FIRST, "priority": PatrolStateScript.WORKSITE_HERBS},
	]
	for route_case in route_cases:
		for endpoint_case in endpoint_cases:
			var patrol = PatrolStateScript.new()
			var worksite_id: String = endpoint_case["worksite_id"]
			var action_id: String = endpoint_case["action_id"]
			var response_id: String = route_case["response"]
			_expect_true(patrol.restore(_patrol_endpoint_snapshot(worksite_id)), "%s 路线的 %s 工作点可恢复" % [response_id, worksite_id])
			var expected_role := "priority" if worksite_id == route_case["priority"] else "followup"
			_expect_equal(patrol.worksite_context(response_id), {
				"worksite_id": worksite_id,
				"action_id": action_id,
				"route_role": expected_role,
			}, "%s×%s 精确映射工作点、行动与先后角色" % [response_id, worksite_id])
			_expect_equal(patrol.interaction_action(endpoint_case["position"], response_id), action_id, "%s×%s 近距提供端点交谈" % [response_id, worksite_id])
			_expect_equal(
				patrol.interaction_action(endpoint_case["position"] + Vector2(PatrolStateScript.INTERACTION_RADIUS + 0.001, 0.0), response_id),
				"",
				"%s×%s 半径外不提供远程端点交谈" % [response_id, worksite_id]
			)
			var before_wrong_finish: Dictionary = patrol.snapshot()
			var wrong_worksite := PatrolStateScript.WORKSITE_HERBS if worksite_id == PatrolStateScript.WORKSITE_BOAT else PatrolStateScript.WORKSITE_BOAT
			_expect_false(patrol.finish_worksite(wrong_worksite), "%s 工作点拒绝结束另一端停留" % worksite_id)
			_expect_equal(patrol.snapshot(), before_wrong_finish, "错误工作点结束保持巡路快照原子不变")
			_expect_true(patrol.finish_worksite(worksite_id), "%s 工作点选择后可结束当前停留" % worksite_id)
			var after_finish: Dictionary = patrol.snapshot()
			_expect_equal(after_finish["dwell_remaining"], 0.0, "结束 %s 工作点只清零停留余量" % worksite_id)
			for key in before_wrong_finish:
				if key != "dwell_remaining":
					_expect_equal(after_finish[key], before_wrong_finish[key], "结束 %s 工作点不修改 %s" % [worksite_id, key])
			_expect_equal(patrol.worksite_context(response_id), {}, "停留结束后 %s 工作点上下文立即失效" % worksite_id)
			_expect_equal(patrol.interaction_action(endpoint_case["position"], response_id), "", "停留结束后 %s 不重复开启工作点对话" % worksite_id)
			_expect_false(patrol.finish_worksite(worksite_id), "%s 停留不能重复结束" % worksite_id)

	var no_route = PatrolStateScript.new()
	_expect_true(no_route.restore(_patrol_endpoint_snapshot(PatrolStateScript.WORKSITE_BOAT)), "未选路线端点夹具合法")
	_expect_equal(no_route.worksite_context(PatrolStateScript.RESPONSE_UNANSWERED), {}, "未选路线不伪造工作点上下文")
	_expect_equal(
		no_route.interaction_action(no_route.position, PatrolStateScript.RESPONSE_UNANSWERED),
		PatrolStateScript.TALK_TO_PATROL_RUNNER,
		"未选路线时端点近距仍只提供初次巡路委托"
	)
	_expect_equal(no_route.interaction_action(Vector2(NAN, no_route.position.y), PatrolStateScript.RESPONSE_UNANSWERED), "", "非有限玩家坐标不能伪造巡路交互")
	var zero_dwell = PatrolStateScript.new()
	_expect_true(zero_dwell.restore(_patrol_endpoint_snapshot(PatrolStateScript.WORKSITE_BOAT, 0.0)), "零停留端点仍是合法移动起点")
	_expect_equal(zero_dwell.worksite_context(PatrolStateScript.RESPONSE_BOAT_FIRST), {}, "精确端点但无停留时不伪造工作点")
	_expect_false(zero_dwell.finish_worksite(PatrolStateScript.WORKSITE_BOAT), "零停留端点不能重复完成工作")
	var midroute = PatrolStateScript.new()
	var midroute_snapshot := PatrolStateScript.default_snapshot()
	midroute_snapshot["dwell_remaining"] = 0.0
	_expect_true(midroute.restore(midroute_snapshot), "路线中段端点否定夹具合法")
	_expect_equal(midroute.worksite_context(PatrolStateScript.RESPONSE_BOAT_FIRST), {}, "路线中段不会只凭已选路线伪造工作点")

	for route_case in route_cases:
		var response_id: String = route_case["response"]
		var target_worksite: String = route_case["priority"]
		var target_position := (
			PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT]
			if target_worksite == PatrolStateScript.WORKSITE_BOAT
			else PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT]
		)
		var waiting = PatrolStateScript.new()
		_expect_true(waiting.apply_priority(response_id), "%s 等候测试先应用路线选择" % response_id)
		waiting.advance(30.0, target_position, response_id)
		_expect_true(waiting.position.distance_to(target_position) <= PatrolStateScript.POSITION_EPSILON, "玩家守候 %s 时陶小满仍先抵达端点" % target_worksite)
		_expect_true(waiting.dwell_remaining > 0.0, "抵达 %s 后保留可交互停留窗口" % target_worksite)
		_expect_true(waiting.yielding_to_player, "抵达 %s 后近距玩家冻结陶小满" % target_worksite)
		_expect_false(waiting.worksite_context(response_id).is_empty(), "抵达 %s 后立即产生工作点上下文" % target_worksite)
		var frozen_snapshot: Dictionary = waiting.snapshot()
		waiting.advance(30.0, target_position, response_id)
		_expect_equal(waiting.snapshot(), frozen_snapshot, "玩家继续守候 %s 时大增量也不吞掉停留窗口" % target_worksite)
		var finished_while_near = PatrolStateScript.new()
		_expect_true(finished_while_near.restore(frozen_snapshot), "%s 近距回应夹具恢复到站状态" % target_worksite)
		_expect_true(finished_while_near.finish_worksite(target_worksite), "%s 近距回应可原子结束停留" % target_worksite)
		_expect_true(finished_while_near.yielding_to_player, "%s 回应只结束停留并保留礼让状态" % target_worksite)
		_expect_false(finished_while_near.is_moving(), "%s 回应后玩家仍近时保持 idle 而不原地走路" % target_worksite)
		var finished_near_position: Vector2 = finished_while_near.position
		finished_while_near.advance(0.1, target_position, response_id)
		_expect_equal(finished_while_near.position, finished_near_position, "%s 回应后近距玩家继续冻结位置" % target_worksite)
		finished_while_near.advance(0.1, target_position + Vector2(PatrolStateScript.YIELD_EXIT_RADIUS + 0.001, 0.0), response_id)
		_expect_false(finished_while_near.yielding_to_player, "%s 回应后玩家离开十分路宽才解除礼让" % target_worksite)
		_expect_true(finished_while_near.is_moving(), "%s 回应后玩家离开才恢复移动动画合同" % target_worksite)
		_expect_true(finished_while_near.position.distance_to(finished_near_position) > 0.0, "%s 回应后玩家离开才恢复路线位移" % target_worksite)
		waiting.advance(0.1, Vector2(-1.0, -1.0), response_id)
		_expect_false(waiting.yielding_to_player, "玩家离开 %s 后解除让路" % target_worksite)
		_expect_true(waiting.dwell_remaining < float(frozen_snapshot["dwell_remaining"]), "玩家离开 %s 后停留计时恢复" % target_worksite)

		var sliced = PatrolStateScript.new()
		_expect_true(sliced.apply_priority(response_id), "%s 切片测试应用同一路线" % response_id)
		for _step in range(300):
			sliced.advance(PatrolStateScript.MAX_STEP_SECONDS, target_position, response_id)
		_expect_true(sliced.position.distance_to(target_position) <= PatrolStateScript.POSITION_EPSILON, "%s 大步与固定切片都抵达目标端点" % response_id)
		_expect_equal(sliced.target_index, frozen_snapshot["target_index"], "%s 大步与固定切片保持相同后续目标" % response_id)
		_expect_equal(sliced.route_step, frozen_snapshot["route_step"], "%s 大步与固定切片保持相同折返方向" % response_id)
		_expect_true(absf(sliced.dwell_remaining - float(frozen_snapshot["dwell_remaining"])) <= PatrolStateScript.POSITION_EPSILON * 4.0, "%s 大步与固定切片保持相同端点停留" % response_id)
		_expect_true(sliced.yielding_to_player, "%s 固定切片同样在到站后礼让玩家" % response_id)

	var selected_courtesy = PatrolStateScript.new()
	var selected_moving_snapshot := PatrolStateScript.default_snapshot()
	selected_moving_snapshot["dwell_remaining"] = 0.0
	_expect_true(selected_courtesy.restore(selected_moving_snapshot), "已选路线礼让测试恢复合法中段")
	var selected_origin: Vector2 = selected_courtesy.position
	selected_courtesy.advance(1.0, selected_origin + Vector2(0.02, 0.0), PatrolStateScript.RESPONSE_BOAT_FIRST)
	_expect_true(selected_courtesy.yielding_to_player, "已选路线在非目标端点仍按每个固定步长礼让近距玩家")
	_expect_equal(selected_courtesy.position, selected_origin, "普通近距礼让不会被端点守候例外误穿透")


func _test_path_keeper_state() -> void:
	var initial = PathKeeperStateScript.new()
	_expect_equal(initial.snapshot(), PathKeeperStateScript.default_snapshot(), "守径状态从唯一默认快照开始")
	_expect_equal(initial.position, PathKeeperStateScript.START_POSITION, "岑苇从山道入口侧端点开始巡看")
	_expect_equal(initial.target_index, PathKeeperStateScript.START_TARGET_INDEX, "守径默认目标指向相邻路点")
	_expect_equal(initial.route_step, PathKeeperStateScript.START_ROUTE_STEP, "守径默认沿正向路点推进")
	var runtime: Dictionary = initial.runtime_contract()
	_expect_equal(runtime["route_points"], PathKeeperStateScript.WAYPOINTS, "守径合同公开四个有序路点")
	_expect_false(runtime["collision_authority"], "守径状态不建立第二套碰撞权威")
	_expect_false(runtime["quest_authority"], "守径状态不建立第二套任务权威")
	_expect_false(runtime["battle_authority"], "守径状态不改变战斗权威")
	_expect_false(runtime["reward_authority"], "守径状态不发放隐藏奖励")
	_expect_true(runtime["persistent"], "守径状态明确进入持久化合同")
	var path = ExplorationStateScript.new()
	_expect_true(path.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID), "守径路线测试进入山道碰撞上下文")
	for waypoint in PathKeeperStateScript.WAYPOINTS:
		_expect_true(path.is_walkable(waypoint), "岑苇路点位于玩家可公开行走的山道路面")
	for index in range(PathKeeperStateScript.WAYPOINTS.size() - 1):
		for sample_index in range(21):
			var sample: Vector2 = PathKeeperStateScript.WAYPOINTS[index].lerp(
				PathKeeperStateScript.WAYPOINTS[index + 1],
				float(sample_index) / 20.0
			)
			_expect_true(path.is_walkable(sample), "岑苇相邻路点之间不穿越山道障碍")

	var start: Vector2 = initial.position
	_expect_equal(initial.advance(0.75), start, "守径端点停留前半段不提前滑动")
	_expect_true(is_equal_approx(initial.dwell_remaining, 0.75), "守径端点停留按确定增量消耗")
	_expect_equal(initial.advance(0.75), start, "完整端点停留保持原位便于玩家发现")
	initial.advance(0.40)
	_expect_true(initial.position.distance_to(start) > 0.0, "守径停留结束后沿公开路线移动")
	_expect_true(initial.is_moving(), "守径路线位移公开移动动画状态")
	_expect_equal(initial.motion_direction().sign(), (PathKeeperStateScript.WAYPOINTS[1] - start).normalized().sign(), "守径朝向由当前目标路点推导")

	var whole_delta = PathKeeperStateScript.new()
	var sliced_delta = PathKeeperStateScript.new()
	whole_delta.advance(15.75)
	for _step in range(315):
		sliced_delta.advance(0.05)
	_expect_true(whole_delta.position.distance_to(sliced_delta.position) <= PathKeeperStateScript.POSITION_EPSILON, "守径大步与小切片得到同一位置")
	_expect_equal(whole_delta.target_index, sliced_delta.target_index, "守径切片方式不改变目标路点")
	_expect_equal(whole_delta.route_step, sliced_delta.route_step, "守径切片方式不改变折返方向")
	_expect_true(
		absf(whole_delta.dwell_remaining - sliced_delta.dwell_remaining) <= PathKeeperStateScript.POSITION_EPSILON * 4.0,
		"守径切片方式不改变停留余量"
	)
	var repeated_delta = PathKeeperStateScript.new()
	repeated_delta.advance(15.75)
	_expect_equal(repeated_delta.snapshot(), whole_delta.snapshot(), "相同守径初态与增量逐字段复现")
	var reversed = PathKeeperStateScript.new()
	reversed.advance(7.0)
	_expect_equal(reversed.position, PathKeeperStateScript.WAYPOINTS[3], "守径人会抵达山道另一端")
	_expect_equal(reversed.route_step, -1, "守径人在末端确定折返")
	_expect_equal(reversed.target_index, 2, "守径末端停留预先指向相邻返程路点")
	reversed.advance(1.0)
	_expect_equal(reversed.route_step, -1, "守径人离开末端后保持反向路线")
	_expect_true(
		reversed.position.distance_to(PathKeeperStateScript.WAYPOINTS[3]) > PathKeeperStateScript.POSITION_EPSILON
		and reversed.position.distance_to(PathKeeperStateScript.WAYPOINTS[2]) > PathKeeperStateScript.POSITION_EPSILON,
		"守径人可处于反向路线中段"
	)
	var reverse_midroute: Dictionary = reversed.snapshot()
	var reverse_restored = PathKeeperStateScript.new()
	_expect_true(reverse_restored.restore(reverse_midroute), "合法反向中段守径快照可以严格恢复")
	_expect_equal(reverse_restored.snapshot(), reverse_midroute, "反向中段恢复逐字段保留位置与目标")
	reversed.advance(0.42)
	reverse_restored.advance(0.42)
	_expect_equal(reverse_restored.snapshot(), reversed.snapshot(), "反向中段恢复后继续巡路逐字段一致")
	var invalid_reverse_target := reverse_midroute.duplicate(true)
	invalid_reverse_target["target_index"] = 3
	_expect_false(reverse_restored.restore(invalid_reverse_target), "反向中段拒绝与方向不符的目标路点")

	var yielding = PathKeeperStateScript.new()
	var moving_snapshot := PathKeeperStateScript.default_snapshot()
	moving_snapshot["dwell_remaining"] = 0.0
	_expect_true(yielding.restore(moving_snapshot), "守径礼让测试恢复合法移动快照")
	var yield_origin: Vector2 = yielding.position
	yielding.advance(0.2, yield_origin + Vector2(0.079, 0.0))
	_expect_true(yielding.yielding_to_player, "玩家进入八分路宽时岑苇确定礼让")
	_expect_equal(yielding.position, yield_origin, "守径礼让期间位置保持不变")
	yielding.advance(0.2, yield_origin + Vector2(0.09, 0.0))
	_expect_true(yielding.yielding_to_player, "守径迟滞带避免反复启停")
	yielding.advance(0.2, yield_origin + Vector2(0.101, 0.0))
	_expect_false(yielding.yielding_to_player, "玩家退出十分路宽后守径恢复")
	_expect_true(yielding.position.distance_to(yield_origin) > 0.0, "解除礼让的同一增量恢复守径位移")
	var coarse_yield = PathKeeperStateScript.new()
	var sliced_yield = PathKeeperStateScript.new()
	_expect_true(coarse_yield.restore(moving_snapshot), "粗切片礼让测试恢复合法移动快照")
	_expect_true(sliced_yield.restore(moving_snapshot), "细切片礼让测试恢复同一移动快照")
	var stationary_player: Vector2 = PathKeeperStateScript.WAYPOINTS[1]
	coarse_yield.advance(1.0, stationary_player)
	for _step in range(40):
		sliced_yield.advance(0.025, stationary_player)
	_expect_true(coarse_yield.yielding_to_player and sliced_yield.yielding_to_player, "粗细时间切片都在同一礼让边界停步")
	_expect_true(
		coarse_yield.position.distance_to(sliced_yield.position) <= PathKeeperStateScript.POSITION_EPSILON,
		"同一静止玩家与总时间不因帧切片写入不同守径坐标"
	)
	_expect_true(
		absf(coarse_yield.position.distance_to(stationary_player) - PathKeeperStateScript.YIELD_ENTER_RADIUS)
		<= PathKeeperStateScript.POSITION_EPSILON,
		"岑苇精确停在礼让进入边界而不按下一帧过冲"
	)
	_expect_equal(yielding.interaction_action(yielding.position), PathKeeperStateScript.TALK_TO_PATH_KEEPER, "近距离提供稳定守径交谈行动")
	_expect_equal(yielding.interaction_action(yielding.position + Vector2(0.066, 0.0)), "", "交互半径外不远程开启守径对话")
	_expect_equal(yielding.interaction_action(yielding.position, false), "", "未激活守径人时不伪造交互")
	_expect_equal(yielding.interaction_action(Vector2(NAN, yielding.position.y)), "", "非有限玩家坐标不能伪造守径交互")

	var strict = PathKeeperStateScript.new()
	strict.advance(2.4)
	var valid_midroute: Dictionary = strict.snapshot()
	var restored = PathKeeperStateScript.new()
	_expect_true(restored.restore(valid_midroute), "合法守径中段快照可以严格恢复")
	_expect_equal(restored.snapshot(), valid_midroute, "守径恢复逐字段保持中段进度")
	var before_invalid: Dictionary = restored.snapshot()
	var missing_field := valid_midroute.duplicate(true)
	missing_field.erase("target_index")
	_expect_false(restored.restore(missing_field), "守径恢复拒绝缺失字段")
	var invalid_cases := [
		{"key": "position_x", "value": NAN, "label": "非有限横坐标"},
		{"key": "position_y", "value": INF, "label": "非有限纵坐标"},
		{"key": "target_index", "value": 1.5, "label": "小数目标路点"},
		{"key": "target_index", "value": PathKeeperStateScript.WAYPOINTS.size(), "label": "越界目标路点"},
		{"key": "route_step", "value": 0, "label": "零路线方向"},
		{"key": "dwell_remaining", "value": -0.01, "label": "负停留余量"},
		{"key": "dwell_remaining", "value": PathKeeperStateScript.ENDPOINT_DWELL_SECONDS + 0.01, "label": "超限停留余量"},
		{"key": "yielding_to_player", "value": 1, "label": "非布尔礼让标记"},
	]
	for invalid_case in invalid_cases:
		var invalid_snapshot := valid_midroute.duplicate(true)
		invalid_snapshot[invalid_case["key"]] = invalid_case["value"]
		_expect_false(restored.restore(invalid_snapshot), "%s被守径恢复严格拒绝" % invalid_case["label"])
		_expect_equal(restored.snapshot(), before_invalid, "%s不会部分修改守径状态" % invalid_case["label"])
	var off_route := valid_midroute.duplicate(true)
	off_route["position_x"] = 0.50
	off_route["position_y"] = 0.50
	_expect_false(restored.restore(off_route), "不在守径折线上的坐标被拒绝")
	var unreachable_target := valid_midroute.duplicate(true)
	unreachable_target["target_index"] = 3
	_expect_false(restored.restore(unreachable_target), "无法从当前守径线段抵达的目标被拒绝")
	var impossible_midroute_dwell := valid_midroute.duplicate(true)
	impossible_midroute_dwell["dwell_remaining"] = 0.1
	_expect_false(restored.restore(impossible_midroute_dwell), "守径路线中段不能伪造到站停留")
	var excessive_middle_dwell := {
		"position_x": PathKeeperStateScript.WAYPOINTS[1].x,
		"position_y": PathKeeperStateScript.WAYPOINTS[1].y,
		"target_index": 2,
		"route_step": 1,
		"dwell_remaining": PathKeeperStateScript.WAYPOINT_DWELL_SECONDS + 0.01,
		"yielding_to_player": false,
	}
	_expect_false(restored.restore(excessive_middle_dwell), "守径中间路点不能伪造端点级停留")
	_expect_equal(restored.snapshot(), before_invalid, "全部非法守径快照保持恢复原子性")
	var before_bad_delta: Dictionary = restored.snapshot()
	restored.advance(NAN)
	restored.advance(INF)
	restored.advance(-1.0)
	_expect_equal(restored.snapshot(), before_bad_delta, "非法守径时间增量不改变状态")
	restored.reset()
	_expect_equal(restored.snapshot(), PathKeeperStateScript.default_snapshot(), "守径重置返回唯一默认快照")


func _test_path_keeper_echoes() -> void:
	var route_checked = _path_keeper_ready_journey()

	var spoor_noted = _path_keeper_ready_journey()
	spoor_noted.choose(JourneyStateScript.INSPECT_ROCK_SPOOR)

	var basket_found = _path_keeper_ready_journey()
	basket_found.choose(JourneyStateScript.INSPECT_MOSS_SPOOR)
	basket_found.choose(JourneyStateScript.INSPECT_ABANDONED_BASKET)

	var basket_returned = _path_keeper_ready_journey()
	basket_returned.choose(JourneyStateScript.INSPECT_ABANDONED_BASKET)
	basket_returned.choose(JourneyStateScript.RETURN_TO_FERRY)
	basket_returned.complete_basket_dialogue(JourneyStateScript.BASKET_RETURN)
	basket_returned.choose(JourneyStateScript.ENTER_SPRING)

	var basket_left = _path_keeper_ready_journey()
	basket_left.choose(JourneyStateScript.INSPECT_ABANDONED_BASKET)
	basket_left.choose(JourneyStateScript.RETURN_TO_FERRY)
	basket_left.complete_basket_dialogue(JourneyStateScript.BASKET_TRAIL)
	basket_left.choose(JourneyStateScript.ENTER_SPRING)

	var after_setback = _path_keeper_ready_journey()
	after_setback.choose(JourneyStateScript.INSPECT_ABANDONED_BASKET)
	after_setback.choose(JourneyStateScript.RETURN_TO_FERRY)
	after_setback.complete_basket_dialogue(JourneyStateScript.BASKET_RETURN)
	after_setback.choose(JourneyStateScript.ENTER_SPRING)
	after_setback.choose(JourneyStateScript.APPROACH_ENEMY)
	after_setback.choose(JourneyStateScript.RETREAT)

	var cases := [
		{"journey": route_checked, "event": "path_keeper_route_checked", "label": "初见路签"},
		{"journey": spoor_noted, "event": "path_keeper_spoor_noted", "label": "已辨敌迹"},
		{"journey": basket_found, "event": "path_keeper_basket_found", "label": "发现公用药篓"},
		{"journey": basket_returned, "event": "path_keeper_basket_returned", "label": "药篓归圃"},
		{"journey": basket_left, "event": "path_keeper_basket_left", "label": "药篓留山"},
		{"journey": after_setback, "event": "path_keeper_after_setback", "label": "战斗撤退"},
	]
	for echo_case in cases:
		var journey = echo_case["journey"]
		_expect_true(
			journey.available_actions().has(JourneyStateScript.TALK_TO_PATH_KEEPER),
			"%s阶段公开岑苇近距语义行动" % echo_case["label"]
		)
		var before: Dictionary = journey.snapshot()
		var result: Dictionary = journey.choose(JourneyStateScript.TALK_TO_PATH_KEEPER)
		_expect_true(result["ok"], "%s岑苇回声可重复触发" % echo_case["label"])
		_expect_equal(result["events"], [echo_case["event"]], "%s选择唯一进度回声" % echo_case["label"])
		_expect_equal(journey.snapshot(), before, "%s岑苇回声不修改完整 Journey 快照" % echo_case["label"])
		var repeated: Dictionary = journey.choose(JourneyStateScript.TALK_TO_PATH_KEEPER)
		_expect_equal(repeated["events"], result["events"], "%s重复询问保持确定结果" % echo_case["label"])
		_expect_equal(journey.snapshot(), before, "%s重复询问仍无任务、战斗或奖励权威" % echo_case["label"])


func _path_keeper_ready_journey():
	var journey = JourneyStateScript.new()
	journey.complete_companion_briefing(JourneyStateScript.RESPONSE_CAREFUL)
	journey.choose(JourneyStateScript.GATHER_MOONLEAF)
	journey.choose(JourneyStateScript.ENTER_SPRING)
	return journey


func _test_life_landmark_observations() -> void:
	var ferry_state = JourneyStateScript.new()
	var ferry_before: Dictionary = ferry_state.snapshot()
	var ferry_cases := [
		{"action": JourneyStateScript.INSPECT_BOAT_REPAIR, "event": "boat_repair_inspected", "label": "补船木架"},
		{"action": JourneyStateScript.INSPECT_DRYING_RACK, "event": "drying_rack_inspected", "label": "晾晒竹架"},
	]
	for landmark_case in ferry_cases:
		var action_id: String = landmark_case["action"]
		_expect_true(ferry_state.available_actions().has(action_id), "%s观察在渡口阶段可用" % landmark_case["label"])
		for repeat_index in range(2):
			var observation: Dictionary = ferry_state.choose(action_id)
			_expect_true(observation["ok"], "%s第%d次观察成功" % [landmark_case["label"], repeat_index + 1])
			_expect_equal(observation["events"], [landmark_case["event"]], "%s重复返回稳定语义事件" % landmark_case["label"])
			_expect_equal(observation["snapshot"], ferry_before, "%s观察结果不产生持久快照字段" % landmark_case["label"])
			_expect_equal(ferry_state.snapshot(), ferry_before, "%s观察不暗中改变旅程状态" % landmark_case["label"])
		_expect_true(ferry_state.available_actions().has(action_id), "%s重复观察后仍保留可用行动" % landmark_case["label"])
	var before_wrong_rain: Dictionary = ferry_state.snapshot()
	var wrong_rain: Dictionary = ferry_state.choose(JourneyStateScript.INSPECT_RAIN_SHELTER)
	_expect_false(wrong_rain["ok"], "渡口阶段不能远程查看山道避雨石棚")
	_expect_equal(wrong_rain["events"], ["invalid_action"], "错地图生活观察返回稳定非法行动事件")
	_expect_equal(ferry_state.snapshot(), before_wrong_rain, "错地图生活观察原子拒绝")

	var path_state = JourneyStateScript.new()
	path_state.choose(JourneyStateScript.TALK_TO_COMPANION)
	path_state.choose(JourneyStateScript.GATHER_MOONLEAF)
	path_state.choose(JourneyStateScript.ENTER_SPRING)
	var path_before: Dictionary = path_state.snapshot()
	_expect_true(path_state.available_actions().has(JourneyStateScript.INSPECT_RAIN_SHELTER), "山道阶段提供可重复避雨石棚观察")
	for repeat_index in range(2):
		var shelter_observation: Dictionary = path_state.choose(JourneyStateScript.INSPECT_RAIN_SHELTER)
		_expect_true(shelter_observation["ok"], "避雨石棚第%d次观察成功" % [repeat_index + 1])
		_expect_equal(shelter_observation["events"], ["rain_shelter_inspected"], "避雨石棚重复返回稳定语义事件")
		_expect_equal(shelter_observation["snapshot"], path_before, "避雨石棚观察结果不产生持久快照字段")
		_expect_equal(path_state.snapshot(), path_before, "避雨石棚观察不暗中改变旅程状态")
	_expect_true(path_state.available_actions().has(JourneyStateScript.INSPECT_RAIN_SHELTER), "避雨石棚重复观察后仍保留可用行动")
	for ferry_action in [JourneyStateScript.INSPECT_BOAT_REPAIR, JourneyStateScript.INSPECT_DRYING_RACK]:
		var wrong_ferry_observation: Dictionary = path_state.choose(ferry_action)
		_expect_false(wrong_ferry_observation["ok"], "山道阶段不能远程触发渡口生活观察")
		_expect_equal(path_state.snapshot(), path_before, "山道错地图生活观察原子拒绝")
	_expect_true(path_state.choose(JourneyStateScript.BYPASS_ENEMY)["ok"], "生活观察测试可建立泉室错误阶段")
	var spring_before: Dictionary = path_state.snapshot()
	for landmark_action in [
		JourneyStateScript.INSPECT_BOAT_REPAIR,
		JourneyStateScript.INSPECT_DRYING_RACK,
		JourneyStateScript.INSPECT_RAIN_SHELTER,
	]:
		var spring_observation: Dictionary = path_state.choose(landmark_action)
		_expect_false(spring_observation["ok"], "泉室阶段拒绝地图生活观察")
		_expect_equal(path_state.snapshot(), spring_before, "泉室阶段生活观察原子拒绝")

	_expect_equal(ExplorationStateScript.BOAT_REPAIR_POSITION, Vector2(0.38, 0.295), "补船木架使用稳定归一化坐标")
	_expect_equal(ExplorationStateScript.DRYING_RACK_POSITION, Vector2(0.92, 0.43), "晾晒竹架使用稳定归一化坐标")
	_expect_equal(ExplorationStateScript.PATH_RAIN_SHELTER_POSITION, Vector2(0.53, 0.67), "避雨石棚使用稳定归一化坐标")
	var ferry_exploration = ExplorationStateScript.new()
	var ferry_life_positions := [
		ExplorationStateScript.BOAT_REPAIR_POSITION,
		ExplorationStateScript.DRYING_RACK_POSITION,
	]
	var existing_ferry_positions := [
		ExplorationStateScript.START_POSITION,
		ExplorationStateScript.MOONLEAF_POSITION,
		ExplorationStateScript.SPRING_GATE_POSITION,
		ExplorationStateScript.COMPANION_POSITION,
		ExplorationStateScript.FERRY_WATERMARK_POSITION,
		ExplorationStateScript.FERRYMAN_POSITION,
		ExplorationStateScript.HERBKEEPER_POSITION,
	]
	for life_position in ferry_life_positions:
		_expect_true(ferry_exploration.is_walkable(life_position), "渡口生活地标锚点位于可行走区域")
		for existing_position in existing_ferry_positions:
			_expect_true(life_position.distance_to(existing_position) > ExplorationStateScript.INTERACTION_RADIUS * 2.0, "渡口生活地标不与既有交互半径重叠")
	_expect_true(
		ExplorationStateScript.BOAT_REPAIR_POSITION.distance_to(ExplorationStateScript.DRYING_RACK_POSITION) > ExplorationStateScript.INTERACTION_RADIUS * 2.0,
		"两个渡口生活地标交互半径彼此分离"
	)
	var boat_visual_feet := Vector2(0.38, 0.35)
	_expect_true(ferry_exploration.is_walkable(boat_visual_feet), "补船木架视觉脚点位于可行走地表")
	_expect_true(
		boat_visual_feet.distance_to(ExplorationStateScript.BOAT_REPAIR_POSITION) <= ExplorationStateScript.INTERACTION_RADIUS,
		"补船木架视觉脚点落在交互半径内"
	)
	_expect_true(ferry_exploration.restore({"map_id": "zhaohe_ferry", "player_x": boat_visual_feet.x, "player_y": boat_visual_feet.y}), "玩家可站到补船木架视觉脚点")
	_expect_equal(ferry_exploration.interaction_action(false, true), ExplorationStateScript.INSPECT_BOAT_REPAIR, "站在补船木架视觉脚点可直接查看")

	var path_exploration = ExplorationStateScript.new()
	_expect_true(path_exploration.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID), "生活地标测试可进入山道地图")
	_expect_true(path_exploration.is_walkable(ExplorationStateScript.PATH_RAIN_SHELTER_POSITION), "避雨石棚锚点位于可行走山道")
	var existing_path_positions := [
		ExplorationStateScript.PATH_RETURN_POSITION,
		ExplorationStateScript.PATH_MARKER_POSITION,
		ExplorationStateScript.PATH_SPRING_SEAM_POSITION,
		ExplorationStateScript.PATH_ABANDONED_BASKET_POSITION,
		ExplorationStateScript.PATH_ROCK_SPOOR_POSITION,
		ExplorationStateScript.PATH_MOSS_SPOOR_POSITION,
		ExplorationStateScript.PATH_PUPPET_SPOOR_POSITION,
		ExplorationStateScript.PATH_ENEMY_POSITION,
		ExplorationStateScript.PATH_MOSS_POSITION,
		ExplorationStateScript.PATH_PUPPET_POSITION,
		ExplorationStateScript.PATH_BYPASS_POSITION,
		ExplorationStateScript.PATH_RETREAT_POSITION,
	]
	for existing_position in existing_path_positions:
		_expect_true(
			ExplorationStateScript.PATH_RAIN_SHELTER_POSITION.distance_to(existing_position) > ExplorationStateScript.INTERACTION_RADIUS * 2.0,
			"避雨石棚不与既有山道交互半径重叠"
		)

	var boat_route = ExplorationStateScript.new()
	boat_route.move(Vector2.UP, 0.80)
	boat_route.move(Vector2.LEFT, 0.27)
	_expect_equal(boat_route.interaction_action(false, true), ExplorationStateScript.INSPECT_BOAT_REPAIR, "可从渡口出生点公开步行到补船木架")
	_expect_true(boat_route.player_position.distance_to(ExplorationStateScript.BOAT_REPAIR_POSITION) <= ExplorationStateScript.INTERACTION_RADIUS, "补船木架公开路线终点进入交互半径")
	var drying_route = ExplorationStateScript.new()
	drying_route.move(Vector2.UP, 1.17)
	drying_route.move(Vector2.RIGHT, 1.50)
	drying_route.move(Vector2.DOWN, 0.90)
	_expect_equal(drying_route.interaction_action(false, true), ExplorationStateScript.INSPECT_DRYING_RACK, "可从渡口出生点绕建筑公开步行到晾晒竹架")
	_expect_true(drying_route.player_position.distance_to(ExplorationStateScript.DRYING_RACK_POSITION) <= ExplorationStateScript.INTERACTION_RADIUS, "晾晒竹架公开路线终点进入交互半径")
	var shelter_route = ExplorationStateScript.new()
	_expect_true(shelter_route.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID), "避雨石棚路线从山道公开出生点开始")
	shelter_route.move(Vector2.UP, 0.20)
	shelter_route.move(Vector2.RIGHT, 1.24)
	shelter_route.move(Vector2.DOWN, 0.17)
	_expect_equal(shelter_route.interaction_action(true, true), ExplorationStateScript.INSPECT_RAIN_SHELTER, "可从山道出生点绕过坡石公开步行到避雨石棚")
	_expect_true(shelter_route.player_position.distance_to(ExplorationStateScript.PATH_RAIN_SHELTER_POSITION) <= ExplorationStateScript.INTERACTION_RADIUS, "避雨石棚公开路线终点进入交互半径")


func _test_state_restore() -> void:
	var source = _battle_state()
	source.choose("guard")
	var snapshot: Dictionary = source.snapshot()
	var restored = JourneyStateScript.new()
	_expect_true(restored.restore(snapshot), "规则状态可以从合法快照恢复")
	_expect_equal(restored.snapshot(), snapshot, "恢复后的规则状态逐字段一致")

	var before: Dictionary = restored.snapshot()
	var impossible := snapshot.duplicate(true)
	impossible["phase"] = "spring"
	_expect_false(restored.restore(impossible), "阶段不变量不成立时拒绝恢复")
	_expect_equal(restored.snapshot(), before, "无效规则快照不会部分修改状态")
	var fractional := snapshot.duplicate(true)
	fractional["player_hp"] = 10.5
	_expect_false(restored.restore(fractional), "规则整数值拒绝小数")
	var missing := snapshot.duplicate(true)
	missing.erase("realm")
	_expect_false(restored.restore(missing), "缺失规则字段时拒绝恢复")
	var response_mismatch := snapshot.duplicate(true)
	response_mismatch["briefing_response"] = "unanswered"
	_expect_false(restored.restore(response_mismatch), "已交谈状态不能恢复为未回应")
	var invalid_harvest := snapshot.duplicate(true)
	invalid_harvest["moonleaf_method"] = "burn_field"
	_expect_false(restored.restore(invalid_harvest), "未知采集方式不会进入规则层")
	var missing_harvest := snapshot.duplicate(true)
	missing_harvest["moonleaf_method"] = "unselected"
	_expect_false(restored.restore(missing_harvest), "持有灵草时不能恢复为未选择采集方式")
	var excessive_status := snapshot.duplicate(true)
	excessive_status["focus_turns"] = 3
	_expect_false(restored.restore(excessive_status), "持续状态层数拒绝超出规则上限")
	var inactive_status: Dictionary = JourneyStateScript.new().snapshot()
	inactive_status["armor_break_turns"] = 1
	_expect_false(restored.restore(inactive_status), "非战斗阶段不能保留破甲状态")
	var unknown_discovery: Dictionary = JourneyStateScript.new().snapshot()
	unknown_discovery["discoveries"] = ["licensed_secret"]
	_expect_false(restored.restore(unknown_discovery), "未知见闻标识被规则层拒绝")
	var duplicate_discovery: Dictionary = JourneyStateScript.new().snapshot()
	duplicate_discovery["discoveries"] = ["ferry_watermark", "ferry_watermark"]
	_expect_false(restored.restore(duplicate_discovery), "重复见闻标识不进入存档状态")
	var impossible_path_discovery: Dictionary = JourneyStateScript.new().snapshot()
	impossible_path_discovery["discoveries"] = ["spring_seam"]
	_expect_false(restored.restore(impossible_path_discovery), "未进山的初始状态不能伪造山道见闻")
	var invalid_ferryman: Dictionary = JourneyStateScript.new().snapshot()
	invalid_ferryman["ferryman_response"] = "take_money"
	_expect_false(restored.restore(invalid_ferryman), "未知守堤回应不能进入持久规则状态")
	var invalid_basket: Dictionary = JourneyStateScript.new().snapshot()
	invalid_basket["basket_response"] = "keep_private"
	_expect_false(restored.restore(invalid_basket), "未知药篓回应不能进入持久规则状态")
	var missing_patrol := snapshot.duplicate(true)
	missing_patrol.erase("patrol_response")
	_expect_false(restored.restore(missing_patrol), "当前规则快照缺少巡路回应时拒绝恢复")
	var invalid_patrol: Dictionary = JourneyStateScript.new().snapshot()
	invalid_patrol["patrol_response"] = "teleport_first"
	_expect_false(restored.restore(invalid_patrol), "未知巡路回应不能进入持久规则状态")
	var impossible_patrol: Dictionary = JourneyStateScript.new().snapshot()
	impossible_patrol["patrol_response"] = "boat_first"
	_expect_false(restored.restore(impossible_patrol), "同伴简报前不能伪造已决定的巡路先后")
	var impossible_basket: Dictionary = JourneyStateScript.new().snapshot()
	impossible_basket["basket_response"] = "return"
	_expect_false(restored.restore(impossible_basket), "没有发现公用印记时不能伪造药篓已安置")
	var missing_intel := snapshot.duplicate(true)
	missing_intel.erase("enemy_intel")
	_expect_false(restored.restore(missing_intel), "缺失敌情字段的当前规则快照被拒绝")
	var malformed_intel := snapshot.duplicate(true)
	malformed_intel["enemy_intel"] = "rock_armor_young"
	_expect_false(restored.restore(malformed_intel), "敌情必须是有序数组")
	var duplicate_intel := snapshot.duplicate(true)
	duplicate_intel["enemy_intel"] = ["rock_armor_young", "rock_armor_young"]
	_expect_false(restored.restore(duplicate_intel), "重复敌情标识不进入规则状态")
	var unknown_intel := snapshot.duplicate(true)
	unknown_intel["enemy_intel"] = ["licensed_enemy"]
	_expect_false(restored.restore(unknown_intel), "未知敌情标识不进入规则状态")
	var impossible_initial_intel := JourneyStateScript.new().snapshot()
	impossible_initial_intel["enemy_intel"] = ["rock_armor_young"]
	_expect_false(restored.restore(impossible_initial_intel), "未进山的初始状态不能伪造已调查敌情")
	var missing_first_breath := snapshot.duplicate(true)
	missing_first_breath.erase("first_breath_stage")
	_expect_false(restored.restore(missing_first_breath), "当前规则快照缺少引息仪轨阶段时拒绝恢复")
	var malformed_first_breath := snapshot.duplicate(true)
	malformed_first_breath["first_breath_stage"] = 1
	_expect_false(restored.restore(malformed_first_breath), "引息仪轨阶段必须使用稳定文本标识")
	var unknown_first_breath := snapshot.duplicate(true)
	unknown_first_breath["first_breath_stage"] = "licensed_breakthrough"
	_expect_false(restored.restore(unknown_first_breath), "未知引息仪轨阶段不会进入规则状态")
	var battle_with_breath_progress := snapshot.duplicate(true)
	battle_with_breath_progress["first_breath_stage"] = "listened"
	_expect_false(restored.restore(battle_with_breath_progress), "战斗阶段不能伪造泉室仪轨进度")
	var zero_hp_battle := snapshot.duplicate(true)
	zero_hp_battle["player_hp"] = 0
	_expect_false(restored.restore(zero_hp_battle), "战斗阶段拒绝零气血死档")
	_expect_equal(restored.snapshot(), before, "敌情、引息字段与气血的无效恢复不部分修改战斗状态")
	var spring_state = JourneyStateScript.new()
	spring_state.choose("talk_to_companion")
	spring_state.choose("gather_moonleaf")
	spring_state.choose("enter_spring")
	spring_state.choose("bypass_enemy")
	var impossible_completed_spring := spring_state.snapshot()
	impossible_completed_spring["first_breath_stage"] = "completed"
	_expect_false(restored.restore(impossible_completed_spring), "泉室进行态不能伪造已完成仪轨")
	var listened_without_moonleaf := spring_state.snapshot()
	listened_without_moonleaf["first_breath_stage"] = "listened"
	listened_without_moonleaf["gathered_moonleaf"] = false
	_expect_false(restored.restore(listened_without_moonleaf), "听泉后尚未温脉时必须仍持有月芽草")
	var warmed_with_moonleaf := spring_state.snapshot()
	warmed_with_moonleaf["first_breath_stage"] = "warmed"
	_expect_false(restored.restore(warmed_with_moonleaf), "温脉完成态不能仍持有已消耗月芽草")
	_expect_true(spring_state.choose("listen_to_spring")["ok"], "泉室合法听泉步骤可用于恢复校验")
	_expect_true(spring_state.choose("warm_meridians")["ok"], "泉室合法温脉步骤可用于恢复校验")
	_expect_true(restored.restore(spring_state.snapshot()), "已温脉且月芽草耗尽的泉室快照可以恢复")
	var restored_warmed_snapshot := restored.snapshot()
	var zero_hp_spring := spring_state.snapshot()
	zero_hp_spring["player_hp"] = 0
	_expect_false(restored.restore(zero_hp_spring), "泉室阶段拒绝零气血死档")
	spring_state.choose("breakthrough")
	var incomplete_complete := spring_state.snapshot()
	incomplete_complete["first_breath_stage"] = "warmed"
	_expect_false(restored.restore(incomplete_complete), "完成阶段必须记录完整的三步引息")
	var zero_hp_complete := spring_state.snapshot()
	zero_hp_complete["player_hp"] = 0
	_expect_false(restored.restore(zero_hp_complete), "完成阶段拒绝零气血死档")
	_expect_equal(restored.snapshot(), restored_warmed_snapshot, "后续无效泉室与完成态恢复保持当前规则状态原子不变")


func _test_dialogue_state() -> void:
	var state = DialogueStateScript.new()
	_expect_equal(state.snapshot(), DialogueStateScript.default_snapshot(), "对话初始快照为空闲态")
	_expect_false(state.start("unknown"), "未知对话不能启动")
	_expect_true(state.start("companion_briefing"), "可启动砚青简报")
	_expect_false(state.start("companion_briefing"), "活动对话不能重复启动")
	_expect_true(state.advance(7), "对话可逐句推进")
	_expect_equal(state.line_index, 1, "逐句推进记录稳定行号")
	_expect_true(state.skip_to_choices(7), "对话可快速显示到回应")
	_expect_true(state.at_choices(7), "末行之后进入回应状态")
	var snapshot := state.snapshot()
	var restored = DialogueStateScript.new()
	_expect_true(restored.restore(snapshot), "活动对话可从快照恢复")
	_expect_equal(restored.snapshot(), snapshot, "恢复保留对话与行号")
	_expect_true(restored.finish(), "回应后结束对话")
	_expect_false(restored.finish(), "空闲对话不能重复结束")
	_expect_true(restored.start("chapter_epilogue"), "完成态余波使用同一结构化对话状态")
	_expect_true(restored.advance(5), "余波对话可逐句推进")
	var epilogue_snapshot: Dictionary = restored.snapshot()
	var restored_epilogue = DialogueStateScript.new()
	_expect_true(restored_epilogue.restore(epilogue_snapshot), "余波对话行号可以从现有快照结构恢复")
	_expect_equal(restored_epilogue.dialogue_id, "chapter_epilogue", "恢复保持稳定余波对话标识")
	_expect_true(restored_epilogue.skip_to_choices(5), "余波可快速显示到收束回应")
	_expect_true(restored_epilogue.finish(), "余波回应后回到空闲对话状态")
	_expect_true(restored_epilogue.start("ferryman_briefing"), "守堤支线复用可恢复结构化对话")
	_expect_true(restored_epilogue.advance(4), "守堤对话可逐句推进")
	var ferryman_dialogue_snapshot: Dictionary = restored_epilogue.snapshot()
	var restored_ferryman_dialogue = DialogueStateScript.new()
	_expect_true(restored_ferryman_dialogue.restore(ferryman_dialogue_snapshot), "守堤对话可在选择前恢复")
	_expect_equal(restored_ferryman_dialogue.dialogue_id, "ferryman_briefing", "守堤恢复保持稳定对话标识")
	_expect_true(restored_ferryman_dialogue.finish(), "守堤回应后释放结构化对话")
	_expect_true(restored_ferryman_dialogue.start("herbkeeper_basket"), "药篓支线复用可恢复结构化对话")
	_expect_true(restored_ferryman_dialogue.advance(4), "蕙婶对话可逐句推进")
	var basket_dialogue_snapshot: Dictionary = restored_ferryman_dialogue.snapshot()
	var restored_basket_dialogue = DialogueStateScript.new()
	_expect_true(restored_basket_dialogue.restore(basket_dialogue_snapshot), "药篓对话可在选择前恢复")
	_expect_equal(restored_basket_dialogue.dialogue_id, "herbkeeper_basket", "药篓恢复保持稳定对话标识")
	_expect_true(restored_basket_dialogue.finish(), "药篓回应后释放结构化对话")
	_expect_true(restored_basket_dialogue.start("patrol_runner_briefing"), "陶小满巡路委托复用可恢复结构化对话")
	_expect_true(restored_basket_dialogue.advance(4), "巡路对话可逐句推进")
	var patrol_dialogue_snapshot: Dictionary = restored_basket_dialogue.snapshot()
	var restored_patrol_dialogue = DialogueStateScript.new()
	_expect_true(restored_patrol_dialogue.restore(patrol_dialogue_snapshot), "巡路对话可在两项选择前恢复")
	_expect_equal(restored_patrol_dialogue.dialogue_id, "patrol_runner_briefing", "巡路恢复保持稳定对话标识")
	_expect_true(restored_patrol_dialogue.finish(), "巡路回应后释放结构化对话")
	var patrol_work_dialogues := [
		{"worksite_id": "boat", "patrol_response": "boat_first", "dialogue_id": "patrol_boat_priority", "route_role": "priority", "action_id": "talk_at_boat_worksite"},
		{"worksite_id": "boat", "patrol_response": "herbs_first", "dialogue_id": "patrol_boat_followup", "route_role": "followup", "action_id": "talk_at_boat_worksite"},
		{"worksite_id": "herbs", "patrol_response": "herbs_first", "dialogue_id": "patrol_herbs_priority", "route_role": "priority", "action_id": "talk_at_herbs_worksite"},
		{"worksite_id": "herbs", "patrol_response": "boat_first", "dialogue_id": "patrol_herbs_followup", "route_role": "followup", "action_id": "talk_at_herbs_worksite"},
	]
	for work_dialogue in patrol_work_dialogues:
		_expect_equal(
			DialogueStateScript.patrol_work_dialogue_id(work_dialogue["worksite_id"], work_dialogue["patrol_response"]),
			work_dialogue["dialogue_id"],
			"工作点与路线稳定映射 %s" % work_dialogue["dialogue_id"]
		)
		_expect_equal(DialogueStateScript.patrol_work_context(work_dialogue["dialogue_id"]), {
			"worksite_id": work_dialogue["worksite_id"],
			"patrol_response": work_dialogue["patrol_response"],
			"route_role": work_dialogue["route_role"],
			"action_id": work_dialogue["action_id"],
		}, "工作点对话 %s 可无损反向映射" % work_dialogue["dialogue_id"])
		var work_state = DialogueStateScript.new()
		_expect_true(work_state.start(work_dialogue["dialogue_id"]), "%s 是受支持结构化对话" % work_dialogue["dialogue_id"])
		_expect_true(work_state.advance(2), "%s 可逐句推进" % work_dialogue["dialogue_id"])
		var restored_work = DialogueStateScript.new()
		_expect_true(restored_work.restore(work_state.snapshot()), "%s 可在回应前恢复" % work_dialogue["dialogue_id"])
		_expect_equal(restored_work.dialogue_id, work_dialogue["dialogue_id"], "%s 恢复保持稳定标识" % work_dialogue["dialogue_id"])
	_expect_equal(DialogueStateScript.patrol_work_dialogue_id("kiln", "boat_first"), "", "未知工作点不映射对话")
	_expect_equal(DialogueStateScript.patrol_work_dialogue_id("boat", "unanswered"), "", "未选路线不映射工作点对话")
	_expect_equal(DialogueStateScript.patrol_work_context("patrol_runner_briefing"), {}, "初次巡路委托不伪装为工作点上下文")
	_expect_true(restored.restore({"active": true, "dialogue_id": "companion_briefing", "line_index": 8}), "规则状态允许未来内容扩充到第八行")
	_expect_false(restored.restore({"active": true, "dialogue_id": "companion_briefing", "line_index": 65}), "异常过大的对话行号被拒绝")
	_expect_false(restored.restore({"active": false, "dialogue_id": "companion_briefing", "line_index": 0}), "空闲状态不能保留对话标识")


func _test_versioned_save() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var journey = JourneyStateScript.new()
	journey.choose("talk_to_companion")
	_expect_true(journey.complete_patrol_dialogue("herbs_first")["ok"], "新版存档夹具记录药叶优先巡路选择")
	journey.choose("gather_moonleaf")
	journey.choose("enter_spring")
	journey.choose("inspect_moss_spoor")
	journey.choose("inspect_rock_spoor")
	journey.choose("approach_enemy")
	journey.choose("guard")
	var exploration = ExplorationStateScript.new()
	_expect_true(exploration.restore({"map_id": "cangquan_path", "player_x": 0.64, "player_y": 0.44}), "准备与战斗阶段一致的合法山道存档")
	var patrol = PatrolStateScript.new()
	patrol.advance(2.4)
	_expect_true(patrol.apply_priority("herbs_first"), "新版存档夹具应用已选择的巡路方向")
	patrol.advance(0.3)
	var path_keeper = PathKeeperStateScript.new()
	path_keeper.advance(2.4)
	var written: Dictionary = SaveGameScript.write(
		journey.snapshot(),
		exploration.snapshot(),
		TEST_SAVE_PATH,
		DialogueStateScript.default_snapshot(),
		false,
		patrol.snapshot(),
		path_keeper.snapshot()
	)
	_expect_true(written["ok"], "版本化存档写入成功")
	_expect_true(SaveGameScript.exists(TEST_SAVE_PATH), "写入后可检测继续游戏")
	var loaded: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(loaded["ok"], "版本化存档读取成功")
	_expect_equal(loaded["data"]["save_version"], float(SaveGameScript.SAVE_VERSION), "存档声明当前版本")
	_expect_equal(loaded["data"]["journey"]["moonleaf_method"], "whole_plant", "新版存档保留取药方式")
	_expect_equal(loaded["data"]["journey"]["enemy_id"], "rock_armor_young", "新版存档声明稳定敌人标识")
	_expect_equal(loaded["data"]["journey"]["enemy_intel"], ["spring_moss_shell", "rock_armor_young"], "v13 磁盘往返保持敌情调查顺序")
	_expect_equal(loaded["data"]["journey"]["first_breath_stage"], "unstarted", "当前版本磁盘往返保持尚未开始的引息仪轨")
	_expect_equal(loaded["data"]["journey"]["patrol_response"], "herbs_first", "当前版本磁盘往返保持巡路先后选择")
	_expect_true(loaded["data"].has("patrol"), "当前版本存档在顶层声明独立巡路状态")
	_expect_true(loaded["data"].has("path_keeper"), "当前版本存档在顶层声明独立守径状态")
	_expect_equal(loaded["data"]["exploration"]["map_id"], "cangquan_path", "新版战斗存档声明一致的山道地图标识")
	var restored_dialogue = DialogueStateScript.new()
	_expect_true(restored_dialogue.restore(loaded["data"]["dialogue"]), "新版存档包含可恢复的空闲对话状态")
	_expect_equal(restored_dialogue.snapshot(), DialogueStateScript.default_snapshot(), "新版空闲对话状态保持默认值")
	var restored_journey = JourneyStateScript.new()
	var restored_exploration = ExplorationStateScript.new()
	var restored_patrol = PatrolStateScript.new()
	var restored_path_keeper = PathKeeperStateScript.new()
	_expect_true(restored_journey.restore(loaded["data"]["journey"]), "读取的规则快照通过业务校验")
	_expect_true(restored_exploration.restore(loaded["data"]["exploration"]), "读取的探索快照通过碰撞校验")
	_expect_true(restored_patrol.restore(loaded["data"]["patrol"]), "读取的巡路快照通过路线校验")
	_expect_true(restored_path_keeper.restore(loaded["data"]["path_keeper"]), "读取的守径快照通过路线校验")
	_expect_equal(restored_journey.snapshot(), journey.snapshot(), "磁盘往返保留规则状态")
	_expect_true(restored_exploration.player_position.is_equal_approx(exploration.player_position), "磁盘往返保留玩家位置")
	_expect_equal(restored_patrol.snapshot(), patrol.snapshot(), "磁盘往返逐字段保留巡路位置与方向")
	_expect_equal(restored_path_keeper.snapshot(), path_keeper.snapshot(), "磁盘往返逐字段保留守径位置与方向")
	var omitted_chosen_patrol := SaveGameScript.write(
		journey.snapshot(),
		exploration.snapshot(),
		TEST_SAVE_PATH + ".missing-patrol"
	)
	_expect_false(omitted_chosen_patrol["ok"], "已决定巡路的旅程不能静默写入默认 patrol")
	_expect_equal(omitted_chosen_patrol["reason"], "missing_patrol", "缺失已选择巡路快照返回稳定原因")
	SaveGameScript.remove(TEST_SAVE_PATH + ".missing-patrol")

	var legacy_journey: Dictionary = journey.snapshot().duplicate(true)
	var legacy_exploration := exploration.snapshot().duplicate(true)
	legacy_exploration.erase("map_id")
	legacy_journey.erase("companion_supports")
	legacy_journey.erase("setbacks")
	legacy_journey.erase("talked_to_companion")
	legacy_journey.erase("spring_lamps")
	legacy_journey.erase("lamp_turns")
	legacy_journey.erase("briefing_response")
	legacy_journey.erase("first_breath_stage")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 1,
		"story_id": SaveGameScript.STORY_ID,
		"journey": legacy_journey,
		"exploration": legacy_exploration,
	}))
	var migrated: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated["ok"], "v1 存档可迁移到当前版本")
	_expect_equal(migrated["migrated_from_version"], 1, "迁移结果声明来源版本")
	_expect_equal(migrated["data"]["save_version"], SaveGameScript.SAVE_VERSION, "迁移后的内存快照升级为当前版本")
	_expect_equal(migrated["data"]["journey"]["enemy_id"], "rock_armor_young", "旧版迁移补入默认敌人标识")
	_expect_equal(migrated["data"]["exploration"]["map_id"], "cangquan_path", "v1 战斗存档按阶段补入山道地图标识")
	_expect_equal(migrated["data"]["journey"]["first_breath_stage"], "unstarted", "v1 战斗存档不虚构引息仪轨进度")
	_expect_equal(migrated["data"]["journey"]["companion_supports"], 1, "迁移补入同伴援护资源")
	_expect_equal(migrated["data"]["journey"]["setbacks"], 0, "迁移补入挫败计数")
	_expect_true(migrated["data"]["journey"]["talked_to_companion"], "战斗中的 v1 存档迁移为已完成简报")
	_expect_equal(migrated["data"]["journey"]["spring_lamps"], 1, "v1 迁移补入战术石灯")
	_expect_equal(migrated["data"]["journey"]["lamp_turns"], 0, "v1 迁移不虚构持续效果")
	_expect_equal(migrated["data"]["journey"]["briefing_response"], "careful", "旧版已交谈存档迁移为谨慎回应")
	_expect_equal(migrated["data"]["journey"]["moonleaf_method"], "whole_plant", "旧版持药存档迁移为保守整株记录")
	_expect_equal(migrated["data"]["journey"]["discoveries"], [], "旧版存档不虚构环境见闻")
	_expect_equal(migrated["data"]["journey"]["ferryman_response"], "unanswered", "旧版存档不虚构守堤选择")
	_expect_equal(migrated["data"]["journey"]["basket_response"], "unanswered", "旧版存档不虚构药篓去向")
	_expect_equal(migrated["data"]["journey"]["patrol_response"], "unanswered", "旧版存档不虚构巡路先后")
	_expect_equal(migrated["data"]["journey"]["enemy_intel"], [], "旧版存档不根据战斗经历虚构敌情调查")
	_expect_equal(migrated["data"]["dialogue"], DialogueStateScript.default_snapshot(), "旧版迁移补入空闲对话状态")
	_expect_equal(migrated["data"]["patrol"], PatrolStateScript.default_snapshot(), "旧版迁移补入中立的默认巡路状态")
	_expect_equal(migrated["data"]["path_keeper"], PathKeeperStateScript.default_snapshot(), "旧版迁移补入中立的默认守径状态")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "迁移后可写回新版存档")
	var version_two_journey: Dictionary = journey.snapshot().duplicate(true)
	version_two_journey.erase("first_breath_stage")
	version_two_journey.erase("talked_to_companion")
	version_two_journey.erase("spring_lamps")
	version_two_journey.erase("lamp_turns")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 2,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_two_journey,
		"exploration": legacy_exploration,
	}))
	var migrated_v2: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v2["ok"], "v2 存档可迁移到当前版本")
	_expect_equal(migrated_v2["migrated_from_version"], 2, "v2 迁移声明来源版本")
	_expect_true(migrated_v2["data"]["journey"]["talked_to_companion"], "战斗中的 v2 存档补入已交谈状态")
	_expect_equal(migrated_v2["data"]["journey"]["spring_lamps"], 1, "v2 存档补入战术石灯")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v2 迁移后可写回新版存档")
	var version_three_journey: Dictionary = journey.snapshot().duplicate(true)
	version_three_journey.erase("first_breath_stage")
	version_three_journey.erase("spring_lamps")
	version_three_journey.erase("lamp_turns")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 3,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_three_journey,
		"exploration": legacy_exploration,
	}))
	var migrated_v3: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v3["ok"], "v3 存档可迁移到当前版本")
	_expect_equal(migrated_v3["migrated_from_version"], 3, "v3 迁移声明来源版本")
	_expect_equal(migrated_v3["data"]["journey"]["spring_lamps"], 1, "v3 存档补入战术石灯")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v3 迁移后可写回新版存档")
	var version_four_journey: Dictionary = journey.snapshot().duplicate(true)
	version_four_journey.erase("first_breath_stage")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 4,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_four_journey,
		"exploration": legacy_exploration,
	}))
	var migrated_v4: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v4["ok"], "v4 存档可迁移到地图感知版本")
	_expect_equal(migrated_v4["migrated_from_version"], 4, "v4 迁移声明来源版本")
	_expect_equal(migrated_v4["data"]["exploration"]["map_id"], "cangquan_path", "v4 战斗存档按阶段补入山道地图标识")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v4 迁移后可写回新版存档")
	var version_five_journey: Dictionary = journey.snapshot().duplicate(true)
	version_five_journey.erase("first_breath_stage")
	version_five_journey.erase("briefing_response")
	version_five_journey.erase("enemy_id")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 5,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_five_journey,
		"exploration": exploration.snapshot(),
	}))
	var migrated_v5: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v5["ok"], "v5 地图存档可迁移到对话感知版本")
	_expect_equal(migrated_v5["migrated_from_version"], 5, "v5 迁移声明来源版本")
	_expect_equal(migrated_v5["data"]["dialogue"], DialogueStateScript.default_snapshot(), "v5 迁移补入空闲对话状态")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v5 迁移后可写回新版存档")
	var version_six_journey: Dictionary = journey.snapshot().duplicate(true)
	version_six_journey.erase("first_breath_stage")
	version_six_journey.erase("enemy_id")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 6,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_six_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v6: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v6["ok"], "v6 对话存档可迁移到敌人感知版本")
	_expect_equal(migrated_v6["migrated_from_version"], 6, "v6 迁移声明来源版本")
	_expect_equal(migrated_v6["data"]["journey"]["enemy_id"], "rock_armor_young", "v6 迁移补入默认敌人标识")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v6 迁移后可写回新版存档")
	var version_seven_journey: Dictionary = journey.snapshot().duplicate(true)
	version_seven_journey.erase("first_breath_stage")
	version_seven_journey.erase("armor_break_turns")
	version_seven_journey.erase("focus_turns")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 7,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_seven_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v7: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v7["ok"], "v7 敌人存档可迁移到战斗状态版本")
	_expect_equal(migrated_v7["migrated_from_version"], 7, "v7 迁移声明来源版本")
	_expect_equal(migrated_v7["data"]["journey"]["armor_break_turns"], 0, "v7 迁移不虚构破甲状态")
	_expect_equal(migrated_v7["data"]["journey"]["focus_turns"], 0, "v7 迁移不虚构凝息状态")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v7 迁移后可写回新版存档")
	var version_eight_journey: Dictionary = journey.snapshot().duplicate(true)
	version_eight_journey.erase("first_breath_stage")
	version_eight_journey.erase("moonleaf_method")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 8,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_eight_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v8: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v8["ok"], "v8 战斗状态存档可迁移到采集选择版本")
	_expect_equal(migrated_v8["migrated_from_version"], 8, "v8 迁移声明来源版本")
	_expect_equal(migrated_v8["data"]["journey"]["moonleaf_method"], "whole_plant", "v8 持药状态迁移为保守整株记录")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v8 迁移后可写回新版存档")
	var version_nine_journey: Dictionary = journey.snapshot().duplicate(true)
	version_nine_journey.erase("first_breath_stage")
	version_nine_journey.erase("discoveries")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 9,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_nine_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v9: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v9["ok"], "v9 采集存档可迁移到环境见闻版本")
	_expect_equal(migrated_v9["migrated_from_version"], 9, "v9 迁移声明来源版本")
	_expect_equal(migrated_v9["data"]["journey"]["discoveries"], [], "v9 迁移不虚构未记录见闻")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v9 迁移后可写回新版存档")
	var version_ten_journey: Dictionary = journey.snapshot().duplicate(true)
	version_ten_journey.erase("first_breath_stage")
	version_ten_journey.erase("ferryman_response")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 10,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_ten_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v10: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v10["ok"], "v10 见闻存档可迁移到守堤选择版本")
	_expect_equal(migrated_v10["migrated_from_version"], 10, "v10 迁移声明来源版本")
	_expect_equal(migrated_v10["data"]["journey"]["ferryman_response"], "unanswered", "v10 迁移不替玩家作守堤选择")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v10 迁移后可写回新版存档")
	var version_eleven_journey: Dictionary = journey.snapshot().duplicate(true)
	version_eleven_journey.erase("first_breath_stage")
	version_eleven_journey.erase("basket_response")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 11,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_eleven_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v11: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v11["ok"], "v11 守堤存档可迁移到药篓选择版本")
	_expect_equal(migrated_v11["migrated_from_version"], 11, "v11 迁移声明来源版本")
	_expect_equal(migrated_v11["data"]["journey"]["basket_response"], "unanswered", "v11 迁移不替玩家作药篓选择")
	_expect_equal(migrated_v11["data"]["journey"]["enemy_intel"], [], "v11 迁移不从遭遇推断敌情")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v11 迁移后可写回新版存档")
	var version_twelve_journey: Dictionary = journey.snapshot().duplicate(true)
	version_twelve_journey.erase("first_breath_stage")
	version_twelve_journey.erase("enemy_intel")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 12,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_twelve_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v12: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v12["ok"], "v12 药篓存档可迁移到敌情版本")
	_expect_equal(migrated_v12["migrated_from_version"], 12, "v12 迁移声明来源版本")
	_expect_equal(migrated_v12["data"]["save_version"], SaveGameScript.SAVE_VERSION, "v12 迁移升级到当前版本")
	_expect_equal(migrated_v12["data"]["journey"]["enemy_intel"], [], "v12 战斗存档迁移为空敌情而不虚构调查")
	_expect_equal(migrated_v12["data"]["journey"]["first_breath_stage"], "unstarted", "v12 战斗存档不虚构引息仪轨进度")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v12 迁移后可写回当前版本存档")

	var version_thirteen_journey: Dictionary = journey.snapshot().duplicate(true)
	version_thirteen_journey.erase("first_breath_stage")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 13,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_thirteen_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v13: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v13["ok"], "v13 敌情存档可迁移到三步引息版本")
	_expect_equal(migrated_v13["migrated_from_version"], 13, "v13 迁移声明来源版本")
	_expect_equal(migrated_v13["data"]["journey"]["first_breath_stage"], "unstarted", "v13 战斗存档迁移为未开始引息")
	_expect_equal(migrated_v13["data"]["exploration"]["map_id"], exploration.map_id, "v13 已匹配阶段的合法山道地图原样保留")
	_expect_true(Vector2(
		float(migrated_v13["data"]["exploration"]["player_x"]),
		float(migrated_v13["data"]["exploration"]["player_y"])
	).is_equal_approx(exploration.player_position), "v13 已匹配阶段的合法山道坐标原样保留")

	var legacy_spring_state = JourneyStateScript.new()
	legacy_spring_state.choose("talk_to_companion")
	legacy_spring_state.choose("gather_moonleaf")
	legacy_spring_state.choose("enter_spring")
	legacy_spring_state.choose("bypass_enemy")
	var legacy_spring_journey: Dictionary = legacy_spring_state.snapshot()
	legacy_spring_journey.erase("first_breath_stage")
	var legacy_spring_exploration := {
		"map_id": "cangquan_path",
		"player_x": ExplorationStateScript.PATH_BYPASS_POSITION.x,
		"player_y": ExplorationStateScript.PATH_BYPASS_POSITION.y,
	}
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 13,
		"story_id": SaveGameScript.STORY_ID,
		"journey": legacy_spring_journey,
		"exploration": legacy_spring_exploration,
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v13_spring: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v13_spring["ok"], "v13 旧泉室存档可迁移到空间仪轨起点")
	_expect_equal(migrated_v13_spring["data"]["journey"]["first_breath_stage"], "unstarted", "旧泉室存档不虚构任何引息步骤")
	_expect_true(migrated_v13_spring["data"]["journey"]["gathered_moonleaf"], "旧泉室迁移保留尚未温脉的月芽草")
	_expect_equal(migrated_v13_spring["data"]["exploration"]["map_id"], "cangquan_spring", "旧泉室迁入独立藏泉石室地图")
	_expect_true(Vector2(
		float(migrated_v13_spring["data"]["exploration"]["player_x"]),
		float(migrated_v13_spring["data"]["exploration"]["player_y"])
	).is_equal_approx(ExplorationStateScript.SPRING_START_POSITION), "旧泉室迁移到不触发仪轨的安全出生点")

	legacy_spring_state.choose("listen_to_spring")
	legacy_spring_state.choose("warm_meridians")
	legacy_spring_state.choose("breakthrough")
	var legacy_complete_journey: Dictionary = legacy_spring_state.snapshot()
	legacy_complete_journey.erase("first_breath_stage")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 13,
		"story_id": SaveGameScript.STORY_ID,
		"journey": legacy_complete_journey,
		"exploration": legacy_spring_exploration,
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v13_complete: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v13_complete["ok"], "v13 完成存档迁移后不会倒退章节")
	_expect_equal(migrated_v13_complete["data"]["journey"]["first_breath_stage"], "completed", "旧完成态推断为完整三步引息")
	_expect_equal(migrated_v13_complete["data"]["exploration"]["map_id"], "cangquan_spring", "旧完成态迁入藏泉石室完成锚点")
	_expect_true(Vector2(
		float(migrated_v13_complete["data"]["exploration"]["player_x"]),
		float(migrated_v13_complete["data"]["exploration"]["player_y"])
	).is_equal_approx(ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION), "旧完成态迁移到静坐引息位置")

	var version_fourteen_journey: Dictionary = journey.snapshot().duplicate(true)
	version_fourteen_journey.erase("patrol_response")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 14,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_fourteen_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	var migrated_v14: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v14["ok"], "v14 引息存档可迁移到独立巡路状态版本")
	_expect_equal(migrated_v14["migrated_from_version"], 14, "v14 迁移声明来源版本")
	_expect_equal(migrated_v14["data"]["journey"]["patrol_response"], "unanswered", "v14 迁移不替玩家决定巡路先后")
	_expect_equal(migrated_v14["data"]["patrol"], PatrolStateScript.default_snapshot(), "v14 迁移从中立默认路线开始")

	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "v14 迁移后可写回当前版本存档")
	var valid_save_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_write_test_file(TEST_SAVE_PATH + ".bak", valid_save_text)
	_write_test_file(TEST_SAVE_PATH, "{broken")
	var recovered: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(recovered["ok"], "主文件损坏时读取安全备份")
	_expect_true(recovered["recovered_from_backup"], "备份恢复被明确标记")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH, {}, false, patrol.snapshot())["ok"], "备份恢复后可以重新保存主文件")

	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 999,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
	}))
	var future: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_false(future["ok"], "未知未来版本不会被静默加载")
	_expect_equal(future["reason"], "unsupported_version", "未知版本返回稳定原因")
	SaveGameScript.remove(TEST_SAVE_PATH)
	var current_spring_state = JourneyStateScript.new()
	current_spring_state.choose("talk_to_companion")
	current_spring_state.choose("gather_moonleaf")
	current_spring_state.choose("enter_spring")
	current_spring_state.choose("bypass_enemy")
	var mismatched_phase_map_cases := [
		{
			"label": "渡口阶段配山道地图",
			"journey": JourneyStateScript.new().snapshot(),
			"exploration": {"map_id": "cangquan_path", "player_x": 0.64, "player_y": 0.44},
		},
		{
			"label": "战斗阶段配渡口地图",
			"journey": journey.snapshot(),
			"exploration": {"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51},
		},
		{
			"label": "泉室阶段配山道地图",
			"journey": current_spring_state.snapshot(),
			"exploration": {"map_id": "cangquan_path", "player_x": 0.64, "player_y": 0.44},
		},
		{
			"label": "完成阶段配渡口地图",
			"journey": legacy_spring_state.snapshot(),
			"exploration": {"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51},
		},
	]
	for mismatch_case in mismatched_phase_map_cases:
		SaveGameScript.remove(TEST_SAVE_PATH)
		_write_test_file(TEST_SAVE_PATH, JSON.stringify({
			"save_version": SaveGameScript.SAVE_VERSION,
			"story_id": SaveGameScript.STORY_ID,
			"journey": mismatch_case["journey"],
			"exploration": mismatch_case["exploration"],
			"dialogue": DialogueStateScript.default_snapshot(),
			"patrol": PatrolStateScript.default_snapshot(),
			"path_keeper": PathKeeperStateScript.default_snapshot(),
		}))
		var mismatched_result: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
		_expect_false(mismatched_result["ok"], "%s不能作为当前存档恢复" % mismatch_case["label"])
		_expect_equal(mismatched_result["reason"], "invalid_map_phase", "%s返回稳定跨对象校验原因" % mismatch_case["label"])
	SaveGameScript.remove(TEST_SAVE_PATH)
	var unknown_map_exploration := exploration.snapshot().duplicate(true)
	unknown_map_exploration["map_id"] = "unreleased_secret_realm"
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": unknown_map_exploration,
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_map", "未知地图不会恢复到错误场景")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": {"active": true, "dialogue_id": "missing", "line_index": 0},
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_dialogue", "未知对话标识不会进入界面层")
	var unknown_enemy_journey: Dictionary = journey.snapshot().duplicate(true)
	unknown_enemy_journey["enemy_id"] = "unreleased_enemy"
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": unknown_enemy_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_enemy", "未知敌人标识不会进入规则层")
	var invalid_intel_cases := [
		{"value": "rock_armor_young", "label": "非数组敌情"},
		{"value": ["rock_armor_young", "rock_armor_young"], "label": "重复敌情"},
		{"value": ["unreleased_enemy_intel"], "label": "未知敌情"},
	]
	for invalid_case in invalid_intel_cases:
		var invalid_intel_journey: Dictionary = journey.snapshot().duplicate(true)
		invalid_intel_journey["enemy_intel"] = invalid_case["value"]
		_write_test_file(TEST_SAVE_PATH, JSON.stringify({
			"save_version": SaveGameScript.SAVE_VERSION,
			"story_id": SaveGameScript.STORY_ID,
			"journey": invalid_intel_journey,
			"exploration": exploration.snapshot(),
			"dialogue": DialogueStateScript.default_snapshot(),
			"patrol": PatrolStateScript.default_snapshot(),
			"path_keeper": PathKeeperStateScript.default_snapshot(),
		}))
		_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_journey", "%s被当前存档严格拒绝" % invalid_case["label"])
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_patrol", "v17 当前存档缺少顶层巡路快照时拒绝恢复")
	var invalid_patrol_snapshot := PatrolStateScript.default_snapshot()
	invalid_patrol_snapshot["position_x"] = 0.50
	invalid_patrol_snapshot["position_y"] = 0.50
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": invalid_patrol_snapshot,
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_patrol", "v17 当前存档拒绝离开公开路线的巡路快照")

	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": PatrolStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_path_keeper", "v17 当前存档缺少顶层守径快照时拒绝恢复")
	var invalid_path_keeper_snapshot := PathKeeperStateScript.default_snapshot()
	invalid_path_keeper_snapshot["position_x"] = 0.50
	invalid_path_keeper_snapshot["position_y"] = 0.50
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": invalid_path_keeper_snapshot,
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_path_keeper", "v17 当前存档拒绝离开公开路线的守径快照")

	var patrol_dialogue_journey = JourneyStateScript.new()
	patrol_dialogue_journey.choose("talk_to_companion")
	var close_patrol_exploration := {
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": PatrolStateScript.START_POSITION.x,
		"player_y": PatrolStateScript.START_POSITION.y,
	}
	var active_patrol_dialogue := {"active": true, "dialogue_id": "patrol_runner_briefing", "line_index": 1}
	var close_patrol_payload := {
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": patrol_dialogue_journey.snapshot(),
		"exploration": close_patrol_exploration,
		"dialogue": active_patrol_dialogue,
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(close_patrol_payload))
	var close_patrol_save: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(close_patrol_save["ok"], "玩家与陶小满处于交互半径内时可恢复活动巡路对话")
	var far_patrol_payload: Dictionary = close_patrol_payload.duplicate(true)
	far_patrol_payload["exploration"] = ExplorationStateScript.new().snapshot()
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(far_patrol_payload))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_dialogue", "玩家远离陶小满时活动巡路对话被跨状态校验拒绝")
	_write_test_file(TEST_SAVE_PATH, "{broken")
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_json", "损坏 JSON 被安全拒绝")
	SaveGameScript.remove(TEST_SAVE_PATH)
	_expect_false(FileAccess.file_exists(TEST_SAVE_PATH), "测试存档和临时文件可清理")


func _test_patrol_work_save_validation() -> void:
	var dialogue_cases := [
		{"worksite": "boat", "response": "boat_first", "dialogue_id": "patrol_boat_priority"},
		{"worksite": "boat", "response": "herbs_first", "dialogue_id": "patrol_boat_followup"},
		{"worksite": "herbs", "response": "herbs_first", "dialogue_id": "patrol_herbs_priority"},
		{"worksite": "herbs", "response": "boat_first", "dialogue_id": "patrol_herbs_followup"},
	]
	var valid_boat_payload: Dictionary = {}
	for dialogue_case in dialogue_cases:
		var journey = JourneyStateScript.new()
		_expect_true(journey.complete_companion_briefing("careful")["ok"], "%s 存档夹具完成同伴简报" % dialogue_case["dialogue_id"])
		_expect_true(journey.complete_patrol_dialogue(dialogue_case["response"])["ok"], "%s 存档夹具记录路线" % dialogue_case["dialogue_id"])
		var patrol_snapshot := _patrol_endpoint_snapshot(dialogue_case["worksite"])
		var endpoint_position := Vector2(float(patrol_snapshot["position_x"]), float(patrol_snapshot["position_y"]))
		var exploration = ExplorationStateScript.new()
		_expect_true(exploration.restore({
			"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
			"player_x": endpoint_position.x,
			"player_y": endpoint_position.y,
		}), "%s 存档夹具把玩家放在准确端点" % dialogue_case["dialogue_id"])
		var payload := {
			"save_version": SaveGameScript.SAVE_VERSION,
			"story_id": SaveGameScript.STORY_ID,
			"journey": journey.snapshot(),
			"exploration": exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": dialogue_case["dialogue_id"], "line_index": 1},
			"patrol": patrol_snapshot,
			"path_keeper": PathKeeperStateScript.default_snapshot(),
		}
		SaveGameScript.remove(TEST_SAVE_PATH)
		_write_test_file(TEST_SAVE_PATH, JSON.stringify(payload))
		var loaded: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
		_expect_true(loaded["ok"], "%s 的路线、端点、距离与停留一致时可恢复" % dialogue_case["dialogue_id"])
		_expect_equal(loaded["data"]["dialogue"]["dialogue_id"], dialogue_case["dialogue_id"], "%s 活动位置按 v17 原样保留" % dialogue_case["dialogue_id"])
		if dialogue_case["dialogue_id"] == "patrol_boat_priority":
			valid_boat_payload = payload.duplicate(true)

	var version_sixteen_payload: Dictionary = valid_boat_payload.duplicate(true)
	version_sixteen_payload["save_version"] = 16
	version_sixteen_payload.erase("path_keeper")
	SaveGameScript.remove(TEST_SAVE_PATH)
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(version_sixteen_payload))
	var migrated_v16: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v16["ok"], "v16 工作点存档可显式迁移到 v17")
	_expect_equal(migrated_v16["migrated_from_version"], 16, "v16 迁移声明准确来源版本")
	_expect_equal(migrated_v16["data"]["save_version"], SaveGameScript.SAVE_VERSION, "v16 迁移提升到当前 v17")
	var restored_v16_dialogue = DialogueStateScript.new()
	var restored_v16_patrol = PatrolStateScript.new()
	_expect_true(restored_v16_dialogue.restore(migrated_v16["data"]["dialogue"]), "v16 迁移后的活动工作点对话可严格恢复")
	_expect_true(restored_v16_patrol.restore(migrated_v16["data"]["patrol"]), "v16 迁移后的巡路状态可严格恢复")
	_expect_equal(restored_v16_dialogue.snapshot(), version_sixteen_payload["dialogue"], "v16 迁移保留合法活动工作点对话")
	_expect_equal(restored_v16_patrol.snapshot(), version_sixteen_payload["patrol"], "v16 迁移逐字段保留已有巡路状态")
	_expect_equal(migrated_v16["data"]["path_keeper"], PathKeeperStateScript.default_snapshot(), "v16 迁移只为未记录的守径人补默认状态")

	var version_fifteen_payload: Dictionary = valid_boat_payload.duplicate(true)
	version_fifteen_payload["save_version"] = 15
	version_fifteen_payload["dialogue"] = DialogueStateScript.default_snapshot()
	version_fifteen_payload.erase("path_keeper")
	SaveGameScript.remove(TEST_SAVE_PATH)
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(version_fifteen_payload))
	var migrated_v15: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v15["ok"], "v15 巡路存档可显式迁移到 v17")
	_expect_equal(migrated_v15["migrated_from_version"], 15, "v15 迁移声明准确来源版本")
	_expect_equal(migrated_v15["data"]["save_version"], SaveGameScript.SAVE_VERSION, "v15 迁移提升到当前 v17")
	var restored_v15_journey = JourneyStateScript.new()
	var restored_v15_patrol = PatrolStateScript.new()
	var restored_v15_exploration = ExplorationStateScript.new()
	_expect_true(restored_v15_journey.restore(migrated_v15["data"]["journey"]), "v15 迁移后的旅程仍可严格恢复")
	_expect_true(restored_v15_patrol.restore(migrated_v15["data"]["patrol"]), "v15 迁移后的巡路仍可严格恢复")
	_expect_true(restored_v15_exploration.restore(migrated_v15["data"]["exploration"]), "v15 迁移后的渡口空间仍可严格恢复")
	_expect_equal(restored_v15_journey.snapshot(), version_fifteen_payload["journey"], "v15 迁移保留已选巡路先后")
	_expect_equal(restored_v15_patrol.snapshot(), version_fifteen_payload["patrol"], "v15 迁移保留独立巡路位置与停留")
	_expect_equal(restored_v15_exploration.snapshot(), version_fifteen_payload["exploration"], "v15 合法渡口空间快照原样保留")
	_expect_equal(migrated_v15["data"]["path_keeper"], PathKeeperStateScript.default_snapshot(), "v15 迁移为未记录的守径人补默认状态")

	for legacy_version in range(1, 16):
		SaveGameScript.remove(TEST_SAVE_PATH)
		_write_test_file(TEST_SAVE_PATH, JSON.stringify({
			"save_version": legacy_version,
			"story_id": SaveGameScript.STORY_ID,
			"journey": {},
			"exploration": {},
			"dialogue": {"active": true, "dialogue_id": "patrol_boat_priority", "line_index": 0},
		}))
		var forged_legacy: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
		_expect_false(forged_legacy["ok"], "v%d 不能伪造尚不存在的工作点对话" % legacy_version)
		_expect_equal(forged_legacy["reason"], "invalid_dialogue", "v%d 伪造工作点对话返回稳定原因" % legacy_version)

	var invalid_current_cases := []
	var wrong_route: Dictionary = valid_boat_payload.duplicate(true)
	wrong_route["journey"]["patrol_response"] = "herbs_first"
	invalid_current_cases.append({"label": "活动对话与巡路选择错配", "payload": wrong_route})
	var wrong_endpoint: Dictionary = valid_boat_payload.duplicate(true)
	wrong_endpoint["patrol"] = _patrol_endpoint_snapshot(PatrolStateScript.WORKSITE_HERBS)
	invalid_current_cases.append({"label": "活动对话与 NPC 工作点错配", "payload": wrong_endpoint})
	var far_player: Dictionary = valid_boat_payload.duplicate(true)
	far_player["exploration"] = ExplorationStateScript.new().snapshot()
	invalid_current_cases.append({"label": "玩家远离活动工作点", "payload": far_player})
	var no_dwell: Dictionary = valid_boat_payload.duplicate(true)
	no_dwell["patrol"] = _patrol_endpoint_snapshot(PatrolStateScript.WORKSITE_BOAT, 0.0)
	invalid_current_cases.append({"label": "活动工作点已结束停留", "payload": no_dwell})
	var wrong_role: Dictionary = valid_boat_payload.duplicate(true)
	wrong_role["dialogue"]["dialogue_id"] = "patrol_boat_followup"
	invalid_current_cases.append({"label": "同一端点优先与后续角色错配", "payload": wrong_role})
	var path_journey = JourneyStateScript.new()
	path_journey.complete_companion_briefing("careful")
	path_journey.complete_patrol_dialogue("boat_first")
	path_journey.choose("gather_moonleaf")
	path_journey.choose("enter_spring")
	var wrong_scene: Dictionary = valid_boat_payload.duplicate(true)
	wrong_scene["journey"] = path_journey.snapshot()
	wrong_scene["exploration"] = {
		"map_id": ExplorationStateScript.MOUNTAIN_PATH_MAP_ID,
		"player_x": ExplorationStateScript.PATH_START_POSITION.x,
		"player_y": ExplorationStateScript.PATH_START_POSITION.y,
	}
	invalid_current_cases.append({"label": "山道场景伪造渡口工作点对话", "payload": wrong_scene})
	for invalid_case in invalid_current_cases:
		SaveGameScript.remove(TEST_SAVE_PATH)
		_write_test_file(TEST_SAVE_PATH, JSON.stringify(invalid_case["payload"]))
		var invalid_result: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
		_expect_false(invalid_result["ok"], "%s 被当前存档拒绝" % invalid_case["label"])
		_expect_equal(invalid_result["reason"], "invalid_dialogue", "%s 返回稳定跨状态原因" % invalid_case["label"])
	SaveGameScript.remove(TEST_SAVE_PATH)


func _test_crash_consistent_save_recovery() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var exploration = ExplorationStateScript.new()
	var first_journey = JourneyStateScript.new()
	_expect_true(SaveGameScript.write(first_journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "首次保存建立主文件")
	var first_save_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_expect_true(first_journey.complete_companion_briefing("careful")["ok"], "准备可区分的第二代存档")
	_expect_true(SaveGameScript.write(first_journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "第二次保存原子提升新主文件")
	_expect_true(FileAccess.file_exists(TEST_SAVE_PATH + ".bak"), "第二次成功保存长期保留上一代备份")
	var retained_backup := SaveGameScript.read(TEST_SAVE_PATH + ".bak")
	_expect_true(retained_backup["ok"], "writer 自然产生的备份可独立校验")
	_expect_false(retained_backup["data"]["journey"]["talked_to_companion"], "长期备份保留上一代而非复制当前主文件")
	_expect_true(SaveGameScript.read(TEST_SAVE_PATH)["data"]["journey"]["talked_to_companion"], "有效主文件仍是最新一代")

	_write_test_file(TEST_SAVE_PATH + ".tmp", first_save_text)
	var primary_preferred := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_equal(primary_preferred["source"], "primary", "有效主文件优先于残留临时文件和旧备份")
	_expect_true(primary_preferred["data"]["journey"]["talked_to_companion"], "主文件优先不会回退进度")

	_write_test_file(TEST_SAVE_PATH, "{broken")
	var temporary_recovery := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(temporary_recovery["ok"], "主文件损坏时可恢复完整中断写入")
	_expect_true(temporary_recovery["recovered_from_temporary"], "临时文件恢复来源被明确标记")
	_expect_equal(temporary_recovery["source"], "temporary", "中断写入优先于更旧备份")
	_expect_false(temporary_recovery["data"]["journey"]["talked_to_companion"], "临时文件恢复精确保留其状态")
	var recovery_source_bytes := FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp")
	var invalid_repair_snapshot := first_journey.snapshot()
	invalid_repair_snapshot["player_hp"] = 99
	var failed_repair := SaveGameScript.write(invalid_repair_snapshot, exploration.snapshot(), TEST_SAVE_PATH, DialogueStateScript.default_snapshot(), true)
	_expect_false(failed_repair["ok"], "恢复重写的独立暂存未通过校验时安全失败")
	_expect_equal(failed_repair["reason"], "verification_failed", "恢复重写校验失败返回稳定原因")
	_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp"), recovery_source_bytes, "恢复重写失败保持唯一有效临时源字节")
	_expect_false(FileAccess.file_exists(TEST_SAVE_PATH + ".repair"), "失败的恢复暂存被清理且不影响原临时源")

	_write_test_file(TEST_SAVE_PATH + ".tmp", "{broken")
	var backup_recovery := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(backup_recovery["ok"], "主文件与临时文件都损坏时恢复安全备份")
	_expect_true(backup_recovery["recovered_from_backup"], "三文件恢复明确标记备份来源")

	SaveGameScript.remove(TEST_SAVE_PATH + ".tmp")
	var invalid_domain_payload: Dictionary = JSON.parse_string(first_save_text)
	invalid_domain_payload["journey"]["player_hp"] = 99
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(invalid_domain_payload))
	var semantic_recovery := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(semantic_recovery["ok"] and semantic_recovery["recovered_from_backup"], "语法合法但 domain 非法的主文件回退到备份")

	var future_payload: Dictionary = invalid_domain_payload.duplicate(true)
	future_payload["save_version"] = 999
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(future_payload))
	var future_blocked := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_false(future_blocked["ok"], "未来版本主文件阻止向旧备份降级")
	_expect_equal(future_blocked["reason"], "unsupported_version", "防降级保留稳定的未来版本原因")
	_expect_false(future_blocked["recovered_from_backup"], "未来版本不会静默选择旧备份")
	var future_primary_bytes := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var future_primary_write := SaveGameScript.write(first_journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)
	_expect_false(future_primary_write["ok"], "旧运行时不会覆盖未来版本主文件")
	_expect_equal(future_primary_write["reason"], "newer_primary_present", "未来主文件写入保护返回可诊断原因")
	_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH), future_primary_bytes, "受阻写入保持未来主文件字节不变")

	future_payload["save_version"] = SaveGameScript.SAVE_VERSION
	future_payload["story_id"] = "another_story"
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(future_payload))
	var story_blocked := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_false(story_blocked["ok"], "不同故事主文件阻止跨故事回退")
	_expect_equal(story_blocked["reason"], "wrong_story", "跨故事防降级返回稳定原因")

	SaveGameScript.remove(TEST_SAVE_PATH)
	var invalid_legacy: Dictionary = JSON.parse_string(first_save_text)
	invalid_legacy["save_version"] = 11
	invalid_legacy["journey"].erase("basket_response")
	invalid_legacy["journey"]["player_hp"] = 99
	_write_test_file(TEST_SAVE_PATH, JSON.stringify(invalid_legacy))
	var rejected_migration := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_false(rejected_migration["ok"], "迁移补字段后仍需通过当前 domain 校验")
	_expect_equal(rejected_migration["reason"], "invalid_journey", "非法旧快照不会被迁移包装成成功")

	_write_test_file(TEST_SAVE_PATH, "{primary-broken")
	_write_test_file(TEST_SAVE_PATH + ".tmp", "{temporary-broken")
	_write_test_file(TEST_SAVE_PATH + ".bak", "{backup-broken")
	var broken_bytes := [
		FileAccess.get_file_as_string(TEST_SAVE_PATH),
		FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp"),
		FileAccess.get_file_as_string(TEST_SAVE_PATH + ".bak"),
	]
	_expect_false(SaveGameScript.read(TEST_SAVE_PATH)["ok"], "三份候选都损坏时拒绝恢复")
	_expect_equal([
		FileAccess.get_file_as_string(TEST_SAVE_PATH),
		FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp"),
		FileAccess.get_file_as_string(TEST_SAVE_PATH + ".bak"),
	], broken_bytes, "失败的只读恢复不修改任何候选字节")

	SaveGameScript.remove(TEST_SAVE_PATH)
	_expect_true(SaveGameScript.write(first_journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "为降级写入保护建立有效主文件")
	var stable_primary_bytes := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var future_temporary: Dictionary = JSON.parse_string(stable_primary_bytes)
	future_temporary["save_version"] = 999
	_write_test_file(TEST_SAVE_PATH + ".tmp", JSON.stringify(future_temporary))
	var protected_write := SaveGameScript.write(first_journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)
	_expect_false(protected_write["ok"], "旧运行时不会覆盖未来版本中断写入")
	_expect_equal(protected_write["reason"], "newer_temporary_present", "写入保护返回可诊断原因")
	_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH), stable_primary_bytes, "受阻写入保持主文件字节不变")
	_expect_equal(JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp"))["save_version"], 999, "受阻写入保留未来临时文件")
	_write_test_file(TEST_SAVE_PATH + ".bak", stable_primary_bytes)
	var downgrade_barrier_candidates := SaveGameScript.read_candidates(TEST_SAVE_PATH)
	_expect_equal(downgrade_barrier_candidates.size(), 0, "未来临时文件阻断旧运行时进入无法继续保存的主候选")
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "unsupported_version", "未来临时屏障不会越过到旧主文件或备份")
	SaveGameScript.remove(TEST_SAVE_PATH)


func _test_stale_temporary_branch_replacement() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var exploration = ExplorationStateScript.new()
	var committed = JourneyStateScript.new()
	_expect_true(SaveGameScript.write(committed.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "分支替换测试建立已提交 P0")
	var committed_p0 := FileAccess.get_file_as_string(TEST_SAVE_PATH)

	var abandoned = JourneyStateScript.new()
	_expect_true(abandoned.complete_companion_briefing("trusting")["ok"], "建立崩溃前已写完但未提交的 P1")
	_write_test_file(TEST_SAVE_PATH + ".tmp", JSON.stringify({
		"save_version": SaveGameScript.SAVE_VERSION,
		"story_id": SaveGameScript.STORY_ID,
		"journey": abandoned.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
		"patrol": PatrolStateScript.default_snapshot(),
		"path_keeper": PathKeeperStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["source"], "primary", "已提交 P0 优先于崩溃前未提交的 P1")

	committed.setbacks = 1
	_expect_true(SaveGameScript.write(committed.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "从 P0 继续形成的 P1′ 可覆盖废弃暂存分支")
	var divergent_p1 := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var saved_divergent := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_equal(saved_divergent["data"]["journey"]["setbacks"], 1.0, "普通保存提交玩家实际选择的 P1′")
	_expect_false(saved_divergent["data"]["journey"]["talked_to_companion"], "普通保存不会复活废弃 P1 的剧情选择")
	_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH + ".bak"), committed_p0, "普通保存先把最后已提交 P0 轮转为长期备份")
	_expect_false(FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"), "成功提升后不残留已废弃或新暂存文件")
	_expect_false(FileAccess.file_exists(TEST_SAVE_PATH + ".repair"), "普通保存不使用恢复专用 repair 工作区")

	# Simulate the only valid post-rotation crash point of the corrected protocol:
	# tmp already contains P1′, bak still contains committed P0, and repair is junk.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	_write_test_file(TEST_SAVE_PATH + ".tmp", divergent_p1)
	_write_test_file(TEST_SAVE_PATH + ".repair", "{partial-repair")
	var crash_recovery := SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(crash_recovery["ok"], "主文件轮转后崩溃仍有完整的最新暂存可恢复")
	_expect_equal(crash_recovery["source"], "temporary", "崩溃恢复选择已验证的 P1′ 而不是更旧备份")
	_expect_equal(crash_recovery["data"]["journey"]["setbacks"], 1.0, "崩溃恢复保持 P1′ 的分支状态")

	_write_test_file(TEST_SAVE_PATH + ".repair", divergent_p1)
	var deliberate_candidates := SaveGameScript.read_candidates(TEST_SAVE_PATH)
	_expect_equal(deliberate_candidates.size(), 2, "有效 repair 也不扩大三个正式槽位的恢复候选集")
	_expect_equal(deliberate_candidates[0]["source"], "temporary", "repair 工作区不会抢占临时恢复源")
	_expect_equal(deliberate_candidates[1]["source"], "backup", "repair 工作区不会遮蔽长期备份")
	SaveGameScript.remove(TEST_SAVE_PATH)


func _test_all_save_artifact_barriers() -> void:
	var barrier_cases := [
		{"suffix": ".repair", "kind": "future", "write_reason": "newer_repair_present"},
		{"suffix": ".repair", "kind": "story", "write_reason": "newer_repair_present"},
		{"suffix": ".bak", "kind": "future", "write_reason": "newer_backup_present"},
		{"suffix": ".bak", "kind": "story", "write_reason": "newer_backup_present"},
	]
	for barrier_case in barrier_cases:
		SaveGameScript.remove(TEST_SAVE_PATH)
		var exploration = ExplorationStateScript.new()
		var journey = JourneyStateScript.new()
		_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "屏障案例先建立有效当前主存档")
		var primary_bytes := FileAccess.get_file_as_string(TEST_SAVE_PATH)
		var barrier_payload: Dictionary = JSON.parse_string(primary_bytes)
		var expected_reason := "unsupported_version"
		if barrier_case["kind"] == "future":
			# A future format is allowed to rename every current schema field; version
			# detection must still block downgrade before inspecting those fields.
			barrier_payload = {
				"save_version": 999,
				"story_id": SaveGameScript.STORY_ID,
				"renamed_journey_v999": {"opaque": true},
			}
		else:
			barrier_payload["story_id"] = "another_story"
			expected_reason = "wrong_story"
		var barrier_path: String = TEST_SAVE_PATH + barrier_case["suffix"]
		var barrier_bytes := JSON.stringify(barrier_payload)
		_write_test_file(barrier_path, barrier_bytes)

		var blocked_read := SaveGameScript.read(TEST_SAVE_PATH)
		_expect_false(blocked_read["ok"], "%s 中的 %s 屏障会阻止加载旧主文件" % [barrier_case["suffix"], barrier_case["kind"]])
		_expect_equal(blocked_read["reason"], expected_reason, "%s 屏障返回稳定读取原因" % barrier_case["suffix"])
		_expect_equal(SaveGameScript.read_candidates(TEST_SAVE_PATH).size(), 0, "%s 屏障清空全部可继续候选" % barrier_case["suffix"])
		var blocked_write := SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)
		_expect_false(blocked_write["ok"], "%s 屏障会阻止旧运行时写入" % barrier_case["suffix"])
		_expect_equal(blocked_write["reason"], barrier_case["write_reason"], "%s 屏障返回稳定写入原因" % barrier_case["suffix"])
		_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH), primary_bytes, "%s 屏障保持当前主文件字节" % barrier_case["suffix"])
		_expect_equal(FileAccess.get_file_as_string(barrier_path), barrier_bytes, "%s 屏障保持自身字节" % barrier_case["suffix"])
	SaveGameScript.remove(TEST_SAVE_PATH)
	var huge_exploration = ExplorationStateScript.new()
	var huge_journey = JourneyStateScript.new()
	_expect_true(SaveGameScript.write(huge_journey.snapshot(), huge_exploration.snapshot(), TEST_SAVE_PATH)["ok"], "极大版本屏障测试建立有效主存档")
	var huge_version_bytes := "{\"save_version\":1e300,\"story_id\":\"%s\",\"future_schema\":{}}" % SaveGameScript.STORY_ID
	_write_test_file(TEST_SAVE_PATH + ".tmp", huge_version_bytes)
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "unsupported_version", "超出整数范围但有限的未来版本安全触发屏障")
	var huge_version_write := SaveGameScript.write(huge_journey.snapshot(), huge_exploration.snapshot(), TEST_SAVE_PATH)
	_expect_false(huge_version_write["ok"], "旧运行时不会覆盖极大未来版本暂存")
	_expect_equal(huge_version_write["reason"], "newer_temporary_present", "极大未来版本返回稳定写入屏障原因")
	_expect_equal(FileAccess.get_file_as_string(TEST_SAVE_PATH + ".tmp"), huge_version_bytes, "极大未来版本字节保持不变")
	SaveGameScript.remove(TEST_SAVE_PATH)


func _test_settings_store() -> void:
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
	var initial: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(initial["ok"], "缺失设置文件时返回安全默认值")
	_expect_equal(initial["reason"], "missing", "默认设置声明文件缺失来源")
	_expect_equal(initial["data"]["settings_version"], 4, "默认设置使用对话速度版本")
	_expect_false(initial["data"]["audio_enabled"], "环境音默认关闭")
	_expect_equal(initial["data"]["audio_volume"], 0.6, "默认音量为六成")
	_expect_equal(initial["data"]["battle_speed"], "standard", "战斗表现默认标准速度")
	_expect_false(initial["data"]["reduced_motion"], "动态效果默认完整")
	_expect_equal(initial["data"]["text_scale"], "standard", "文字大小默认标准")
	_expect_false(initial["data"]["high_contrast"], "高对比默认关闭")
	_expect_equal(initial["data"]["dialogue_speed"], "standard", "对话显字默认标准速度")
	_expect_true(SettingsStoreScript.write({"audio_enabled": true, "audio_volume": 0.35}, TEST_SETTINGS_PATH), "音频偏好写入成功")
	var stored: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(stored["ok"], "音频偏好可以读取")
	_expect_true(stored["data"]["audio_enabled"], "音频开关持久化")
	_expect_equal(stored["data"]["audio_volume"], 0.35, "音量持久化")
	_expect_equal(stored["data"]["battle_speed"], "standard", "缺省写入补齐标准战斗表现")
	_expect_equal(stored["data"]["dialogue_speed"], "standard", "缺省写入补齐标准对话显字速度")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 1, "audio_enabled": true, "audio_volume": 1.0}))
	var migrated_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(migrated_settings["ok"], "v1 音频设置可迁移到表现选项版本")
	_expect_equal(migrated_settings["reason"], "migrated_v1", "旧设置声明迁移来源")
	_expect_equal(migrated_settings["data"]["battle_speed"], "standard", "旧设置迁移不擅自开启快速模式")
	_expect_false(migrated_settings["data"]["reduced_motion"], "旧设置迁移保持完整动态默认值")
	_expect_equal(migrated_settings["data"]["text_scale"], "standard", "v1 迁移不擅自放大文字")
	_expect_false(migrated_settings["data"]["high_contrast"], "v1 迁移保持默认对比")
	_expect_equal(migrated_settings["data"]["dialogue_speed"], "standard", "v1 迁移使用标准对话显字速度")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 2, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "fast", "reduced_motion": true}))
	var migrated_v2_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(migrated_v2_settings["ok"], "v2 表现设置可迁移到无障碍版本")
	_expect_equal(migrated_v2_settings["reason"], "migrated_v2", "v2 设置声明迁移来源")
	_expect_equal(migrated_v2_settings["data"]["battle_speed"], "fast", "v2 迁移保留快速战斗表现")
	_expect_true(migrated_v2_settings["data"]["reduced_motion"], "v2 迁移保留简化动态偏好")
	_expect_equal(migrated_v2_settings["data"]["text_scale"], "standard", "v2 迁移不擅自放大文字")
	_expect_false(migrated_v2_settings["data"]["high_contrast"], "v2 迁移保持默认对比")
	_expect_equal(migrated_v2_settings["data"]["dialogue_speed"], "standard", "v2 迁移使用标准对话显字速度")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 3, "audio_enabled": true, "audio_volume": 1.0, "battle_speed": "fast", "reduced_motion": true, "text_scale": "large", "high_contrast": true}))
	var migrated_v3_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(migrated_v3_settings["ok"], "v3 无障碍设置可迁移到对话速度版本")
	_expect_equal(migrated_v3_settings["reason"], "migrated_v3", "v3 设置声明迁移来源")
	_expect_equal(migrated_v3_settings["data"]["battle_speed"], "fast", "v3 迁移保留快速战斗表现")
	_expect_true(migrated_v3_settings["data"]["reduced_motion"], "v3 迁移保留简化动态偏好")
	_expect_equal(migrated_v3_settings["data"]["text_scale"], "large", "v3 迁移保留大字偏好")
	_expect_true(migrated_v3_settings["data"]["high_contrast"], "v3 迁移保留高对比偏好")
	_expect_equal(migrated_v3_settings["data"]["dialogue_speed"], "standard", "v3 迁移使用标准对话显字速度")
	_write_test_file(TEST_SETTINGS_PATH, "{broken")
	var corrupt: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_false(corrupt["ok"], "损坏设置不会加载")
	_expect_false(corrupt["data"]["audio_enabled"], "损坏设置回退到静音")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 9, "audio_enabled": true, "audio_volume": 1.0}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "unsupported_version", "未知设置版本被拒绝")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 1, "audio_enabled": "yes", "audio_volume": 0.5}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "invalid_audio_enabled", "非布尔音频开关被拒绝")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 1, "audio_enabled": true, "audio_volume": 1.5}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "invalid_audio_volume", "越界音量被拒绝")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 2, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "instant", "reduced_motion": false}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "invalid_battle_speed", "未知战斗表现速度被拒绝")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 2, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "fast", "reduced_motion": "yes"}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "invalid_reduced_motion", "非布尔动态偏好被拒绝")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 3, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "standard", "reduced_motion": false, "text_scale": "huge", "high_contrast": true}))
	var rejected_scale: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_equal(rejected_scale["reason"], "invalid_text_scale", "未知文字大小被拒绝")
	_expect_equal(rejected_scale["data"]["text_scale"], "standard", "非法文字设置整体回退标准字号")
	_expect_false(rejected_scale["data"]["high_contrast"], "非法文字设置不泄漏部分校验的高对比")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 3, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "standard", "reduced_motion": false, "text_scale": "large", "high_contrast": "yes"}))
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["reason"], "invalid_high_contrast", "非布尔对比偏好被拒绝")
	var valid_v4 := {"settings_version": 4, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "standard", "reduced_motion": false, "text_scale": "large", "high_contrast": true, "dialogue_speed": "fast"}
	var missing_dialogue_speed: Dictionary = valid_v4.duplicate(true)
	missing_dialogue_speed.erase("dialogue_speed")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify(missing_dialogue_speed))
	var rejected_missing_dialogue: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_equal(rejected_missing_dialogue["reason"], "invalid_dialogue_speed", "v4 缺失对话显字速度被拒绝")
	_expect_equal(rejected_missing_dialogue["data"], SettingsStoreScript.defaults(), "缺失对话显字速度整体回退默认设置")
	var typed_dialogue_speed: Dictionary = valid_v4.duplicate(true)
	typed_dialogue_speed["dialogue_speed"] = 2
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify(typed_dialogue_speed))
	var rejected_typed_dialogue: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_equal(rejected_typed_dialogue["reason"], "invalid_dialogue_speed", "非字符串对话显字速度被拒绝")
	_expect_equal(rejected_typed_dialogue["data"], SettingsStoreScript.defaults(), "错类型对话显字速度整体回退默认设置")
	var unknown_dialogue_speed: Dictionary = valid_v4.duplicate(true)
	unknown_dialogue_speed["dialogue_speed"] = "cinematic"
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify(unknown_dialogue_speed))
	var rejected_unknown_dialogue: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_equal(rejected_unknown_dialogue["reason"], "invalid_dialogue_speed", "未知对话显字速度被拒绝")
	_expect_equal(rejected_unknown_dialogue["data"], SettingsStoreScript.defaults(), "未知对话显字速度整体回退默认设置")
	for dialogue_speed in ["standard", "fast", "instant"]:
		_expect_true(SettingsStoreScript.write({"audio_enabled": false, "audio_volume": 0.6, "battle_speed": "standard", "reduced_motion": false, "text_scale": "large", "high_contrast": true, "dialogue_speed": dialogue_speed}, TEST_SETTINGS_PATH), "%s 对话显字偏好写入成功" % dialogue_speed)
		var round_trip: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
		_expect_true(round_trip["ok"], "%s 对话显字偏好可以读取" % dialogue_speed)
		_expect_equal(round_trip["reason"], "", "%s 对话显字偏好无需迁移" % dialogue_speed)
		_expect_equal(round_trip["data"]["dialogue_speed"], dialogue_speed, "%s 对话显字偏好精确往返" % dialogue_speed)
	var accessible: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(accessible["ok"], "无障碍偏好可以读取")
	_expect_equal(accessible["data"]["text_scale"], "large", "大字偏好持久化")
	_expect_true(accessible["data"]["high_contrast"], "高对比偏好持久化")
	var valid_primary_bytes := FileAccess.get_file_as_string(TEST_SETTINGS_PATH)
	_expect_false(SettingsStoreScript.write({"audio_enabled": true, "audio_volume": 1.0, "battle_speed": "fast", "reduced_motion": true, "text_scale": "standard", "high_contrast": false, "dialogue_speed": "cinematic"}, TEST_SETTINGS_PATH), "非法对话显字候选写入验证失败")
	_expect_equal(FileAccess.get_file_as_string(TEST_SETTINGS_PATH), valid_primary_bytes, "非法对话显字候选不替换合法主设置")
	_expect_false(FileAccess.file_exists(TEST_SETTINGS_PATH + ".tmp"), "非法对话显字候选清理验证暂存")
	_expect_equal(SettingsStoreScript.read(TEST_SETTINGS_PATH)["data"]["dialogue_speed"], "instant", "非法写入后保留原有整句显示偏好")
	var blocking_backup_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH + ".bak")
	_expect_equal(DirAccess.make_dir_absolute(blocking_backup_path), OK, "设置提升失败夹具建立备份路径屏障")
	_expect_false(SettingsStoreScript.write({"audio_enabled": true, "audio_volume": 1.0, "battle_speed": "fast", "reduced_motion": true, "text_scale": "standard", "high_contrast": false, "dialogue_speed": "fast"}, TEST_SETTINGS_PATH), "备份路径屏障令设置提升安全失败")
	_expect_equal(FileAccess.get_file_as_string(TEST_SETTINGS_PATH), valid_primary_bytes, "设置提升失败保持已提交主文件字节")
	_expect_false(FileAccess.file_exists(TEST_SETTINGS_PATH + ".tmp"), "设置提升失败清理验证暂存")
	_expect_equal(DirAccess.remove_absolute(blocking_backup_path), OK, "设置提升失败夹具清理备份路径屏障")
	var interrupted_backup_path := TEST_SETTINGS_PATH + ".bak"
	_expect_equal(DirAccess.rename_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH), ProjectSettings.globalize_path(interrupted_backup_path)), OK, "设置中断恢复夹具轮转已提交主文件")
	var recovered_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(recovered_settings["ok"], "缺失主文件时从已提交设置备份恢复")
	_expect_equal(recovered_settings["reason"], "recovered_backup", "设置备份恢复返回稳定来源")
	_expect_equal(recovered_settings["data"]["dialogue_speed"], "instant", "设置备份恢复保留整句显示偏好")
	_expect_true(FileAccess.file_exists(TEST_SETTINGS_PATH), "设置备份恢复重新提升主文件")
	_expect_false(FileAccess.file_exists(interrupted_backup_path), "设置备份恢复消费轮转备份")
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)


func _test_companion_trail() -> void:
	var trail = CompanionTrailScript.new()
	var initial := trail.reset("riverbank", Vector2(0.50, 0.50), Vector2(0.042, 0.011))
	_expect_equal(initial, Vector2(0.542, 0.511), "同行轨迹从主角旁的安全休息位开始")
	for step in range(1, 16):
		trail.record("riverbank", Vector2(0.50 + float(step) * 0.01, 0.50), Vector2(0.042, 0.011))
	var straight: Dictionary = trail.visual_contract()
	_expect_true(float(straight["position"].x) < 0.65, "砚青保持在主角已走过的路线后方")
	_expect_true(is_equal_approx(float(straight["position"].y), 0.50), "直线路段不会产生横向漂移")
	trail.record("riverbank", Vector2(0.65, 0.53), Vector2(0.042, 0.011))
	var corner: Vector2 = trail.visual_contract()["position"]
	_expect_true(corner.x < 0.65 and is_equal_approx(corner.y, 0.50), "转弯初段沿旧脚印而不是斜切墙角")
	var reset_count := int(trail.visual_contract()["reset_count"])
	var teleported := trail.record("riverbank", Vector2(0.90, 0.20), Vector2(0.042, 0.011))
	_expect_equal(teleported, Vector2(0.942, 0.211), "远距离读档在新位置旁安全重建同行者")
	_expect_equal(trail.visual_contract()["reset_count"], reset_count + 1, "远距离跳转只记录一次轨迹重置")
	trail.record("mountain_path", Vector2(0.16, 0.68), Vector2(-0.040, 0.012))
	_expect_equal(trail.visual_contract()["context_id"], "mountain_path", "换图清空旧地图脚印上下文")
	_expect_true(trail.visual_contract()["point_count"] <= trail.visual_contract()["max_points"], "同行轨迹受固定点数预算约束")


func _test_dialogue_portraits() -> void:
	var portrait = DialoguePortraitScript.new()
	_expect_true(portrait.set_portrait("protagonist"), "纸绘头像接受稳定主角标识")
	var protagonist: Dictionary = portrait.visual_contract()
	_expect_equal(protagonist["portrait_id"], "protagonist", "主角头像合同回显稳定标识")
	_expect_equal(protagonist["medium"], "painted_paper", "叙事头像使用已确认的纸绘媒介")
	_expect_equal(protagonist["style_revision"], 2, "纸绘头像公开明亮矿物色 v2 合同")
	_expect_equal(protagonist["rendering"], "deterministic_runtime_primitives", "头像只使用确定性运行时绘制")
	_expect_true(protagonist["deterministic"], "纸绘头像不读取时间或随机状态")
	_expect_false(protagonist["external_assets"], "纸绘头像不把概念图或外部位图带入运行时")
	_expect_equal(protagonist["asset_dependencies"], [], "纸绘头像没有隐藏资产依赖")
	_expect_equal(protagonist["palette"]["protagonist"], Color("58738f"), "主角肖像使用晴靛识别色")
	_expect_equal(protagonist["palette"]["morning_peach"], Color("e7a76f"), "明亮头像只以合同晨桃作低频暖色")
	_expect_equal(protagonist["profile"], {
		"expression": "curious",
		"silhouette": "high_tie_straw_cape",
		"accent": "indigo_ribbon",
	}, "主角 v2 合同公开警觉中带好奇的蓑衣轮廓")
	_expect_true(protagonist["motion_free"], "纸绘头像不依赖动态效果")
	_expect_false(protagonist["rule_authority"], "头像表现不成为规则权威")
	_expect_false(protagonist["save_authority"], "头像表现不新增存档权威")
	_expect_true(portrait.set_portrait("yanqing"), "纸绘头像接受稳定砚青标识")
	_expect_equal(portrait.visual_contract()["portrait_id"], "yanqing", "砚青头像与主角拥有不同表现标识")
	_expect_equal(portrait.visual_contract()["profile"]["accent"], "medicine_case", "砚青 v2 以药匣而非单靠衣色识别")
	_expect_true(portrait.set_portrait("liangshu"), "纸绘头像接受稳定梁叔标识")
	_expect_equal(portrait.visual_contract()["palette"]["liangshu"], Color("355e63"), "梁叔头像使用守堤冷青识别色")
	_expect_equal(portrait.visual_contract()["profile"]["expression"], "steady", "梁叔 v2 保持稳重而不统一笑脸")
	_expect_true(portrait.set_portrait("huishen"), "纸绘头像接受稳定蕙婶标识")
	_expect_equal(portrait.visual_contract()["palette"]["huishen"], Color("8ebb83").darkened(0.12), "蕙婶头像使用明快药圃青识别色")
	_expect_equal(portrait.visual_contract()["profile"]["silhouette"], "head_wrap_low_bun", "蕙婶 v2 以头巾低髻建立轮廓")
	_expect_true(portrait.set_portrait("tao_xiaoman"), "纸绘头像接受稳定陶小满标识")
	_expect_equal(portrait.visual_contract()["portrait_id"], "tao_xiaoman", "陶小满拥有独立巡路人头像标识")
	_expect_equal(portrait.visual_contract()["palette"]["tao_xiaoman"], Color("e4c36e").darkened(0.08), "陶小满头像使用明亮日金识别色")
	_expect_equal(portrait.visual_contract()["profile"]["expression"], "bright", "陶小满 v2 保留年轻跑腿人的松弛神情")
	_expect_false(portrait.set_portrait("licensed_character"), "未知或外部人物标识不会直接进入头像表现")
	_expect_equal(portrait.visual_contract()["portrait_id"], "journal", "未知头像安全回退为无人物的行旅札记")
	_expect_equal(portrait.visual_contract()["profile"]["accent"], "morning_seal", "无人物札记 v2 保留独立晨桃印记")
	_expect_equal(portrait.visual_contract()["supported_ids"], [
		"protagonist", "yanqing", "liangshu", "huishen", "tao_xiaoman", "journal",
	], "切片只按稳定顺序声明六个有限头像表现标识")
	portrait.free()


func _test_ferryman_side_story() -> void:
	var repair_state = JourneyStateScript.new()
	var before_repair: Dictionary = repair_state.snapshot()
	var repaired: Dictionary = repair_state.complete_ferryman_dialogue("repair")
	_expect_true(repaired["ok"], "渡口可选择扶正水尺")
	_expect_equal(repaired["events"], ["ferryman_repair"], "扶尺返回稳定语义事件")
	_expect_equal(repair_state.ferryman_response, "repair", "扶尺选择进入持久状态")
	var after_repair: Dictionary = repair_state.snapshot()
	for key in before_repair:
		if key != "ferryman_response":
			_expect_equal(after_repair[key], before_repair[key], "扶尺不暗中奖励或修改 %s" % key)
	_expect_false(repair_state.complete_ferryman_dialogue("record")["ok"], "守堤选择不能重复领取")
	_expect_false(repair_state.available_actions().has("talk_to_ferryman"), "完成后守堤行动隐藏")

	var record_state = JourneyStateScript.new()
	_expect_false(record_state.complete_ferryman_dialogue("steal_gauge")["ok"], "未知守堤选择不修改状态")
	_expect_equal(record_state.ferryman_response, "unanswered", "非法守堤选择保留未回应")
	var recorded: Dictionary = record_state.complete_ferryman_dialogue("record")
	_expect_true(recorded["ok"], "渡口可选择记录涨水时辰")
	_expect_equal(recorded["events"], ["ferryman_record"], "记时返回稳定语义事件")
	record_state.choose("talk_to_companion")
	record_state.choose("gather_moonleaf")
	record_state.choose("enter_spring")
	_expect_false(record_state.complete_ferryman_dialogue("repair")["ok"], "离开渡口不能远程改变守堤选择")


func _test_basket_side_story() -> void:
	var unavailable = JourneyStateScript.new()
	_expect_false(unavailable.complete_basket_dialogue("return")["ok"], "发现山道药篓前不能远程决定去向")
	_expect_equal(unavailable.complete_basket_dialogue("return")["events"], ["basket_unavailable"], "未发现药篓返回稳定不可用事件")

	var returned = _basket_ready_state()
	_expect_true(returned.available_actions().has("talk_to_herbkeeper"), "带药篓回渡口后出现蕙婶交谈行动")
	var before_return: Dictionary = returned.snapshot()
	_expect_false(returned.complete_basket_dialogue("keep_private")["ok"], "私占等未知药篓选择被规则拒绝")
	_expect_equal(returned.snapshot(), before_return, "非法药篓选择不部分修改状态")
	var return_result: Dictionary = returned.complete_basket_dialogue("return")
	_expect_true(return_result["ok"], "公用药篓可归还渡口药圃")
	_expect_equal(return_result["events"], ["basket_return"], "归圃返回稳定语义事件")
	var after_return: Dictionary = returned.snapshot()
	for key in before_return:
		if key != "basket_response":
			_expect_equal(after_return[key], before_return[key], "归还药篓不暗中奖励或修改 %s" % key)
	_expect_false(returned.available_actions().has("talk_to_herbkeeper"), "药篓安置后交谈行动隐藏")
	_expect_false(returned.complete_basket_dialogue("trail")["ok"], "药篓去向不能重复选择")
	var restored_return = JourneyStateScript.new()
	_expect_true(restored_return.restore(returned.snapshot()), "归圃结果可从规则快照恢复")
	_expect_equal(restored_return.basket_response, "return", "恢复保持药篓归圃结果")

	var trailed = _basket_ready_state()
	var before_trail: Dictionary = trailed.snapshot()
	var trail_result: Dictionary = trailed.complete_basket_dialogue("trail")
	_expect_true(trail_result["ok"], "公用药篓可补绳后留在山道")
	_expect_equal(trail_result["events"], ["basket_trail"], "留山返回稳定语义事件")
	var after_trail: Dictionary = trailed.snapshot()
	for key in before_trail:
		if key != "basket_response":
			_expect_equal(after_trail[key], before_trail[key], "留山药篓不暗中奖励或修改 %s" % key)


func _test_patrol_side_story() -> void:
	var unavailable = JourneyStateScript.new()
	var unavailable_before: Dictionary = unavailable.snapshot()
	var unavailable_result: Dictionary = unavailable.complete_patrol_dialogue("boat_first")
	_expect_false(unavailable_result["ok"], "同伴简报前不能远程决定陶小满巡路")
	_expect_equal(unavailable_result["events"], ["patrol_unavailable"], "未激活巡路委托返回稳定不可用事件")
	_expect_equal(unavailable.snapshot(), unavailable_before, "不可用巡路选择不修改旅程")

	var briefed = JourneyStateScript.new()
	_expect_true(briefed.complete_companion_briefing("careful")["ok"], "完成同伴简报后激活巡路委托")
	_expect_true(briefed.available_actions().has("talk_to_patrol_runner"), "陶小满委托在渡口行动列表中可选")
	var briefed_snapshot: Dictionary = briefed.snapshot()
	var invalid_result: Dictionary = briefed.complete_patrol_dialogue("skip_everything")
	_expect_false(invalid_result["ok"], "未知巡路先后被规则层拒绝")
	_expect_equal(invalid_result["events"], ["invalid_patrol_response"], "非法巡路先后返回稳定语义事件")
	_expect_equal(briefed.snapshot(), briefed_snapshot, "非法巡路选择原子保留旅程")

	var boat_first = JourneyStateScript.new()
	var herbs_first = JourneyStateScript.new()
	_expect_true(boat_first.restore(briefed_snapshot), "木楔优先分支从相同简报快照开始")
	_expect_true(herbs_first.restore(briefed_snapshot), "药叶优先分支从相同简报快照开始")
	var boat_result: Dictionary = boat_first.complete_patrol_dialogue("boat_first")
	var herbs_result: Dictionary = herbs_first.complete_patrol_dialogue("herbs_first")
	_expect_true(boat_result["ok"], "可选择先把木楔送往补船架")
	_expect_equal(boat_result["events"], ["patrol_boat_first"], "木楔优先返回稳定语义事件")
	_expect_true(herbs_result["ok"], "可选择先翻晾晒竹架的药叶")
	_expect_equal(herbs_result["events"], ["patrol_herbs_first"], "药叶优先返回稳定语义事件")
	_expect_equal(boat_first.patrol_response, "boat_first", "木楔优先进入持久规则状态")
	_expect_equal(herbs_first.patrol_response, "herbs_first", "药叶优先进入持久规则状态")
	for key in briefed_snapshot:
		if key != "patrol_response":
			_expect_equal(boat_first.snapshot()[key], briefed_snapshot[key], "木楔优先不暗中奖励或修改 %s" % key)
			_expect_equal(herbs_first.snapshot()[key], briefed_snapshot[key], "药叶优先不暗中奖励或修改 %s" % key)
	_expect_false(boat_first.available_actions().has("talk_to_patrol_runner"), "木楔优先后巡路行动隐藏")
	_expect_false(herbs_first.available_actions().has("talk_to_patrol_runner"), "药叶优先后巡路行动隐藏")
	for selected_route in [boat_first, herbs_first]:
		_expect_true(selected_route.available_actions().has(JourneyStateScript.TALK_AT_BOAT_WORKSITE), "选定巡路后旅程目录公开船架端点行动")
		_expect_true(selected_route.available_actions().has(JourneyStateScript.TALK_AT_HERBS_WORKSITE), "选定巡路后旅程目录公开竹架端点行动")
		var before_remote_work: Dictionary = selected_route.snapshot()
		_expect_equal(selected_route.choose(JourneyStateScript.TALK_AT_BOAT_WORKSITE)["events"], ["invalid_action"], "无空间上下文的 choose 不能远程代选船架回应")
		_expect_equal(selected_route.choose(JourneyStateScript.TALK_AT_HERBS_WORKSITE)["events"], ["invalid_action"], "无空间上下文的 choose 不能远程代选竹架回应")
		_expect_equal(selected_route.snapshot(), before_remote_work, "远程工作点 shortcut 被拒绝且不修改旅程")
	var work_choice_cases := [
		{"worksite": JourneyStateScript.WORKSITE_BOAT, "response": JourneyStateScript.SECURE_BOAT_CLOTH, "event": "patrol_boat_cloth_secured"},
		{"worksite": JourneyStateScript.WORKSITE_BOAT, "response": JourneyStateScript.CHECK_BOAT_MEASURE, "event": "patrol_boat_measure_checked"},
		{"worksite": JourneyStateScript.WORKSITE_HERBS, "response": JourneyStateScript.STEADY_HERB_TRAY, "event": "patrol_herbs_tray_steadied"},
		{"worksite": JourneyStateScript.WORKSITE_HERBS, "response": JourneyStateScript.CHECK_HERB_LIGHT, "event": "patrol_herbs_light_checked"},
	]
	var work_snapshot: Dictionary = boat_first.snapshot()
	for work_choice in work_choice_cases:
		var work_result: Dictionary = boat_first.complete_patrol_work_dialogue(work_choice["worksite"], work_choice["response"])
		_expect_true(work_result["ok"], "%s 可完成对应工作点回应" % work_choice["response"])
		_expect_equal(work_result["events"], [work_choice["event"]], "%s 返回锁定语义事件" % work_choice["response"])
		_expect_equal(work_result["snapshot"], work_snapshot, "%s 结果快照保持无奖励工作回声" % work_choice["response"])
		_expect_equal(boat_first.snapshot(), work_snapshot, "%s 不修改旅程持久状态" % work_choice["response"])
	var invalid_work_before: Dictionary = boat_first.snapshot()
	_expect_equal(boat_first.complete_patrol_work_dialogue("boat", "steady_herb_tray")["events"], ["invalid_patrol_work_response"], "工作点与回应错配返回稳定错误")
	_expect_equal(boat_first.complete_patrol_work_dialogue("kiln", "secure_boat_cloth")["events"], ["invalid_patrol_work_response"], "未知工作点返回稳定错误")
	_expect_equal(boat_first.snapshot(), invalid_work_before, "非法工作点回应保持旅程原子不变")
	_expect_equal(unavailable.complete_patrol_work_dialogue("boat", "secure_boat_cloth")["events"], ["patrol_worksite_unavailable"], "未选路线不能远程完成工作点回应")
	_expect_equal(unavailable.snapshot(), unavailable_before, "未选路线工作点回应保持原子不变")
	_expect_equal(boat_first.complete_patrol_dialogue("herbs_first")["events"], ["patrol_unavailable"], "巡路先后不能重复改选")
	var restored_boat = JourneyStateScript.new()
	var restored_herbs = JourneyStateScript.new()
	_expect_true(restored_boat.restore(boat_first.snapshot()), "木楔优先结果可从规则快照恢复")
	_expect_true(restored_herbs.restore(herbs_first.snapshot()), "药叶优先结果可从规则快照恢复")
	_expect_equal(restored_boat.patrol_response, "boat_first", "恢复保持木楔优先结果")
	_expect_equal(restored_herbs.patrol_response, "herbs_first", "恢复保持药叶优先结果")

	var direct_choice = JourneyStateScript.new()
	direct_choice.choose("talk_to_companion")
	var direct_result: Dictionary = direct_choice.choose("talk_to_patrol_runner")
	_expect_true(direct_result["ok"], "无对话界面的语义行动仍有稳定默认分支")
	_expect_equal(direct_choice.patrol_response, "boat_first", "语义行动默认选择木楔优先而不产生随机结果")
	var wrong_phase = JourneyStateScript.new()
	wrong_phase.choose("talk_to_companion")
	wrong_phase.choose("gather_moonleaf")
	wrong_phase.choose("enter_spring")
	var wrong_phase_before: Dictionary = wrong_phase.snapshot()
	_expect_equal(wrong_phase.complete_patrol_dialogue("herbs_first")["events"], ["patrol_unavailable"], "离开渡口后不能远程决定巡路")
	_expect_equal(wrong_phase.complete_patrol_work_dialogue("boat", "secure_boat_cloth")["events"], ["patrol_worksite_unavailable"], "离开渡口后不能远程完成工作点回应")
	_expect_equal(wrong_phase.snapshot(), wrong_phase_before, "错阶段巡路选择保持原子性")


func _basket_ready_state():
	var state = JourneyStateScript.new()
	state.choose("talk_to_companion")
	state.choose("gather_moonleaf")
	state.choose("enter_spring")
	state.choose("inspect_abandoned_basket")
	state.choose("return_to_ferry")
	return state


func _test_environment_discoveries() -> void:
	var state = JourneyStateScript.new()
	var ferry_discovery: Dictionary = state.choose("inspect_ferry_watermark")
	_expect_true(ferry_discovery["ok"], "渡口旧水痕可以调查")
	_expect_equal(ferry_discovery["events"], ["ferry_watermark_discovered"], "渡口调查返回稳定语义事件")
	_expect_equal(state.discoveries, ["ferry_watermark"], "渡口见闻进入有序持久列表")
	_expect_false(state.choose("inspect_ferry_watermark")["ok"], "同一见闻不能重复记入")
	_expect_false(state.available_actions().has("inspect_ferry_watermark"), "已读渡口见闻从可用行动隐藏")
	state.choose("talk_to_companion")
	state.choose("gather_moonleaf")
	state.choose("enter_spring")
	_expect_true(state.choose("inspect_spring_seam")["ok"], "山道泉纹可以调查")
	_expect_true(state.choose("inspect_abandoned_basket")["ok"], "弃置药篓可以调查")
	_expect_equal(state.discoveries, ["ferry_watermark", "spring_seam", "abandoned_basket"], "三处见闻按发现顺序保存")
	_expect_false(state.available_actions().has("inspect_spring_seam"), "已读泉纹从山道行动隐藏")
	_expect_false(state.available_actions().has("inspect_abandoned_basket"), "已读药篓从山道行动隐藏")
	var restored = JourneyStateScript.new()
	_expect_true(restored.restore(state.snapshot()), "三处见闻可以随规则快照恢复")
	_expect_equal(restored.discoveries, state.discoveries, "恢复保持环境见闻顺序")
	state.choose("bypass_enemy")
	state.choose("listen_to_spring")
	state.choose("warm_meridians")
	state.choose("breakthrough")
	_expect_true(state.snapshot()["discoveries"].size() == 3, "完成章节保留本轮见闻用于结算")
	state.choose("replay_chapter")
	_expect_equal(state.discoveries, [], "重游序章清空上一轮见闻")


func _test_enemy_intel() -> void:
	var state = JourneyStateScript.new()
	state.choose("talk_to_companion")
	state.choose("gather_moonleaf")
	state.choose("enter_spring")
	_expect_equal(state.visible_enemy_intents(), [], "非战斗阶段不会泄露敌人意图")
	_expect_true(state.available_actions().has("inspect_rock_spoor"), "山道提供岩甲擦痕调查")
	_expect_true(state.available_actions().has("inspect_moss_spoor"), "山道提供泉苔湿痕调查")
	_expect_true(state.available_actions().has("inspect_puppet_spoor"), "山道提供石傀拖痕调查")
	var before_invalid_intel: Dictionary = state.snapshot()
	var invalid_intel: Dictionary = state.call("_record_enemy_intel", "rock_armor_warden", "should_not_emit")
	_expect_false(invalid_intel["ok"], "敌情记录边界拒绝首领等非三条稳定标识")
	_expect_equal(state.snapshot(), before_invalid_intel, "非法敌情记录不部分修改旅程")
	var spoor_cases := [
		{"action": "inspect_moss_spoor", "event": "moss_spoor_inspected", "intel": "spring_moss_shell"},
		{"action": "inspect_rock_spoor", "event": "rock_spoor_inspected", "intel": "rock_armor_young"},
		{"action": "inspect_puppet_spoor", "event": "puppet_spoor_inspected", "intel": "unbalanced_stone_puppet"},
	]
	for spoor_case in spoor_cases:
		var before_spoor: Dictionary = state.snapshot()
		var investigated: Dictionary = state.choose(spoor_case["action"])
		_expect_true(investigated["ok"], "敌踪首次调查成功")
		_expect_equal(investigated["events"], [spoor_case["event"]], "敌踪调查返回稳定语义事件")
		_expect_equal(state.enemy_intel[-1], spoor_case["intel"], "敌情按玩家调查顺序持久记录")
		for key in before_spoor:
			if key != "enemy_intel":
				_expect_equal(investigated["snapshot"][key], before_spoor[key], "敌踪调查不暗中修改 %s" % key)
	_expect_equal(state.enemy_intel, ["spring_moss_shell", "rock_armor_young", "unbalanced_stone_puppet"], "三条敌情保持调查顺序")
	_expect_false(state.choose("inspect_moss_spoor")["ok"], "同一敌踪不能重复记录")
	_expect_false(state.available_actions().has("inspect_moss_spoor"), "已调查敌踪从山道行动隐藏")
	_expect_true(state.knows_enemy_intel("rock_armor_warden"), "岩甲擦痕同时识别同类守巢者")
	_expect_false(state.knows_enemy_intel("missing"), "未知敌人不会伪装成已知敌情")
	var restored = JourneyStateScript.new()
	_expect_true(restored.restore(state.snapshot()), "有序敌情列表可随规则快照恢复")
	_expect_equal(restored.enemy_intel, state.enemy_intel, "恢复保持敌情调查顺序")
	state.choose("return_to_ferry")
	_expect_equal(state.enemy_intel.size(), 3, "主动返回渡口保留敌情")
	state.choose("enter_spring")
	state.choose("bypass_enemy")
	state.choose("listen_to_spring")
	state.choose("warm_meridians")
	state.choose("breakthrough")
	_expect_equal(state.enemy_intel.size(), 3, "绕行与章节完成保留敌情结算")
	state.choose("replay_chapter")
	_expect_equal(state.enemy_intel, [], "重游序章清空上一轮敌情")

	var unknown = _battle_state()
	var unknown_round_one: Array[Dictionary] = unknown.visible_enemy_intents()
	_expect_equal(unknown_round_one.size(), 1, "未知敌情只显示当前意图")
	_expect_false(unknown_round_one[0].has("counter_action"), "未知敌情意图由规则层移除反制提示")
	var known = JourneyStateScript.new()
	known.choose("talk_to_companion")
	known.choose("gather_moonleaf")
	known.choose("enter_spring")
	known.choose("inspect_rock_spoor")
	known.choose("approach_enemy")
	var known_round_one: Array[Dictionary] = known.visible_enemy_intents()
	_expect_equal(known_round_one.size(), 2, "已知敌情显示当前与下一意图")
	_expect_equal(known_round_one[1]["id"], "rock_rending_charge", "已知敌情预告下一招稳定标识")
	var unknown_guard: Dictionary = unknown.choose("guard")
	var known_guard: Dictionary = known.choose("guard")
	_expect_equal(known_guard["snapshot"]["enemy_hp"], unknown_guard["snapshot"]["enemy_hp"], "敌情知识不改变错误窗口伤害")
	_expect_equal(known_guard["snapshot"]["player_hp"], unknown_guard["snapshot"]["player_hp"], "敌情知识不改变敌方结算")
	_expect_false(unknown.current_enemy_intent().get("counter_action", "").is_empty(), "未知敌情的当前规范意图仍含内部反制规则")
	var unknown_round_two: Array[Dictionary] = unknown.visible_enemy_intents()
	_expect_false(unknown_round_two[0].has("counter_action"), "未知敌情即使进入反制窗口也不泄露提示")
	var known_round_two: Array[Dictionary] = known.visible_enemy_intents()
	_expect_equal(known_round_two[0].get("counter_action"), "use_talisman", "已知敌情在裂石窗口显示符箓反制")
	var unknown_counter: Dictionary = unknown.choose("use_talisman")
	var known_counter: Dictionary = known.choose("use_talisman")
	_expect_equal(known_counter["snapshot"]["enemy_hp"], unknown_counter["snapshot"]["enemy_hp"], "敌情知识不改变正确窗口伤害")
	_expect_equal(known_counter["snapshot"]["armor_break_turns"], unknown_counter["snapshot"]["armor_break_turns"], "敌情知识不改变破甲结算")
	_expect_true(unknown_counter["events"].has("weakness_exposed"), "未调查玩家仍可凭行动命中正确反制窗口")
	_expect_equal(unknown.enemy_intel, [], "战斗试错不会自动写入敌情")
	known.choose("retreat")
	_expect_equal(known.enemy_intel, ["rock_armor_young"], "主动撤退保留已调查敌情")
	known.choose("approach_enemy")
	for turn in range(12):
		known.choose("guard")
		if known.phase_id() == "riverbank":
			break
	_expect_equal(known.phase_id(), "riverbank", "敌情保留测试触发同伴救援")
	_expect_equal(known.enemy_intel, ["rock_armor_young"], "同伴救援保留已调查敌情")


func _test_gathering_and_gate() -> void:
	var state = JourneyStateScript.new()
	var blocked: Dictionary = state.choose("enter_spring")
	_expect_false(blocked["ok"], "缺少灵草时阻止进山")
	_expect_equal(blocked["events"], ["need_briefing"], "未交谈时先返回任务简报提示")
	_expect_true(state.choose("talk_to_companion")["ok"], "首次同伴交谈成功")
	_expect_false(state.choose("talk_to_companion")["ok"], "同伴简报不能重复领取")
	blocked = state.choose("enter_spring")
	_expect_false(blocked["ok"], "交谈后仍需准备灵草")
	_expect_equal(blocked["events"], ["need_moonleaf"], "返回准备提示")
	_expect_true(state.choose("gather_moonleaf")["ok"], "首次采集成功")
	_expect_equal(state.moonleaf_method, "whole_plant", "旧规行动记录整株取药")
	_expect_false(state.choose("gather_moonleaf")["ok"], "重复采集无收益")
	_expect_false(state.available_actions().has("gather_moonleaf"), "完成行动从选项隐藏")
	_expect_false(state.available_actions().has("gather_moonleaf_cutting"), "采集后另一种方式也从选项隐藏")
	_expect_true(state.choose("enter_spring")["ok"], "准备后进入战斗")
	_expect_equal(state.phase_id(), "mountain_path", "山门先进入可探索山道")
	_expect_true(state.choose("inspect_path_marker")["ok"], "山道石标可以调查")
	_expect_true(state.choose("return_to_ferry")["ok"], "山道可以主动返回渡口")
	_expect_equal(state.phase_id(), "riverbank", "返回行动回到渡口阶段")
	_expect_true(state.choose("enter_spring")["ok"], "再次从山门进入山道")
	_expect_true(state.choose("approach_enemy")["ok"], "接近敌人才进入战斗")
	_expect_equal(state.phase_id(), "battle", "战斗阶段")

	var bypass = JourneyStateScript.new()
	bypass.choose("talk_to_companion")
	bypass.choose("gather_moonleaf")
	bypass.choose("enter_spring")
	var bypassed: Dictionary = bypass.choose("bypass_enemy")
	_expect_true(bypassed["ok"], "山道提供不战斗绕行")
	_expect_equal(bypass.phase_id(), "spring", "绕行直接进入泉室")
	_expect_equal(bypassed["snapshot"]["player_hp"], 12, "绕行不损失气血")
	_expect_equal(bypassed["snapshot"]["talismans"], 1, "绕行不消耗符箓")
	_expect_equal(bypassed["snapshot"]["round"], 1, "绕行不推进战斗回合")
	_expect_true(bypassed["events"].has("enemy_bypassed"), "绕行返回独立语义事件")

	var cutting = JourneyStateScript.new()
	cutting.choose("talk_to_companion")
	var cutting_result: Dictionary = cutting.choose("gather_moonleaf_cutting")
	_expect_true(cutting_result["ok"], "剪叶留根同样取得护脉灵草")
	_expect_equal(cutting_result["events"], ["gathered_cutting"], "剪叶方式返回独立语义事件")
	_expect_equal(cutting_result["snapshot"]["moonleaf_method"], "cutting", "剪叶方式进入确定性快照")
	_expect_true(cutting.choose("enter_spring")["ok"], "剪叶留根不会锁死进山主线")


func _test_combat_paths() -> void:
	var state = _battle_state()
	var guarded: Dictionary = state.choose("guard")
	_expect_equal(guarded["snapshot"]["player_hp"], 11, "守势只受一点伤害")
	_expect_equal(guarded["snapshot"]["round"], 2, "守势推进回合")
	_expect_true(guarded["events"].has("enemy_glanced"), "守势返回减伤事件")

	var talisman: Dictionary = state.choose("use_talisman")
	_expect_equal(talisman["snapshot"]["enemy_hp"], 6, "符箓命中岩甲弱点造成六点伤害")
	_expect_true(talisman["events"].has("weakness_exposed"), "材质相克返回独立语义事件")
	_expect_equal(talisman["snapshot"]["talismans"], 0, "符箓被消耗")
	_expect_false(state.choose("use_talisman")["ok"], "空符箓不会结算敌方攻击")
	_expect_false(state.choose("invalid")["ok"], "战斗拒绝未知行动")

	var victory: Dictionary = state.choose("use_art")
	_expect_equal(victory["snapshot"]["enemy_hp"], 2, "破甲状态令后续术式追加一点伤害")
	_expect_equal(victory["snapshot"]["armor_break_turns"], 1, "一次攻势消耗一层破甲延续")
	victory = state.choose("use_art")
	_expect_equal(victory["snapshot"]["enemy_id"], "rock_armor_warden", "普通敌人退场后统一解析器切换首领配置")
	_expect_equal(victory["snapshot"]["enemy_hp"], 14, "首领以完整生命进入同一战斗阶段")
	_expect_equal(state.phase_id(), "battle", "普通战胜利不会跳过守巢首领")
	_expect_true(victory["events"].has("boss_arrived"), "普通战结束返回首领入场事件")


func _test_enemy_profile_combat() -> void:
	var moss = _battle_state("approach_moss_shell")
	_expect_equal(moss.enemy_id, "spring_moss_shell", "泉苔接近行动选择对应配置")
	_expect_equal(moss.enemy_hp, 8, "泉苔使用独立生命上限")
	_expect_equal(moss.current_enemy_intent()["name"], "吸潮蓄壳", "泉苔显示第一回合意图")
	var moss_hit: Dictionary = moss.choose("use_art")
	_expect_equal(moss_hit["snapshot"]["enemy_hp"], 4, "引气术命中泉苔弱点造成四点伤害")
	_expect_true(moss_hit["events"].has("weakness_exposed"), "泉苔相克事件可供表现层消费")
	moss.choose("use_art")
	_expect_equal(moss.enemy_id, "rock_armor_warden", "泉苔退场后同样进入共享首领战")

	var puppet = _battle_state("approach_stone_puppet")
	_expect_equal(puppet.enemy_id, "unbalanced_stone_puppet", "石傀接近行动选择对应配置")
	_expect_equal(puppet.current_enemy_intent()["damage"], 4, "石傀预告第一回合重击")
	var counter: Dictionary = puppet.choose("guard")
	_expect_equal(counter["snapshot"]["enemy_hp"], 8, "守势借力对失衡石傀造成两点伤害")
	_expect_equal(counter["snapshot"]["player_hp"], 10, "守势同时按预告伤害结算减伤")
	_expect_true(counter["events"].has("weakness_exposed"), "石傀守势相克返回语义事件")
	var saved_puppet: Dictionary = puppet.snapshot()
	var restored_puppet = JourneyStateScript.new()
	_expect_true(restored_puppet.restore(saved_puppet), "非默认敌人与回合可以从快照恢复")
	_expect_equal(restored_puppet.enemy_id, "unbalanced_stone_puppet", "恢复保持稳定敌人标识")
	_expect_equal(restored_puppet.current_enemy_intent()["name"], "踏地回正", "恢复保持由回合推导的下一意图")


func _test_boss_and_statuses() -> void:
	var boss = _battle_state()
	boss.choose("guard")
	boss.choose("use_talisman")
	boss.choose("use_art")
	var arrival: Dictionary = boss.choose("use_art")
	_expect_equal(boss.enemy_id, "rock_armor_warden", "普通遭遇胜利触发岩甲守巢者")
	_expect_equal(boss.player_hp, 12, "首领入场间隙由砚青包扎到满气血")
	_expect_equal(boss.companion_supports, 1, "首领战重新准备一次同伴援护")
	_expect_equal(boss.spring_lamps, 1, "首领战重新准备一盏战术石灯")
	_expect_equal(boss.talismans, 0, "首领转场不返还普通战消耗的符箓")
	_expect_true(arrival["events"].has("regular_enemy_won"), "普通敌人退场事件与首领入场分离")

	var early_guard: Dictionary = boss.choose("guard")
	_expect_equal(early_guard["snapshot"]["enemy_hp"], 14, "压阵肩撞期间守势不提前造成反伤")
	_expect_equal(early_guard["snapshot"]["armor_break_turns"], 0, "错误意图窗口不施加破甲")
	_expect_false(early_guard["events"].has("weakness_exposed"), "错误意图窗口不返回弱点事件")
	var counter: Dictionary = boss.choose("guard")
	_expect_equal(counter["snapshot"]["enemy_hp"], 12, "守住崩石重击造成两点反伤")
	_expect_equal(counter["snapshot"]["armor_break_turns"], 2, "命中首领重击窗口施加两层破甲")
	_expect_true(counter["events"].has("weakness_exposed"), "首领正确窗口返回弱点事件")
	var broken_hit: Dictionary = boss.choose("use_art")
	_expect_equal(broken_hit["snapshot"]["enemy_hp"], 8, "破甲令引气术从三点增为四点")
	_expect_equal(broken_hit["snapshot"]["armor_break_turns"], 1, "破甲按后续攻击次数递减")
	var support: Dictionary = boss.choose("companion_support")
	_expect_equal(support["snapshot"]["focus_turns"], 2, "砚青援护同时施加两层凝息")
	var saved_statuses: Dictionary = boss.snapshot()
	var restored_boss = JourneyStateScript.new()
	_expect_true(restored_boss.restore(saved_statuses), "首领与两种持续状态可以存档恢复")
	_expect_equal(restored_boss.current_enemy_intent()["name"], boss.current_enemy_intent()["name"], "首领恢复保持下一招")
	var focused_hit: Dictionary = boss.choose("use_art")
	_expect_equal(focused_hit["snapshot"]["enemy_hp"], 3, "破甲与凝息同时为术式追加两点伤害")
	_expect_equal(focused_hit["snapshot"]["armor_break_turns"], 0, "术式消耗最后一层破甲")
	_expect_equal(focused_hit["snapshot"]["focus_turns"], 1, "术式消耗一层凝息")
	var boss_victory: Dictionary = boss.choose("use_art")
	_expect_equal(boss.phase_id(), "spring", "击败守巢者后才打开泉室")
	_expect_equal(boss_victory["snapshot"]["enemy_hp"], 0, "首领伤害不会低于零")
	_expect_equal(boss_victory["snapshot"]["focus_turns"], 0, "战斗结束清理持续状态")
	_expect_true(boss_victory["events"].has("battle_won"), "首领胜利返回最终战斗事件")


func _test_companion_retreat_and_rescue() -> void:
	var deployed = _battle_state()
	var deployment: Dictionary = deployed.choose("deploy_spring_lamp")
	_expect_true(deployment["ok"], "战斗中可以布置战术石灯")
	_expect_equal(deployment["snapshot"]["spring_lamps"], 0, "部署物占用唯一战术槽")
	_expect_equal(deployment["snapshot"]["lamp_turns"], 1, "部署回合后石灯仍可再保护一次")
	_expect_equal(deployment["snapshot"]["player_hp"], 10, "部署回合由石灯降低一点伤害")
	_expect_true(deployment["events"].has("spring_lamp_absorbed"), "部署返回持续效果事件")
	var warded_guard: Dictionary = deployed.choose("guard")
	_expect_equal(warded_guard["snapshot"]["player_hp"], 9, "守势与石灯削弱预告的四点重击")
	_expect_equal(warded_guard["snapshot"]["lamp_turns"], 0, "石灯持续次数耗尽")
	_expect_false(deployed.available_actions().has("deploy_spring_lamp"), "已占用的部署槽从行动隐藏")
	_expect_false(deployed.choose("deploy_spring_lamp")["ok"], "同一挑战不能重复部署石灯")

	var supported = _battle_state()
	supported.choose("use_art")
	var support: Dictionary = supported.choose("companion_support")
	_expect_true(support["ok"], "战斗中可以请求篇章同伴援护")
	_expect_equal(support["snapshot"]["player_hp"], 10, "援护治疗并抵消大半当回合重击")
	_expect_equal(support["snapshot"]["companion_supports"], 0, "援护资源每场只能使用一次")
	_expect_false(supported.available_actions().has("companion_support"), "用尽的援护从玩家选项隐藏")
	var no_support: Dictionary = supported.choose("companion_support")
	_expect_false(no_support["ok"], "同一场战斗不能重复获得援护")
	_expect_equal(no_support["snapshot"]["player_hp"], 10, "无效援护不会触发敌方攻击")

	var retreated = _battle_state()
	retreated.choose("use_talisman")
	var retreat: Dictionary = retreated.choose("retreat")
	_expect_true(retreat["ok"], "战斗中可以主动撤退")
	_expect_equal(retreated.phase_id(), "mountain_path", "撤退返回山道旧石标")
	_expect_equal(retreat["snapshot"]["enemy_hp"], 12, "撤退后敌人恢复完整甲势")
	_expect_equal(retreat["snapshot"]["talismans"], 0, "撤退不会返还已消耗符箓")
	_expect_equal(retreat["snapshot"]["setbacks"], 1, "撤退记录一次挫败")
	_expect_equal(retreat["snapshot"]["spring_lamps"], 1, "撤退后下一次挑战可重新布灯")
	_expect_true(retreated.choose("approach_enemy")["ok"], "撤退后可在山道再次挑战")

	var rescued = _battle_state()
	var final_guard: Dictionary = {}
	for turn in range(12):
		final_guard = rescued.choose("guard")
		if rescued.phase_id() == "riverbank":
			break
	_expect_equal(rescued.phase_id(), "riverbank", "气血耗尽不会形成死档")
	_expect_true(final_guard["events"].has("companion_rescue"), "气血耗尽触发同伴救援")
	_expect_equal(final_guard["snapshot"]["player_hp"], 8, "救援后恢复到可继续状态")
	_expect_equal(final_guard["snapshot"]["setbacks"], 1, "救援记录一次挫败")


func _test_first_breath_ritual_and_completion() -> void:
	var incomplete = JourneyStateScript.new()
	var incomplete_snapshot: Dictionary = incomplete.snapshot()
	_expect_false(incomplete.complete_epilogue("record")["ok"], "章节完成前不能结算余波回应")
	_expect_equal(incomplete.snapshot(), incomplete_snapshot, "非法余波回应不修改旅程")
	var state = _battle_state()
	state.choose("guard")
	state.choose("use_talisman")
	state.choose("use_art")
	state.choose("use_art")
	_defeat_boss(state)
	_expect_equal(state.phase_id(), "spring", "组合行动可以获胜")
	_expect_false(state.choose("invalid")["ok"], "泉室拒绝未知行动")
	_expect_equal(state.first_breath_stage, "unstarted", "进入泉室从三步引息起点开始")
	_expect_equal(
		state.available_actions(),
		PackedStringArray(["listen_to_spring", "warm_meridians", "breakthrough"]),
		"泉室三个空间仪点都可被亲自尝试"
	)
	var initial_ritual_snapshot: Dictionary = state.snapshot()
	for initial_wrong_action in ["warm_meridians", "breakthrough"]:
		var initial_wrong_result: Dictionary = state.choose(initial_wrong_action)
		_expect_false(initial_wrong_result["ok"], "未听泉前越级仪轨被安全拒绝")
		_expect_equal(initial_wrong_result["events"], ["first_breath_out_of_order"], "越级仪轨返回稳定顺序提示")
		_expect_equal(state.snapshot(), initial_ritual_snapshot, "未听泉越级不损耗任何资源或推进状态")

	var listened: Dictionary = state.choose("listen_to_spring")
	_expect_true(listened["ok"], "第一步听泉辨脉成功")
	_expect_equal(listened["events"], ["spring_listened"], "听泉返回稳定语义事件")
	_expect_equal(state.first_breath_stage, "listened", "听泉后记录第一步完成")
	_expect_true(state.gathered_moonleaf, "听泉不会提前消耗月芽草")
	var listened_snapshot: Dictionary = state.snapshot()
	for listened_wrong_action in ["listen_to_spring", "breakthrough"]:
		var listened_wrong_result: Dictionary = state.choose(listened_wrong_action)
		_expect_false(listened_wrong_result["ok"], "听泉后重复或越级仪轨被安全拒绝")
		_expect_equal(listened_wrong_result["events"], ["first_breath_out_of_order"], "听泉后的错误步骤返回同一稳定提示")
		_expect_equal(state.snapshot(), listened_snapshot, "听泉后的错误步骤保持完整快照原子不变")

	var warmed: Dictionary = state.choose("warm_meridians")
	_expect_true(warmed["ok"], "第二步月芽温脉成功")
	_expect_equal(warmed["events"], ["meridians_warmed"], "温脉返回稳定语义事件")
	_expect_equal(state.first_breath_stage, "warmed", "温脉后记录第二步完成")
	_expect_false(state.gathered_moonleaf, "月芽草只在正确温脉步骤被消耗")
	var warmed_snapshot: Dictionary = state.snapshot()
	for warmed_wrong_action in ["listen_to_spring", "warm_meridians"]:
		var warmed_wrong_result: Dictionary = state.choose(warmed_wrong_action)
		_expect_false(warmed_wrong_result["ok"], "温脉后倒退或重复仪轨被安全拒绝")
		_expect_equal(warmed_wrong_result["events"], ["first_breath_out_of_order"], "温脉后的错误步骤返回稳定提示")
		_expect_equal(state.snapshot(), warmed_snapshot, "温脉后的错误步骤不会再次消耗资源")

	var result: Dictionary = state.choose("breakthrough")
	_expect_true(result["ok"], "第三步静坐引息成功")
	_expect_equal(result["events"], ["breakthrough"], "静坐引息沿用稳定突破事件")
	_expect_equal(result["snapshot"]["realm"], "引息境一层", "境界更新")
	_expect_equal(result["snapshot"]["first_breath_stage"], "completed", "完成态记录三步仪轨闭环")
	_expect_false(result["snapshot"]["gathered_moonleaf"], "最终引息不会返还或重复消耗灵草")
	_expect_equal(result["snapshot"]["moonleaf_method"], "whole_plant", "突破后仍保留采集方式用于结算")
	_expect_equal(state.available_actions(), PackedStringArray(["review_journey", "return_to_title", "replay_chapter"]), "完成后可回顾、返回标题或重游")
	_expect_true(state.choose("review_journey")["ok"], "回顾不重复奖励")
	var complete_snapshot: Dictionary = state.snapshot()
	var recorded: Dictionary = state.complete_epilogue("record")
	_expect_true(recorded["ok"] and recorded["events"] == ["epilogue_recorded"], "记录札记回应返回稳定语义事件")
	_expect_equal(state.snapshot(), complete_snapshot, "余波回应不追加数值、奖励或隐藏状态")
	_expect_true(state.complete_epilogue("return")["events"].has("epilogue_returned"), "再走一程回应有独立语义回声")
	_expect_false(state.complete_epilogue("steal_reward")["ok"], "未知余波回应不会进入规则层")
	_expect_true(state.choose("return_to_title")["ok"], "规则层允许完成本节返回标题")
	var complete_with_patrol: Dictionary = state.snapshot()
	complete_with_patrol["patrol_response"] = "herbs_first"
	_expect_true(state.restore(complete_with_patrol), "完成态可保留既有巡路选择用于重游重置校验")
	var replay: Dictionary = state.choose("replay_chapter")
	_expect_true(replay["ok"], "完成后可以重游本章")
	_expect_equal(replay["snapshot"]["phase"], "riverbank", "重游回到渡口")
	_expect_equal(replay["snapshot"]["realm"], "凡身", "重游重置境界")
	_expect_equal(replay["snapshot"]["talismans"], 1, "重游重置消耗品")
	_expect_equal(replay["snapshot"]["setbacks"], 0, "重游重置挫败记录")
	_expect_equal(replay["snapshot"]["spring_lamps"], 1, "重游重置战术部署物")
	_expect_false(replay["snapshot"]["talked_to_companion"], "重游重置开场交谈")
	_expect_equal(replay["snapshot"]["moonleaf_method"], "unselected", "重游重置采集选择")
	_expect_equal(replay["snapshot"]["patrol_response"], "unanswered", "重游清空巡路先后选择")
	_expect_equal(replay["snapshot"]["first_breath_stage"], "unstarted", "重游清空三步引息进度")
	_expect_false(state.choose("breakthrough")["ok"], "突破不能重复")


func _test_visual_scale_scene() -> void:
	var scene: PackedScene = load("res://tools/scale_test.tscn")
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect_equal(instance.recommended_actor_height_px(), 56.0, "比例测试锁定 56 px 工作基准")
	instance.queue_free()
	await process_frame


func _test_scene_smoke() -> void:
	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SCENE_SETTINGS_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var instance := scene.instantiate()
	instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(instance)
	await process_frame
	_expect_true(instance.get_node("%TitleOverlay").visible, "首次启动显示中文标题界面")
	_expect_false(instance.get_node("%JournalButton").visible, "标题界面不显示地图内札记入口")
	_expect_true(instance.get_node("%TitleOverlay").z_index > instance.get_node("%PlayerSprite").z_index, "标题纸面位于角色精灵之上")
	_expect_true(instance.get_node("%PauseOverlay").z_index > instance.get_node("%TitleOverlay").z_index, "暂停模态层不会被标题或地图穿透")
	_expect_true(instance.get_node("%DialogueOverlay").z_index > instance.get_node("%PlayerSprite").z_index, "对话纸面位于角色精灵之上")
	_expect_true(instance.get_node("%ContinueButton").disabled, "没有存档时继续按钮禁用")
	_expect_equal(instance.get_node("%TitleAudioButton").text, "环境音：关闭", "标题默认静音且不自动播放")
	_expect_equal(instance.get_node("%TitleBattleSpeedButton").text, "战斗表现：标准", "标题默认显示标准战斗表现")
	_expect_equal(instance.get_node("%TitleMotionButton").text, "动态效果：完整", "标题默认显示完整动态效果")
	_expect_equal(instance.get_node("%TitleDialogueSpeedButton").text, "对话显字：标准", "标题默认显示标准对话显字速度")
	_expect_equal(instance.get_node("%PauseDialogueSpeedButton").text, "对话显字：标准", "标题与暂停默认对话显字速度同步")
	var transition: Control = instance.get_node("%SceneTransition")
	_expect_true(instance.get_node("%JournalOverlay").z_index > instance.get_node("%DialogueOverlay").z_index, "行旅札记覆盖对话以下的游戏层")
	_expect_true(instance.get_node("%JournalOverlay").z_index < instance.get_node("%TitleOverlay").z_index, "标题界面始终高于行旅札记")
	_expect_true(instance.get_node("%JournalOverlay").z_index < instance.get_node("%PauseOverlay").z_index, "暂停模态始终高于行旅札记")
	_expect_true(transition.z_index < instance.get_node("%DialogueOverlay").z_index, "转场纸面不会覆盖对话模态")
	_expect_true(transition.z_index > instance.get_node("%MapCanvas").occlusion_contract()["map_depth_ceiling"], "转场纸面覆盖完整地图深度带")
	transition.play("藏泉山道 · 石阶入云", false)
	await process_frame
	var opening_transition: Dictionary = transition.transition_contract()
	_expect_true(opening_transition["active"], "完整动态会显示可感知转场")
	_expect_equal(opening_transition["duration"], 0.48, "转场时长保持短促而可读")
	_expect_true(opening_transition["blocks_input"], "活动转场阻断地图鼠标输入")
	_expect_equal(root.gui_get_focus_owner(), instance.get_node("%TransitionInputSink"), "活动转场接管键盘与手柄焦点")
	transition.advance(0.24)
	_expect_true(transition.transition_contract()["alpha"] > 0.0 and transition.transition_contract()["alpha"] < 1.0, "转场中段逐步显露新场景")
	transition.finish()
	_expect_false(transition.is_transitioning(), "转场可以确定性结束并释放输入")
	transition.play("第一息 · 山河有应", true)
	_expect_false(transition.is_transitioning(), "简化动态直接显示目标场景")
	_expect_true(transition.transition_contract()["reduced_motion"], "转场合同记录简化动态降级")
	instance.get_node("%MapCanvas").show_battle_feedback(["enemy_hit"], false, false)
	var standard_feedback: Dictionary = instance.get_node("%MapCanvas").feedback_contract()
	_expect_equal(standard_feedback["text"], "受到冲击", "标准反馈映射战斗语义事件")
	_expect_equal(standard_feedback["duration"], 0.70, "标准反馈保留完整可读时长")
	_expect_true(standard_feedback["motion_enabled"], "完整动态允许反馈脉冲")
	instance.get_node("%TitleAudioButton").pressed.emit()
	await process_frame
	_expect_equal(instance.get_node("%TitleAudioButton").text, "环境音：开启", "标题可以开启原创环境音")
	_expect_equal(instance.get_node("%PauseAudioButton").text, "环境音：开启", "标题与暂停音频开关同步")
	_expect_true(instance.get_node("%AudioManager").is_audio_active(), "开启后音频生成器运行")
	instance.get_node("%TitleVolumeButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleVolumeButton").text, "音量：100%", "音量按钮循环到满音量")
	instance.get_node("%TitleBattleSpeedButton").pressed.emit()
	instance.get_node("%TitleMotionButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleBattleSpeedButton").text, "战斗表现：快速", "标题可以切换快速战斗反馈")
	_expect_equal(instance.get_node("%PauseBattleSpeedButton").text, "战斗表现：快速", "标题与暂停战斗表现同步")
	_expect_equal(instance.get_node("%TitleMotionButton").text, "动态效果：简化", "标题可以切换简化动态")
	_expect_equal(instance.get_node("%PauseMotionButton").text, "动态效果：简化", "标题与暂停动态偏好同步")
	_expect_equal(instance.get_node("%TitleTextScaleButton").text, "文字大小：标准", "标题默认显示标准文字大小")
	_expect_equal(instance.get_node("%TitleContrastButton").text, "高对比：关闭", "标题默认关闭高对比")
	var base_accessibility: Dictionary = instance.accessibility_contract()
	_expect_false(base_accessibility["rule_authority"], "无障碍表现不成为规则权威")
	_expect_equal(base_accessibility["reading_label_count"], 15, "无障碍阅读标签清单保持精确覆盖")
	_expect_equal(base_accessibility["dialogue_speed"], "standard", "对话显字默认使用标准枚举")
	_expect_equal(base_accessibility["dialogue_characters_per_second"], 42.0, "标准对话显字保持每秒四十二字")
	_expect_false(base_accessibility["dialogue_instant"], "标准对话显字不会直接显示整句")
	var title_settings_journey: Dictionary = instance.journey.snapshot()
	instance.get_node("%TitleDialogueSpeedButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleDialogueSpeedButton").text, "对话显字：快速", "标题可切到快速对话显字")
	_expect_equal(instance.get_node("%PauseDialogueSpeedButton").text, "对话显字：快速", "标题与暂停快速对话显字同步")
	_expect_equal(instance.accessibility_contract()["dialogue_characters_per_second"], 84.0, "快速对话显字使用每秒八十四字")
	instance.get_node("%TitleDialogueSpeedButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleDialogueSpeedButton").text, "对话显字：整句", "标题可关闭渐显并直接显示整句")
	_expect_true(instance.accessibility_contract()["dialogue_instant"], "整句模式在无障碍合同中明确可见")
	instance.get_node("%TitleDialogueSpeedButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleDialogueSpeedButton").text, "对话显字：标准", "第三次切换稳定回到标准对话显字")
	_expect_equal(instance.journey.snapshot(), title_settings_journey, "标题对话显字设置不进入旅程规则")
	instance.get_node("%TitleTextScaleButton").pressed.emit()
	instance.get_node("%TitleContrastButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleTextScaleButton").text, "文字大小：大字", "标题可以切换大字模式")
	_expect_equal(instance.get_node("%PauseTextScaleButton").text, "文字大小：大字", "标题与暂停文字大小同步")
	_expect_equal(instance.get_node("%TitleContrastButton").text, "高对比：开启", "标题可以开启高对比文字")
	_expect_equal(instance.get_node("%PauseContrastButton").text, "高对比：开启", "标题与暂停对比偏好同步")
	var boosted_accessibility: Dictionary = instance.accessibility_contract()
	_expect_equal(boosted_accessibility["dialogue_font_size"], ceili(float(base_accessibility["dialogue_font_size"]) * 1.25), "大字模式放大对话正文")
	_expect_true(boosted_accessibility["dialogue_font_size"] > base_accessibility["dialogue_font_size"], "大字模式严格大于基准字号")
	_expect_equal(boosted_accessibility["dialogue_font_color"].a, 1.0, "高对比正文使用完全不透明文字")
	_expect_true(boosted_accessibility["dialogue_font_color"] != base_accessibility["dialogue_font_color"], "高对比正文颜色相对基准增强")
	_expect_equal(boosted_accessibility["dialogue_font_color"], instance.HIGH_CONTRAST_INK, "浅纸上的深色正文推向深墨锚点")
	_expect_equal(instance.get_node("%StatusLabel").get_theme_color("font_color"), instance.HIGH_CONTRAST_PAPER, "深底上的浅色状态文字推向纸白锚点")
	instance.get_node("%TitleTextScaleButton").pressed.emit()
	_expect_equal(instance.accessibility_contract()["dialogue_font_size"], base_accessibility["dialogue_font_size"], "恢复标准后正文回到基准字号")
	instance.get_node("%TitleContrastButton").pressed.emit()
	_expect_equal(instance.accessibility_contract()["dialogue_font_color"], base_accessibility["dialogue_font_color"], "关闭高对比后正文回到基准颜色")
	instance.get_node("%TitleTextScaleButton").pressed.emit()
	instance.get_node("%TitleContrastButton").pressed.emit()
	instance.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_false(instance.get_node("%TitleOverlay").visible, "新游戏进入实际地图")
	_expect_true(instance.get_node("%JournalButton").visible, "进入游戏后显示可点击行旅札记入口")
	_expect_true(SaveGameScript.exists(TEST_SCENE_SAVE_PATH), "新游戏立即建立版本化存档")
	_expect_equal(instance.get_node("%LocationLabel").text, "照禾渡口", "主场景读取内容")
	_expect_equal(_action_button_count(instance), 1, "出生点只显示近距离同伴交谈")
	_expect_equal(instance.get_node("%MapCanvas").actor_height_px(), 56.0, "角色使用 56 px 生产基准")
	_expect_true(instance.get_node("%MapCanvas").uses_animated_actor_sprites(), "主角、同伴、两位渡口居民与巡路人使用 AnimatedSprite2D 表现节点")
	var player_sprite: AnimatedSprite2D = instance.get_node("%PlayerSprite")
	var sprite_contract: Dictionary = player_sprite.animation_contract()
	_expect_equal(sprite_contract["frame_size"], Vector2(32, 56), "人物帧遵守 32×56 像素合同")
	_expect_equal(sprite_contract["foot_anchor"], Vector2(16, 52), "人物动画共享固定脚底锚点")
	_expect_equal(sprite_contract["collision_box"], Vector2(16, 20), "动画与 16×20 碰撞基准解耦")
	_expect_equal(sprite_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "人物纹理使用最近邻过滤")
	_expect_equal(player_sprite.sprite_frames.get_animation_names().size(), 8, "人物提供四方向待机与行走动画")
	_expect_equal(player_sprite.sprite_frames.get_frame_count("walk_right"), 2, "行走方向包含两个可循环帧")
	var ferryman_sprite: AnimatedSprite2D = instance.get_node("%FerrymanSprite")
	_expect_true(ferryman_sprite.visible, "梁叔在渡口以独立地图角色出现")
	_expect_equal(ferryman_sprite.animation_contract()["frame_size"], Vector2(32, 56), "守堤人复用固定人物动画合同")
	var herbkeeper_sprite: AnimatedSprite2D = instance.get_node("%HerbkeeperSprite")
	_expect_true(herbkeeper_sprite.visible, "蕙婶在渡口药圃旁以独立地图角色出现")
	_expect_equal(herbkeeper_sprite.animation_contract()["frame_size"], Vector2(32, 56), "药圃守复用固定人物动画合同")
	_expect_equal(herbkeeper_sprite.animation, &"idle_left", "蕙婶以朝向渡口主路的稳定待机帧出现")
	var patrol_sprite: AnimatedSprite2D = instance.get_node("%PatrolSprite")
	_expect_false(patrol_sprite.visible, "同伴简报前陶小满不提前出现在渡口")
	_expect_equal(patrol_sprite.animation_contract()["frame_size"], Vector2(32, 56), "巡路人作为第五位地图人物复用固定动画合同")
	_expect_equal(patrol_sprite.atlas_texture.resource_path, "res://assets/pixel/tao_xiaoman.png", "巡路人读取提交的陶小满独立人物图集")
	_expect_equal(patrol_sprite.animation, &"idle_up", "陶小满从稳定朝北待机帧开始")
	var initial_ferryman_visual: Dictionary = instance.get_node("%MapCanvas").ferryman_visual_contract()
	_expect_equal(initial_ferryman_visual["response"], "unanswered", "未交谈时地图不替玩家选择守堤处理")
	_expect_false(initial_ferryman_visual["gauge_upright"], "初始歪斜水尺可从地图辨认")
	_expect_true(instance.get_node("%MapCanvas").uses_animated_enemy_sprites(), "山道与战斗敌人使用 AnimatedSprite2D 表现节点")
	var enemy_sprite: AnimatedSprite2D = instance.get_node("%BattleEnemySprite")
	var enemy_sprite_contract: Dictionary = enemy_sprite.animation_contract()
	_expect_equal(enemy_sprite_contract["frame_size"], Vector2(64, 64), "敌人图集使用 64×64 像素帧")
	_expect_equal(enemy_sprite_contract["foot_anchor"], Vector2(32, 56), "四类敌人共享固定脚底锚点")
	_expect_equal(enemy_sprite_contract["frames_per_state"], 2, "每类敌人的待机、攻击与受击姿态各使用两帧")
	_expect_equal(enemy_sprite_contract["animations_per_profile"], 3, "每类敌人提供三种稳定语义姿态")
	_expect_equal(enemy_sprite_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "敌人纹理使用最近邻过滤")
	_expect_false(enemy_sprite_contract["damage_authority"], "敌人动画不决定伤害")
	_expect_false(enemy_sprite_contract["intent_authority"], "敌人动画不决定意图")
	_expect_false(enemy_sprite_contract["gameplay_timing_authority"], "敌人动画不推进规则时间")
	_expect_false(enemy_sprite_contract["save_authority"], "敌人动画不写入存档")
	_expect_equal(enemy_sprite.sprite_frames.get_animation_names().size(), 12, "四个稳定敌人标识各提供三种动画")
	_expect_equal(enemy_sprite.sprite_frames.get_frame_count("idle_rock_armor_warden"), 2, "首领使用独立双帧图集行")
	var enemy_rows := {
		"rock_armor_young": 0,
		"spring_moss_shell": 1,
		"unbalanced_stone_puppet": 2,
		"rock_armor_warden": 3,
	}
	var enemy_state_columns := {"idle": 0, "attack": 2, "react": 4}
	var enemy_state_fps := {"idle": 2.5, "attack": 8.0, "react": 7.0}
	var enemy_atlas_image: Image = enemy_sprite.atlas_texture.get_image()
	_expect_equal(enemy_atlas_image.get_size(), Vector2i(384, 256), "敌人源图集严格使用六列四行")
	for profile_row in range(4):
		for atlas_column in range(6):
			var opaque_pixels := 0
			var opaque_border_pixels := 0
			for frame_y in range(64):
				for frame_x in range(64):
					var pixel := enemy_atlas_image.get_pixel(atlas_column * 64 + frame_x, profile_row * 64 + frame_y)
					if pixel.a > 0.0:
						opaque_pixels += 1
						if frame_x in [0, 63] or frame_y in [0, 63]:
							opaque_border_pixels += 1
			_expect_true(opaque_pixels > 0, "敌人图集第 %d 行第 %d 列不是透明空帧" % [profile_row, atlas_column])
			_expect_equal(opaque_border_pixels, 0, "敌人图集第 %d 行第 %d 列保留透明防串色边界" % [profile_row, atlas_column])
	for profile_id in enemy_rows:
		for state_id in enemy_state_columns:
			var semantic_animation := "%s_%s" % [state_id, profile_id]
			_expect_true(enemy_sprite.sprite_frames.has_animation(semantic_animation), "%s 存在" % semantic_animation)
			_expect_equal(enemy_sprite.sprite_frames.get_frame_count(semantic_animation), 2, "%s 使用双帧" % semantic_animation)
			_expect_equal(enemy_sprite.sprite_frames.get_animation_loop(semantic_animation), state_id == "idle", "%s 循环合同正确" % semantic_animation)
			_expect_equal(enemy_sprite.sprite_frames.get_animation_speed(semantic_animation), enemy_state_fps[state_id], "%s 使用固定表现帧率" % semantic_animation)
			for semantic_frame_index in range(2):
				var semantic_frame: AtlasTexture = enemy_sprite.sprite_frames.get_frame_texture(semantic_animation, semantic_frame_index)
				_expect_equal(semantic_frame.region, Rect2(float(enemy_state_columns[state_id] + semantic_frame_index) * 64.0, float(enemy_rows[profile_id]) * 64.0, 64.0, 64.0), "%s 第 %d 帧读取固定图集区域" % [semantic_animation, semantic_frame_index])
	var journey_before_enemy_presentation: Dictionary = instance.journey.snapshot()
	for profile_id in enemy_rows:
		_expect_true(enemy_sprite.set_enemy_id(profile_id), "%s 可选择固定表现行" % profile_id)
		var stable_enemy_position := enemy_sprite.position
		_expect_true(enemy_sprite.consume_battle_events(["enemy_hit"], false, false), "%s 消费敌方反击语义" % profile_id)
		var attack_contract: Dictionary = enemy_sprite.presentation_contract()
		_expect_equal(attack_contract["state"], "attack", "%s 反击选择攻击姿态" % profile_id)
		_expect_equal(attack_contract["event_id"], "enemy_hit", "%s 记录实际消费事件" % profile_id)
		_expect_equal(attack_contract["animation"], "attack_%s" % profile_id, "%s 播放自身攻击帧" % profile_id)
		_expect_equal(attack_contract["duration"], 0.70, "%s 标准反馈使用固定表现时长" % profile_id)
		_expect_true(attack_contract["motion_enabled"], "%s 标准反馈启用双帧动作" % profile_id)
		_expect_false(attack_contract["rule_authority"], "%s 表现姿态不拥有规则权威" % profile_id)
		_expect_false(attack_contract["timing_authority"], "%s 表现时长不拥有回合权威" % profile_id)
		_expect_false(attack_contract["save_authority"], "%s 表现姿态不拥有存档权威" % profile_id)
		_expect_false(attack_contract["blocks_input"], "%s 一次性姿态不阻断下一次输入" % profile_id)
		_expect_equal(enemy_sprite.position, stable_enemy_position, "%s 语义动画不移动规则脚点" % profile_id)
		enemy_sprite.frame = 1
		_expect_true(enemy_sprite.consume_battle_events(["enemy_hit"], false, false), "%s 可被同一新事件替换" % profile_id)
		_expect_equal(enemy_sprite.frame, 0, "%s 重复事件从第一帧重启" % profile_id)
		_expect_true(enemy_sprite.consume_battle_events(["art_hit", "enemy_hit"], false, false), "%s 消费玩家命中语义" % profile_id)
		var reaction_contract: Dictionary = enemy_sprite.presentation_contract()
		_expect_equal(reaction_contract["state"], "react", "%s 命中优先于同批敌方反击" % profile_id)
		_expect_equal(reaction_contract["event_id"], "art_hit", "%s 固定优先级不依赖事件排列" % profile_id)
		_expect_true(enemy_sprite.consume_battle_events(["enemy_glanced", "weakness_exposed"], false, false), "%s 消费破绽语义" % profile_id)
		_expect_equal(enemy_sprite.presentation_contract()["event_id"], "weakness_exposed", "%s 破绽优先于格挡反馈" % profile_id)
		var stable_reaction: Dictionary = enemy_sprite.presentation_contract()
		_expect_false(enemy_sprite.consume_battle_events(["unknown_event", 7], false, false), "%s 原子忽略未知事件" % profile_id)
		_expect_equal(enemy_sprite.presentation_contract(), stable_reaction, "%s 未知事件不污染当前表现" % profile_id)
		_expect_false(enemy_sprite.advance_presentation(0.0), "%s 拒绝零表现步长" % profile_id)
		_expect_false(enemy_sprite.advance_presentation(-0.1), "%s 拒绝负表现步长" % profile_id)
		_expect_false(enemy_sprite.advance_presentation(NAN), "%s 拒绝非有限表现步长" % profile_id)
		_expect_equal(enemy_sprite.presentation_contract(), stable_reaction, "%s 非法步长不污染当前表现" % profile_id)
		_expect_true(enemy_sprite.advance_presentation(0.70), "%s 精确边界结束一次性姿态" % profile_id)
		_expect_equal(enemy_sprite.presentation_contract()["state"], "idle", "%s 到时恢复自身待机" % profile_id)
		_expect_true(enemy_sprite.consume_battle_events(["enemy_glanced"], true, true), "%s 消费快速简化动态事件" % profile_id)
		var reduced_contract: Dictionary = enemy_sprite.presentation_contract()
		_expect_equal(reduced_contract["duration"], 0.18, "%s 快速模式只缩短表现时长" % profile_id)
		_expect_false(reduced_contract["motion_enabled"], "%s 简化动态冻结语义首帧" % profile_id)
		_expect_true(reduced_contract["motion_skipped"], "%s 合同标记已跳过运动" % profile_id)
		_expect_equal(enemy_sprite.frame, 0, "%s 简化动态保留可读静态姿态" % profile_id)
		_expect_true(enemy_sprite.advance_presentation(1.0), "%s 过大合法步长安全收束" % profile_id)
		_expect_equal(enemy_sprite.presentation_contract()["state"], "idle", "%s 过大步长无残留姿态" % profile_id)
	_expect_true(enemy_sprite.set_enemy_id("rock_armor_young"), "表现偏好四象限测试使用稳定敌人")
	_expect_true(enemy_sprite.consume_battle_events(["enemy_hit"], true, false), "快速完整动态消费攻击事件")
	_expect_equal(enemy_sprite.presentation_contract()["duration"], 0.18, "快速完整动态只缩短表现时长")
	_expect_true(enemy_sprite.presentation_contract()["motion_enabled"], "快速模式不会擅自关闭动作")
	_expect_true(enemy_sprite.consume_battle_events(["enemy_hit"], false, true), "标准简化动态消费攻击事件")
	_expect_equal(enemy_sprite.presentation_contract()["duration"], 0.70, "简化动态不会擅自缩短标准时长")
	_expect_false(enemy_sprite.presentation_contract()["motion_enabled"], "标准简化动态只冻结动作")
	for suppressed_event in ["battle_won", "retreated", "companion_rescue"]:
		_expect_true(enemy_sprite.consume_battle_events(["enemy_hit"], false, false), "%s 抑制前建立活动姿态" % suppressed_event)
		_expect_false(enemy_sprite.consume_battle_events([suppressed_event], false, false), "%s 不播放不属于当前档案的瞬时姿态" % suppressed_event)
		_expect_equal(enemy_sprite.presentation_contract()["state"], "idle", "%s 重置到待机" % suppressed_event)
		_expect_equal(enemy_sprite.animation, &"idle_rock_armor_young", "%s 保留当前档案行" % suppressed_event)
	_expect_true(enemy_sprite.set_enemy_id("rock_armor_warden"), "终局抑制测试先同步到首领行")
	_expect_false(enemy_sprite.consume_battle_events(["art_hit", "regular_enemy_won", "boss_arrived"], false, false), "普通敌人退场与首领入场抑制错误受击动画")
	_expect_equal(enemy_sprite.animation, &"idle_rock_armor_warden", "首领不会替已退场普通敌人播放受击")
	var stable_warden_contract: Dictionary = enemy_sprite.presentation_contract()
	_expect_false(enemy_sprite.set_enemy_id("unknown_enemy"), "敌人表现节点拒绝未知配置而不伪造动画")
	_expect_equal(enemy_sprite.presentation_contract(), stable_warden_contract, "非法表现标识原子保留当前首领状态")
	_expect_equal(instance.journey.snapshot(), journey_before_enemy_presentation, "敌人表现测试不会改变领域快照")
	_expect_true(enemy_sprite.set_enemy_id("rock_armor_young"), "后续场景测试恢复默认敌人表现行")
	var map_canvas = instance.get_node("%MapCanvas")
	var world_root: Node2D = instance.get_node("%WorldRoot")
	var map_frame: Control = instance.get_node("%MapFrame")
	var world_contract: Dictionary = map_canvas.world_visual_contract()
	_expect_equal(world_contract["world_size"], Vector2(1536, 864), "地图表现展开为大于最小窗口的 48×27 世界")
	_expect_equal(world_contract["expected_world_size"], Vector2(1536, 864), "世界像素尺寸与 32 px 地图合同一致")
	_expect_true(world_contract["world_size"].x > map_frame.size.x and world_contract["world_size"].y > map_frame.size.y, "渡口需要镜头滚动而非一次显示全部目标")
	_expect_true(world_contract["normalized_coordinates"], "扩大世界仍只消费 domain 归一化坐标")
	_expect_false(world_contract["collision_authority"], "地图表现不会成为第二套碰撞权威")
	_expect_equal(map_canvas.get_parent(), world_root, "地图画布与人物位于统一世界根节点")
	_expect_equal(instance.get_node("%FerryGround").get_parent(), world_root, "地表与地图画布共享同一镜头变换")
	_expect_equal(instance.get_node("%MapDetailLayer").get_parent(), world_root, "细节层与人物共享同一镜头变换")
	_expect_false(world_root.is_ancestor_of(instance.get_node("%ChapterLabel")), "HUD 保持屏幕空间而不随世界镜头移动")
	var world_depth_ceiling := int(map_canvas.occlusion_contract()["map_depth_ceiling"])
	for hud_path in ["ChapterHud", "StatusHud", "StoryPanel"]:
		_expect_true(instance.get_node(hud_path).z_index > world_depth_ceiling, "%s 绘制在全部世界角色与遮挡物之上" % hud_path)
	var initial_camera: Dictionary = instance.world_camera_contract()
	_expect_equal(initial_camera["world_size"], Vector2(1536, 864), "场景镜头读取固定世界边界")
	_expect_equal(initial_camera["world_offset"], world_root.position, "场景世界根节点应用镜头偏移")
	_expect_true(initial_camera["pixel_snap"], "场景镜头不产生半像素抖动")
	var initial_screen_focus: Vector2 = initial_camera["world_focus"] - initial_camera["origin"]
	_expect_true(initial_camera["safe_frame"]["rect"].has_point(initial_screen_focus), "出生点在顶部 HUD 与底部纸面之间取景")
	var hud_position_before_camera: Vector2 = instance.get_node("%ChapterLabel").global_position
	var initial_camera_origin: Vector2 = initial_camera["origin"]
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "镜头测试可到达东侧山门")
	instance._render([])
	_expect_true(instance.world_camera_contract()["origin"].x > initial_camera_origin.x, "远端传送在同一渲染帧重新取景")
	_expect_equal(instance.get_node("%ChapterLabel").global_position, hud_position_before_camera, "镜头移动不挪动屏幕空间 HUD")
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "镜头测试后恢复稳定出生点")
	instance._render([])
	var initial_patrol_visual: Dictionary = map_canvas.patrol_visual_contract()
	_expect_false(initial_patrol_visual["active"], "简报前巡路表现合同保持未激活")
	_expect_false(initial_patrol_visual["visible"], "未激活巡路表现不占用地图画面")
	_expect_equal(initial_patrol_visual["response"], "unanswered", "巡路表现不替玩家决定先后")
	_expect_equal(initial_patrol_visual["normalized_position"], PatrolStateScript.START_POSITION, "巡路表现从 domain 默认坐标同步")
	_expect_false(initial_patrol_visual["collision_authority"], "巡路精灵不拥有碰撞权威")
	_expect_false(initial_patrol_visual["quest_authority"], "巡路精灵不拥有任务权威")
	var landmark_contract: Dictionary = map_canvas.landmark_visual_contract()
	_expect_equal(landmark_contract["schema_version"], 2, "照禾地标表现合同使用稳定版本")
	_expect_equal(landmark_contract["atlas_path"], "res://assets/pixel/zhaohe_landmarks.png", "地图读取提交的原创地标图集")
	_expect_equal(landmark_contract["atlas_size"], Vector2(2112, 128), "十一个地标帧完整装入固定图集")
	_expect_equal(landmark_contract["frame_size"], Vector2i(192, 128), "每个地标区域使用固定像素边界")
	_expect_equal(landmark_contract["profiles"].size(), 11, "表现合同只暴露十一个稳定地标标识")
	for profile_id in ["tree_celadon", "ferry_house_rust", "ferry_house_ochre", "ferry_house_teal", "ferry_dock", "mountain_rock", "spring_cave", "spring_gate", "ferry_boat_repair", "ferry_drying_rack", "path_rain_shelter"]:
		_expect_true(landmark_contract["profiles"].has(profile_id), "地标合同包含 %s" % profile_id)
	var life_landmarks: Dictionary = landmark_contract["life_landmarks"]
	_expect_equal(life_landmarks.size(), 3, "地标合同精确暴露三处生活地标")
	_expect_equal(life_landmarks["ferry_boat_repair"]["visual_feet"], Vector2(0.38, 0.35), "补船木架视觉脚点避开既有树冠并贴近可走地表")
	_expect_equal(life_landmarks["ferry_boat_repair"]["interaction_anchor"], ExplorationStateScript.BOAT_REPAIR_POSITION, "补船木架表现复用 domain 交互锚点")
	_expect_equal(life_landmarks["ferry_drying_rack"]["visual_feet"], Vector2(0.915, 0.48), "晾晒竹架收在东侧房屋旁")
	_expect_equal(life_landmarks["ferry_drying_rack"]["interaction_anchor"], ExplorationStateScript.DRYING_RACK_POSITION, "晾晒竹架表现复用 domain 交互锚点")
	_expect_equal(life_landmarks["path_rain_shelter"]["visual_feet"], Vector2(0.575, 0.69), "避雨石棚位于山道下缘开放地带")
	_expect_equal(life_landmarks["path_rain_shelter"]["interaction_anchor"], ExplorationStateScript.PATH_RAIN_SHELTER_POSITION, "避雨石棚表现复用 domain 交互锚点")
	_expect_equal(landmark_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "地图地标以最近邻绘制")
	_expect_true(landmark_contract["pixel_snap"], "地图地标脚点锁定整数像素")
	_expect_false(landmark_contract["collision_authority"], "地标图集不替代确定性碰撞规则")
	_expect_false(map_canvas._draw_landmark("unknown_landmark", Vector2.ZERO), "地图表现拒绝未知地标标识")
	_expect_true(instance.get_node("%MapCanvas").uses_ferry_tile_layers(), "照禾渡口地表由 TileMapLayer 组成")
	var ferry_ground: TileMapLayer = instance.get_node("%FerryGround")
	var map_contract: Dictionary = ferry_ground.map_contract()
	_expect_equal(map_contract["map_size"], Vector2i(48, 27), "渡口生产地图覆盖 48×27 个网格")
	_expect_equal(map_contract["tile_size"], Vector2i(32, 32), "地图使用 32 px TileSet 网格")
	_expect_equal(map_contract["used_rect"], Rect2i(0, 0, 48, 27), "TileMapLayer 无断裂地覆盖完整滚动世界")
	_expect_equal(map_contract["tile_counts"]["water"], 432, "扩展地图水域单元数量固定")
	_expect_equal(map_contract["tile_counts"]["bank"], 108, "扩展地图岸线单元数量固定")
	_expect_equal(map_contract["tile_counts"]["moonleaf"], 32, "扩展月芽田在 TileSet 中有明确区域")
	_expect_equal(map_contract["tile_counts"]["stone"], 16, "扩展山门石地区域被地图数据标记")
	_expect_true(map_contract["tile_counts"]["path"] > 70, "扩展地图包含可读的主路与药田支路")
	_expect_equal(map_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "地图纹理使用最近邻过滤")
	_expect_true(instance.get_node("%MapCanvas").uses_map_detail_layer(), "渡口与山道共享独立细节 TileMapLayer")
	var map_detail: TileMapLayer = instance.get_node("%MapDetailLayer")
	var ferry_detail_contract: Dictionary = map_detail.map_contract()
	_expect_equal(ferry_detail_contract["schema_version"], 1, "地图细节合同使用稳定版本")
	_expect_equal(ferry_detail_contract["context_id"], "riverbank", "地图细节合同记录渡口表现上下文")
	_expect_equal(ferry_detail_contract["map_kind"], "ferry", "地图细节构建渡口固定单元图")
	_expect_equal(ferry_detail_contract["map_size"], Vector2i(48, 27), "地图细节与地表共享 48×27 边界")
	_expect_equal(ferry_detail_contract["tile_size"], Vector2i(32, 32), "地图细节使用同一 32 px 网格")
	_expect_equal(ferry_detail_contract["used_rect"], Rect2i(1, 1, 46, 26), "渡口细节占用范围保持在扩展地图内")
	_expect_equal(ferry_detail_contract["used_cell_count"], 77, "渡口细节随滚动世界保持稀疏密度")
	_expect_equal(ferry_detail_contract["tile_counts"], {
		"reeds": 9,
		"bank_grass": 8,
		"path_pebbles": 18,
		"wildflowers": 12,
		"stone_cracks": 5,
		"moss": 7,
		"fallen_leaves": 10,
		"water_foam": 8,
	}, "渡口八类透明细节数量固定")
	_expect_equal(ferry_detail_contract["tile_cells"]["stone_cracks"], [Vector2i(40, 3), Vector2i(43, 4), Vector2i(41, 5), Vector2i(42, 6), Vector2i(40, 6)], "渡口石裂只落在扩展山门石地")
	_expect_equal(ferry_detail_contract["tile_cells"]["water_foam"], [Vector2i(3, 4), Vector2i(8, 9), Vector2i(5, 16), Vector2i(12, 20), Vector2i(1, 24), Vector2i(6, 2), Vector2i(14, 11), Vector2i(4, 26)], "渡口水沫使用固定扩展河面单元")
	_expect_true(ferry_detail_contract["visible"], "渡口细节在探索与标题底图可见")
	_expect_false(ferry_detail_contract["collision_authority"], "地图细节明确不拥有碰撞权威")
	_expect_equal(ferry_detail_contract["physics_layer_count"], 0, "细节 TileSet 不建立物理层")
	_expect_equal(ferry_detail_contract["navigation_layer_count"], 0, "细节 TileSet 不建立导航层")
	_expect_equal(ferry_detail_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "透明细节使用最近邻过滤")
	_expect_equal(ferry_detail_contract["rebuild_count"], 1, "渡口细节首次只构建一次")
	_expect_equal(ferry_detail_contract["layout_signature"].length(), 64, "渡口细节暴露完整布局签名")
	_expect_detail_cells_bounded_and_unique(ferry_detail_contract, "渡口")
	var before_detail_resync: Dictionary = instance.journey.snapshot()
	instance._render([])
	_expect_equal(map_detail.map_contract()["rebuild_count"], 1, "同一渡口上下文重复渲染不重建细节")
	_expect_equal(instance.journey.snapshot(), before_detail_resync, "纯表现细节同步不修改确定性旅程")
	var ferry_occlusion: Dictionary = map_canvas.occlusion_contract()
	_expect_equal(ferry_occlusion["count"], 7, "渡口以三处屋檐和四处树冠组成独立前景节点")
	_expect_equal(ferry_occlusion["asset_backed_count"], 7, "渡口全部可排序前景由同一像素地标图集提供")
	_expect_true(ferry_occlusion["ids"].has("ferry_roof_0"), "前景合同包含可识别屋檐")
	_expect_true(ferry_occlusion["ids"].has("ferry_tree_3"), "前景合同包含可识别树冠")
	_expect_equal(ferry_occlusion["profiles"]["ferry_roof_0"], "ferry_house_rust", "首栋房屋映射稳定赭瓦图集列")
	_expect_equal(ferry_occlusion["profiles"]["ferry_tree_3"], "tree_celadon", "树冠共享稳定青叶图集列")
	var first_roof: Sprite2D = map_canvas.get_node("Occluder_ferry_roof_0")
	_expect_true(first_roof.region_enabled, "房屋前景直接裁取图集区域")
	_expect_equal(first_roof.texture.resource_path, "res://assets/pixel/zhaohe_landmarks.png", "房屋前景不再即时绘制屋檐")
	_expect_equal(first_roof.position, first_roof.position.round(), "房屋脚点保持整数像素")
	_expect_true(ferry_occlusion["maximum_depth"] <= ferry_occlusion["map_depth_ceiling"], "地图前景不越过深度上限")
	_expect_true(instance.get_node("%DialogueOverlay").z_index > ferry_occlusion["maximum_depth"], "对话模态始终位于所有地图遮挡之上")
	_expect_true(instance.get_node("%MapCanvas").depth_for_y(120.0) < instance.get_node("%MapCanvas").depth_for_y(520.0), "脚底越靠下显示深度越靠前")
	_expect_equal(ferry_occlusion["player_depth"], instance.get_node("%MapCanvas").depth_for_y(player_sprite.position.y), "主角显示深度来自脚底 Y 值")
	_expect_equal(ferry_occlusion["ferryman_depth"], instance.get_node("%MapCanvas").depth_for_y(ferryman_sprite.position.y), "守堤人显示深度来自脚底 Y 值")
	_expect_equal(ferry_occlusion["herbkeeper_depth"], instance.get_node("%MapCanvas").depth_for_y(herbkeeper_sprite.position.y), "药圃守显示深度来自脚底 Y 值")
	_expect_equal(ferry_occlusion["patrol_depth"], instance.get_node("%MapCanvas").depth_for_y(patrol_sprite.position.y), "巡路人显示深度来自脚底 Y 值")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "riverbank", "初始地图使用渡口画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("与渡碑旁"), "初始目标引导同伴交谈")
	_expect_true(instance.get_node("%InputHint").text.contains("WASD"), "探索显示键盘与手柄输入提示")
	_expect_true(InputMap.has_action("move_left"), "移动使用语义输入动作")
	_expect_true(InputMap.has_action("interact"), "交互使用语义输入动作")
	_expect_true(_action_has_joypad_event("move_left"), "移动动作包含手柄绑定")
	_expect_true(_action_has_joypad_event("interact"), "交互动作包含手柄绑定")
	_expect_true(_action_has_joypad_event("pause_menu"), "暂停动作包含手柄绑定")
	_expect_true(InputMap.has_action("open_journal"), "行旅札记使用独立语义输入动作")
	_expect_true(_action_has_joypad_event("open_journal"), "行旅札记动作包含手柄 Y 绑定")
	_expect_true(instance.get_node("%JournalButton").z_index > ferry_occlusion["map_depth_ceiling"], "札记入口不会被地图前景遮挡")
	_expect_true(instance.get_node("%JournalButton").z_index < transition.z_index, "场景转场可以覆盖札记入口")
	var before_journal: Dictionary = instance.journey.snapshot()
	instance.get_node("%JournalButton").pressed.emit()
	await process_frame
	var empty_journal: Dictionary = instance.journal_contract()
	_expect_true(empty_journal["visible"], "鼠标按钮可以打开行旅札记")
	_expect_true(empty_journal["blocks_input"], "札记纸面声明阻断背后地图输入")
	_expect_equal(empty_journal["discovered_count"], 0, "新旅程札记没有伪造见闻")
	_expect_equal(empty_journal["locked_count"], 3, "未读见闻显示为三个不剧透的空位")
	_expect_true(empty_journal["objective"].contains("砚青"), "札记回显当前任务目标")
	_expect_false(empty_journal["entries_text"].contains("渡堤三重水痕"), "未发现条目不提前揭示标题")
	_expect_equal(root.gui_get_focus_owner(), instance.get_node("%JournalCloseButton"), "打开札记后焦点落在关闭按钮")
	_expect_equal(instance.journey.snapshot(), before_journal, "打开纯表现札记不修改旅程规则")
	instance.close_journal()
	_expect_false(instance.get_node("%JournalOverlay").visible, "札记可关闭并返回游戏")
	instance.toggle_pause_menu()
	_expect_true(instance.get_node("%PauseOverlay").visible, "暂停菜单可由统一动作打开")
	instance.toggle_pause_menu()
	_expect_false(instance.get_node("%PauseOverlay").visible, "暂停菜单可继续游戏")
	var already_briefed: Dictionary = instance.journey.snapshot().duplicate(true)
	already_briefed["talked_to_companion"] = true
	already_briefed["briefing_response"] = "careful"
	var inconsistent_dialogue: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": already_briefed,
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "companion_briefing", "line_index": 1},
			"patrol": instance.patrol.snapshot(),
			"path_keeper": instance.path_keeper.snapshot(),
		},
	})
	_expect_false(inconsistent_dialogue["ok"], "已完成简报的剧情不能同时恢复活动对话")
	_expect_true(inconsistent_dialogue["reason"].contains("不一致"), "跨状态存档返回明确中文原因")
	var invalid_dialogue_position: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": instance.journey.snapshot(),
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "companion_briefing", "line_index": 8},
			"patrol": instance.patrol.snapshot(),
			"path_keeper": instance.path_keeper.snapshot(),
		},
	})
	_expect_false(invalid_dialogue_position["ok"], "超过当前剧本长度的结构化对话位置仍被拒绝")
	var premature_epilogue: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": instance.journey.snapshot(),
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "chapter_epilogue", "line_index": 1},
			"patrol": instance.patrol.snapshot(),
			"path_keeper": instance.path_keeper.snapshot(),
		},
	})
	_expect_false(premature_epilogue["ok"], "未完成章节不能伪造活动余波对话")
	var answered_ferryman: Dictionary = instance.journey.snapshot().duplicate(true)
	answered_ferryman["ferryman_response"] = "repair"
	var inconsistent_ferryman_dialogue: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": answered_ferryman,
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "ferryman_briefing", "line_index": 1},
			"patrol": instance.patrol.snapshot(),
			"path_keeper": instance.path_keeper.snapshot(),
		},
	})
	_expect_false(inconsistent_ferryman_dialogue["ok"], "已完成守堤选择不能同时恢复活动支线对话")
	var far_patrol_dialogue: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": already_briefed,
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "patrol_runner_briefing", "line_index": 1},
			"patrol": instance.patrol.snapshot(),
			"path_keeper": instance.path_keeper.snapshot(),
		},
	})
	_expect_false(far_patrol_dialogue["ok"], "活动巡路对话不能从陶小满交互半径外恢复")
	_expect_true(far_patrol_dialogue["reason"].contains("巡路对话位置"), "巡路远距恢复返回明确中文原因")
	_expect_true(instance.interact()["ok"], "出生点语义交互开启同伴对话")
	_expect_true(instance.get_node("%DialogueOverlay").visible, "场景显示独立对话层")
	_expect_false(instance.journey.talked_to_companion, "回应前不提前完成风险简报")
	_expect_equal(instance.get_node("%DialogueSpeakerLabel").text, "砚青", "对话显示当前说话人")
	var portrait: Control = instance.get_node("%DialoguePortrait")
	_expect_equal(portrait.visual_contract()["portrait_id"], "yanqing", "砚青台词切换到暖赭纸绘头像")
	_expect_equal(instance.get_node("%DialoguePortraitLabel").text, "砚青 · 照禾药师", "头像保留可读人物身份文字")
	_expect_true(portrait.size.x >= 134.0 and portrait.size.y >= 154.0, "纸绘头像在最小窗口保留完整可读画幅")
	_expect_equal(portrait.mouse_filter, Control.MOUSE_FILTER_IGNORE, "头像不拦截对话键鼠操作")
	_expect_equal(instance._dialogue_choice_event("careful"), "briefing_careful", "开场回应内容事件与规则映射一致")
	_expect_equal(instance._dialogue_choice_event("missing"), "", "未知回应没有伪造内容事件")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("泉眼昨夜"), "场景呈现砚青的第一句风险简报")
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 0, "新对话从逐字显示开始")
	var reveal_journey_before: Dictionary = instance.journey.snapshot()
	var reveal_dialogue_before: Dictionary = instance.dialogue.snapshot()
	var reveal_save_before := FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH)
	instance._process_dialogue_reveal(-0.25)
	instance._process_dialogue_reveal(NAN)
	instance._process_dialogue_reveal(INF)
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 0, "负数、NaN 与无限 delta 不改变逐字状态")
	instance._process_dialogue_reveal(0.25)
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 10, "标准速度四分之一秒确定显示十字")
	instance.show_full_dialogue_line()
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, -1, "玩家可以立即显示整句")
	_expect_equal(instance.dialogue.snapshot(), reveal_dialogue_before, "显示全文不推进结构化对话")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), reveal_save_before, "显示全文不产生游戏存档写入")
	instance._begin_dialogue_reveal()
	instance._process_dialogue_reveal(0.10)
	instance._process_dialogue_reveal(0.15)
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 10, "分段 delta 与整体 delta 的标准显字结果一致")
	instance.toggle_dialogue_speed()
	_expect_equal(instance.settings["dialogue_speed"], "fast", "活动对话可切到快速显字")
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 10, "标准切快速不会倒退或重置已显示文字")
	instance._begin_dialogue_reveal()
	instance._process_dialogue_reveal(0.25)
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 21, "快速速度四分之一秒确定显示二十一字")
	instance._process_dialogue_reveal(1e300)
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, -1, "超大有限 delta 安全夹紧为整句")
	_expect_equal(instance.dialogue.line_index, 0, "超大 delta 不会自动推进对话")
	instance._begin_dialogue_reveal()
	instance.toggle_dialogue_speed()
	_expect_equal(instance.settings["dialogue_speed"], "instant", "快速显字可切到整句模式")
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, -1, "切到整句立即补全当前台词")
	_expect_equal(instance.get_node("%DialogueNextButton").text, "继续", "整句模式从当前行显示继续语义")
	instance._process_dialogue_reveal(10.0)
	_expect_equal(instance.dialogue.line_index, 0, "整句模式经过时间也绝不自动推进")
	instance.toggle_dialogue_speed()
	_expect_equal(instance.settings["dialogue_speed"], "standard", "整句模式继续循环回标准速度")
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, -1, "从整句切回渐显不会隐藏已读文字")
	_expect_equal(instance.journey.snapshot(), reveal_journey_before, "三档对话显字均不修改旅程状态")
	_expect_equal(instance.dialogue.snapshot(), reveal_dialogue_before, "三档对话显字均不修改对话行权威")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), reveal_save_before, "对话显字偏好只写独立设置文件")
	instance.advance_dialogue()
	_expect_equal(instance.dialogue.line_index, 1, "继续按钮推进一行并自动保存")
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, 0, "推进后的下一行按当前标准速度重新渐显")
	_expect_equal(portrait.visual_contract()["portrait_id"], "protagonist", "主角台词切换到晴靛纸绘头像")
	_expect_equal(instance.get_node("%DialoguePortraitLabel").text, "行旅者 · 初入山河", "主角纸绘像保留身份文字")
	instance.toggle_dialogue_history()
	_expect_true(instance.get_node("%DialogueSpeakerLabel").text.contains("对话回顾"), "对话过程可以查看已读记录")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("泉眼昨夜"), "回顾保留已经读过的台词")
	_expect_equal(portrait.visual_contract()["portrait_id"], "journal", "回顾模式使用无人物行旅札记图而不误指说话人")
	instance.toggle_dialogue_history()
	_expect_equal(portrait.visual_contract()["portrait_id"], "protagonist", "返回正文恢复当前说话人的纸绘头像")
	instance.skip_dialogue_to_response()
	_expect_equal(_dialogue_choice_count(instance), 2, "跳过只到回应选择而不替玩家决定")
	_expect_equal(portrait.visual_contract()["portrait_id"], "protagonist", "回应选择保持主角头像与决策归属一致")
	await _press_dialogue_choice(instance, "先看退路，再进山。")
	_expect_false(instance.get_node("%DialogueOverlay").visible, "选择回应后关闭对话层")
	_expect_true(instance.journey.talked_to_companion, "选择回应后完成风险简报")
	_expect_equal(instance.journey.briefing_response, "careful", "谨慎回应被规则层记住")
	_expect_true(instance.get_node("%EventLabel").text.contains("先确认退路"), "回应产生明确同行回声")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("月芽田"), "回应后目标切换为采药")
	var initial_follow: Dictionary = instance.get_node("%MapCanvas").companion_follow_contract()
	_expect_true(initial_follow["active"], "简报结束后砚青启动同行轨迹")
	_expect_equal(initial_follow["context_id"], "riverbank", "同行轨迹绑定当前地图表现上下文")
	_expect_equal(initial_follow["point_count"], 2, "同行开始时只建立安全休息位与主角脚印")
	_expect_false(instance.interact()["ok"], "完成交谈后原地没有重复奖励")
	_expect_true(instance.get_node("%EventLabel").text.contains("附近没有"), "无目标交互给出中文反馈")
	_expect_true(patrol_sprite.visible, "同伴简报完成后陶小满作为第五位地图人物出现")
	var idle_disk_before: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["patrol"].duplicate(true)
	var idle_patrol_before: Dictionary = instance.patrol.snapshot()
	instance._process(1.1)
	_expect_true(instance.patrol.snapshot() != idle_patrol_before, "闲置帧仍推进陶小满巡路表现")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["patrol"], idle_disk_before, "闲置巡路不会每秒轮转磁盘存档")
	var overlap_position := ExplorationStateScript.FERRY_WATERMARK_POSITION
	_expect_true(instance.patrol.restore({
		"position_x": overlap_position.x,
		"position_y": overlap_position.y,
		"target_index": 1,
		"route_step": 1,
		"dwell_remaining": 0.0,
		"yielding_to_player": false,
	}), "重叠优先级测试把陶小满恢复到旧水痕旁的合法路线点")
	_expect_true(instance.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": overlap_position.x,
		"player_y": overlap_position.y,
	}), "玩家可站到巡路与固定地标的重叠点")
	_expect_equal(instance._resolved_nearby_action(instance.journey.snapshot()), "talk_to_patrol_runner", "未回应的礼让巡路人在重叠点保持交互优先")
	var answered_overlap: Dictionary = instance.journey.snapshot()
	answered_overlap["patrol_response"] = "boat_first"
	_expect_equal(instance._resolved_nearby_action(answered_overlap), "inspect_ferry_watermark", "巡路回应后重叠点立即恢复固定地标行动")
	var patrol_midpoint: Vector2 = PatrolStateScript.WAYPOINTS[0].lerp(PatrolStateScript.WAYPOINTS[1], 0.5)
	_expect_true(instance.patrol.restore({
		"position_x": patrol_midpoint.x,
		"position_y": patrol_midpoint.y,
		"target_index": 1,
		"route_step": 1,
		"dwell_remaining": 0.0,
		"yielding_to_player": false,
	}), "场景巡路测试恢复到合法路线中段")
	_expect_true(instance.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": patrol_midpoint.x,
		"player_y": patrol_midpoint.y,
	}), "玩家可站到陶小满当前公开路面位置")
	instance._render([])
	var active_patrol_visual: Dictionary = map_canvas.patrol_visual_contract()
	_expect_true(active_patrol_visual["active"] and active_patrol_visual["visible"], "巡路表现同步已激活且可见状态")
	_expect_equal(active_patrol_visual["normalized_position"], patrol_midpoint, "巡路精灵同步 domain 路线中段坐标")
	_expect_equal(active_patrol_visual["sprite_position"], active_patrol_visual["sprite_position"].round(), "巡路精灵落在整数像素脚点")
	_expect_equal(active_patrol_visual["sprite_depth"], map_canvas.depth_for_y(patrol_sprite.position.y), "巡路精灵按当前脚底 Y 排序")
	_expect_equal(_first_action_button(instance).text, "问问陶小满", "靠近巡路人显示可点击中文行动")
	_expect_true(instance.interact()["ok"], "近距离语义交互开启陶小满巡路对话")
	_expect_equal(instance.dialogue.dialogue_id, "patrol_runner_briefing", "场景启动稳定巡路对话标识")
	_expect_equal(instance.get_node("%DialoguePortrait").visual_contract()["portrait_id"], "tao_xiaoman", "陶小满台词显示第六个独立纸绘头像")
	_expect_equal(instance.get_node("%DialoguePortraitLabel").text, "陶小满 · 照禾渡口跑腿人", "巡路头像保留中文人物身份")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("补船缺两枚木楔"), "巡路对话呈现渡口生活委托")
	var active_patrol_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_true(active_patrol_save["ok"], "近距活动巡路对话可写入并通过当前版本跨状态校验")
	instance.skip_dialogue_to_response()
	await process_frame
	_expect_equal(_dialogue_choice_count(instance), 2, "巡路委托提供两个可点击同等选择")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("不改变战斗强度"), "巡路选择明确只改变路线与章节回声")
	_expect_equal(instance._dialogue_choice_event("boat_first"), "patrol_boat_first", "木楔优先内容事件与规则映射一致")
	_expect_equal(instance._dialogue_choice_event("herbs_first"), "patrol_herbs_first", "药叶优先内容事件与规则映射一致")
	await _press_dialogue_choice(instance, "木楔怕潮，先送船架。")
	_expect_equal(instance.journey.patrol_response, "boat_first", "场景选择木楔优先进入持久规则状态")
	_expect_equal(instance.patrol.target_index, 0, "木楔优先立即把巡路目标转向船架一侧")
	_expect_equal(instance.patrol.route_step, -1, "木楔优先立即改变路线方向")
	_expect_equal(_action_button_count(instance), 0, "巡路先后决定后近距行动隐藏")
	var patrol_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_equal(patrol_save["data"]["journey"]["patrol_response"], "boat_first", "巡路选择立即自动保存")
	_expect_true(patrol_save["data"].has("patrol"), "场景存档包含独立顶层巡路快照")
	var saved_patrol = PatrolStateScript.new()
	_expect_true(saved_patrol.restore(patrol_save["data"]["patrol"]), "场景写出的巡路快照可严格恢复")
	var boat_work_snapshot := _patrol_endpoint_snapshot(PatrolStateScript.WORKSITE_BOAT)
	boat_work_snapshot["yielding_to_player"] = true
	_expect_true(instance.patrol.restore(boat_work_snapshot), "场景可把陶小满恢复到船架端点停留")
	_expect_true(instance.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
		"player_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
	}), "场景可让玩家在船架端点等候")
	instance._render([])
	var boat_work_visual: Dictionary = map_canvas.patrol_visual_contract()
	_expect_equal(boat_work_visual["worksite_id"], PatrolStateScript.WORKSITE_BOAT, "船架到站视觉合同暴露稳定工作点")
	_expect_true(boat_work_visual["worksite_marker_visible"], "船架停留显示非权威工作点标记")
	_expect_equal(boat_work_visual["motion"], Vector2.LEFT, "船架端点闲置时陶小满朝向工作物")
	_expect_false(boat_work_visual["collision_authority"], "工作点标记不取得碰撞权威")
	_expect_false(boat_work_visual["quest_authority"], "工作点标记不取得任务权威")
	map_canvas.set_patrol_state(
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT],
		Vector2.ZERO,
		false,
		true,
		PatrolStateScript.WORKSITE_HERBS
	)
	var herbs_work_visual: Dictionary = map_canvas.patrol_visual_contract()
	_expect_equal(herbs_work_visual["worksite_id"], PatrolStateScript.WORKSITE_HERBS, "竹架到站视觉合同暴露稳定工作点")
	_expect_true(herbs_work_visual["worksite_marker_visible"], "竹架停留显示非权威工作点标记")
	_expect_equal(herbs_work_visual["motion"], Vector2.RIGHT, "竹架端点闲置时陶小满朝向工作物")
	instance._render([])
	_expect_equal(_first_action_button(instance).text, "问问船架这头", "玩家与陶小满同在船架端点时出现可点击中文行动")
	var endpoint_decode_payload := {
		"ok": true,
		"data": {
			"journey": instance.journey.snapshot(),
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "patrol_boat_priority", "line_index": 1},
			"patrol": boat_work_snapshot,
			"path_keeper": instance.path_keeper.snapshot(),
		},
	}
	_expect_true(instance._decode_save(endpoint_decode_payload)["ok"], "场景解码接受路线、端点、距离一致的船架工作对话")
	var wrong_role_decode: Dictionary = endpoint_decode_payload.duplicate(true)
	wrong_role_decode["data"]["dialogue"]["dialogue_id"] = "patrol_boat_followup"
	_expect_false(instance._decode_save(wrong_role_decode)["ok"], "场景解码拒绝先后角色与路线错配的工作对话")
	var far_work_decode: Dictionary = endpoint_decode_payload.duplicate(true)
	far_work_decode["data"]["exploration"] = ExplorationStateScript.new().snapshot()
	_expect_false(instance._decode_save(far_work_decode)["ok"], "场景解码拒绝玩家远离端点的工作对话")
	var before_work_journey: Dictionary = instance.journey.snapshot()
	_expect_true(instance.interact()["ok"], "船架端点近距交互开启工作对话")
	_expect_equal(instance.dialogue.dialogue_id, DialogueStateScript.PATROL_BOAT_PRIORITY, "木楔优先路线在船架开启 priority 剧本")
	_expect_true(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["ok"], "活动船架对话可通过 v17 跨状态校验并自动保存")
	instance.skip_dialogue_to_response()
	await process_frame
	_expect_equal(_dialogue_choice_count(instance), 2, "船架工作对话提供两个可点击回应")
	_expect_equal(instance._dialogue_choice_event("secure_boat_cloth"), "patrol_boat_cloth_secured", "船架篷布回应与规则事件一致")
	await _press_dialogue_choice(instance, "替她压稳篷布边角。")
	_expect_false(instance.dialogue.active, "提交船架回应后关闭结构化对话")
	_expect_equal(instance.journey.snapshot(), before_work_journey, "船架工作回应不暗中奖励或修改旅程")
	_expect_equal(instance.patrol.dwell_remaining, 0.0, "船架回应原子结束当前端点停留")
	_expect_true(instance.patrol.yielding_to_player, "船架回应保留玩家仍近的礼让状态")
	_expect_false(instance.patrol.is_moving(), "船架回应后玩家仍近时保持 idle 表现")
	_expect_true(instance.get_node("%EventLabel").text.contains("重新收紧系绳"), "船架回应显示独立中文回声")
	_expect_false(map_canvas.patrol_visual_contract()["worksite_marker_visible"], "端点停留结束后工作标记立即隐藏")
	var finished_work_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_true(finished_work_save["ok"], "船架回应后的 v17 存档保持可恢复")
	_expect_false(finished_work_save["data"]["dialogue"]["active"], "船架回应存档关闭活动对话")
	_expect_equal(finished_work_save["data"]["patrol"]["dwell_remaining"], 0.0, "船架回应存档持久化已结束停留")
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "巡路选择后返回公开同行起点")
	instance._render([])

	instance.move_player(Vector2.LEFT, 0.27)
	instance.move_player(Vector2.UP, 0.80)
	await process_frame
	_expect_equal(_first_action_button(instance).text, "查看补船木架", "场景通过公开移动到达补船木架并显示中文行动")
	var boat_life_snapshot: Dictionary = instance.journey.snapshot()
	await _press_action(instance, "查看补船木架")
	_expect_true(instance.get_node("%EventLabel").text.contains("渡舟午后就能再下水"), "补船木架显示中文生活事件")
	_expect_equal(instance.journey.snapshot(), boat_life_snapshot, "补船木架不修改完整旅程快照")
	await _press_action(instance, "查看补船木架")
	_expect_equal(_first_action_button(instance).text, "查看补船木架", "补船木架调查后仍可重复选择")
	_expect_equal(instance.journey.snapshot(), boat_life_snapshot, "重复查看补船木架仍不修改旅程快照")

	instance.move_player(Vector2.DOWN, 0.80)
	instance.move_player(Vector2.RIGHT, 0.27)
	instance.move_player(Vector2.LEFT, 0.10)
	instance.move_player(Vector2.UP, 1.17)
	instance.move_player(Vector2.RIGHT, 1.60)
	instance.move_player(Vector2.DOWN, 0.91)
	await process_frame
	_expect_equal(_first_action_button(instance).text, "查看晾晒竹架", "场景通过公开移动到达晾晒竹架并显示中文行动")
	var drying_life_snapshot: Dictionary = instance.journey.snapshot()
	await _press_action(instance, "查看晾晒竹架")
	_expect_true(instance.get_node("%EventLabel").text.contains("木牌记着翻晒时辰"), "晾晒竹架显示中文生活事件")
	_expect_equal(instance.journey.snapshot(), drying_life_snapshot, "晾晒竹架不修改完整旅程快照")
	await _press_action(instance, "查看晾晒竹架")
	_expect_equal(_first_action_button(instance).text, "查看晾晒竹架", "晾晒竹架调查后仍可重复选择")
	_expect_equal(instance.journey.snapshot(), drying_life_snapshot, "重复查看晾晒竹架仍不修改旅程快照")

	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "场景测试到达守堤人身旁")
	instance._render([])
	_expect_equal(_action_button_count(instance), 1, "梁叔身旁只显示近距离守堤行动")
	_expect_true(instance.interact()["ok"], "近距离交互开启守堤支线")
	_expect_equal(instance.dialogue.dialogue_id, "ferryman_briefing", "场景启动稳定守堤对话标识")
	_expect_equal(instance.get_node("%DialoguePortrait").visual_contract()["portrait_id"], "liangshu", "梁叔台词显示独立纸绘头像")
	_expect_equal(instance.get_node("%DialoguePortraitLabel").text, "梁叔 · 照禾守堤人", "梁叔头像保留中文身份说明")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("浅石"), "守堤对话呈现原创空间细节")
	instance.skip_dialogue_to_response()
	await process_frame
	_expect_equal(_dialogue_choice_count(instance), 2, "守堤支线提供两个同等选择")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("不改变战斗强度"), "选择提示明确无隐藏战斗奖励")
	_expect_equal(instance._dialogue_choice_event("repair"), "ferryman_repair", "扶尺内容事件与规则映射一致")
	await _press_dialogue_choice(instance, "一起扶正水尺。")
	_expect_equal(instance.journey.ferryman_response, "repair", "场景选择扶尺进入持久规则状态")
	var repaired_visual: Dictionary = instance.get_node("%MapCanvas").ferryman_visual_contract()
	_expect_true(repaired_visual["gauge_upright"], "扶尺后地图永久显示直立水尺")
	_expect_false(repaired_visual["record_tag"], "扶尺结果不误画记时纸签")
	_expect_equal(_action_button_count(instance), 0, "完成守堤选择后交互行动隐藏")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["save_version"], float(SaveGameScript.SAVE_VERSION), "守堤选择写入当前存档版本")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["ferryman_response"], "repair", "守堤选择立即自动保存")
	instance.open_journal()
	await process_frame
	var ferryman_journal: Dictionary = instance.journal_contract()
	_expect_true(ferryman_journal["unlocked_titles"].has("扶正的照禾水尺"), "守堤结果进入内容驱动札记")
	_expect_true(ferryman_journal["entries_text"].contains("下一次涨水"), "札记保留选择的公共后果")
	instance.close_journal()
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42}), "场景测试到达渡口旧水痕")
	instance._render([])
	_expect_equal(_action_button_count(instance), 1, "旧水痕近旁只显示对应调查")
	await _press_action(instance, "辨认旧水痕")
	_expect_true(instance.get_node("%EventLabel").text.contains("三层旧水痕"), "渡口调查呈现原创环境历史")
	_expect_equal(instance.journey.discoveries, ["ferry_watermark"], "渡口调查进入规则见闻")
	_expect_equal(instance.get_node("%MapCanvas").discovery_visual_contract()["read_count"], 1, "地图表现收到已读渡口见闻")
	_expect_equal(_action_button_count(instance), 0, "一次性渡口见闻读后隐藏行动")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["discoveries"], ["ferry_watermark"], "渡口见闻立即自动保存")
	instance.open_journal()
	await process_frame
	var discovered_journal: Dictionary = instance.journal_contract()
	_expect_equal(discovered_journal["discovered_count"], 1, "新见闻立即出现在札记计数")
	_expect_true(discovered_journal["unlocked_titles"].has("渡堤三重水痕"), "札记以内容驱动标题回显渡口见闻")
	_expect_true(discovered_journal["entries_text"].contains("整夜转移药苗"), "札记显示已发现历史摘要")
	_expect_false(discovered_journal["entries_text"].contains("分向旧圃的泉纹"), "札记仍不剧透未发现山道标题")
	instance.close_journal()
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "调查后返回同行起点")
	instance._render([])

	for _step in range(4):
		instance.move_player(Vector2.DOWN, 0.10)
	for _step in range(7):
		instance.move_player(Vector2.RIGHT, 0.10)
	instance.move_player(Vector2.RIGHT, 0.04)
	var moved_follow: Dictionary = instance.get_node("%MapCanvas").companion_follow_contract()
	_expect_true(moved_follow["point_count"] > initial_follow["point_count"], "主角移动会追加受预算约束的脚印")
	_expect_true(instance.exploration.player_position.distance_to(moved_follow["normalized_position"]) <= 0.061, "同行者保持紧凑跟随距离")
	_expect_true(not moved_follow["motion"].is_zero_approx(), "同行者根据自身脚印位移播放行走方向")
	_expect_equal(moved_follow["sprite_position"], moved_follow["sprite_position"].round(), "同行者脚底保持整数像素对齐")
	_expect_equal(instance.get_node("%CompanionSprite").z_index, instance.get_node("%MapCanvas").depth_for_y(moved_follow["sprite_position"].y), "同行轨迹位置继续参与脚底深度排序")
	_expect_equal(player_sprite.animation, &"walk_right", "向右移动驱动右向行走动画")
	_expect_equal(player_sprite.position, player_sprite.position.round(), "人物脚底位置保持整数像素对齐")
	await process_frame
	_expect_equal(_action_button_count(instance), 2, "靠近月芽草显示两种可选择采集方式")
	_expect_equal(_first_action_button(instance).custom_minimum_size.y, 48.0, "交互按钮保持可点击高度")

	await _press_action(instance, "依旧规取一株")
	_expect_true(instance.get_node("%EventLabel").text.contains("只取一株"), "场景呈现采集结果")
	_expect_equal(instance.journey.moonleaf_method, "whole_plant", "场景默认旧规按钮进入整株记录")
	var whole_plant_visual: Dictionary = instance.get_node("%MapCanvas").moonleaf_visual_contract()
	_expect_false(whole_plant_visual["regrowing"], "整株取药后不伪造留根新芽")
	_expect_equal(_action_button_count(instance), 0, "采集按钮完成后隐藏")

	instance.move_player(Vector2.LEFT, 0.82)
	instance.move_player(Vector2.UP, 1.56)
	instance.move_player(Vector2.RIGHT, 1.46)
	instance.move_player(Vector2.DOWN, 0.06)
	await process_frame
	_expect_equal(_action_button_count(instance), 1, "走到山门后显示进入行动")
	instance.toggle_reduced_motion()
	await _press_action(instance, "进入藏泉山道")
	var path_transition: Dictionary = transition.transition_contract()
	_expect_true(path_transition["active"], "真实地图阶段变化触发纸墨转场")
	_expect_equal(path_transition["label"], "藏泉山道 · 石阶入云", "地图转场文案来自已验证剧情内容")
	_expect_equal(root.gui_get_focus_owner(), instance.get_node("%TransitionInputSink"), "地图转场期间实际接管焦点")
	transition.finish()
	instance.toggle_reduced_motion()
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "mountain_path", "山门进入可自由探索山道")
	_expect_false(instance.get_node("%PatrolSprite").visible, "离开渡口后巡路人不跨地图显示")
	var path_follow: Dictionary = instance.get_node("%MapCanvas").companion_follow_contract()
	_expect_equal(path_follow["context_id"], "mountain_path", "山道不会沿用渡口脚印")
	_expect_equal(path_follow["point_count"], 2, "换图只在新出生点重建同行轨迹")
	_expect_equal(instance.exploration.map_id, "cangquan_path", "场景切换到稳定山道地图标识")
	_expect_true(instance.get_node("%PathGround").visible, "山道 TileMapLayer 在探索阶段可见")
	_expect_true(instance.get_node("%MapCanvas").uses_mountain_path_tile_layers(), "山道使用独立 TileMapLayer")
	instance.move_player(Vector2.UP, 0.20)
	instance.move_player(Vector2.RIGHT, 1.24)
	instance.move_player(Vector2.DOWN, 0.17)
	await process_frame
	_expect_equal(_first_action_button(instance).text, "查看避雨石棚", "场景通过公开移动从山道入口到达避雨石棚")
	var shelter_life_snapshot: Dictionary = instance.journey.snapshot()
	await _press_action(instance, "查看避雨石棚")
	_expect_true(instance.get_node("%EventLabel").text.contains("干柴、引火绒"), "避雨石棚显示中文生活事件")
	_expect_equal(instance.journey.snapshot(), shelter_life_snapshot, "避雨石棚不修改完整旅程快照")
	await _press_action(instance, "查看避雨石棚")
	_expect_equal(_first_action_button(instance).text, "查看避雨石棚", "避雨石棚调查后仍可重复选择")
	_expect_equal(instance.journey.snapshot(), shelter_life_snapshot, "重复查看避雨石棚仍不修改旅程快照")
	_expect_true(instance.get_node("%PathRockEnemySprite").visible, "山道显示岩甲幼兽像素轮廓")
	_expect_true(instance.get_node("%PathMossEnemySprite").visible, "山道显示泉苔寄壳像素轮廓")
	_expect_true(instance.get_node("%PathPuppetEnemySprite").visible, "山道显示失衡石傀像素轮廓")
	_expect_false(enemy_sprite.visible, "探索阶段不会叠加战斗敌人节点")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 5, "山道使用五处可排序树冠前景")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["asset_backed_count"], 5, "山道五处树冠全部复用像素地标图集")
	var path_contract: Dictionary = instance.get_node("%PathGround").map_contract()
	_expect_equal(path_contract["map_kind"], "mountain_path", "山道图层声明独立地图类型")
	_expect_equal(path_contract["tile_counts"]["water"], 161, "扩展山道溪流与七乘七返程石桥保持固定水陆布局")
	_expect_true(path_contract["tile_counts"]["path"] > 70, "扩展山道存在连续可读石路")
	_expect_true(path_contract["tile_counts"]["stone"] > 3, "山道敌区与调查点使用石地标记")
	_expect_equal(path_contract["mountain_gate_bridge"], Rect2i(3, 16, 7, 7), "返程山门使用固定七乘七石桥区域")
	var path_ground: TileMapLayer = instance.get_node("%PathGround")
	_expect_equal(path_ground.tile_kind_at_normalized(ExplorationStateScript.PATH_RETURN_POSITION), "stone", "山道返程交互点不再落在溪水图块")
	for anchor in [
		ExplorationStateScript.PATH_START_POSITION,
		ExplorationStateScript.PATH_RETURN_POSITION,
		ExplorationStateScript.PATH_MARKER_POSITION,
		ExplorationStateScript.PATH_SPRING_SEAM_POSITION,
		ExplorationStateScript.PATH_ABANDONED_BASKET_POSITION,
		ExplorationStateScript.PATH_ROCK_SPOOR_POSITION,
		ExplorationStateScript.PATH_MOSS_SPOOR_POSITION,
		ExplorationStateScript.PATH_PUPPET_SPOOR_POSITION,
		ExplorationStateScript.PATH_ENEMY_POSITION,
		ExplorationStateScript.PATH_MOSS_POSITION,
		ExplorationStateScript.PATH_PUPPET_POSITION,
		ExplorationStateScript.PATH_BYPASS_POSITION,
	]:
		var anchor_tile_kind: String = path_ground.tile_kind_at_normalized(anchor)
		_expect_true(anchor_tile_kind != "water" and anchor_tile_kind != "outside", "山道交互锚点 %s 落在可读非水地表" % anchor)
	var path_detail_contract: Dictionary = map_detail.map_contract()
	_expect_equal(path_detail_contract["context_id"], "mountain_path", "山道切换共享细节层上下文")
	_expect_equal(path_detail_contract["map_kind"], "mountain_path", "山道切换独立固定细节单元图")
	_expect_equal(path_detail_contract["used_rect"], Rect2i(1, 1, 46, 26), "山道细节占用范围保持在扩展地图内")
	_expect_equal(path_detail_contract["used_cell_count"], 74, "山道细节随滚动世界保持稀疏密度")
	_expect_equal(path_detail_contract["tile_counts"], {
		"reeds": 7,
		"bank_grass": 7,
		"path_pebbles": 15,
		"wildflowers": 11,
		"stone_cracks": 7,
		"moss": 9,
		"fallen_leaves": 11,
		"water_foam": 7,
	}, "山道八类透明细节数量固定")
	_expect_equal(path_detail_contract["tile_cells"]["stone_cracks"], [Vector2i(32, 7), Vector2i(38, 9), Vector2i(35, 10), Vector2i(33, 11), Vector2i(38, 11), Vector2i(22, 16), Vector2i(20, 17)], "山道石裂只落在两处扩展石地区")
	_expect_equal(path_detail_contract["tile_cells"]["path_pebbles"], [Vector2i(8, 19), Vector2i(10, 20), Vector2i(13, 19), Vector2i(16, 18), Vector2i(19, 16), Vector2i(21, 15), Vector2i(24, 14), Vector2i(27, 12), Vector2i(30, 11), Vector2i(33, 9), Vector2i(36, 8), Vector2i(39, 6), Vector2i(41, 5), Vector2i(43, 4), Vector2i(17, 17)], "山道碎石沿固定扩展路线排列")
	_expect_true(path_detail_contract["visible"], "山道细节在自由探索阶段可见")
	_expect_equal(path_detail_contract["rebuild_count"], 2, "首次换图只追加一次细节重建")
	_expect_true(path_detail_contract["layout_signature"] != ferry_detail_contract["layout_signature"], "渡口与山道细节布局签名不同")
	_expect_detail_cells_bounded_and_unique(path_detail_contract, "山道")
	instance._render([])
	_expect_equal(map_detail.map_contract()["rebuild_count"], 2, "同一山道上下文重复渲染不重建细节")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30}), "场景测试移动到石缝泉纹")
	instance._render([])
	await _press_action(instance, "观察石缝泉纹")
	_expect_true(instance.get_node("%EventLabel").text.contains("旧药圃"), "泉纹调查揭示山道曾有人照料")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "场景测试移动到弃置药篓")
	instance._render([])
	await _press_action(instance, "翻看弃置药篓")
	_expect_true(instance.get_node("%EventLabel").text.contains("提绳"), "药篓调查提供生活痕迹而非战斗奖励")
	var discovery_visual: Dictionary = instance.get_node("%MapCanvas").discovery_visual_contract()
	_expect_equal(discovery_visual["read_count"], 3, "地图表现呈现三处已读环境见闻")
	_expect_equal(discovery_visual["total"], 3, "本章见闻总数有稳定合同")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["discoveries"].size(), 3, "山道见闻立即自动保存")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "场景测试带药篓到达山道退路")
	instance._render([])
	await _press_action(instance, "沿石阶返回渡口")
	transition.finish()
	_expect_equal(instance.journey.phase_id(), "riverbank", "药篓发现后可返回渡口完成支线")
	var returned_ferry_detail: Dictionary = map_detail.map_contract()
	_expect_true(returned_ferry_detail["visible"], "返回渡口后共享细节层重新可见")
	_expect_equal(returned_ferry_detail["map_kind"], "ferry", "返回渡口后恢复渡口细节单元图")
	_expect_equal(returned_ferry_detail["rebuild_count"], 3, "实际地图类型变化才重建渡口细节")
	var awaiting_basket_visual: Dictionary = instance.get_node("%MapCanvas").basket_visual_contract()
	_expect_true(awaiting_basket_visual["herbkeeper_visible"], "返回渡口后蕙婶地图角色可见")
	_expect_equal(awaiting_basket_visual["response"], "unanswered", "交谈前地图不替玩家决定药篓去向")
	var expected_herbkeeper_position := Vector2(instance.get_node("%MapCanvas").size.x * 0.75, instance.get_node("%MapCanvas").size.y * 0.66).round()
	_expect_equal(awaiting_basket_visual["herbkeeper_position"], expected_herbkeeper_position, "蕙婶脚底使用可达且整数对齐的位置")
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "场景测试到达蕙婶身旁")
	instance._render([])
	await process_frame
	_expect_equal(_action_button_count(instance), 1, "蕙婶身旁只显示药篓安置行动")
	_expect_true(instance.interact()["ok"], "近距离语义交互开启药篓支线")
	_expect_equal(instance.dialogue.dialogue_id, "herbkeeper_basket", "场景启动稳定药篓对话标识")
	_expect_equal(instance.get_node("%DialoguePortrait").visual_contract()["portrait_id"], "huishen", "蕙婶台词显示独立纸绘头像")
	_expect_equal(instance.get_node("%DialoguePortraitLabel").text, "蕙婶 · 照禾药圃守", "蕙婶头像保留中文身份说明")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("双叶印"), "药篓对话回扣已调查的公共印记")
	instance.skip_dialogue_to_response()
	await process_frame
	_expect_equal(_dialogue_choice_count(instance), 2, "药篓支线提供两个无战力差异的选择")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("不改变战斗强度"), "药篓选择提示明确无隐藏战斗奖励")
	_expect_equal(instance._dialogue_choice_event("return"), "basket_return", "归圃内容事件与规则映射一致")
	await _press_dialogue_choice(instance, "把药篓带回圃里。")
	_expect_equal(instance.journey.basket_response, "return", "场景选择归圃进入持久规则状态")
	var returned_basket_visual: Dictionary = instance.get_node("%MapCanvas").basket_visual_contract()
	_expect_true(returned_basket_visual["returned_to_ferry"], "归圃后渡口显示公用药篓余留")
	_expect_false(returned_basket_visual["repaired_on_trail"], "归圃结果不误画留山药篓")
	_expect_equal(_action_button_count(instance), 0, "药篓安置后近距离行动隐藏")
	var basket_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_equal(basket_save["data"]["save_version"], float(SaveGameScript.SAVE_VERSION), "药篓选择写入当前存档版本")
	_expect_equal(basket_save["data"]["journey"]["basket_response"], "return", "药篓选择立即自动保存")
	instance.open_journal()
	await process_frame
	var basket_journal: Dictionary = instance.journal_contract()
	_expect_true(basket_journal["unlocked_titles"].has("回到药圃的公用篓"), "归圃结果进入内容驱动札记")
	_expect_true(basket_journal["entries_text"].contains("下一位采药人"), "药篓札记保留公共后果")
	instance.close_journal()
	_expect_true(instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "完成药篓支线后再次到达山门")
	instance._render([])
	await _press_action(instance, "进入藏泉山道")
	transition.finish()
	_expect_equal(instance.journey.phase_id(), "mountain_path", "药篓支线不会锁死主线或山道重返")
	_expect_equal(map_detail.map_contract()["rebuild_count"], 4, "再次进入不同地图只追加一次细节重建")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.43, "player_y": 0.57}), "场景测试移动到旧石标")
	var resets_before_restore := int(instance.get_node("%MapCanvas").companion_follow_contract()["reset_count"])
	instance._render([])
	_expect_equal(instance.get_node("%MapCanvas").companion_follow_contract()["reset_count"], resets_before_restore + 1, "远距离读档重建砚青位置而不跨图跑来")
	await _press_action(instance, "查看旧石标")
	_expect_true(instance.get_node("%EventLabel").text.contains("旧猎户的箭记"), "山道可选调查返回原创环境线索")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "场景测试移动到敌人预警区")
	instance._render([])
	await _press_action(instance, "接近岩甲幼兽")
	_expect_false(transition.is_transitioning(), "简化动态进入战斗不播放渐隐动画")
	_expect_equal(transition.transition_contract()["label"], "碎甲声近 · 临势应战", "简化动态仍记录已发生的战斗转场语义")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景进入战斗")
	_expect_false(ferry_ground.visible, "离开渡口后隐藏渡口 TileMapLayer")
	_expect_equal(_action_button_count(instance), 6, "战斗显示术式、符箓、守势、援护、石灯与撤退")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "battle", "战斗切换山道画面")
	var battle_camera: Dictionary = instance.world_camera_contract()
	_expect_equal(battle_camera["normalized_focus"], instance.get_node("%MapCanvas").presentation_focus_normalized(instance.exploration.player_position), "战斗镜头改用三名可见演员的表现中心")
	var battle_safe_frame: Rect2 = battle_camera["safe_frame"]["rect"]
	for battle_actor_path in ["%PlayerSprite", "%CompanionSprite", "%BattleEnemySprite"]:
		var battle_actor: Node2D = instance.get_node(battle_actor_path)
		_expect_true(battle_safe_frame.has_point(battle_actor.position - battle_camera["origin"]), "%s 脚点避开顶部 HUD 与底部纸面" % battle_actor_path)
	var battle_detail_contract: Dictionary = map_detail.map_contract()
	_expect_false(battle_detail_contract["visible"], "战斗阶段隐藏探索细节层")
	_expect_equal(battle_detail_contract["context_id"], "battle", "隐藏细节仍记录当前表现上下文")
	_expect_equal(battle_detail_contract["rebuild_count"], 4, "进入非地图场景不重复构建缓存的山道细节")
	_expect_true(enemy_sprite.visible, "战斗阶段显示独立敌人图集节点")
	_expect_equal(enemy_sprite.enemy_id, "rock_armor_young", "岩甲遭遇选择对应图集行")
	_expect_equal(enemy_sprite.animation, &"idle_rock_armor_young", "战斗节点播放岩甲双帧待机动画")
	_expect_false(instance.get_node("%PathRockEnemySprite").visible, "战斗阶段隐藏探索用敌人轮廓")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 4, "战斗镜头重建四处可排序树冠前景")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("试探冲撞"), "战斗目标预告下一项敌方意图")
	_expect_false(instance.get_node("%ObjectiveLabel").text.contains("破绽窗口"), "未调查岩甲擦痕时战斗目标不泄露反制窗口")
	await _press_action(instance, "撤到旧石标")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景撤退返回山道")
	_expect_true(map_detail.map_contract()["visible"], "撤退回山道后复用并显示缓存细节")
	_expect_equal(map_detail.map_contract()["rebuild_count"], 4, "战斗返回同一山道不重建细节")
	_expect_true(instance.get_node("%EventLabel").text.contains("旧石标"), "场景说明撤退路线与敌人重置")
	_expect_equal(instance.exploration.player_position, ExplorationStateScript.PATH_RETREAT_POSITION, "撤退落在山道安全位置")
	_expect_true(instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "撤退后回到敌人预警区")
	instance._render([])
	await _press_action(instance, "接近岩甲幼兽")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景可在撤退后再次进山")
	var rules_mirror = JourneyStateScript.new()
	_expect_true(rules_mirror.restore(instance.journey.snapshot()), "表现模式对照恢复相同战斗起点")
	rules_mirror.choose("deploy_spring_lamp")
	await _press_action(instance, "布置引泉石灯")
	_expect_equal(instance.journey.snapshot(), rules_mirror.snapshot(), "快速简化反馈不改变同一行动的规则结果")
	_expect_true(instance.get_node("%EventLabel").text.contains("青白泉光"), "场景呈现战术部署物")
	_expect_true(instance.get_node("%StatusLabel").text.contains("石灯 0"), "状态显示部署槽已使用")
	var fast_feedback: Dictionary = instance.get_node("%MapCanvas").feedback_contract()
	_expect_equal(fast_feedback["text"], "石灯护阵", "战斗语义事件触发对应画面反馈")
	_expect_equal(fast_feedback["duration"], 0.18, "快速模式缩短反馈持续时间")
	_expect_false(fast_feedback["motion_enabled"], "简化动态关闭反馈脉冲")
	var fast_enemy_cue: Dictionary = enemy_sprite.presentation_contract()
	_expect_equal(fast_enemy_cue["state"], "attack", "石灯结算后的敌方反击触发攻击姿态")
	_expect_equal(fast_enemy_cue["event_id"], "enemy_glanced", "攻击姿态消费实际格挡后的敌方事件")
	_expect_equal(fast_enemy_cue["duration"], 0.18, "敌人姿态与快速反馈共享非权威表现时长")
	_expect_false(fast_enemy_cue["motion_enabled"], "简化动态将攻击姿态冻结为可读首帧")

	await _press_action(instance, "请砚青援护")
	_expect_true(instance.get_node("%EventLabel").text.contains("护脉药雾"), "场景呈现主动同伴援护")
	_expect_true(instance.get_node("%StatusLabel").text.contains("援护 0"), "战斗状态显示援护资源用尽")
	_expect_equal(enemy_sprite.presentation_contract()["state"], "attack", "同伴援护后的敌方回应继续使用攻击姿态")
	await _press_action(instance, "镇岩符")
	_expect_true(instance.get_node("%StatusLabel").text.contains("回合 4"), "战斗状态呈现回合信息")
	_expect_equal(enemy_sprite.presentation_contract()["state"], "react", "镇岩符命中触发敌人受击姿态")
	_expect_equal(enemy_sprite.presentation_contract()["event_id"], "talisman_hit", "受击姿态记录符箓命中语义")
	await _press_action(instance, "引气术")
	await _press_action(instance, "引气术")
	_expect_true(instance.get_node("%StatusLabel").text.contains("岩甲兽守巢者 14/14"), "普通敌人后无缝进入首领配置")
	_expect_equal(transition.transition_contract()["label"], "守巢者现 · 临势应战", "未调查时首领入场转场保持中性")
	_expect_equal(enemy_sprite.enemy_id, "rock_armor_warden", "首领入场立即切换正式像素图集行")
	_expect_equal(enemy_sprite.animation, &"idle_rock_armor_warden", "首领播放独立双帧待机动画")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("成熟岩甲"), "场景显示不剧透的首领短描述")
	_expect_false(instance.get_node("%DescriptionLabel").text.contains("重击落空") or instance.get_node("%DescriptionLabel").text.contains("腹甲错开"), "未调查首领描述不泄露精确反制")
	_expect_false(instance.get_node("%EventLabel").text.contains("守住重击") or instance.get_node("%EventLabel").text.contains("腹甲错位"), "未调查首领入场事件不替玩家解题")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("压阵肩撞"), "首领第一招在行动前明示")
	_expect_false(instance.get_node("%ObjectiveLabel").text.contains("后一势") or instance.get_node("%ObjectiveLabel").text.contains("破绽窗口"), "未调查岩甲痕迹时首领目标不显示后续或反制")
	await _press_action(instance, "守势调息")
	_expect_false(instance.get_node("%StatusLabel").text.contains("破甲"), "压阵肩撞期间守势不会提前破甲")
	_expect_equal(enemy_sprite.presentation_contract()["state"], "attack", "首领压阵回应触发自身攻击姿态")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("崩石重击"), "首领第二回合明示真正重击窗口")
	await _press_action(instance, "守势调息")
	_expect_true(instance.get_node("%StatusLabel").text.contains("破甲 2"), "守住崩石重击后状态栏显示破甲")
	_expect_equal(enemy_sprite.presentation_contract()["state"], "react", "首领破绽事件优先触发受击姿态")
	_expect_equal(enemy_sprite.presentation_contract()["event_id"], "weakness_exposed", "首领受击姿态保留破绽语义")
	await _press_action(instance, "引气术")
	await _press_action(instance, "请砚青援护")
	_expect_true(instance.get_node("%StatusLabel").text.contains("凝息 2"), "同伴援护后状态栏显示凝息")
	await _press_action(instance, "引气术")
	await _press_action(instance, "引气术")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉石室", "胜利进入泉室")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 0, "泉室不残留上一地图的树冠节点")
	_expect_false(map_detail.map_contract()["visible"], "泉室不残留山道细节画面")
	_expect_equal(instance.exploration.map_id, "cangquan_spring", "胜利后切换到独立泉室探索地图")
	_expect_equal(instance.exploration.player_position, ExplorationStateScript.SPRING_START_POSITION, "胜利路线落在泉室安全出生点")
	_expect_true(instance._is_exploration_phase(), "泉室仪轨沿用可移动语义输入路径")
	var initial_breath_visual: Dictionary = instance.get_node("%MapCanvas").first_breath_visual_contract()
	_expect_equal(initial_breath_visual["stage"], "unstarted", "泉室画面从未开始仪轨状态绘制")
	_expect_equal(initial_breath_visual["positions"]["listen_to_spring"], ExplorationStateScript.SPRING_LISTEN_POSITION, "泉室画面合同锁定听泉点")
	_expect_false(initial_breath_visual["rule_authority"], "泉室仪点明确不拥有领域权威")

	_expect_true(instance.exploration.restore({"map_id": "cangquan_spring", "player_x": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.x, "player_y": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.y}), "场景可先走到最终静坐点测试乱序保护")
	instance._render([])
	var before_out_of_order: Dictionary = instance.journey.snapshot()
	var before_out_of_order_save := FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH)
	await _press_action(instance, "静坐引息")
	_expect_equal(instance.journey.snapshot(), before_out_of_order, "乱序静坐不会改变规则资源或仪轨阶段")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), before_out_of_order_save, "乱序仪轨不会改写磁盘存档")
	_expect_true(instance.get_node("%EventLabel").text.contains("先听泉"), "乱序仪轨提供可操作的中文顺序提示")

	_expect_true(instance.exploration.restore({"map_id": "cangquan_spring", "player_x": ExplorationStateScript.SPRING_LISTEN_POSITION.x, "player_y": ExplorationStateScript.SPRING_LISTEN_POSITION.y}), "场景走到泉沿听息点")
	instance._render([])
	await _press_action(instance, "听泉辨脉")
	_expect_equal(instance.journey.first_breath_stage, "listened", "场景第一步推进为已听泉")
	_expect_true(instance.journey.gathered_moonleaf, "听泉后仍持有护脉月芽草")
	var listened_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_equal(listened_save["data"]["journey"]["first_breath_stage"], "listened", "听泉步骤立即自动存档")
	_expect_true(Vector2(float(listened_save["data"]["exploration"]["player_x"]), float(listened_save["data"]["exploration"]["player_y"])).is_equal_approx(ExplorationStateScript.SPRING_LISTEN_POSITION), "听泉自动存档保留准确空间点")

	_expect_true(instance.exploration.restore({"map_id": "cangquan_spring", "player_x": ExplorationStateScript.SPRING_WARM_POSITION.x, "player_y": ExplorationStateScript.SPRING_WARM_POSITION.y}), "场景走到月芽温脉石台")
	instance._render([])
	await _press_action(instance, "月芽温脉")
	_expect_equal(instance.journey.first_breath_stage, "warmed", "场景第二步推进为已温脉")
	_expect_false(instance.journey.gathered_moonleaf, "场景只在温脉步骤消耗月芽草")
	var warmed_save: Dictionary = SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_equal(warmed_save["data"]["journey"]["first_breath_stage"], "warmed", "温脉步骤立即自动存档")
	_expect_false(warmed_save["data"]["journey"]["gathered_moonleaf"], "温脉存档记录月芽草已被正确消耗")
	_expect_equal(instance.get_node("%MapCanvas").first_breath_visual_contract()["completed_actions"], ["listen_to_spring", "warm_meridians"], "泉室画面留下前两步完成印记")

	_expect_true(instance.exploration.restore({"map_id": "cangquan_spring", "player_x": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.x, "player_y": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.y}), "场景沿亮起石纹到达静坐点")
	instance._render([])
	await _press_action(instance, "静坐引息")
	_expect_equal(instance.get_node("%LocationLabel").text, "第一息", "场景完成章节")
	_expect_true(instance.get_node("%StatusLabel").text.contains("引息境一层"), "场景显示突破境界")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "complete", "结算切换明亮突破画面")
	var complete_camera: Dictionary = instance.world_camera_contract()
	_expect_equal(complete_camera["normalized_focus"], instance.get_node("%MapCanvas").presentation_focus_normalized(instance.exploration.player_position), "结算镜头改用双人表现中心而非旧探索坐标")
	var complete_safe_frame: Rect2 = complete_camera["safe_frame"]["rect"]
	for complete_actor_path in ["%PlayerSprite", "%CompanionSprite"]:
		var complete_actor: Node2D = instance.get_node(complete_actor_path)
		_expect_true(complete_safe_frame.has_point(complete_actor.position - complete_camera["origin"]), "%s 结算脚点避开底部章节面板" % complete_actor_path)
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("本节结算"), "完成画面显示战绩结算")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("水尺扶正"), "结算回显本轮守堤选择")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("药篓归圃"), "结算回显本轮药篓去向")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("依旧规取药"), "结算回显本轮采集选择")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("见闻 3/3"), "结算回显环境探索完成度")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("经历 1 次"), "结算记录实际撤退次数")
	_expect_equal(_action_button_count(instance), 3, "结算提供回顾、返回标题和重游")
	_expect_true(instance._resolved_dialogue_text("{setback_reflection}").contains("退过一次"), "余波文本把一次撤退写成知道何时回头")
	instance.journey.setbacks = 2
	_expect_true(instance._resolved_dialogue_text("{setback_reflection}").contains("经历2次"), "余波文本可以归纳多次撤退或救援")
	instance.journey.setbacks = 1
	await _press_action(instance, "回顾此行")
	_expect_true(instance.dialogue.active and instance.dialogue.dialogue_id == "chapter_epilogue", "结算回顾开启可保存的余波对话")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("依旧规只取了一株"), "余波回显本轮整株采集方式")
	_expect_true(instance.get_node("%DialogueLabel").text.contains("沿途3处生活痕迹"), "余波回显本轮见闻数量")
	_expect_true(instance._resolved_dialogue_text("{ferryman_reflection}").contains("重新立稳"), "余波回显扶尺结果")
	_expect_true(instance._resolved_dialogue_text("{basket_reflection}").contains("挂回圃门"), "余波回显药篓归圃结果")
	_expect_equal(instance.get_node("%DialoguePortrait").visual_contract()["portrait_id"], "yanqing", "余波首句显示砚青纸绘头像")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["dialogue"]["dialogue_id"], "chapter_epilogue", "余波开启后立即保存结构化位置")
	_expect_equal(instance._dialogue_choice_event("record"), "epilogue_recorded", "余波回应内容事件与规则映射一致")
	instance.skip_dialogue_to_response()
	_expect_true(instance.get_node("%DialogueLabel").text.contains("怎样收好"), "余波回应提示来自原创内容而非开场硬编码")
	await _press_dialogue_choice(instance, "明日再沿河走一趟。")
	_expect_false(instance.get_node("%DialogueOverlay").visible, "余波回应后关闭对话层")
	_expect_true(instance.get_node("%EventLabel").text.contains("明早再看一次河势"), "余波选择产生独立中文回声")
	await _press_action(instance, "完成本节并返回标题")
	await process_frame
	_expect_true(instance.get_node("%TitleOverlay").visible, "完成后可以保存并返回标题")
	_expect_false(instance.get_node("%ContinueButton").disabled, "已有存档时允许继续")
	instance.get_node("%AudioManager").set_audio_enabled(false)
	instance.queue_free()
	await process_frame

	var resumed := scene.instantiate()
	resumed.configure_save_path(TEST_SCENE_SAVE_PATH)
	resumed.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(resumed)
	await process_frame
	_expect_true(resumed.get_node("%TitleStatus").text.contains("第一息"), "标题界面展示存档位置")
	_expect_equal(resumed.get_node("%TitleVolumeButton").text, "音量：100%", "新场景恢复音量偏好")
	_expect_true(resumed.get_node("%AudioManager").is_audio_active(), "新场景恢复用户开启的环境音")
	_expect_equal(resumed.get_node("%TitleBattleSpeedButton").text, "战斗表现：快速", "新场景恢复快速战斗表现")
	_expect_equal(resumed.get_node("%TitleMotionButton").text, "动态效果：简化", "新场景恢复简化动态偏好")
	_expect_equal(resumed.get_node("%TitleTextScaleButton").text, "文字大小：大字", "新场景恢复大字偏好")
	_expect_equal(resumed.get_node("%TitleContrastButton").text, "高对比：开启", "新场景恢复高对比偏好")
	_expect_equal(resumed.accessibility_contract()["dialogue_font_size"], ceili(float(resumed.accessibility_contract()["base_dialogue_font_size"]) * 1.25), "新场景立即应用持久化大字模式")
	_expect_equal(resumed.accessibility_contract()["dialogue_font_color"], resumed.HIGH_CONTRAST_INK, "新场景立即应用持久化高对比颜色")
	resumed.toggle_high_contrast()
	_expect_equal(resumed.accessibility_contract()["dialogue_font_color"], base_accessibility["dialogue_font_color"], "新场景基准在应用高对比之前捕获")
	resumed.toggle_high_contrast()
	var completed_save_text := FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH)
	resumed.get_node("%NewGameButton").pressed.emit()
	await process_frame
	var confirmation: Dictionary = resumed.new_game_confirmation_contract()
	_expect_true(confirmation["visible"], "有效存档要求二次确认才会重新开始")
	_expect_true(confirmation["warning"].contains("无法撤销"), "覆盖警告明确说明不可撤销")
	_expect_equal(confirmation["confirm_label"], "确认重新开始", "危险操作使用明确确认标签")
	_expect_equal(confirmation["cancel_label"], "取消，保留存档", "安全默认项说明会保留存档")
	_expect_true(confirmation["settings_disabled"], "确认期间停用无关标题设置")
	_expect_false(confirmation["rule_authority"], "覆盖确认不成为旅程规则权威")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), completed_save_text, "第一次重新开始点击不改写有效存档")
	_expect_equal(resumed.journey.phase_id(), "riverbank", "标题确认不提前替换内存旅程")
	_expect_equal(root.gui_get_focus_owner(), resumed.get_node("%ContinueButton"), "覆盖确认默认聚焦取消")
	resumed.get_node("%ContinueButton").pressed.emit()
	await process_frame
	_expect_false(resumed.new_game_confirmation_contract()["visible"], "取消会离开覆盖确认状态")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), completed_save_text, "取消覆盖完整保留存档字节")
	_expect_true(resumed.get_node("%TitleStatus").text.contains("第一息"), "取消后恢复原存档位置说明")
	_expect_equal(root.gui_get_focus_owner(), resumed.get_node("%NewGameButton"), "取消后焦点回到发起操作的按钮")
	_expect_true(resumed.continue_game(), "新场景可以继续本地存档")
	await process_frame
	_expect_equal(resumed.get_node("%LocationLabel").text, "第一息", "继续游戏恢复章节完成态")
	_expect_true(resumed.get_node("%EventLabel").text.contains("本地存档恢复"), "恢复存档提供中文反馈")
	await _press_action(resumed, "重游序章（重置进度）")
	_expect_equal(resumed.get_node("%LocationLabel").text, "照禾渡口", "结算页可重游序章")
	_expect_equal(resumed.get_node("%MapCanvas").current_visual_mode(), "riverbank", "重游恢复渡口地图")
	_expect_equal(resumed.exploration.player_position, ExplorationStateScript.START_POSITION, "重游重置玩家位置")
	_expect_equal(resumed.journey.discoveries, [], "重游清空上一轮环境见闻")
	_expect_equal(resumed.journey.ferryman_response, "unanswered", "重游清空上一轮守堤选择")
	_expect_equal(resumed.journey.basket_response, "unanswered", "重游清空上一轮药篓选择")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["phase"], "riverbank", "重游结果写入存档")
	resumed.journey.setbacks = 3
	resumed.return_to_title()
	resumed.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_true(resumed.new_game_confirmation_contract()["visible"], "第二次尝试仍先进入覆盖确认")
	resumed.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_false(resumed.get_node("%TitleOverlay").visible, "明确确认后才进入新旅程")
	_expect_equal(resumed.journey.setbacks, 0, "明确确认会建立全新的规则状态")
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["setbacks"], 0.0, "明确确认把新旅程写入存档")
	resumed.get_node("%AudioManager").set_audio_enabled(false)
	resumed.queue_free()
	await process_frame

	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	_write_test_file(TEST_SCENE_SAVE_PATH, "{not-json")
	var invalid_save_instance := scene.instantiate()
	invalid_save_instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	invalid_save_instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(invalid_save_instance)
	await process_frame
	_expect_true(invalid_save_instance.get_node("%ContinueButton").disabled, "异常存档不能继续载入")
	invalid_save_instance.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_true(invalid_save_instance.new_game_confirmation_contract()["visible"], "异常存档也不会被一次点击删除")
	_expect_true(invalid_save_instance.new_game_confirmation_contract()["warning"].contains("异常存档"), "异常存档使用准确覆盖警告")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), "{not-json", "异常原文件在确认前保持原样")
	invalid_save_instance.get_node("%ContinueButton").pressed.emit()
	await process_frame
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), "{not-json", "取消后异常原文件仍可供人工恢复")
	invalid_save_instance.get_node("%AudioManager").set_audio_enabled(false)
	invalid_save_instance.queue_free()
	await process_frame
	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SCENE_SETTINGS_PATH)


func _test_scene_save_recovery() -> void:
	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SCENE_SETTINGS_PATH)
	var journey = JourneyStateScript.new()
	var exploration = ExplorationStateScript.new()
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SCENE_SAVE_PATH)["ok"], "场景恢复测试建立有效存档")
	var valid_text := FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH)
	_write_test_file(TEST_SCENE_SAVE_PATH + ".tmp", valid_text)
	_write_test_file(TEST_SCENE_SAVE_PATH, "{interrupted-primary")

	var scene: PackedScene = load("res://src/ui/main.tscn")
	var temporary_instance := scene.instantiate()
	temporary_instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	temporary_instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(temporary_instance)
	await process_frame
	_expect_true(temporary_instance.continue_game(), "主文件损坏时场景可继续有效中断写入")
	_expect_true(temporary_instance.get_node("%EventLabel").text.contains("中断写入"), "临时恢复提供准确中文反馈")
	_expect_true(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["ok"], "临时恢复后自动修复主文件")
	_expect_false(FileAccess.file_exists(TEST_SCENE_SAVE_PATH + ".tmp"), "临时恢复重新落盘后不残留中断文件")
	temporary_instance.get_node("%AudioManager").set_audio_enabled(false)
	temporary_instance.queue_free()
	await process_frame

	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SCENE_SAVE_PATH)["ok"], "内容级回退建立第一代主文件")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SCENE_SAVE_PATH)["ok"], "内容级回退自然建立安全备份")
	var content_invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH))
	content_invalid["dialogue"] = {"active": true, "dialogue_id": "companion_briefing", "line_index": 63}
	_write_test_file(TEST_SCENE_SAVE_PATH, JSON.stringify(content_invalid))
	_expect_true(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["ok"], "存储层接受结构合法但超出当前内容的行号")

	var backup_instance := scene.instantiate()
	backup_instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	backup_instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(backup_instance)
	await process_frame
	_expect_true(backup_instance.continue_game(), "主候选无法映射当前内容时继续尝试安全备份")
	_expect_true(backup_instance.get_node("%EventLabel").text.contains("安全备份"), "内容级回退提供准确中文反馈")
	var healed := SaveGameScript.read(TEST_SCENE_SAVE_PATH)
	_expect_true(healed["ok"] and not healed["data"]["dialogue"]["active"], "内容级回退后把可解码状态重新写为主文件")
	var preserved_backup := SaveGameScript.read(TEST_SCENE_SAVE_PATH + ".bak")
	_expect_true(preserved_backup["ok"] and not preserved_backup["data"]["dialogue"]["active"], "内容级回退不会用被 UI 拒绝的主候选覆盖已知良好备份")
	backup_instance.get_node("%AudioManager").set_audio_enabled(false)
	backup_instance.queue_free()
	await process_frame

	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SCENE_SAVE_PATH)["ok"], "只读屏障测试建立有效旧主文件")
	var barrier_primary_bytes := FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH)
	var future_temporary: Dictionary = JSON.parse_string(barrier_primary_bytes)
	future_temporary["save_version"] = 999
	var future_temporary_text := JSON.stringify(future_temporary)
	_write_test_file(TEST_SCENE_SAVE_PATH + ".tmp", future_temporary_text)
	var barrier_instance := scene.instantiate()
	barrier_instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	barrier_instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
	root.add_child(barrier_instance)
	await process_frame
	_expect_true(barrier_instance.get_node("%ContinueButton").disabled, "有效旧主文件旁存在未来临时文件时禁用普通继续")
	_expect_false(barrier_instance.continue_game(), "未来临时屏障不进入看似可保存的旅程")
	_expect_true(barrier_instance.get_node("%TitleOverlay").visible, "受阻继续仍停留在标题界面")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), barrier_primary_bytes, "受阻继续保持旧主文件字节")
	_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH + ".tmp"), future_temporary_text, "受阻继续保持未来临时文件字节")
	barrier_instance.get_node("%AudioManager").set_audio_enabled(false)
	barrier_instance.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SCENE_SAVE_PATH + ".tmp"))
	for barrier_suffix in [".repair", ".bak"]:
		_write_test_file(TEST_SCENE_SAVE_PATH + barrier_suffix, future_temporary_text)
		var secondary_barrier_instance := scene.instantiate()
		secondary_barrier_instance.configure_save_path(TEST_SCENE_SAVE_PATH)
		secondary_barrier_instance.configure_settings_path(TEST_SCENE_SETTINGS_PATH)
		root.add_child(secondary_barrier_instance)
		await process_frame
		_expect_true(secondary_barrier_instance.get_node("%ContinueButton").disabled, "未来 %s 屏障会在标题界面禁用继续" % barrier_suffix)
		_expect_false(secondary_barrier_instance.continue_game(), "未来 %s 屏障不会进入旅程" % barrier_suffix)
		_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH), barrier_primary_bytes, "未来 %s 屏障保持旧主文件字节" % barrier_suffix)
		_expect_equal(FileAccess.get_file_as_string(TEST_SCENE_SAVE_PATH + barrier_suffix), future_temporary_text, "未来 %s 屏障保持自身字节" % barrier_suffix)
		secondary_barrier_instance.get_node("%AudioManager").set_audio_enabled(false)
		secondary_barrier_instance.queue_free()
		await process_frame
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SCENE_SAVE_PATH + barrier_suffix))
	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SCENE_SETTINGS_PATH)


func _press_action(instance: Node, label: String) -> void:
	var action_list: GridContainer = instance.get_node("%Actions")
	for child in action_list.get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await process_frame
			await process_frame
			return
	failures.append("没有找到场景行动：%s" % label)


func _press_dialogue_choice(instance: Node, label: String) -> void:
	for child in instance.get_node("%DialogueChoices").get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await process_frame
			return
	failures.append("没有找到对话回应：%s" % label)


func _dialogue_choice_count(instance: Node) -> int:
	var count := 0
	for child in instance.get_node("%DialogueChoices").get_children():
		if child is Button:
			count += 1
	return count


func _action_button_count(instance: Node) -> int:
	var count := 0
	for child in instance.get_node("%Actions").get_children():
		if child is Button:
			count += 1
	return count


func _first_action_button(instance: Node) -> Button:
	for child in instance.get_node("%Actions").get_children():
		if child is Button:
			return child
	return null


func _action_has_joypad_event(action_name: StringName) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadMotion or event is InputEventJoypadButton:
			return true
	return false


func _expect_detail_cells_bounded_and_unique(contract: Dictionary, map_label: String) -> void:
	var cells: Array = contract["used_cells"]
	var unique_cells := {}
	for cell_value in cells:
		var cell := Vector2i(cell_value)
		unique_cells[cell] = true
		_expect_true(Rect2i(Vector2i.ZERO, Vector2i(48, 27)).has_point(cell), "%s细节单元位于 48×27 边界内" % map_label)
	_expect_equal(unique_cells.size(), cells.size(), "%s细节单元没有互相覆盖" % map_label)
	var counted_cells := 0
	for tile_count in contract["tile_counts"].values():
		counted_cells += int(tile_count)
	_expect_equal(counted_cells, cells.size(), "%s细节分类计数覆盖全部单元" % map_label)


func _image_region_has_opaque_pixel(image: Image, region: Rect2i) -> bool:
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if image.get_pixel(x, y).a > 0.0:
				return true
	return false


func _patrol_endpoint_snapshot(worksite_id: String, dwell: float = PatrolStateScript.ENDPOINT_DWELL_SECONDS) -> Dictionary:
	if worksite_id == PatrolStateScript.WORKSITE_BOAT:
		return {
			"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
			"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
			"target_index": PatrolStateScript.BOAT_WAYPOINT + 1,
			"route_step": 1,
			"dwell_remaining": dwell,
			"yielding_to_player": false,
		}
	if worksite_id == PatrolStateScript.WORKSITE_HERBS:
		return {
			"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].x,
			"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].y,
			"target_index": PatrolStateScript.HERBS_WAYPOINT - 1,
			"route_step": -1,
			"dwell_remaining": dwell,
			"yielding_to_player": false,
		}
	return {}


func _write_test_file(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("无法写入测试文件：%s" % path)
		return
	file.store_string(contents)
	file.close()


func _battle_state(approach_action: String = "approach_enemy"):
	var state = JourneyStateScript.new()
	state.choose("talk_to_companion")
	state.choose("gather_moonleaf")
	state.choose("enter_spring")
	state.choose(approach_action)
	return state


func _defeat_boss(state) -> Dictionary:
	state.choose("guard")
	state.choose("guard")
	state.choose("use_art")
	state.choose("companion_support")
	state.choose("use_art")
	return state.choose("use_art")


func _expect_true(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s：期望 true" % label)


func _expect_false(value: bool, label: String) -> void:
	_expect_true(not value, label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s：期望 %s，实际 %s" % [label, expected, actual])
