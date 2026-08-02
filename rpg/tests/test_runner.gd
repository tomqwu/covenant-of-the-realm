extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const TEST_SAVE_PATH := "user://automated-test-save.json"
const TEST_SCENE_SAVE_PATH := "user://automated-scene-save.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_initial_state()
	_test_exploration_rules()
	_test_state_restore()
	_test_versioned_save()
	_test_gathering_and_gate()
	_test_combat_paths()
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
	_expect_true(state.available_actions().has("gather_moonleaf"), "初始可采集")
	_expect_true(state.available_actions().has("enter_spring"), "初始可尝试进山")
	_expect_false(state.choose("unknown")["ok"], "未知行动不改变状态")


func _test_exploration_rules() -> void:
	var state = ExplorationStateScript.new()
	_expect_equal(state.player_position, ExplorationStateScript.START_POSITION, "探索使用确定的起点")
	_expect_true(state.is_walkable(state.player_position), "初始位置可以行走")
	_expect_equal(state.interaction_action(false), "", "出生点不能隔空交互")

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
	_expect_equal(loaded["data"]["save_version"], 1.0, "存档声明当前版本")
	var restored_journey = JourneyStateScript.new()
	var restored_exploration = ExplorationStateScript.new()
	_expect_true(restored_journey.restore(loaded["data"]["journey"]), "读取的规则快照通过业务校验")
	_expect_true(restored_exploration.restore(loaded["data"]["exploration"]), "读取的探索快照通过碰撞校验")
	_expect_equal(restored_journey.snapshot(), journey.snapshot(), "磁盘往返保留规则状态")
	_expect_true(restored_exploration.player_position.is_equal_approx(exploration.player_position), "磁盘往返保留玩家位置")
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


func _test_gathering_and_gate() -> void:
	var state = JourneyStateScript.new()
	var blocked: Dictionary = state.choose("enter_spring")
	_expect_false(blocked["ok"], "缺少灵草时阻止进山")
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
	_expect_equal(state.available_actions(), PackedStringArray(["review_journey"]), "完成后只可回顾")
	_expect_true(state.choose("review_journey")["ok"], "回顾不重复奖励")
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
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var instance := scene.instantiate()
	instance.configure_save_path(TEST_SCENE_SAVE_PATH)
	root.add_child(instance)
	await process_frame
	_expect_true(instance.get_node("%TitleOverlay").visible, "首次启动显示中文标题界面")
	_expect_true(instance.get_node("%ContinueButton").disabled, "没有存档时继续按钮禁用")
	instance.get_node("%NewGameButton").pressed.emit()
	await process_frame
	_expect_false(instance.get_node("%TitleOverlay").visible, "新游戏进入实际地图")
	_expect_true(SaveGameScript.exists(TEST_SCENE_SAVE_PATH), "新游戏立即建立版本化存档")
	_expect_equal(instance.get_node("%LocationLabel").text, "照禾渡口", "主场景读取内容")
	_expect_equal(_action_button_count(instance), 0, "出生点不显示远距离行动")
	_expect_equal(instance.get_node("%MapCanvas").actor_height_px(), 56.0, "角色使用 56 px 生产基准")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "riverbank", "初始地图使用渡口画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("护脉灵草"), "探索目标进入抬头信息")
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
	_expect_false(instance.interact()["ok"], "出生点交互不会隔空采集")
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
	_expect_equal(instance.get_node("%Actions").get_child_count(), 3, "战斗显示三种行动")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "battle", "战斗切换山道画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("甲缝"), "战斗目标提示弱点与退路")

	await _press_action(instance, "镇岩符")
	_expect_true(instance.get_node("%StatusLabel").text.contains("回合 2"), "战斗状态呈现回合信息")
	await _press_action(instance, "引气术")
	await _press_action(instance, "引气术")
	_expect_equal(instance.get_node("%LocationLabel").text, "藏泉石室", "胜利进入泉室")

	await _press_action(instance, "静心引息")
	_expect_equal(instance.get_node("%LocationLabel").text, "第一息", "场景完成章节")
	_expect_true(instance.get_node("%StatusLabel").text.contains("引息境一层"), "场景显示突破境界")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "complete", "结算切换明亮突破画面")
	instance.return_to_title()
	await process_frame
	_expect_true(instance.get_node("%TitleOverlay").visible, "完成后可以保存并返回标题")
	_expect_false(instance.get_node("%ContinueButton").disabled, "已有存档时允许继续")
	instance.queue_free()
	await process_frame

	var resumed := scene.instantiate()
	resumed.configure_save_path(TEST_SCENE_SAVE_PATH)
	root.add_child(resumed)
	await process_frame
	_expect_true(resumed.get_node("%TitleStatus").text.contains("第一息"), "标题界面展示存档位置")
	_expect_true(resumed.continue_game(), "新场景可以继续本地存档")
	await process_frame
	_expect_equal(resumed.get_node("%LocationLabel").text, "第一息", "继续游戏恢复章节完成态")
	_expect_true(resumed.get_node("%EventLabel").text.contains("本地存档恢复"), "恢复存档提供中文反馈")
	resumed.queue_free()
	await process_frame
	SaveGameScript.remove(TEST_SCENE_SAVE_PATH)


func _press_action(instance: Node, label: String) -> void:
	var action_list: VBoxContainer = instance.get_node("%Actions")
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
