extends SceneTree

const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const TEST_SAVE_PATH := "user://automated-e2e-save.json"
const TEST_SETTINGS_PATH := "user://automated-e2e-settings.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var game := scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()

	_expect(game.get_node("%TitleOverlay").visible, "E2E 从标题界面开始")
	game.get_node("%NewGameButton").pressed.emit()
	await _settle()
	_expect(game.get_node("%LocationLabel").text == "照禾渡口", "E2E 新游戏进入照禾渡口")
	await _trigger_semantic_action("interact")
	await _settle()
	_expect(game.dialogue.active and game.get_node("%DialogueOverlay").visible, "E2E 交互开启逐句风险简报")
	game.show_full_dialogue_line()
	game.advance_dialogue()
	game.show_full_dialogue_line()
	game.advance_dialogue()
	var interrupted_line: int = game.dialogue.line_index
	var interrupted_text: String = game.get_node("%DialogueLabel").text
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复对话中途存档")
	_expect(game.dialogue.active and game.dialogue.line_index == interrupted_line, "E2E 中断恢复保持对话行号")
	_expect(game.get_node("%DialogueLabel").text == interrupted_text, "E2E 中断恢复保持当前台词")
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "先看退路，再进山。")
	_expect(game.journey.talked_to_companion, "E2E 选择谨慎回应完成风险简报")
	_expect(game.get_node("%ObjectiveLabel").text.contains("月芽田"), "E2E 简报后任务切换到采药")

	game.move_player(Vector2.DOWN, 0.40)
	game.move_player(Vector2.RIGHT, 0.74)
	await _settle()
	await _trigger_semantic_action("interact")
	await _settle()
	_expect(game.journey.gathered_moonleaf, "E2E 通过语义交互采集月芽草")
	_expect(game.journey.moonleaf_method == "whole_plant", "E2E 语义交互保留向后兼容的旧规取药")

	game.move_player(Vector2.LEFT, 0.82)
	game.move_player(Vector2.UP, 1.56)
	game.move_player(Vector2.RIGHT, 1.46)
	game.move_player(Vector2.DOWN, 0.06)
	await _settle()
	await _press_action(game, "进入藏泉山道")
	_expect(game.journey.phase_id() == "mountain_path", "E2E 从山门进入可探索山道")
	_expect(game.exploration.map_id == "cangquan_path", "E2E 山道使用独立地图标识")
	_expect(SaveGameScript.read(TEST_SAVE_PATH)["data"]["exploration"]["map_id"] == "cangquan_path", "E2E 山道地图与坐标自动保存")
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复山道中途存档")
	_expect(game.journey.phase_id() == "mountain_path" and game.exploration.map_id == "cangquan_path", "E2E 中途恢复保持剧情与地图一致")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "E2E 到达山道退路")
	game._render([])
	await _trigger_semantic_action("interact")
	_expect(game.journey.phase_id() == "riverbank" and game.exploration.map_id == "zhaohe_ferry", "E2E 可从山道主动返回渡口")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "E2E 返回后再次到达山门")
	game._render([])
	await _trigger_semantic_action("interact")
	_expect(game.journey.phase_id() == "mountain_path", "E2E 返回后可以再次进入山道")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.43, "player_y": 0.57}), "E2E 到达旧石标")
	game._render([])
	await _trigger_semantic_action("interact")
	_expect(game.get_node("%EventLabel").text.contains("箭记"), "E2E 调查旧石标")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "E2E 到达敌人预警区")
	game._render([])
	await _trigger_semantic_action("interact")
	_expect(game.journey.phase_id() == "battle", "E2E 接近敌人才进入战斗")
	await _press_action(game, "撤到旧石标")
	_expect(game.journey.phase_id() == "mountain_path", "E2E 可沿退路撤到山道")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.56, "player_y": 0.48}), "E2E 撤退后接近另一种敌人")
	game._render([])
	await _press_action(game, "触碰泉苔寄壳")
	_expect(game.journey.enemy_id == "spring_moss_shell", "E2E 非默认遭遇选择泉苔配置")
	_expect(game.get_node("%ObjectiveLabel").text.contains("吸潮蓄壳"), "E2E 战斗 UI 预告泉苔意图")
	var saved_intent: String = game.journey.current_enemy_intent()["name"]
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复非默认敌人战斗")
	_expect(game.journey.enemy_id == "spring_moss_shell", "E2E 战斗恢复保持敌人标识")
	_expect(game.journey.current_enemy_intent()["name"] == saved_intent, "E2E 战斗恢复保持下一意图")
	await _press_action(game, "布置引泉石灯")
	_expect(game.journey.lamp_turns == 1, "E2E 战术石灯进入持续状态")
	await _press_action(game, "请砚青援护")
	await _press_action(game, "镇岩符")
	await _press_action(game, "引气术")
	_expect(game.journey.enemy_id == "rock_armor_warden", "E2E 普通遭遇后进入共享首领战")
	_expect(game.get_node("%ObjectiveLabel").text.contains("压阵肩撞"), "E2E 首领意图在行动前明示")
	await _press_action(game, "守势调息")
	_expect(game.journey.armor_break_turns == 2, "E2E 守势命中首领弱点施加破甲")
	await _press_action(game, "引气术")
	await _press_action(game, "请砚青援护")
	_expect(game.journey.focus_turns == 2, "E2E 同伴援护施加凝息")
	var boss_intent: String = game.journey.current_enemy_intent()["name"]
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可恢复带状态的首领战")
	_expect(game.journey.armor_break_turns == 1 and game.journey.focus_turns == 2, "E2E 恢复保留破甲与凝息层数")
	_expect(game.journey.current_enemy_intent()["name"] == boss_intent, "E2E 首领恢复保持下一意图")
	await _press_action(game, "引气术")
	await _press_action(game, "引气术")
	_expect(game.journey.phase_id() == "spring", "E2E 击败首领后打开泉室")
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
	resumed.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(resumed)
	await _settle()
	_expect(not resumed.get_node("%ContinueButton").disabled, "E2E 新实例发现完成存档")
	resumed.get_node("%ContinueButton").pressed.emit()
	await _settle()
	_expect(resumed.journey.phase_id() == "complete", "E2E 继续游戏恢复完成态")
	await _press_action(resumed, "重游序章（重置进度）")
	_expect(resumed.journey.phase_id() == "riverbank", "E2E 重游回到序章起点")
	_expect(resumed.exploration.player_position == ExplorationStateScript.START_POSITION, "E2E 重游重置地图坐标")
	resumed._on_action("talk_to_companion")
	resumed.skip_dialogue_to_response()
	await _press_dialogue_choice(resumed, "我信你的判断，一起走。")
	_expect(resumed.journey.briefing_response == "trusting", "E2E 重游可选择不同同行态度")
	resumed._on_action("gather_moonleaf_cutting")
	_expect(resumed.journey.moonleaf_method == "cutting", "E2E 重游可选择剪叶留根")
	_expect(resumed.get_node("%MapCanvas").moonleaf_visual_contract()["regrowing"], "E2E 剪叶后地图显示留根新芽")
	resumed._on_action("enter_spring")
	_expect(resumed.exploration.restore({"map_id": "cangquan_path", "player_x": 0.86, "player_y": 0.18}), "E2E 重游后到达绕行入口")
	resumed._render([])
	await _trigger_semantic_action("interact")
	_expect(resumed.journey.phase_id() == "spring", "E2E 沿溪绕行不进入战斗即可到泉室")
	_expect(resumed.journey.player_hp == 12 and resumed.journey.talismans == 1 and resumed.journey.round_number == 1, "E2E 绕行保留气血、符箓和战斗回合")
	await _press_action(resumed, "静心引息")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("以信任同行"), "E2E 结算回应重游时的信任选择")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("月芽留根"), "E2E 结算回应重游时的采集选择")

	resumed.queue_free()
	await _settle()
	SaveGameScript.remove(TEST_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
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


func _press_dialogue_choice(game: Node, label: String) -> void:
	for child in game.get_node("%DialogueChoices").get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await _settle()
			return
	failures.append("E2E 找不到对话回应：%s" % label)


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
