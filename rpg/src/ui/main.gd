extends Control

const CONTENT_PATH := "res://content/prologue.json"
const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var chapter_label: Label = %ChapterLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var location_label: Label = %LocationLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var actions: GridContainer = %Actions
@onready var input_hint: Label = %InputHint
@onready var title_overlay: Control = %TitleOverlay
@onready var title_status: Label = %TitleStatus
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var return_title_button: Button = %ReturnTitleButton
@onready var title_audio_button: Button = %TitleAudioButton
@onready var title_volume_button: Button = %TitleVolumeButton
@onready var pause_audio_button: Button = %PauseAudioButton
@onready var pause_volume_button: Button = %PauseVolumeButton
@onready var audio_manager: AudioStreamPlayer = %AudioManager

var content: Dictionary = {}
var journey = JourneyStateScript.new()
var exploration = ExplorationStateScript.new()
var nearby_action_id := ""
var save_path := SaveGameScript.DEFAULT_SAVE_PATH
var settings_path := SettingsStoreScript.DEFAULT_PATH
var settings := SettingsStoreScript.defaults()
var is_playing := false
var autosave_elapsed := 0.0


func _ready() -> void:
	_ensure_input_actions()
	content = _load_content()
	settings = SettingsStoreScript.read(settings_path)["data"]
	_render([])
	_style_menu_button(new_game_button)
	_style_menu_button(continue_button)
	_style_menu_button(resume_button)
	_style_menu_button(return_title_button)
	_style_settings_button(title_audio_button)
	_style_settings_button(title_volume_button)
	_style_settings_button(pause_audio_button)
	_style_settings_button(pause_volume_button)
	new_game_button.pressed.connect(start_new_game)
	continue_button.pressed.connect(continue_game)
	resume_button.pressed.connect(toggle_pause_menu)
	return_title_button.pressed.connect(return_to_title)
	title_audio_button.pressed.connect(toggle_audio)
	pause_audio_button.pressed.connect(toggle_audio)
	title_volume_button.pressed.connect(cycle_audio_volume)
	pause_volume_button.pressed.connect(cycle_audio_volume)
	_apply_audio_settings()
	pause_overlay.hide()
	_refresh_title_state()
	title_overlay.show()
	if continue_button.disabled:
		new_game_button.grab_focus.call_deferred()
	else:
		continue_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	if not is_playing or title_overlay.visible or pause_overlay.visible or journey.phase_id() != "riverbank":
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not direction.is_zero_approx():
		var before: Vector2 = exploration.player_position
		move_player(direction, delta)
		if not exploration.player_position.is_equal_approx(before):
			autosave_elapsed += delta
			if autosave_elapsed >= 1.0:
				_save_game()
				autosave_elapsed = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if is_playing and event.is_action_pressed("pause_menu"):
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if not is_playing or title_overlay.visible or pause_overlay.visible:
		return
	if journey.phase_id() == "riverbank" and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func _load_content() -> Dictionary:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取原创剧情文件：%s" % CONTENT_PATH)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("剧情文件不是有效对象：%s" % CONTENT_PATH)
		return {}
	return parsed


func _render(event_ids: Array) -> void:
	if content.is_empty():
		return
	var snapshot := journey.snapshot()
	var node: Dictionary = content["nodes"][snapshot["phase"]]
	chapter_label.text = "序章 · 第一息"
	objective_label.text = _objective_text(snapshot)
	location_label.text = node["title"]
	description_label.text = node["description"]
	if snapshot["phase"] == "complete":
		description_label.text += "\n\n" + _chapter_summary(snapshot)
	status_label.text = _status_text(snapshot)
	event_label.text = _event_text(event_ids)
	map_canvas.set_story_state(snapshot["phase"], snapshot["gathered_moonleaf"], snapshot["talked_to_companion"])
	nearby_action_id = exploration.interaction_action(snapshot["gathered_moonleaf"], snapshot["talked_to_companion"])
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	_build_actions(node)


func _status_text(snapshot: Dictionary) -> String:
	var herb := "有" if snapshot["gathered_moonleaf"] else "无"
	if snapshot["phase"] == "battle":
		return "%s　气血 %d/12　岩甲兽 %d/9　镇岩符 %d　援护 %d　回合 %d" % [
			snapshot["realm"],
			snapshot["player_hp"],
			snapshot["enemy_hp"],
			snapshot["talismans"],
			snapshot["companion_supports"],
			snapshot["round"],
		]
	return "%s　气血 %d/12　月芽草：%s　同行：砚青" % [snapshot["realm"], snapshot["player_hp"], herb]


func _objective_text(snapshot: Dictionary) -> String:
	match snapshot["phase"]:
		"riverbank":
			if not snapshot["talked_to_companion"]:
				return "当前目标　与渡碑旁的砚青交谈"
			if not snapshot["gathered_moonleaf"]:
				return "当前目标　前往月芽田准备护脉灵草"
			return "当前目标　沿石路寻找藏泉山门"
		"battle":
			return "当前目标　看清甲缝，留住退路"
		"spring":
			return "当前目标　借月芽草完成第一次引息"
		_:
			return "本节完成　山河自此显出第一道灵息"


