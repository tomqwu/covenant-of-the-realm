extends Control

const CONTENT_PATH := "res://content/prologue.json"
const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var chapter_label: Label = %ChapterLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var location_label: Label = %LocationLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var actions: VBoxContainer = %Actions
@onready var input_hint: Label = %InputHint

var content: Dictionary = {}
var journey = JourneyStateScript.new()
var exploration = ExplorationStateScript.new()
var nearby_action_id := ""


func _ready() -> void:
	_ensure_input_actions()
	content = _load_content()
	_render([])


func _process(delta: float) -> void:
	if journey.phase_id() != "riverbank":
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not direction.is_zero_approx():
		move_player(direction, delta)


func _unhandled_input(event: InputEvent) -> void:
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
	objective_label.text = _objective_text(snapshot["phase"])
	location_label.text = node["title"]
	description_label.text = node["description"]
	status_label.text = _status_text(snapshot)
	event_label.text = _event_text(event_ids)
	map_canvas.set_story_state(snapshot["phase"], snapshot["gathered_moonleaf"])
	nearby_action_id = exploration.interaction_action(snapshot["gathered_moonleaf"])
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	_build_actions(node)


func _status_text(snapshot: Dictionary) -> String:
	var herb := "有" if snapshot["gathered_moonleaf"] else "无"
	if snapshot["phase"] == "battle":
		return "%s　气血 %d/12　岩甲兽 %d/9　镇岩符 %d　回合 %d" % [
			snapshot["realm"],
			snapshot["player_hp"],
			snapshot["enemy_hp"],
			snapshot["talismans"],
			snapshot["round"],
		]
	return "%s　月芽草：%s　同行：砚青" % [snapshot["realm"], herb]


func _objective_text(phase_id: String) -> String:
	match phase_id:
		"riverbank":
			return "当前目标　准备护脉灵草，寻找藏泉入口"
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


func _on_action(action_id: String) -> void:
	var result: Dictionary = journey.choose(action_id)
	_render(result["events"])


func move_player(direction: Vector2, delta: float) -> Vector2:
	if journey.phase_id() != "riverbank":
		return exploration.player_position
	var previous_action := nearby_action_id
	exploration.move(direction, delta)
	nearby_action_id = exploration.interaction_action(journey.gathered_moonleaf)
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
	return result


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("interact", [KEY_E, KEY_SPACE])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("interact", JOY_BUTTON_A)


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
