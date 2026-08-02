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
	var journal_position: Vector2 = game.exploration.player_position
	await _trigger_key(KEY_J)
	_expect(game.get_node("%JournalOverlay").visible, "键盘 J 打开行旅札记")
	_expect(root.gui_get_focus_owner() == game.get_node("%JournalCloseButton"), "键盘打开札记后焦点落在关闭按钮")
	await _hold_key(KEY_D, 0.12)
	_expect(game.exploration.player_position == journal_position, "札记打开时真实移动输入不会作用于背后地图")
	await _trigger_joy_button(JOY_BUTTON_Y)
	_expect(not game.get_node("%JournalOverlay").visible, "手柄 Y 关闭行旅札记")
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.get_node("%DialogueOverlay").visible, "键盘 E 开启同伴简报")
	_expect(game.get_node("%DialoguePortrait").mouse_filter == Control.MOUSE_FILTER_IGNORE, "纸绘头像不截获键盘或手柄对话焦点")
	game.skip_dialogue_to_response()
	await _settle()
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "protagonist", "手柄回应前显示主角纸绘头像")
	var response_focus := root.gui_get_focus_owner()
	_expect(response_focus is Button and response_focus.text == "先看退路，再进山。", "回应选择默认聚焦第一项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.talked_to_companion and game.journey.briefing_response == "careful", "手柄 A 确认对话回应")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "输入验收到达渡口守堤人")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "ferryman_briefing", "键盘 E 开启守堤支线")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "liangshu", "守堤支线显示梁叔纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	var ferryman_focus := root.gui_get_focus_owner()
	_expect(ferryman_focus is Button and ferryman_focus.text == "一起扶正水尺。", "守堤选择默认聚焦第一项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.ferryman_response == "repair", "手柄 A 确认守堤选择")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42}), "输入验收到达渡口旧水痕")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.discoveries == ["ferry_watermark"], "键盘 E 记录近距离环境见闻")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "输入验收调查后回到同行起点")
	game._render([])

	var before_move: Vector2 = game.exploration.player_position
	await _hold_key(KEY_S, 0.12)
	_expect(game.exploration.player_position.y > before_move.y, "键盘 S 持续驱动角色位置")
	var follow_contract: Dictionary = game.get_node("%MapCanvas").companion_follow_contract()
	_expect(follow_contract["active"] and follow_contract["point_count"] > 2, "真实持续输入为砚青留下可跟随脚印")
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(game.get_node("%PauseOverlay").visible, "手柄 Start 打开暂停界面")
	await _settle()
	_expect(root.gui_get_focus_owner() == game.get_node("%ResumeButton"), "暂停焦点落在继续修行")
	game.get_node("%PauseBattleSpeedButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseBattleSpeedButton").text == "战斗表现：快速", "手柄 A 切换快速战斗反馈")
	game.get_node("%PauseMotionButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseMotionButton").text == "动态效果：简化", "手柄 A 切换简化动态")
	game.get_node("%PauseTextScaleButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseTextScaleButton").text == "文字大小：大字", "手柄 A 切换大字模式")
	game.get_node("%PauseContrastButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseContrastButton").text == "高对比：开启", "手柄 A 开启高对比文字")
	game.get_node("%PauseTextScaleButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseTextScaleButton").text == "文字大小：标准", "手柄 A 恢复标准文字大小")
	game.get_node("%PauseContrastButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseContrastButton").text == "高对比：关闭", "手柄 A 关闭高对比文字")
	game.get_node("%ResumeButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%PauseOverlay").visible, "手柄 A 从暂停恢复")

	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.69, "player_y": 0.62}), "输入验收移动到合法月芽田坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.gathered_moonleaf, "交互动作在月芽田采集")
	_expect(game.journey.moonleaf_method == "whole_plant", "单键交互采用稳定的旧规取药默认项")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "输入验收移动到合法山门坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.phase_id() == "mountain_path", "交互动作从山门进入可探索山道")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "输入验收移动到山道弃置药篓")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.discoveries.has("abandoned_basket"), "键盘 E 调查药篓生活痕迹")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "输入验收带药篓到达山道退路")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.phase_id() == "riverbank", "键盘 E 从山道返回渡口")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "输入验收到达药圃守蕙婶")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "herbkeeper_basket", "键盘 E 开启药篓支线")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "huishen", "药篓支线显示蕙婶纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	var basket_focus := root.gui_get_focus_owner()
	_expect(basket_focus is Button and basket_focus.text == "把药篓带回圃里。", "药篓选择默认聚焦归圃项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.basket_response == "return", "手柄 A 确认药篓归圃选择")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "输入验收再次到达山门")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.phase_id() == "mountain_path", "键盘 E 在支线后重新进入山道")
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
	game.return_to_title()
	await _settle()
	var battle_save_text := FileAccess.get_file_as_string(SAVE_PATH)
	game.get_node("%NewGameButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.new_game_confirmation_contract()["visible"], "手柄 A 对有效存档只打开覆盖确认")
	_expect(game.get_node("%TitleOverlay").visible and game.journey.phase_id() == "battle", "手柄确认态保留当前战斗旅程")
	_expect(root.gui_get_focus_owner() == game.get_node("%ContinueButton"), "手柄覆盖确认默认聚焦取消")
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(not game.new_game_confirmation_contract()["visible"], "手柄 Start 安全取消覆盖确认")
	_expect(FileAccess.get_file_as_string(SAVE_PATH) == battle_save_text, "手柄取消覆盖保持存档字节不变")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "手柄取消后焦点回到重新开始")
	await _trigger_joy_button(JOY_BUTTON_A)
	await _trigger_action("ui_down")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "方向动作可从取消移到确认重新开始")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%TitleOverlay").visible and game.journey.phase_id() == "riverbank", "手柄二次确认建立新旅程")

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
