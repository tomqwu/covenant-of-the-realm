extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
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
	_test_exploration_rules()
	_test_state_restore()
	_test_versioned_save()
	_test_settings_store()
	_test_gathering_and_gate()
	_test_combat_paths()
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
	_expect_true(state.available_actions().has("enter_spring"), "初始可尝试进山")
	_expect_false(state.choose("unknown")["ok"], "未知行动不改变状态")


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

	_expect_true(state.restore({"player_x": 0.69, "player_y": 0.62}), "可恢复到合法月芽田位置")
	_expect_equal(state.interaction_action(false), "gather_moonleaf", "靠近月芽草出现采集交互")
	_expect_equal(state.interaction_action(true), "", "采集后月芽草不再交互")
	_expect_true(state.restore({"player_x": 0.88, "player_y": 0.18}), "可恢复到合法山门位置")
	_expect_equal(state.interaction_action(false), "enter_spring", "靠近山门出现进山交互")
	var gate_position: Vector2 = state.player_position
	_expect_false(state.restore({"player_x": 0.2, "player_y": 0.5}), "拒绝恢复到碰撞区")
	_expect_equal(state.player_position, gate_position, "无效恢复保留原位置")
	_expect_false(state.restore({"player_x": 0.5}), "缺失坐标的快照被拒绝")
	_expect_equal(state.snapshot().keys(), ["player_x", "player_y"], "探索快照只含稳定坐标")


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


func _test_versioned_save() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var journey = _battle_state()
	journey.choose("guard")
	var exploration = ExplorationStateScript.new()
	_expect_true(exploration.restore({"player_x": 0.88, "player_y": 0.18}), "准备合法探索存档")
	var written: Dictionary = SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)
	_expect_true(written["ok"], "版本化存档写入成功")
	_expect_true(SaveGameScript.exists(TEST_SAVE_PATH), "写入后可检测继续游戏")
	var loaded: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(loaded["ok"], "版本化存档读取成功")
	_expect_equal(loaded["data"]["save_version"], 4.0, "存档声明当前版本")
	var restored_journey = JourneyStateScript.new()
	var restored_exploration = ExplorationStateScript.new()
	_expect_true(restored_journey.restore(loaded["data"]["journey"]), "读取的规则快照通过业务校验")
	_expect_true(restored_exploration.restore(loaded["data"]["exploration"]), "读取的探索快照通过碰撞校验")
	_expect_equal(restored_journey.snapshot(), journey.snapshot(), "磁盘往返保留规则状态")
	_expect_true(restored_exploration.player_position.is_equal_approx(exploration.player_position), "磁盘往返保留玩家位置")

	var legacy_journey: Dictionary = journey.snapshot().duplicate(true)
	legacy_journey.erase("companion_supports")
	legacy_journey.erase("setbacks")
	legacy_journey.erase("talked_to_companion")
	legacy_journey.erase("spring_lamps")
	legacy_journey.erase("lamp_turns")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 1,
		"story_id": SaveGameScript.STORY_ID,
		"journey": legacy_journey,
		"exploration": exploration.snapshot(),
	}))
	var migrated: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated["ok"], "v1 存档可迁移到当前版本")
	_expect_equal(migrated["migrated_from_version"], 1, "迁移结果声明来源版本")
	_expect_equal(migrated["data"]["save_version"], 4, "迁移后的内存快照升级为 v4")
	_expect_equal(migrated["data"]["journey"]["companion_supports"], 1, "迁移补入同伴援护资源")
	_expect_equal(migrated["data"]["journey"]["setbacks"], 0, "迁移补入挫败计数")
	_expect_true(migrated["data"]["journey"]["talked_to_companion"], "战斗中的 v1 存档迁移为已完成简报")
	_expect_equal(migrated["data"]["journey"]["spring_lamps"], 1, "v1 迁移补入战术石灯")
	_expect_equal(migrated["data"]["journey"]["lamp_turns"], 0, "v1 迁移不虚构持续效果")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "迁移后可写回新版存档")
	var version_two_journey: Dictionary = journey.snapshot().duplicate(true)
	version_two_journey.erase("talked_to_companion")
	version_two_journey.erase("spring_lamps")
	version_two_journey.erase("lamp_turns")
	_write_test_file(TEST_SAVE_PATH, JSON.stringify({
		"save_version": 2,
		"story_id": SaveGameScript.STORY_ID,
		"journey": version_two_journey,
		"exploration": exploration.snapshot(),
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
		"exploration": exploration.snapshot(),
	}))
	var migrated_v3: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect_true(migrated_v3["ok"], "v3 存档可迁移到当前版本")
	_expect_equal(migrated_v3["migrated_from_version"], 3, "v3 迁移声明来源版本")
	_expect_equal(migrated_v3["data"]["journey"]["spring_lamps"], 1, "v3 存档补入战术石灯")
	_expect_true(SaveGameScript.write(journey.snapshot(), exploration.snapshot(), TEST_SAVE_PATH)["ok"], "v3 迁移后可写回新版存档")
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
	_expect_true(SettingsStoreScript.write({"audio_enabled": true, "audio_volume": 0.35}, TEST_SETTINGS_PATH), "音频偏好写入成功")
	var stored: Dictionary = SettingsStoreScript.read(TEST_SETTINGS_PATH)
	_expect_true(stored["ok"], "音频偏好可以读取")
	_expect_true(stored["data"]["audio_enabled"], "音频开关持久化")
	_expect_equal(stored["data"]["audio_volume"], 0.35, "音量持久化")
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
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)


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
	_expect_false(state.choose("gather_moonleaf")["ok"], "重复采集无收益")
	_expect_false(state.available_actions().has("gather_moonleaf"), "完成行动从选项隐藏")
	_expect_true(state.choose("enter_spring")["ok"], "准备后进入战斗")
	_expect_equal(state.phase_id(), "battle", "战斗阶段")


