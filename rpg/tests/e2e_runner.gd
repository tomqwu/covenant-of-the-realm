extends SceneTree

const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const TEST_SAVE_PATH := "user://automated-e2e-save.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var game := scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	root.add_child(game)
	await _settle()

	_expect(game.get_node("%TitleOverlay").visible, "E2E 从标题界面开始")
	game.get_node("%NewGameButton").pressed.emit()
	await _settle()
	_expect(game.get_node("%LocationLabel").text == "照禾渡口", "E2E 新游戏进入照禾渡口")

	game.move_player(Vector2.DOWN, 0.40)
	game.move_player(Vector2.RIGHT, 0.74)
	await _settle()
	await _trigger_semantic_action("interact")
	await _settle()
	_expect(game.journey.gathered_moonleaf, "E2E 通过语义交互采集月芽草")

	game.move_player(Vector2.LEFT, 0.82)
	game.move_player(Vector2.UP, 1.56)
	game.move_player(Vector2.RIGHT, 1.46)
	game.move_player(Vector2.DOWN, 0.06)
	await _settle()
	await _press_action(game, "进入藏泉山道")
	_expect(game.journey.phase_id() == "battle", "E2E 从山门进入战斗")
	await _press_action(game, "撤回照禾渡口")
	_expect(game.journey.phase_id() == "riverbank", "E2E 可沿退路撤回")
	await _press_action(game, "进入藏泉山道")
	await _press_action(game, "请砚青援护")
	await _press_action(game, "镇岩符")
	await _press_action(game, "引气术")
	await _press_action(game, "引气术")
	_expect(game.journey.phase_id() == "spring", "E2E 同伴与战斗行动打开泉室")
	await _press_action(game, "静心引息")
	_expect(game.journey.phase_id() == "complete", "E2E 完成第一次引息")
	_expect(game.get_node("%DescriptionLabel").text.contains("本节结算"), "E2E 显示章节结算")
	_expect(SaveGameScript.read(TEST_SAVE_PATH)["data"]["journey"]["phase"] == "complete", "E2E 完成态已落盘")

	await _press_action(game, "完成本节并返回标题")
	_expect(game.get_node("%TitleOverlay").visible, "E2E 从结算返回标题")
	game.queue_free()
	await _settle()

	var resumed := scene.instantiate()
	resumed.configure_save_path(TEST_SAVE_PATH)
	root.add_child(resumed)
	await _settle()
	_expect(not resumed.get_node("%ContinueButton").disabled, "E2E 新实例发现完成存档")
	resumed.get_node("%ContinueButton").pressed.emit()
	await _settle()
	_expect(resumed.journey.phase_id() == "complete", "E2E 继续游戏恢复完成态")
	await _press_action(resumed, "重游序章（重置进度）")
	_expect(resumed.journey.phase_id() == "riverbank", "E2E 重游回到序章起点")
	_expect(resumed.exploration.player_position == ExplorationStateScript.START_POSITION, "E2E 重游重置地图坐标")

	resumed.queue_free()
	await _settle()
	SaveGameScript.remove(TEST_SAVE_PATH)
	if failures.is_empty():
		print("RPG E2E passed: %d assertions, new game to replay." % assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _press_action(game: Node, label: String) -> void:
	for child in game.get_node("%Actions").get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await _settle()
			return
	failures.append("E2E 找不到行动：%s" % label)


func _trigger_semantic_action(action_name: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _settle() -> void:
	await process_frame
	await process_frame


func _expect(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s：期望 true" % label)
