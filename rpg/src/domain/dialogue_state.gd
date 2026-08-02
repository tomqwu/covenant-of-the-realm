extends RefCounted
class_name DialogueState

const NONE := ""
const COMPANION_BRIEFING := "companion_briefing"
const CHAPTER_EPILOGUE := "chapter_epilogue"
const FERRYMAN_BRIEFING := "ferryman_briefing"
const HERBKEEPER_BASKET := "herbkeeper_basket"
const SUPPORTED_DIALOGUES := [COMPANION_BRIEFING, CHAPTER_EPILOGUE, FERRYMAN_BRIEFING, HERBKEEPER_BASKET]
const MAX_SAVED_LINE_INDEX := 64

var active := false
var dialogue_id := NONE
var line_index := 0


func start(next_dialogue_id: String) -> bool:
	if active or not SUPPORTED_DIALOGUES.has(next_dialogue_id):
		return false
	active = true
	dialogue_id = next_dialogue_id
	line_index = 0
	return true


func advance(line_count: int) -> bool:
	if not active or line_count <= 0 or line_index >= line_count:
		return false
	line_index += 1
	return true


func skip_to_choices(line_count: int) -> bool:
	if not active or line_count <= 0 or line_index >= line_count:
		return false
	line_index = line_count
	return true


func at_choices(line_count: int) -> bool:
	return active and line_count > 0 and line_index >= line_count


func finish() -> bool:
	if not active:
		return false
	active = false
	dialogue_id = NONE
	line_index = 0
	return true


func snapshot() -> Dictionary:
	return {
		"active": active,
		"dialogue_id": dialogue_id,
		"line_index": line_index,
	}


func restore(snapshot_data: Dictionary) -> bool:
	for key in ["active", "dialogue_id", "line_index"]:
		if not snapshot_data.has(key):
			return false
	if typeof(snapshot_data["active"]) != TYPE_BOOL or typeof(snapshot_data["dialogue_id"]) != TYPE_STRING:
		return false
	if not _valid_integer(snapshot_data["line_index"]):
		return false
	var next_active: bool = snapshot_data["active"]
	var next_dialogue_id: String = snapshot_data["dialogue_id"]
	var next_index := int(snapshot_data["line_index"])
	if next_active:
		if not SUPPORTED_DIALOGUES.has(next_dialogue_id) or next_index > MAX_SAVED_LINE_INDEX:
			return false
	elif next_dialogue_id != NONE or next_index != 0:
		return false
	active = next_active
	dialogue_id = next_dialogue_id
	line_index = next_index
	return true


static func default_snapshot() -> Dictionary:
	return {"active": false, "dialogue_id": NONE, "line_index": 0}


func _valid_integer(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric == floorf(numeric) and numeric >= 0.0
