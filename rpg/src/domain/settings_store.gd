extends RefCounted
class_name SettingsStore

const SETTINGS_VERSION := 1
const DEFAULT_PATH := "user://settings.json"
const DEFAULT_VOLUME := 0.6


static func defaults() -> Dictionary:
	return {
		"settings_version": SETTINGS_VERSION,
		"audio_enabled": false,
		"audio_volume": DEFAULT_VOLUME,
	}


static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "data": defaults(), "reason": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "data": defaults(), "reason": "read_failed"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "data": defaults(), "reason": "invalid_json"}
	var data: Dictionary = parser.data
	if data.get("settings_version") != float(SETTINGS_VERSION) and data.get("settings_version") != SETTINGS_VERSION:
		return {"ok": false, "data": defaults(), "reason": "unsupported_version"}
	if typeof(data.get("audio_enabled")) != TYPE_BOOL:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_enabled"}
	if typeof(data.get("audio_volume")) not in [TYPE_INT, TYPE_FLOAT]:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_volume"}
	var volume := float(data["audio_volume"])
	if not is_finite(volume) or volume < 0.0 or volume > 1.0:
		return {"ok": false, "data": defaults(), "reason": "invalid_audio_volume"}
	return {
		"ok": true,
		"data": {
			"settings_version": SETTINGS_VERSION,
			"audio_enabled": data["audio_enabled"],
			"audio_volume": volume,
		},
		"reason": "",
	}


static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var validation_path := path + ".tmp"
	var payload := {
		"settings_version": SETTINGS_VERSION,
		"audio_enabled": bool(data.get("audio_enabled", false)),
		"audio_volume": clampf(float(data.get("audio_volume", DEFAULT_VOLUME)), 0.0, 1.0),
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
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(validation_path),
		ProjectSettings.globalize_path(path)
	)
	return error == OK


static func remove(path: String = DEFAULT_PATH) -> void:
	for candidate in [path, path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
