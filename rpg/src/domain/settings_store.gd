extends RefCounted
class_name SettingsStore

const SETTINGS_VERSION := 4
const DEFAULT_PATH := "user://settings.json"
const DEFAULT_VOLUME := 0.6


static func defaults() -> Dictionary:
	return {
		"settings_version": SETTINGS_VERSION,
		"audio_enabled": false,
		"audio_volume": DEFAULT_VOLUME,
		"battle_speed": "standard",
		"reduced_motion": false,
		"text_scale": "standard",
		"high_contrast": false,
		"dialogue_speed": "standard",
	}


static func read(path: String = DEFAULT_PATH) -> Dictionary:
	var primary := _read_single(path)
	if primary["reason"] != "missing":
		return primary
	var backup_path := path + ".bak"
	var backup := _read_single(backup_path)
	if backup["reason"] == "missing":
		return primary
	if not backup["ok"]:
		return backup
	var restore_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(backup_path),
		ProjectSettings.globalize_path(path)
	)
	backup["reason"] = "recovered_backup" if restore_error == OK else "recovered_backup_unpromoted"
	return backup


static func _read_single(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "data": defaults(), "reason": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": defaults(), "reason": "read_failed"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "data": defaults(), "reason": "invalid_json"}
	var data: Dictionary = parser.data
	var stored_version = data.get("settings_version")
	if stored_version not in [1, 1.0, 2, 2.0, 3, 3.0, SETTINGS_VERSION, float(SETTINGS_VERSION)]:
		return {"ok": false, "data": defaults(), "reason": "unsupported_version"}
	if typeof(data.get("audio_enabled")) != TYPE_BOOL:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_enabled"}
	if typeof(data.get("audio_volume")) not in [TYPE_INT, TYPE_FLOAT]:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_volume"}
	var volume := float(data["audio_volume"])
	if not is_finite(volume) or volume < 0.0 or volume > 1.0:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_volume"}
	var battle_speed := "standard"
	var reduced_motion := false
	var text_scale := "standard"
	var high_contrast := false
	var dialogue_speed := "standard"
	var reason := "migrated_v%d" % int(stored_version) if int(stored_version) < SETTINGS_VERSION else ""
	if int(stored_version) >= 2:
		if data.get("battle_speed") not in ["standard", "fast"]:
			return {"ok": false, "data": defaults(), "reason": "invalid_battle_speed"}
		if typeof(data.get("reduced_motion")) != TYPE_BOOL:
			return {"ok": false, "data": defaults(), "reason": "invalid_reduced_motion"}
		battle_speed = data["battle_speed"]
		reduced_motion = data["reduced_motion"]
	if int(stored_version) >= 3:
		if data.get("text_scale") not in ["standard", "large"]:
			return {"ok": false, "data": defaults(), "reason": "invalid_text_scale"}
		if typeof(data.get("high_contrast")) != TYPE_BOOL:
			return {"ok": false, "data": defaults(), "reason": "invalid_high_contrast"}
		text_scale = data["text_scale"]
		high_contrast = data["high_contrast"]
	if int(stored_version) >= 4:
		if data.get("dialogue_speed") not in ["standard", "fast", "instant"]:
			return {"ok": false, "data": defaults(), "reason": "invalid_dialogue_speed"}
		dialogue_speed = data["dialogue_speed"]
	return {
		"ok": true,
		"data": {
			"settings_version": SETTINGS_VERSION,
			"audio_enabled": data["audio_enabled"],
			"audio_volume": volume,
			"battle_speed": battle_speed,
			"reduced_motion": reduced_motion,
			"text_scale": text_scale,
			"high_contrast": high_contrast,
			"dialogue_speed": dialogue_speed,
		},
		"reason": reason,
	}


static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var validation_path := path + ".tmp"
	var backup_path := path + ".bak"
	var payload := {
		"settings_version": SETTINGS_VERSION,
		"audio_enabled": bool(data.get("audio_enabled", false)),
		"audio_volume": clampf(float(data.get("audio_volume", DEFAULT_VOLUME)), 0.0, 1.0),
		"battle_speed": str(data.get("battle_speed", "standard")),
		"reduced_motion": bool(data.get("reduced_motion", false)),
		"text_scale": str(data.get("text_scale", "standard")),
		"high_contrast": bool(data.get("high_contrast", false)),
		"dialogue_speed": str(data.get("dialogue_speed", "standard")),
	}
	var file := FileAccess.open(validation_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()
	var verified := read(validation_path)
	if not verified["ok"]:
		remove(validation_path)
		return false
	var rotated_primary := false
	if FileAccess.file_exists(path):
		_remove_file(backup_path)
		var backup_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(path),
			ProjectSettings.globalize_path(backup_path)
		)
		if backup_error != OK:
			_remove_file(validation_path)
			return false
		rotated_primary = true
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(validation_path),
		ProjectSettings.globalize_path(path)
	)
	if error != OK:
		if rotated_primary and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(
				ProjectSettings.globalize_path(backup_path),
				ProjectSettings.globalize_path(path)
			)
		_remove_file(validation_path)
		return false
	_remove_file(backup_path)
	return true


static func remove(path: String = DEFAULT_PATH) -> void:
	for candidate in [path, path + ".tmp", path + ".bak"]:
		_remove_file(candidate)


static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
