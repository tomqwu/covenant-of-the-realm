extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const DialogueStateScript := preload("res://src/domain/dialogue_state.gd")
const EnemyCatalogScript := preload("res://src/domain/enemy_catalog.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const DialoguePortraitScript := preload("res://src/ui/dialogue_portrait.gd")
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
	_test_state_restore()
	_test_dialogue_state()
	_test_versioned_save()
	_test_settings_store()
	_test_companion_trail()
	_test_dialogue_portraits()
	_test_ferryman_side_story()
	_test_environment_discoveries()
	_test_gathering_and_gate()
	_test_combat_paths()
	_test_enemy_profile_combat()
	_test_boss_and_statuses()
	_test_companion_retreat_and_rescue()
	_test_breakthrough_and_completion()
	await _test_visual_scale_scene()
	await _test_scene_smoke()
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
	_expect_equal(state.snapshot()["discoveries"], [], "新旅程没有伪造已读见闻")
	_expect_equal(state.snapshot()["moonleaf_method"], "unselected", "采集前没有伪造取药方式")
	_expect_true(state.available_actions().has("enter_spring"), "初始可尝试进山")
	_expect_false(state.choose("unknown")["ok"], "未知行动不改变状态")


func _test_enemy_catalog() -> void:
	_expect_equal(EnemyCatalogScript.REGULAR_ENEMY_IDS.size(), 3, "山道配置三种原创普通敌人")
	_expect_equal(EnemyCatalogScript.ENEMY_IDS.size(), 4, "普通敌人与首领共用一个配置目录")
	_expect_true(EnemyCatalogScript.supports("rock_armor_young"), "稳定敌人标识可识别")
	_expect_false(EnemyCatalogScript.supports(3), "非文本敌人标识被拒绝")
	var rock: Dictionary = EnemyCatalogScript.profile("rock_armor_young")
	_expect_equal(rock["name"], "岩甲兽幼体", "岩甲幼兽配置中文名称")
	_expect_equal(rock["max_hp"], 12, "岩甲幼兽生命值由配置提供")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 1)["name"], "试探冲撞", "第一回合意图稳定")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 2)["damage"], 4, "第二回合意图伤害稳定")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 3)["name"], "试探冲撞", "意图序列确定性循环")
	_expect_equal(EnemyCatalogScript.intent("missing", 1), {}, "未知敌人没有伪造意图")
	_expect_equal(EnemyCatalogScript.intent("rock_armor_young", 0), {}, "无效回合没有意图")
	_expect_equal(EnemyCatalogScript.player_damage("rock_armor_young", "use_talisman"), 6, "符压命中岩甲弱点增加一点伤害")
	_expect_equal(EnemyCatalogScript.player_damage("spring_moss_shell", "use_art"), 4, "泉息命中泉苔弱点增加一点伤害")
	_expect_equal(EnemyCatalogScript.player_damage("unbalanced_stone_puppet", "guard"), 2, "守势借力令失衡石傀受创")
	_expect_equal(EnemyCatalogScript.player_damage("missing", "unknown"), 0, "未知组合不产生伤害")
	_expect_true(EnemyCatalogScript.exposes_weakness("spring_moss_shell", "use_art"), "配置可判断材质相克")
	_expect_false(EnemyCatalogScript.exposes_weakness("spring_moss_shell", "guard"), "非弱点行动不误报相克")
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
	_expect_true(state.restore({"map_id": "cangquan_path", "player_x": 0.80, "player_y": 0.25}), "失衡石傀坐标可达")
	_expect_equal(state.interaction_action(true, true), "approach_stone_puppet", "失衡石傀有独立接近行动")


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
	_expect_true(restored.restore({"active": true, "dialogue_id": "companion_briefing", "line_index": 8}), "规则状态允许未来内容扩充到第八行")
	_expect_false(restored.restore({"active": true, "dialogue_id": "companion_briefing", "line_index": 65}), "异常过大的对话行号被拒绝")
	_expect_false(restored.restore({"active": false, "dialogue_id": "companion_briefing", "line_index": 0}), "空闲状态不能保留对话标识")


