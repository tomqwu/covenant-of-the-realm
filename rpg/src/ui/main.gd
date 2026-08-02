extends Control

const CONTENT_PATH := "res://content/prologue.json"
const JourneyStateScript := preload("res://src/domain/journey_state.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var chapter_label: Label = %ChapterLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var location_label: Label = %LocationLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var actions: VBoxContainer = %Actions

var content: Dictionary = {}
var journey = JourneyStateScript.new()


func _ready() -> void:
	content = _load_content()
	_render([])


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
		var button := Button.new()
		button.text = action["label"]
		button.custom_minimum_size = Vector2(0, 48)
		button.focus_mode = Control.FOCUS_ALL
		_style_action_button(button)
		button.pressed.connect(_on_action.bind(action["id"]))
		actions.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus.call_deferred()


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