func _event_text(event_ids: Array) -> String:
	if event_ids.is_empty():
		if journey.phase_id() == "riverbank":
			return "沿路寻找发光的月芽草；金色圆环会提示可交互地点。"
		return "选择行动。所有结果由确定性规则结算。"
	var messages: Array[String] = []
	for event_id in event_ids:
		messages.append(content["messages"].get(event_id, event_id))
	return "\n".join(messages)


func _chapter_summary(snapshot: Dictionary) -> String:
	var setback_text := "全程无失手" if snapshot["setbacks"] == 0 else "经历 %d 次撤退或救援" % snapshot["setbacks"]
	var talisman_text := "镇岩符留存" if snapshot["talismans"] > 0 else "镇岩符已用"
	return "本节结算　%s · %s · %s · 砚青平安同行" % [snapshot["realm"], setback_text, talisman_text]


func _build_actions(node: Dictionary) -> void:
	for child in actions.get_children():
		child.queue_free()
	var available := journey.available_actions()
	var first_button: Button = null
	for action: Dictionary in node["actions"]:
		if not available.has(action["id"]):
			continue
		if journey.phase_id() == "riverbank" and action["id"] != nearby_action_id:
			continue
		var button := Button.new()
		button.text = action["label"]
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE if journey.phase_id() == "riverbank" else Control.FOCUS_ALL
		_style_action_button(button)
		button.pressed.connect(_on_action.bind(action["id"]))
		actions.add_child(button)
		if first_button == null:
			first_button = button
	if first_button == null and journey.phase_id() == "riverbank":
		var guidance := Label.new()
		guidance.text = "附近暂无可交互目标"
		guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		guidance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		guidance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		guidance.size_flags_vertical = Control.SIZE_EXPAND_FILL
		guidance.add_theme_color_override("font_color", Color("5f674f"))
		actions.add_child(guidance)
	if first_button != null and journey.phase_id() != "riverbank":
		first_button.grab_focus.call_deferred()
	input_hint.text = "WASD / 方向键移动 · E / 空格 / 手柄 A 交互" if journey.phase_id() == "riverbank" else "鼠标点击 · 方向键选择 · Enter / 手柄 A 确认"


func _style_action_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("e2d2b3")
	normal.border_color = Color("7f846d")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)

	var hover := normal.duplicate()
	hover.bg_color = Color("f7eccf")
	hover.border_color = Color("9b8050")

	var pressed := normal.duplicate()
	pressed.bg_color = Color("ccb68f")
	pressed.border_color = Color("5f674f")

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("e4c36e")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("27312e"))
	button.add_theme_color_override("font_hover_color", Color("27312e"))
	button.add_theme_color_override("font_pressed_color", Color("27312e"))
	button.add_theme_color_override("font_focus_color", Color("27312e"))
	button.add_theme_font_size_override("font_size", 17)


func _style_menu_button(button: Button) -> void:
	_style_action_button(button)
	button.custom_minimum_size = Vector2(320, 52)
	button.focus_mode = Control.FOCUS_ALL


func _style_settings_button(button: Button) -> void:
	_style_action_button(button)
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL


func _on_action(action_id: String) -> void:
	var result: Dictionary = journey.choose(action_id)
	if result["ok"] and action_id == JourneyStateScript.REPLAY_CHAPTER:
		exploration = ExplorationStateScript.new()
	_render(result["events"])
	if result["ok"]:
		_save_game()
	if result["ok"] and action_id == JourneyStateScript.RETURN_TO_TITLE:
		return_to_title()


func move_player(direction: Vector2, delta: float) -> Vector2:
	if journey.phase_id() != "riverbank":
		return exploration.player_position
	var previous_action := nearby_action_id
	exploration.move(direction, delta)
	nearby_action_id = exploration.interaction_action(journey.gathered_moonleaf, journey.talked_to_companion)
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	if nearby_action_id != previous_action:
		_build_actions(content["nodes"]["riverbank"])
	return exploration.player_position


func interact() -> Dictionary:
	if journey.phase_id() != "riverbank" or nearby_action_id.is_empty():
		var no_target := {"ok": false, "events": ["nothing_nearby"], "snapshot": journey.snapshot()}
		_render(no_target["events"])
		return no_target
	var result: Dictionary = journey.choose(nearby_action_id)
	_render(result["events"])
	if result["ok"]:
		_save_game()
	return result


func configure_save_path(path: String) -> void:
	save_path = path


func configure_settings_path(path: String) -> void:
	settings_path = path


func toggle_audio() -> void:
	settings["audio_enabled"] = not settings["audio_enabled"]
	SettingsStoreScript.write(settings, settings_path)
	_apply_audio_settings()