func _test_versioned_save() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var journey = _battle_state()
	journey.choose("guard")
	var exploration = ExplorationStateScript.new()
	_expect_true(exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "准备合法探索存档")
	var written: Dictionary = SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)
	_expect_true(written["ok"], "版本化存档写入成功")
	_expect_true(SaveGameScript.exists(TEST_SAVE_PATH), "写入后可检测继续游戏")
	var loaded: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(loaded["ok"], "版本化存档读取成功")
	_expect_equal(loaded["data"]["save_version"], 11.0, "存档声明当前版本")
	_expect_equal(loaded["data"]["journey"]["moonleaf_method"], "whole_plant", "新版存档保留取药方式")
	_expect_equal(loaded["data"]["journey"]["enemy_id"], "rock_armor_young", "新版存档声明稳定敌人标识")
	_expect_equal(loaded["data"]["exploration"]["map_id"], "zhaohe_ferry", "新版存档声明稳定地图标识")
	var restored_dialogue = DialogueStateScript.new()
	_expect_true(restored_dialogue.restore(loaded["data"]["dialogue"]), "新版存档包含可恢复的空闲对话状态")
	_expect_equal(restored_dialogue.snapshot(), DialogueStateScript.default_snapshot(), "新版空闲对话状态保持默认值")
	var restored_journey = JourneyStateScript.new()
	var restored_exploration = ExplorationStateScript.new()
	_expect_true(restored_journey.restore(loaded["data"]["journey"]), "读取的规则快照通过业务校验")
	_expect_true(restored_exploration.restore(loaded["data"]["exploration"]), "读取的探索快照通过碰撞校验")
	_expect_equal(restored_journey.snapshot(), journey.snapshot(), "磁盘往返保留规则状态")
	_expect_true(restored_exploration.player_position.is_equal_approx(exploration.player_position), "磁盘往返保留玩家位置")

	var legacy_journey: Dictionary = journey.snapshot().duplicate(true)
	var legacy_exploration := exploration.snapshot().duplicate(true)
	legacy_exploration.erase("map_id")
	legacy_journey.erase("companion_supports")
	legacy_journey.erase("setbacks")
	legacy_journey.erase("talked_to_companion")
	legacy_journey.erase("spring_lamps")
	legacy_journey.erase("lamp_turns")
	legacy_journey.erase("briefing_response")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 1,
		"story_id": SaveGameScript.STORY_ID,
		"journey": legacy_journey,
		"exploration": legacy_exploration,
	}))
	var migrated: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated["ok"], "v1 存档可迁移到当前版本")
	_expect_equal(migrated["migrated_from_version"], 1, "迁移结果声明来源版本")
	_expect_equal(migrated["data"]["save_version"], 11, "迁移后的内存快照升级为 v11")
	_expect_equal(migrated["data"]["journey"]["enemy_id"], "rock_armor_young", "旧版迁移补入默认敌人标识")
	_expect_equal(migrated["data"]["exploration"]["map_id"], "zhaohe_ferry", "v1 迁移补入照禾渡口地图标识")
	_expect_equal(migrated["data"]["journey"]["companion_supports"], 1, "迁移补入同伴援护资源")
	_expect_equal(migrated["data"]["journey"]["setbacks"], 0, "迁移补入挫败计数")
	_expect_true(migrated["data"]["journey"]["talked_to_companion"], "战斗中的 v1 存档迁移为已完成简报")
	_expect_equal(migrated["data"]["journey"]["spring_lamps"], 1, "v1 迁移补入战术石灯")
	_expect_equal(migrated["data"]["journey"]["lamp_turns"], 0, "v1 迁移不虚构持续效果")
	_expect_equal(migrated["data"]["journey"]["briefing_response"], "careful", "旧版已交谈存档迁移为谨慎回应")
	_expect_equal(migrated["data"]["journey"]["moonleaf_method"], "whole_plant", "旧版持药存档迁移为保守整株记录")
	_expect_equal(migrated["data"]["journey"]["discoveries"], [], "旧版存档不虚构环境见闻")
	_expect_equal(migrated["data"]["journey"]["ferryman_response"], "unanswered", "旧版存档不虚构守堤选择")
	_expect_equal(migrated["data"]["dialogue"], DialogueStateScript.default_snapshot(), "旧版迁移补入空闲对话状态")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "迁移后可写回新版存档")
	var version_two_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v2 迁移后可写回新版存档")
	var version_three_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v3 迁移后可写回新版存档")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 4,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": legacy_exploration,
	}))
	var migrated_v4: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v4["ok"], "v4 存档可迁移到地图感知版本")
	_expect_equal(migrated_v4["migrated_from_version"], 4, "v4 迁移声明来源版本")
	_expect_equal(migrated_v4["data"]["exploration"]["map_id"], "zhaohe_ferry", "v4 迁移补入照禾渡口地图标识")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v4 迁移后可写回新版存档")
	var version_five_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v5 迁移后可写回新版存档")
	var version_six_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v6 迁移后可写回新版存档")
	var version_seven_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v7 迁移后可写回新版存档")
	var version_eight_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v8 迁移后可写回新版存档")
	var version_nine_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v9 迁移后可写回新版存档")
	var version_ten_journey: Dictionary = journey.snapshot().duplicate(true)
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
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v10 迁移后可写回新版存档")
	var valid_save_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_write_test_file(TEST_SAVE_PATH + ".bak", valid_save_text)
	_write_test_file(TEST_SAVE_PATH, "{broken")
	var recovered: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(recovered["ok"], "主文件损坏时读取安全备份")
	_expect_true(recovered["recovered_from_backup"], "备份恢复被明确标记")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "备份恢复后可以重新保存主文件")

	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 999,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
	}))
	var future: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_false(future["ok"], "未知未来版本不会被静默加载")
	_expect_equal(future["reason"], "unsupported_version", "未知版本返回稳定原因")
	var unknown_map_exploration := exploration.snapshot().duplicate(true)
	unknown_map_exploration["map_id"] = "unreleased_secret_realm"
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 11,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": unknown_map_exploration,
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_map", "未知地图不会恢复到错误场景")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 11,
		"story_id": SaveGameScript.STORY_ID,
		"journey": journey.snapshot(),
		"exploration": exploration.snapshot(),
		"dialogue": {"active": true, "dialogue_id": "missing", "line_index": 0},
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_dialogue", "未知对话标识不会进入界面层")
	var unknown_enemy_journey: Dictionary = journey.snapshot().duplicate(true)
	unknown_enemy_journey["enemy_id"] = "unreleased_enemy"
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 11,
		"story_id": SaveGameScript.STORY_ID,
		"journey": unknown_enemy_journey,
		"exploration": exploration.snapshot(),
		"dialogue": DialogueStateScript.default_snapshot(),
	}))
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_enemy", "未知敌人标识不会进入规则层")
	_write_test_file(TEST_SAVE_PATH, "{broken")
	_expect_equal(SaveGameScript.read(TEST_SAVE_PATH)["reason"], "invalid_json", "损坏 JSON 被安全拒绝")
	SaveGameScript.remove(TEST_SAVE_PATH)
	_expect_false(FileAccess.file_exists(TEST_SAVE_PATH), "测试存档和临时文件可清理")