func _test_combat_paths() -> void:
	var state = _battle_state()
	var guarded: Dictionary = state.choose("guard")
	_expect_equal(guarded["snapshot"]["player_hp"], 11, "守势只受一点伤害")
	_expect_equal(guarded["snapshot"]["round"], 2, "守势推进回合")
	_expect_true(guarded["events"].has("enemy_glanced"), "守势返回减伤事件")

	var talisman: Dictionary = state.choose("use_talisman")
	_expect_equal(talisman["snapshot"]["enemy_hp"], 4, "符箓造成五点伤害")
	_expect_equal(talisman["snapshot"]["talismans"], 0, "符箓被消耗")
	_expect_false(state.choose("use_talisman")["ok"], "空符箓不会结算敌方攻击")
	_expect_false(state.choose("invalid")["ok"], "战斗拒绝未知行动")

	var victory: Dictionary = state.choose("use_art")
	_expect_equal(victory["snapshot"]["enemy_hp"], 1, "术式造成三点伤害")
	victory = state.choose("use_art")
	_expect_equal(victory["snapshot"]["enemy_hp"], 0, "伤害不会低于零")
	_expect_equal(state.phase_id(), "spring", "胜利进入泉室")
	_expect_true(victory["events"].has("battle_won"), "胜利事件只在结束时返回")


