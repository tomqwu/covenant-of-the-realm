extends RefCounted
class_name SaveGame

const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")

const SAVE_VERSION := 5
const STORY_ID := "zhaohe_first_breath"
const DEFAULT_SAVE_PATH := "user://zhaohe-save.json"


static func write(
	journey_snapshot: Dictionary,
	exploration_snapshot: Dictionary,
	path: String = DEFAULT_SAVE_PATH
) -> Dictionary:
	var payload := {
		"save_version": SAVE_VERSION,
		"story_id": STORY_ID,
		"journey": journey_snapshot,
		"exploration": exploration_snapshot,
	}
	var temporary_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _result(false, {}, "write_failed")
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()

	var verification := _read_single(temporary_path)
	if not verification["ok"]:
		_remove_if_present(temporary_path)
		return _result(false, {}, "verification_failed")

	_remove_if_present(backup_path)
	if FileAccess.file_exists(path):
		var backup_error := DirAccess.rename_absolute(_absolute(path), _absolute(backup_path))
		if backup_error != OK:
			_remove_if_present(temporary_path)
			return _result(false, {}, "backup_failed")

	var promote_error := DirAccess.rename_absolute(_absolute(temporary_path), _absolute(path))
	if promote_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(_absolute(backup_path), _absolute(path))
		_remove_if_present(temporary_path)
		return _result(false, {}, "promote_failed")
	_remove_if_present(backup_path)
	return _result(true, payload, "")


static func read(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var primary := _read_single(path)
	if primary["ok"]:
		return primary
	var backup := _read_single(path + ".bak")
	if backup["ok"]:
		backup["recovered_from_backup"] = true
		return backup
	return primary


static func exists(path: String = DEFAULT_SAVE_PATH) -> bool:
	return read(path)["ok"]


static func remove(path: String = DEFAULT_SAVE_PATH) -> void:
	_remove_if_present(path)
	_remove_if_present(path + ".tmp")
	_remove_if_present(path + ".bak")


static func _read_single(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _result(false, {}, "missing")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(false, {}, "read_failed")
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return _result(false, {}, "invalid_json")
	var parsed = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_json")
	return _validate(parsed)


static func _validate(payload: Dictionary) -> Dictionary:
	if not payload.has("save_version") or typeof(payload["save_version"]) not in [TYPE_INT, TYPE_FLOAT]:
		return _result(false, {}, "missing_version")
	var version := float(payload["save_version"])
	if version != floorf(version):
		return _result(false, {}, "unsupported_version")
	if payload.get("story_id") != STORY_ID:
		return _result(false, {}, "wrong_story")
	if typeof(payload.get("journey")) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_journey")
	if typeof(payload.get("exploration")) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_exploration")
	if int(version) == 1:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["companion_supports"] = 1
		migrated["journey"]["setbacks"] = 0
		migrated["journey"]["talked_to_companion"] = migrated["journey"].get("phase") != "riverbank"
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		var migration_result := _result(true, migrated, "")
		migration_result["migrated_from_version"] = 1
		return migration_result
	if int(version) == 2:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["talked_to_companion"] = migrated["journey"].get("phase") != "riverbank"
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		var migration_result := _result(true, migrated, "")
		migration_result["migrated_from_version"] = 2
		return migration_result
	if int(version) == 3:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		var migration_result := _result(true, migrated, "")
		migration_result["migrated_from_version"] = 3
		return migration_result
	if int(version) == 4:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		var migration_result := _result(true, migrated, "")
		migration_result["migrated_from_version"] = 4
		return migration_result
	if int(version) != SAVE_VERSION:
		return _result(false, {}, "unsupported_version")
	if not ExplorationStateScript.supports_map_id(payload["exploration"].get("map_id")):
		return _result(false, {}, "invalid_map")
	return _result(true, payload, "")


static func _result(ok: bool, data: Dictionary, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"data": data,
		"reason": reason,
		"recovered_from_backup": false,
		"migrated_from_version": 0,
	}


static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_absolute(path))