func _test_settings_store() -> void:
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
	var initial: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(initial["ok"], "缺失设置文件时返回安全默认值")
	_expect_equal(initial["reason"], "missing", "默认设置声明文件缺失来源")
	_expect_false(initial["data"]["audio_enabled"], "环境音默认关闭")
	_expect_equal(initial["data"]["audio_volume"], 0.6, "默认音量为六成")
	_expect_equal(initial["data"]["battle_speed"], "standard", "战斗表现默认标准速度")
	_expect_false(initial["data"]["reduced_motion"], "动态效果默认完整")
	_expect_equal(initial["data"]["text_scale"], "standard", "文字大小默认标准")
	_expect_false(initial["data"]["high_contrast"], "高对比默认关闭")
	_expect_true(SettingsStoreScript.write({"audio_enabled": true, "audio_volume": 0.35}, TEST_SETTINGS_PATH), "音频偏好写入成功")
	var stored: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(stored["ok"], "音频偏好可以读取")
	_expect_true(stored["data"]["audio_enabled"], "音频开关持久化")
	_expect_equal(stored["data"]["audio_volume"], 0.35, "音量持久化")
	_expect_equal(stored["data"]["battle_speed"], "standard", "缺省写入补齐标准战斗表现")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 1, "audio_enabled": true, "audio_volume": 1.0}))
	var migrated_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(migrated_settings["ok"], "v1 音频设置可迁移到表现选项版本")
	_expect_equal(migrated_settings["reason"], "migrated_v1", "旧设置声明迁移来源")
	_expect_equal(migrated_settings["data"]["battle_speed"], "standard", "旧设置迁移不擅自开启快速模式")
	_expect_false(migrated_settings["data"]["reduced_motion"], "旧设置迁移保持完整动态默认值")
	_expect_equal(migrated_settings["data"]["text_scale"], "standard", "v1 迁移不擅自放大文字")
	_expect_false(migrated_settings["data"]["high_contrast"], "v1 迁移保持默认对比")
	_write_test_file(TEST_SETTINGS_PATH, JSON.stringify({"settings_version": 2, "audio_enabled": true, "audio_volume": 0.6, "battle_speed": "fast", "reduced_motion": true}))
	var migrated_v2_settings: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(migrated_v2_settings["ok"], "v2 表现设置可迁移到无障碍版本")
	_expect_equal(migrated_v2_settings["reason"], "migrated_v2", "v2 设置声明迁移来源")
	_expect_equal(migrated_v2_settings["data"]["battle_speed"], "fast", "v2 迁移保留快速战斗表现")
	_expect_true(migrated_v2_settings["data"]["reduced_motion"], "v2 迁移保留简化动态偏好")
	_expect_equal(migrated_v2_settings["data"]["text_scale"], "standard", "v2 迁移不擅自放大文字")
	_expect_false(migrated_v2_settings["data"]["high_contrast"], "v2 迁移保持默认对比")
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
	_expect_true(SettingsStoreScript.write({"audio_enabled": false, "audio_volume": 0.6, "battle_speed": "standard", "reduced_motion": false, "text_scale": "large", "high_contrast": true}, TEST_SETTINGS_PATH), "无障碍偏好写入成功")
	var accessible: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(accessible["ok"], "无障碍偏好可以读取")
	_expect_equal(accessible["data"]["text_scale"], "large", "大字偏好持久化")
	_expect_true(accessible["data"]["high_contrast"], "高对比偏好持久化")
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
	_expect_equal(protagonist["palette"]["protagonist"], Color("58738f"), "主角肖像使用晴靛识别色")
	_expect_true(protagonist["motion_free"], "纸绘头像不依赖动态效果")
	_expect_false(protagonist["rule_authority"], "头像表现不成为规则权威")
	_expect_true(portrait.set_portrait("yanqing"), "纸绘头像接受稳定砚青标识")
	_expect_equal(portrait.visual_contract()["portrait_id"], "yanqing", "砚青头像与主角拥有不同表现标识")
	_expect_true(portrait.set_portrait("liangshu"), "纸绘头像接受稳定梁叔标识")
	_expect_equal(portrait.visual_contract()["palette"]["liangshu"], Color("355e63"), "梁叔头像使用守堤冷青识别色")
	_expect_false(portrait.set_portrait("licensed_character"), "未知或外部人物标识不会直接进入头像表现")
	_expect_equal(portrait.visual_contract()["portrait_id"], "journal", "未知头像安全回退为无人物的行旅札记")
	_expect_equal(portrait.visual_contract()["supported_ids"].size(), 4, "切片只声明四个有限头像表现标识")
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
	state.choose("breakthrough")
	_expect_true(state.snapshot()["discoveries"].size() == 3, "完成章节保留本轮见闻用于结算")
	state.choose("replay_chapter")
	_expect_equal(state.discoveries, [], "重游序章清空上一轮见闻")


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
	boss.choose("use_talisman")
	boss.choose("use_art")
	var arrival: Dictionary = boss.choose("use_art")
	_expect_equal(boss.enemy_id, "rock_armor_warden", "普通遭遇胜利触发岩甲守巢者")
	_expect_equal(boss.player_hp, 12, "首领入场间隙由砚青包扎到满气血")
	_expect_equal(boss.companion_supports, 1, "首领战重新准备一次同伴援护")
	_expect_equal(boss.spring_lamps, 1, "首领战重新准备一盏战术石灯")
	_expect_equal(boss.talismans, 0, "首领转场不返还普通战消耗的符箓")
	_expect_true(arrival["events"].has("regular_enemy_won"), "普通敌人退场事件与首领入场分离")

	var counter: Dictionary = boss.choose("guard")
	_expect_equal(counter["snapshot"]["enemy_hp"], 12, "守势借首领重击造成两点反伤")
	_expect_equal(counter["snapshot"]["armor_break_turns"], 2, "命中首领弱点施加两层破甲")
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