func _test_companion_retreat_and_rescue() -> void:
	var deployed = _battle_state()
	var deployment: Dictionary = deployed.choose("deploy_spring_lamp")
	_expect_true(deployment["ok"], "战斗中可以布置战术石灯")
	_expect_equal(deployment["snapshot"]["spring_lamps"], 0, "部署物占用唯一战术槽")
	_expect_equal(deployment["snapshot"]["lamp_turns"], 1, "部署回合后石灯仍可再保护一次")
	_expect_equal(deployment["snapshot"]["player_hp"], 10, "部署回合由石灯降低一点伤害")
	_expect_true(deployment["events"].has("spring_lamp_absorbed"), "部署返回持续效果事件")
	var warded_guard: Dictionary = deployed.choose("guard")
	_expect_equal(warded_guard["snapshot"]["player_hp"], 10, "守势与石灯合计免除下一次冲击")
	_expect_equal(warded_guard["snapshot"]["lamp_turns"], 0, "石灯持续次数耗尽")
	_expect_false(deployed.available_actions().has("deploy_spring_lamp"), "已占用的部署槽从行动隐藏")
	_expect_false(deployed.choose("deploy_spring_lamp")["ok"], "同一挑战不能重复部署石灯")

	var supported = _battle_state()
	supported.choose("use_art")
	var support: Dictionary = supported.choose("companion_support")
	_expect_true(support["ok"], "战斗中可以请求篇章同伴援护")
	_expect_equal(support["snapshot"]["player_hp"], 11, "援护治疗并抵消大半当回合伤害")
	_expect_equal(support["snapshot"]["companion_supports"], 0, "援护资源每场只能使用一次")
	_expect_false(supported.available_actions().has("companion_support"), "用尽的援护从玩家选项隐藏")
	var no_support: Dictionary = supported.choose("companion_support")
	_expect_false(no_support["ok"], "同一场战斗不能重复获得援护")
	_expect_equal(no_support["snapshot"]["player_hp"], 11, "无效援护不会触发敌方攻击")

	var retreated = _battle_state()
	retreated.choose("use_talisman")
	var retreat: Dictionary = retreated.choose("retreat")
	_expect_true(retreat["ok"], "战斗中可以主动撤退")
	_expect_equal(retreated.phase_id(), "riverbank", "撤退返回照禾渡口")
	_expect_equal(retreat["snapshot"]["enemy_hp"], 9, "撤退后敌人恢复完整甲势")
	_expect_equal(retreat["snapshot"]["talismans"], 0, "撤退不会返还已消耗符箓")
	_expect_equal(retreat["snapshot"]["setbacks"], 1, "撤退记录一次挫败")
	_expect_equal(retreat["snapshot"]["spring_lamps"], 1, "撤退后下一次挑战可重新布灯")
	_expect_true(retreated.choose("enter_spring")["ok"], "撤退后可从山门再次挑战")

	var rescued = _battle_state()
	var final_guard: Dictionary = {}
	for turn in range(12):
		final_guard = rescued.choose("guard")
	_expect_equal(rescued.phase_id(), "riverbank", "气血耗尽不会形成死档")
	_expect_true(final_guard["events"].has("companion_rescue"), "气血耗尽触发同伴救援")
	_expect_equal(final_guard["snapshot"]["player_hp"], 8, "救援后恢复到可继续状态")
	_expect_equal(final_guard["snapshot"]["setbacks"], 1, "救援记录一次挫败")


