extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_initial_state()
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
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect_equal(instance.get_node("%LocationLabel").text, "照禾渡口", "主场景读取内容")
	_expect_equal(instance.get_node("%Actions").get_child_count(), 2, "主场景渲染可选行动")
	_expect_equal(instance.get_node("%MapCanvas").actor_height_px(), 56.0, "角色使用 56 px 生产基准")
	_expect_equal(instance.get_node("%MapCanvas").current_visual_mode(), "riverbank", "初始地图使用渡口画面")
	_expect_true(instance.get_node("%ObjectiveLabel").text.contains("护脉灵草"), "探索目标进入抬头信息")
	_expect_equal(instance.get_node("%Actions").get_child(0).custom_minimum_size.y, 48.0, "行动按钮保持可点击高度")

	await _press_action(instance, "查看月芽田")
	_expect_true(instance.get_node("%EventLabel").text.contains("只取一株"), "场景呈现采集结果")
	_expect_equal(instance.get_node("%Actions").get_child_count(), 1, "采集按钮完成后隐藏")

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
	instance.queue_free()
	await process_frame


func _press_action(instance: Node, label: String) -> void:
	var action_list: VBoxContainer = instance.get_node("%Actions")
	for child in action_list.get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await process_frame
			await process_frame
			return
	failures.append("没有找到场景行动：%s" % label)


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