func _test_breakthrough_and_completion() -> void:
	var incomplete = JourneyStateScript.new()
	var incomplete_snapshot: Dictionary = incomplete.snapshot()
	_expect_false(incomplete.complete_epilogue("record")["ok"], "章节完成前不能结算余波回应")
	_expect_equal(incomplete.snapshot(), incomplete_snapshot, "非法余波回应不修改旅程")
	var state = _battle_state()
	state.choose("use_talisman")
	state.choose("use_art")
	state.choose("use_art")
	_defeat_boss(state)
	_expect_equal(state.phase_id(), "spring", "组合行动可以获胜")
	_expect_false(state.choose("invalid")["ok"], "泉室拒绝未知行动")
	var result: Dictionary = state.choose("breakthrough")
	_expect_true(result["ok"], "突破成功")
	_expect_equal(result["snapshot"]["realm"], "引息境一层", "境界更新")
	_expect_false(result["snapshot"]["gathered_moonleaf"], "突破消耗灵草")
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
	var replay: Dictionary = state.choose("replay_chapter")
	_expect_true(replay["ok"], "完成后可以重游本章")
	_expect_equal(replay["snapshot"]["phase"], "riverbank", "重游回到渡口")
	_expect_equal(replay["snapshot"]["realm"], "凡身", "重游重置境界")
	_expect_equal(replay["snapshot"]["talismans"], 1, "重游重置消耗品")
	_expect_equal(replay["snapshot"]["setbacks"], 0, "重游重置挫败记录")
	_expect_equal(replay["snapshot"]["spring_lamps"], 1, "重游重置战术部署物")
	_expect_false(replay["snapshot"]["talked_to_companion"], "重游重置开场交谈")
	_expect_equal(replay["snapshot"]["moonleaf_method"], "unselected", "重游重置采集选择")
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
	_expect_true(instance.get_node("%MapCanvas").uses_animated_actor_sprites(), "主角、同伴与守堤人使用 AnimatedSprite2D 表现节点")
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
	var initial_ferryman_visual: Dictionary = instance.get_node("%MapCanvas").ferryman_visual_contract()
	_expect_equal(initial_ferryman_visual["response"], "unanswered", "未交谈时地图不替玩家选择守堤处理")
	_expect_false(initial_ferryman_visual["gauge_upright"], "初始歪斜水尺可从地图辨认")
	_expect_true(instance.get_node("%MapCanvas").uses_animated_enemy_sprites(), "山道与战斗敌人使用 AnimatedSprite2D 表现节点")
	var enemy_sprite: AnimatedSprite2D = instance.get_node("%BattleEnemySprite")
	var enemy_sprite_contract: Dictionary = enemy_sprite.animation_contract()
	_expect_equal(enemy_sprite_contract["frame_size"], Vector2(64, 64), "敌人图集使用 64×64 像素帧")
	_expect_equal(enemy_sprite_contract["foot_anchor"], Vector2(32, 56), "四类敌人共享固定脚底锚点")
	_expect_equal(enemy_sprite_contract["frames_per_profile"], 2, "每类敌人有两帧可循环待机动画")
	_expect_equal(enemy_sprite_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "敌人纹理使用最近邻过滤")
	_expect_equal(enemy_sprite.sprite_frames.get_animation_names().size(), 4, "图集为四个稳定敌人标识提供动画")
	_expect_equal(enemy_sprite.sprite_frames.get_frame_count("idle_rock_armor_warden"), 2, "首领使用独立双帧图集行")
	_expect_false(enemy_sprite.set_enemy_id("unknown_enemy"), "敌人表现节点拒绝未知配置而不伪造动画")
	_expect_equal(enemy_sprite.enemy_id, "rock_armor_young", "非法表现标识不会覆盖当前敌人")
	_expect_true(instance.get_node("%MapCanvas").uses_ferry_tile_layers(), "照禾渡口地表由 TileMapLayer 组成")
	var ferry_ground: TileMapLayer = instance.get_node("%FerryGround")
	var map_contract: Dictionary = ferry_ground.map_contract()
	_expect_equal(map_contract["map_size"], Vector2i(36, 20), "渡口生产地图覆盖 36×20 个网格")
	_expect_equal(map_contract["tile_size"], Vector2i(32, 32), "地图使用 32 px TileSet 网格")
	_expect_equal(map_contract["used_rect"], Rect2i(0, 0, 36, 20), "TileMapLayer 无断裂地覆盖整个镜头")
	_expect_equal(map_contract["tile_counts"]["water"], 240, "地图水域单元数量固定")
	_expect_equal(map_contract["tile_counts"]["bank"], 60, "地图岸线单元数量固定")
	_expect_equal(map_contract["tile_counts"]["moonleaf"], 18, "月芽田在 TileSet 中有明确区域")
	_expect_equal(map_contract["tile_counts"]["stone"], 9, "山门石地区域被地图数据标记")
	_expect_true(map_contract["tile_counts"]["path"] > 40, "地图包含可读的主路与药田支路")
	_expect_equal(map_contract["filter"], CanvasItem.TEXTURE_FILTER_NEAREST, "地图纹理使用最近邻过滤")
	var ferry_occlusion: Dictionary = instance.get_node("%MapCanvas").occlusion_contract()
	_expect_equal(ferry_occlusion["count"], 7, "渡口以三处屋檐和四处树冠组成独立前景节点")
	_expect_true(ferry_occlusion["ids"].has("ferry_roof_0"), "前景合同包含可识别屋檐")
	_expect_true(ferry_occlusion["ids"].has("ferry_tree_3"), "前景合同包含可识别树冠")
	_expect_true(ferry_occlusion["maximum_depth"] <= ferry_occlusion["map_depth_ceiling"], "地图前景不越过深度上限")
	_expect_true(instance.get_node("%DialogueOverlay").z_index > ferry_occlusion["maximum_depth"], "对话模态始终位于所有地图遮挡之上")
	_expect_true(instance.get_node("%MapCanvas").depth_for_y(120.0) < instance.get_node("%MapCanvas").depth_for_y(520.0), "脚底越靠下显示深度越靠前")
	_expect_equal(ferry_occlusion["player_depth"], instance.get_node("%MapCanvas").depth_for_y(player_sprite.position.y), "主角显示深度来自脚底 Y 值")
	_expect_equal(ferry_occlusion["ferryman_depth"], instance.get_node("%MapCanvas").depth_for_y(ferryman_sprite.position.y), "守堤人显示深度来自脚底 Y 值")
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
		},
	})
	_expect_false(invalid_dialogue_position["ok"], "超过当前剧本长度的结构化对话位置仍被拒绝")
	var premature_epilogue: Dictionary = instance._decode_save({
		"ok": true,
		"data": {
			"journey": instance.journey.snapshot(),
			"exploration": instance.exploration.snapshot(),
			"dialogue": {"active": true, "dialogue_id": "chapter_epilogue", "line_index": 1},
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
		},
	})
	_expect_false(inconsistent_ferryman_dialogue["ok"], "已完成守堤选择不能同时恢复活动支线对话")
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
	instance.show_full_dialogue_line()
	_expect_equal(instance.get_node("%DialogueLabel").visible_characters, -1, "玩家可以立即显示整句")
	instance.advance_dialogue()
	_expect_equal(instance.dialogue.line_index, 1, "继续按钮推进一行并自动保存")
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
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["save_version"], 11.0, "守堤选择写入存档 v11")
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
	var path_follow: Dictionary = instance.get_node("%MapCanvas").companion_follow_contract()
	_expect_equal(path_follow["context_id"], "mountain_path", "山道不会沿用渡口脚印")
	_expect_equal(path_follow["point_count"], 2, "换图只在新出生点重建同行轨迹")
	_expect_equal(instance.exploration.map_id, "cangquan_path", "场景切换到稳定山道地图标识")
	_expect_true(instance.get_node("%PathGround").visible, "山道 TileMapLayer 在探索阶段可见")
	_expect_true(instance.get_node("%MapCanvas").uses_mountain_path_tile_layers(), "山道使用独立 TileMapLayer")
	_expect_true(instance.get_node("%PathRockEnemySprite").visible, "山道显示岩甲幼兽像素轮廓")
	_expect_true(instance.get_node("%PathMossEnemySprite").visible, "山道显示泉苔寄壳像素轮廓")
	_expect_true(instance.get_node("%PathPuppetEnemySprite").visible, "山道显示失衡石傀像素轮廓")
	_expect_false(enemy_sprite.visible, "探索阶段不会叠加战斗敌人节点")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 5, "山道使用五处可排序树冠前景")
	var path_contract: Dictionary = instance.get_node("%PathGround").map_contract()
	_expect_equal(path_contract["map_kind"], "mountain_path", "山道图层声明独立地图类型")
	_expect_equal(path_contract["tile_counts"]["water"], 100, "山道溪流宽度由固定地图数据约束")
	_expect_true(path_contract["tile_counts"]["path"] > 40, "山道存在连续可读石路")
	_expect_true(path_contract["tile_counts"]["stone"] > 3, "山道敌区与调查点使用石地标记")
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
	_expect_true(enemy_sprite.visible, "战斗阶段显示独立敌人图集节点")
	_expect_equal(enemy_sprite.enemy_id, "rock_armor_young", "岩甲遭遇选择对应图集行")
	_expect_equal(enemy_sprite.animation, &"idle_rock_armor_young", "战斗节点播放岩甲双帧待机动画")
	_expect_false(instance.get_node("%PathRockEnemySprite").visible, "战斗阶段隐藏探索用敌人轮廓")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 4, "战斗镜头重建四处可排序树冠前景")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("试探冲撞"), "战斗目标预告下一项敌方意图")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("甲缝"), "战斗目标提示材质弱点")
	await _press_action(instance, "撤到旧石标")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景撤退返回山道")
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

	await _press_action(instance, "请砚青援护")
	_expect_true(instance.get_node("%EventLabel").text.contains("护脉药雾"), "场景呈现主动同伴援护")
	_expect_true(instance.get_node("%StatusLabel").text.contains("援护 0"), "战斗状态显示援护资源用尽")
	await _press_action(instance, "镇岩符")
	_expect_true(instance.get_node("%StatusLabel").text.contains("回合 4"), "战斗状态呈现回合信息")
	await _press_action(instance, "引气术")
	_expect_true(instance.get_node("%StatusLabel").text.contains("岩甲兽守巢者 14/14"), "普通敌人后无缝进入首领配置")
	_expect_equal(transition.transition_contract()["label"], "守巢者现 · 先守后破", "同阶段首领入场也发出独立转场语义")
	_expect_equal(enemy_sprite.enemy_id, "rock_armor_warden", "首领入场立即切换正式像素图集行")
	_expect_equal(enemy_sprite.animation, &"idle_rock_armor_warden", "首领播放独立双帧待机动画")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("成熟腹甲"), "场景显示首领专属短描述")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("压阵肩撞"), "首领第一招在行动前明示")
	await _press_action(instance, "守势调息")
	_expect_true(instance.get_node("%StatusLabel").text.contains("破甲 2"), "守住首领重击后状态栏显示破甲")
	await _press_action(instance, "引气术")
	await _press_action(instance, "请砚青援护")
	_expect_true(instance.get_node("%StatusLabel").text.contains("凝息 2"), "同伴援护后状态栏显示凝息")
	await _press_action(instance, "引气术")
	await _press_action(instance, "引气术")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉石室", "胜利进入泉室")
	_expect_equal(instance.get_node("%MapCanvas").occlusion_contract()["count"], 0, "泉室不残留上一地图的树冠节点")

	await _press_action(instance, "静心引息")
	_expect_equal(instance.get_node("%LocationLabel").text, "第一息", "场景完成章节")
	_expect_true(instance.get_node("%StatusLabel").text.contains("引息境一层"), "场景显示突破境界")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "complete", "结算切换明亮突破画面")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("本节结算"), "完成画面显示战绩结算")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("水尺扶正"), "结算回显本轮守堤选择")
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
	_expect_equal(SaveGameScript.read(TEST_SCENE_SAVE_PATH)["data"]["journey"]["phase"], "riverbank", "重游结果写入存档")
	resumed.get_node("%AudioManager").set_audio_enabled(false)
	resumed.queue_free()
	await process_frame
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