func cycle_audio_volume() -> void:
	var current := float(settings["audio_volume"])
	if current < 0.5:
		settings["audio_volume"] = 0.6
	elif current < 0.8:
		settings["audio_volume"] = 1.0
	else:
		settings["audio_volume"] = 0.35
	SettingsStoreScript.write(settings, settings_path)
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	audio_manager.set_audio_volume(float(settings["audio_volume"]))
	audio_manager.set_audio_enabled(bool(settings["audio_enabled"]))
	var audio_text := "环境音：开启" if settings["audio_enabled"] else "环境音：关闭"
	var volume_text := "音量：%d%%" % roundi(float(settings["audio_volume"]) * 100.0)
	title_audio_button.text = audio_text
	pause_audio_button.text = audio_text
	title_volume_button.text = volume_text
	pause_volume_button.text = volume_text


func start_new_game() -> void:
	SaveGameScript.remove(save_path)
	journey = JourneyStateScript.new()
	exploration = ExplorationStateScript.new()
	nearby_action_id = ""
	autosave_elapsed = 0.0
	is_playing = true
	title_overlay.hide()
	pause_overlay.hide()
	_render([])
	_save_game()


func continue_game() -> bool:
	var loaded: Dictionary = SaveGameScript.read(save_path)
	var decoded := _decode_save(loaded)
	if not decoded["ok"]:
		_refresh_title_state()
		return false
	journey = decoded["journey"]
	exploration = decoded["exploration"]
	is_playing = true
	autosave_elapsed = 0.0
	title_overlay.hide()
	pause_overlay.hide()
	var load_event := "save_loaded"
	if loaded["recovered_from_backup"]:
		load_event = "save_loaded_backup"
	elif loaded["migrated_from_version"] > 0:
		load_event = "save_migrated"
	_render([load_event])
	if loaded["migrated_from_version"] > 0:
		_save_game()
	return true


func toggle_pause_menu() -> void:
	if not is_playing or title_overlay.visible:
		return
	pause_overlay.visible = not pause_overlay.visible
	if pause_overlay.visible:
		_save_game()
		resume_button.grab_focus.call_deferred()


func return_to_title() -> void:
	if is_playing:
		_save_game()
	is_playing = false
	pause_overlay.hide()
	_refresh_title_state()
	title_overlay.show()
	if continue_button.disabled:
		new_game_button.grab_focus.call_deferred()
	else:
		continue_button.grab_focus.call_deferred()


func _save_game() -> bool:
	if not is_playing:
		return false
	var result: Dictionary = SaveGameScript.write(journey.snapshot(), exploration.snapshot(), save_path)
	if not result["ok"]:
		event_label.text = "自动存档失败（%s）。当前游戏仍可继续。" % result["reason"]
	return result["ok"]


func _refresh_title_state() -> void:
	var loaded: Dictionary = SaveGameScript.read(save_path)
	var decoded := _decode_save(loaded)
	continue_button.disabled = not decoded["ok"]
	if decoded["ok"]:
		var phase_name := _phase_display_name(str(loaded["data"]["journey"].get("phase", "")))
		title_status.text = "发现本地存档 · %s" % phase_name
		new_game_button.text = "重新开始（覆盖存档）"
	elif loaded["reason"] == "missing":
		title_status.text = "尚无旅程存档。"
		new_game_button.text = "踏入山河"
	elif loaded["ok"]:
		title_status.text = "%s；原文件已保留。" % decoded["reason"]
		new_game_button.text = "开始新游戏（覆盖异常存档）"
	else:
		title_status.text = "存档暂不可读取（%s）；原文件已保留。" % loaded["reason"]
		new_game_button.text = "开始新游戏（覆盖异常存档）"


func _decode_save(loaded: Dictionary) -> Dictionary:
	if not loaded["ok"]:
		return {"ok": false, "reason": "存档文件不可读取"}
	var restored_journey = JourneyStateScript.new()
	if not restored_journey.restore(loaded["data"]["journey"]):
		return {"ok": false, "reason": "存档中的剧情状态无效"}
	var restored_exploration = ExplorationStateScript.new()
	if not restored_exploration.restore(loaded["data"]["exploration"]):
		return {"ok": false, "reason": "存档中的地图位置无效"}
	return {
		"ok": true,
		"reason": "",
		"journey": restored_journey,
		"exploration": restored_exploration,
	}


func _phase_display_name(phase_name: String) -> String:
	match phase_name:
		"riverbank":
			return "照禾渡口"
		"battle":
			return "藏泉山道"
		"spring":
			return "藏泉石室"
		"complete":
			return "第一息"
	return "未知地点"


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("interact", [KEY_E, KEY_SPACE])
	_add_key_action("pause_menu", [KEY_ESCAPE])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("interact", JOY_BUTTON_A)
	_add_joy_button("pause_menu", JOY_BUTTON_START)


func _add_key_action(action_name: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _add_joy_axis(action_name: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _add_joy_button(action_name: StringName, button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)
