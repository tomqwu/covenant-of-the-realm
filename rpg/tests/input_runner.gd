extends SceneTree

const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const SAVE_PATH := "user://automated-input-save.json"
const SETTINGS_PATH := "user://automated-input-settings.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGameScript.remove(SAVE_PATH)
	SettingsStoreScript.remove(SETTINGS_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var game := scene.instantiate()
	game.configure_save_path(SAVE_PATH)
	game.configure_settings_path(SETTINGS_PATH)
	root.add_child(game)
	await _settle()

	_expect(ProjectSettings.get_setting("display/window/size/min_width") == 1152, "最小窗口宽度保持可读基准")
	_expect(ProjectSettings.get_setting("display/window/size/min_height") == 648, "最小窗口高度保持可读基准")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "首次标题焦点落在新游戏")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%TitleOverlay").visible, "手柄 A 启动新游戏")
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.get_node("%DialogueOverlay").visible, "键盘 E 开启同伴简报")
	game.skip_dialogue_to_response()
	await _settle()
	var response_focus := root.gui_get_focus_owner()
	_expect(response_focus is Button and response_focus.text == "先看退路，再进山。", "回应选择默认聚焦第一项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.talked_to_companion and game.journey.briefing_response == "careful", "手柄 A 确认对话回应")

	var before_move: Vector2 = game.exploration.player_position
	await _hold_key(KEY_S, 0.12)
	_expect(game.exploration.player_position.y > before_move.y, "键盘 S 持续驱动角色位置")
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(game.get_node("%PauseOverlay").visible, "手柄 Start 打开暂停界面")
	await _settle()
	_expect(root.gui_get_focus_owner() == game.get_node("%ResumeButton"), "暂停焦点落在继续修行")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%PauseOverlay").visible, "手柄 A 从暂停恢复")

	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.69, "player_y": 0.62}), "输入验收移动到合法月芽田坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.gathered_moonleaf, "交互动作在月芽田采集")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "输入验收移动到合法山门坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.phase_id() == "mountain_path", "交互动作从山门进入可探索山道")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "输入验收移动到敌人预警区")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.phase_id() == "battle", "交互动作从敌人预警区进入战斗")
	await _settle()
	var first_focus := root.gui_get_focus_owner()
	_expect(first_focus is Button and first_focus.text == "引气术", "战斗焦点落在第一项术式")
	await _trigger_action("ui_right")
	var moved_focus := root.gui_get_focus_owner()
	_expect(moved_focus is Button and moved_focus != first_focus, "方向动作在战斗网格中移动焦点")
	await _trigger_action("ui_accept")
	_expect(game.journey.round_number == 2, "确认动作执行当前战斗焦点")

	game.get_node("%AudioManager").set_audio_enabled(false)
	game.queue_free()
	await _settle()
	SaveGameScript.remove(SAVE_PATH)
	SettingsStoreScript.remove(SETTINGS_PATH)
	if failures.is_empty():
		print("RPG input passed: %d semantic input and focus assertions." % assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _trigger_action(action_name: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _hold_action(action_name: StringName, seconds: float) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await create_timer(seconds).timeout
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_key(keycode: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.physical_keycode = keycode
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.physical_keycode = keycode
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _hold_key(keycode: Key, seconds: float) -> void:
	var pressed := InputEventKey.new()
	pressed.physical_keycode = keycode
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await create_timer(seconds).timeout
	var released := InputEventKey.new()
	released.physical_keycode = keycode
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_joy_button(button_index: JoyButton) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.button_index = button_index
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventJoypadButton.new()
	released.button_index = button_index
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _settle() -> void:
	await process_frame
	await process_frame


func _expect(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s：期望 true" % label)
