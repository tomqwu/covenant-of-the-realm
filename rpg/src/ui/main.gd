extends Control

const CONTENT_PATH := "res://content/prologue.json"
const JourneyStateScript := preload("res://src/domain/journey_state.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var chapter_label: Label = %ChapterLabel
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
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(_on_action.bind(action["id"]))
		actions.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus.call_deferred()


func _on_action(action_id: String) -> void:
	var result: Dictionary = journey.choose(action_id)
	_render(result["events"])