func _test_breakthrough_and_completion() -> void:
	var state = _battle_state()
	state.choose("use_talisman")
	state.choose("use_art")
	state.choose("use_art")
	_expect_equal(state.phase_id(), "spring", "组合行动可以获胜")
	_expect_false(state.choose("invalid")["ok"], "泉室拒绝未知行动")
	var result: Dictionary = state.choose("breakthrough")
	_expect_true(result["ok"], "突破成功")
	_expect_equal(result["snapshot"]["realm"], "引息境一层", "境界更新")
	_expect_false(result["snapshot"]["gathered_moonleaf"], "突破消耗灵草")
	_expect_equal(state.available_actions(), PackedStringArray(["review_journey", "return_to_title", "replay_chapter"]), "完成后可回顾、返回标题或重游")
	_expect_true(state.choose("review_journey")["ok"], "回顾不重复奖励")
	_expect_true(state.choose("return_to_title")["ok"], "规则层允许完成本节返回标题")
	var replay: Dictionary = state.choose("replay_chapter")
	_expect_true(replay["ok"], "完成后可以重游本章")
	_expect_equal(replay["snapshot"]["phase"], "riverbank", "重游回到渡口")
	_expect_equal(replay["snapshot"]["realm"], "凡身", "重游重置境界")
	_expect_equal(replay["snapshot"]["talismans"], 1, "重游重置消耗品")
	_expect_equal(replay["snapshot"]["setbacks"], 0, "重游重置挫败记录")
	_expect_equal(replay["snapshot"]["spring_lamps"], 1, "重游重置战术部署物")
	_expect_false(replay["snapshot"]["talked_to_companion"], "重游重置开场交谈")
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
	_expect_true(instance.get_node("%ContinueButton").disabled, "没有存档时继续按钮禁用")
	_expect_equal(instance.get_node("%TitleAudioButton").text, "环境音：关闭", "标题默认静音且不自动播放")
	instance.get_node("%TitleAudioButton").pressed.emit()
	await process_frame
	_expect_equal(instance.get_node("%TitleAudioButton").text, "环境音：开启", "标题可以开启原创环境音")
	_expect_equal(instance.get_node("%PauseAudioButton").text, "环境音：开启", "标题与暂停音频开关同步")
	_expect_true(instance.get_node("%AudioManager").is_audio_active(), "开启后音频生成器运行")
	instance.get_node("%TitleVolumeButton").pressed.emit()
	_expect_equal(instance.get_node("%TitleVolumeButton").text, "音量：100%", "音量按钮循环到满音量")
	instance.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_false(instance.get_node("%TitleOverlay").visible, "新游戏进入实际地图")
	_expect_true(SaveGameScript.exists(TEST_SCENE_SAVE_PATH), "新游戏立即建立版本化存档")
	_expect_equal(instance.get_node("%LocationLabel").text, "照禾渡口", "主场景读取内容")
	_expect_equal(_action_button_count(instance), 1, "出生点只显示近距离同伴交谈")
	_expect_equal(instance.get_node("%MapCanvas").actor_height_px(), 56.0, "角色使用 56 px 生产基准")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "riverbank", "初始地图使用渡口画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("与渡碑旁"), "初始目标引导同伴交谈")
	_expect_true(instance.get_node("%InputHint").text.contains("WASD"), "探索显示键盘与手柄输入提示")
	_expect_true(InputMap.has_action("move_left"), "移动使用语义输入动作")
	_expect_true(InputMap.has_action("interact"), "交互使用语义输入动作")
	_expect_true(_action_has_joypad_event("move_left"), "移动动作包含手柄绑定")
	_expect_true(_action_has_joypad_event("interact"), "交互动作包含手柄绑定")
	_expect_true(_action_has_joypad_event("pause_menu"), "暂停动作包含手柄绑定")
	instance.toggle_pause_menu()
	_expect_true(instance.get_node("%PauseOverlay").visible, "暂停菜单可由统一动作打开")
	instance.toggle_pause_menu()
	_expect_false(instance.get_node("%PauseOverlay").visible, "暂停菜单可继续游戏")
	_expect_true(instance.interact()["ok"], "出生点语义交互与同伴交谈")
	_expect_true(instance.get_node("%EventLabel").text.contains("泉眼昨夜"), "场景呈现砚青的风险简报")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("月芽田"), "交谈后目标切换为采药")
	_expect_false(instance.interact()["ok"], "完成交谈后原地没有重复奖励")
	_expect_true(instance.get_node("%EventLabel").text.contains("附近没有"), "无目标交互给出中文反馈")

	instance.move_player(Vector2.DOWN, 0.40)
	instance.move_player(Vector2.RIGHT, 0.74)
	await process_frame
	_expect_equal(_action_button_count(instance), 1, "靠近月芽草显示一个交互行动")
	_expect_equal(_first_action_button(instance).custom_minimum_size.y, 48.0, "交互按钮保持可点击高度")

	await _press_action(instance, "查看月芽田")
	_expect_true(instance.get_node("%EventLabel").text.contains("只取一株"), "场景呈现采集结果")
	_expect_equal(_action_button_count(instance), 0, "采集按钮完成后隐藏")

	instance.move_player(Vector2.LEFT, 0.82)
	instance.move_player(Vector2.UP, 1.56)
	instance.move_player(Vector2.RIGHT, 1.46)
	instance.move_player(Vector2.DOWN, 0.06)
	await process_frame
	_expect_equal(_action_button_count(instance), 1, "走到山门后显示进入行动")
	await _press_action(instance, "进入藏泉山道")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景进入战斗")
	_expect_equal(_action_button_count(instance), 6, "战斗显示术式、符箓、守势、援护、石灯与撤退")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "battle", "战斗切换山道画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("甲缝"), "战斗目标提示弱点与退路")
	await _press_action(instance, "撤回照禾渡口")
	_expect_equal(instance.get_node("%LocationLabel").text, "照禾渡口", "场景撤退返回渡口")
	_expect_true(instance.get_node("%EventLabel").text.contains("预留的石标"), "场景说明撤退路线与敌人重置")
	_expect_equal(_action_button_count(instance), 1, "撤回山门附近可立即重新挑战")
	await _press_action(instance, "进入藏泉山道")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉山道", "场景可在撤退后再次进山")
	await _press_action(instance, "布置引泉石灯")
	_expect_true(instance.get_node("%EventLabel").text.contains("青白泉光"), "场景呈现战术部署物")
	_expect_true(instance.get_node("%StatusLabel").text.contains("石灯 0"), "状态显示部署槽已使用")

	await _press_action(instance, "请砚青援护")
	_expect_true(instance.get_node("%EventLabel").text.contains("护脉药雾"), "场景呈现主动同伴援护")
	_expect_true(instance.get_node("%StatusLabel").text.contains("援护 0"), "战斗状态显示援护资源用尽")
	await _press_action(instance, "镇岩符")
	_expect_true(instance.get_node("%StatusLabel").text.contains("回合 4"), "战斗状态呈现回合信息")
	await _press_action(instance, "引气术")
	await _press_action(instance, "引气术")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉石室", "胜利进入泉室")

	await _press_action(instance, "静心引息")
	_expect_equal(instance.get_node("%LocationLabel").text, "第一息", "场景完成章节")
	_expect_true(instance.get_node("%StatusLabel").text.contains("引息境一层"), "场景显示突破境界")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "complete", "结算切换明亮突破画面")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("本节结算"), "完成画面显示战绩结算")
	_expect_true(instance.get_node("%DescriptionLabel").text.contains("经历 1 次"), "结算记录实际撤退次数")
	_expect_equal(_action_button_count(instance), 3, "结算提供回顾、返回标题和重游")
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
	_expect_true(resumed.continue_game(), "新场景可以继续本地存档")
	await process_frame
	_expect_equal(resumed.get_node("%LocationLabel").text, "第一息", "继续游戏恢复章节完成态")
	_expect_true(resumed.get_node("%EventLabel").text.contains("本地存档恢复"), "恢复存档提供中文反馈")
	await _press_action(resumed, "重游序章（重置进度）")
	_expect_equal(resumed.get_node("%LocationLabel").text, "照禾渡口", "结算页可重游序章")
	_expect_equal(resumed.get_node("%MapCanvas").current_visual_mode(), "riverbank", "重游恢复渡口地图")
	_expect_equal(resumed.exploration.player_position, ExplorationStateScript.START_POSITION, "重游重置玩家位置")
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


func _battle_state():
	var state = JourneyStateScript.new()
	state.choose("talk_to_companion")
	state.choose("gather_moonleaf")
	state.choose("enter_spring")
	return state


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
