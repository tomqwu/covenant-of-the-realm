extends RefCounted
class_name SaveGame

const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const DialogueStateScript := preload("res://src/domain/dialogue_state.gd")
const EnemyCatalogScript := preload("res://src/domain/enemy_catalog.gd")
const JourneyStateScript := preload("res://src/domain/journey_state.gd")

const SAVE_VERSION := 13
const STORY_ID := "zhaohe_first_breath"
const DEFAULT_SAVE_PATH := "user://zhaohe-save.json"


static func write(
	journey_snapshot: Dictionary,
	exploration_snapshot: Dictionary,
	path: String = DEFAULT_SAVE_PATH,
	dialogue_snapshot: Dictionary = {},
	preserve_existing_backup: bool = false
) -> Dictionary:
	var stored_dialogue := dialogue_snapshot if not dialogue_snapshot.is_empty() else DialogueStateScript.default_snapshot()
	var payload := {
		"save_version": SAVE_VERSION,
		"story_id": STORY_ID,
		"journey": journey_snapshot,
		"exploration": exploration_snapshot,
		"dialogue": stored_dialogue,
	}
	var temporary_path := path + ".tmp"
	var repair_path := path + ".repair"
	var backup_path := path + ".bak"
	var existing_primary := _read_single(path)
	var existing_temporary := _read_single(temporary_path)
	var existing_repair := _read_single(repair_path)
	var existing_backup := _read_single(backup_path)
	var write_barriers := [
		{"path": path, "result": existing_primary, "reason": "newer_primary_present"},
		{"path": temporary_path, "result": existing_temporary, "reason": "newer_temporary_present"},
		{"path": repair_path, "result": existing_repair, "reason": "newer_repair_present"},
		{"path": backup_path, "result": existing_backup, "reason": "newer_backup_present"},
	]
	for barrier in write_barriers:
		if FileAccess.file_exists(barrier["path"]) and _blocks_fallback(barrier["result"]):
			return _result(false, {}, barrier["reason"])

	# A normal save always replaces a stale temporary candidate before rotating the
	# committed primary. The separate repair workspace is reserved for healing a
	# recovery while its valid temporary source must remain byte-for-byte intact.
	var use_repair_staging: bool = preserve_existing_backup and bool(existing_temporary["ok"])
	var staging_path := repair_path if use_repair_staging else temporary_path
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		return _result(false, {}, "write_failed")
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	file.close()

	var verification := _read_single(staging_path)
	if not verification["ok"]:
		_remove_if_present(staging_path)
		return _result(false, {}, "verification_failed")

	var rotated_primary := false
	if FileAccess.file_exists(path):
		if existing_primary["ok"] and not preserve_existing_backup:
			_remove_if_present(backup_path)
			var backup_error := DirAccess.rename_absolute(_absolute(path), _absolute(backup_path))
			if backup_error != OK:
				_remove_if_present(staging_path)
				return _result(false, {}, "backup_failed")
			rotated_primary = true
		else:
			var remove_error := DirAccess.remove_absolute(_absolute(path))
			if remove_error != OK:
				_remove_if_present(staging_path)
				return _result(false, {}, "replace_failed")

	var promote_error := DirAccess.rename_absolute(_absolute(staging_path), _absolute(path))
	if promote_error != OK:
		if rotated_primary and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(_absolute(backup_path), _absolute(path))
		if rotated_primary or staging_path == repair_path:
			_remove_if_present(staging_path)
		return _result(false, {}, "promote_failed")
	if staging_path == repair_path:
		_remove_if_present(temporary_path)
	_remove_if_present(repair_path)
	return _result(true, payload, "")


static func read(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var recovery := _recovery_set(path)
	var candidates: Array[Dictionary] = recovery["candidates"]
	if not candidates.is_empty():
		return candidates[0]
	return recovery["failure"]


static func read_candidates(path: String = DEFAULT_SAVE_PATH) -> Array[Dictionary]:
	return _recovery_set(path)["candidates"]


static func exists(path: String = DEFAULT_SAVE_PATH) -> bool:
	return read(path)["ok"]


static func remove(path: String = DEFAULT_SAVE_PATH) -> void:
	_remove_if_present(path)
	_remove_if_present(path + ".tmp")
	_remove_if_present(path + ".repair")
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
	if not is_finite(version) or version != floorf(version):
		return _result(false, {}, "unsupported_version")
	# Reject unknown versions before inspecting any version-specific fields. A
	# future schema may legitimately rename or remove today's journey keys.
	if version < 1.0 or version > float(SAVE_VERSION):
		return _result(false, {}, "unsupported_version")
	var version_number := int(version)
	if payload.get("story_id") != STORY_ID:
		return _result(false, {}, "wrong_story")
	if typeof(payload.get("journey")) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_journey")
	if typeof(payload.get("exploration")) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_exploration")
	if version_number == 1:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["companion_supports"] = 1
		migrated["journey"]["setbacks"] = 0
		migrated["journey"]["talked_to_companion"] = migrated["journey"].get("phase") != "riverbank"
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["journey"]["briefing_response"] = _legacy_briefing_response(migrated["journey"])
		_migrate_enemy_snapshot(migrated["journey"])
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		migrated["dialogue"] = DialogueStateScript.default_snapshot()
		return _validated_migration(migrated, 1)
	if version_number == 2:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["talked_to_companion"] = migrated["journey"].get("phase") != "riverbank"
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["journey"]["briefing_response"] = _legacy_briefing_response(migrated["journey"])
		_migrate_enemy_snapshot(migrated["journey"])
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		migrated["dialogue"] = DialogueStateScript.default_snapshot()
		return _validated_migration(migrated, 2)
	if version_number == 3:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["spring_lamps"] = 1
		migrated["journey"]["lamp_turns"] = 0
		migrated["journey"]["briefing_response"] = _legacy_briefing_response(migrated["journey"])
		_migrate_enemy_snapshot(migrated["journey"])
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		migrated["dialogue"] = DialogueStateScript.default_snapshot()
		return _validated_migration(migrated, 3)
	if version_number == 4:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["briefing_response"] = _legacy_briefing_response(migrated["journey"])
		_migrate_enemy_snapshot(migrated["journey"])
		migrated["exploration"]["map_id"] = ExplorationStateScript.DEFAULT_MAP_ID
		migrated["dialogue"] = DialogueStateScript.default_snapshot()
		return _validated_migration(migrated, 4)
	if version_number == 5:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		migrated["journey"]["briefing_response"] = _legacy_briefing_response(migrated["journey"])
		_migrate_enemy_snapshot(migrated["journey"])
		migrated["dialogue"] = DialogueStateScript.default_snapshot()
		return _validated_migration(migrated, 5)
	if version_number == 6:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_enemy_snapshot(migrated["journey"])
		return _validated_migration(migrated, 6)
	if version_number == 7:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_combat_status_snapshot(migrated["journey"])
		return _validated_migration(migrated, 7)
	if version_number == 8:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_moonleaf_snapshot(migrated["journey"])
		return _validated_migration(migrated, 8)
	if version_number == 9:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_discovery_snapshot(migrated["journey"])
		return _validated_migration(migrated, 9)
	if version_number == 10:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_ferryman_snapshot(migrated["journey"])
		return _validated_migration(migrated, 10)
	if version_number == 11:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_basket_snapshot(migrated["journey"])
		return _validated_migration(migrated, 11)
	if version_number == 12:
		var migrated := payload.duplicate(true)
		migrated["save_version"] = SAVE_VERSION
		_migrate_enemy_intel_snapshot(migrated["journey"])
		return _validated_migration(migrated, 12)
	return _validate_current(payload)


static func _validate_current(payload: Dictionary) -> Dictionary:
	if not ExplorationStateScript.supports_map_id(payload["exploration"].get("map_id")):
		return _result(false, {}, "invalid_map")
	if not EnemyCatalogScript.supports(payload["journey"].get("enemy_id")):
		return _result(false, {}, "invalid_enemy")
	if typeof(payload.get("dialogue")) != TYPE_DICTIONARY:
		return _result(false, {}, "invalid_dialogue")
	var restored_dialogue = DialogueStateScript.new()
	if not restored_dialogue.restore(payload["dialogue"]):
		return _result(false, {}, "invalid_dialogue")
	var restored_journey = JourneyStateScript.new()
	if not restored_journey.restore(payload["journey"]):
		return _result(false, {}, "invalid_journey")
	var restored_exploration = ExplorationStateScript.new()
	if not restored_exploration.restore(payload["exploration"]):
		return _result(false, {}, "invalid_exploration")
	if not _dialogue_matches_journey(restored_dialogue, restored_journey):
		return _result(false, {}, "invalid_dialogue")
	return _result(true, payload, "")


static func _validated_migration(payload: Dictionary, source_version: int) -> Dictionary:
	var result := _validate_current(payload)
	if result["ok"]:
		result["migrated_from_version"] = source_version
	return result


static func _dialogue_matches_journey(dialogue, journey) -> bool:
	if not dialogue.active:
		return true
	match dialogue.dialogue_id:
		DialogueStateScript.COMPANION_BRIEFING:
			return journey.phase_id() == "riverbank" and not journey.talked_to_companion
		DialogueStateScript.CHAPTER_EPILOGUE:
			return journey.phase_id() == "complete"
		DialogueStateScript.FERRYMAN_BRIEFING:
			return journey.phase_id() == "riverbank" and journey.ferryman_response == JourneyStateScript.FERRYMAN_UNANSWERED
		DialogueStateScript.HERBKEEPER_BASKET:
			return (
				journey.phase_id() == "riverbank"
				and journey.discoveries.has(JourneyStateScript.DISCOVERY_ABANDONED_BASKET)
				and journey.basket_response == JourneyStateScript.BASKET_UNANSWERED
			)
	return false


static func _recovery_set(path: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var primary := _read_single(path)
	var temporary := _read_single(path + ".tmp")
	var repair := _read_single(path + ".repair")
	var backup := _read_single(path + ".bak")
	# A future-version or different-story artifact is an explicit downgrade
	# barrier regardless of which slot contains it. Never enter an older journey
	# that this runtime would then be unable to save without destroying evidence.
	for artifact in [primary, temporary, repair, backup]:
		if _blocks_fallback(artifact):
			candidates.clear()
			return {"candidates": candidates, "failure": artifact}

	_append_valid_candidate(candidates, primary, "primary")
	_append_valid_candidate(candidates, temporary, "temporary")
	# .repair is deliberately not a recovery candidate. It is scratch space used
	# only while the selected temporary/backup source remains intact.
	_append_valid_candidate(candidates, backup, "backup")
	if not candidates.is_empty():
		return {"candidates": candidates, "failure": _result(false, {}, "missing")}

	var failure: Dictionary = primary
	if failure["reason"] == "missing" and temporary["reason"] != "missing":
		failure = temporary
	if failure["reason"] == "missing" and backup["reason"] != "missing":
		failure = backup
	if failure["reason"] == "missing" and repair["reason"] != "missing":
		failure = _result(false, {}, "repair_incomplete") if repair["ok"] else repair
	return {"candidates": candidates, "failure": failure}


static func _append_valid_candidate(candidates: Array[Dictionary], candidate: Dictionary, source: String) -> void:
	if candidate["ok"]:
		candidates.append(_mark_source(candidate, source))


static func _mark_source(result: Dictionary, source: String) -> Dictionary:
	result["source"] = source
	result["recovered_from_temporary"] = source == "temporary"
	result["recovered_from_backup"] = source == "backup"
	return result


static func _blocks_fallback(result: Dictionary) -> bool:
	return not result["ok"] and result["reason"] in ["unsupported_version", "wrong_story"]


static func _legacy_briefing_response(journey_snapshot: Dictionary) -> String:
	return "careful" if journey_snapshot.get("talked_to_companion", false) else "unanswered"


static func _migrate_enemy_snapshot(journey_snapshot: Dictionary) -> void:
	journey_snapshot["enemy_id"] = EnemyCatalogScript.DEFAULT_ENEMY_ID
	if journey_snapshot.get("phase") in ["riverbank", "mountain_path"]:
		journey_snapshot["enemy_hp"] = EnemyCatalogScript.max_hp(EnemyCatalogScript.DEFAULT_ENEMY_ID)
	_migrate_combat_status_snapshot(journey_snapshot)


static func _migrate_combat_status_snapshot(journey_snapshot: Dictionary) -> void:
	journey_snapshot["armor_break_turns"] = 0
	journey_snapshot["focus_turns"] = 0
	_migrate_moonleaf_snapshot(journey_snapshot)


static func _migrate_moonleaf_snapshot(journey_snapshot: Dictionary) -> void:
	if journey_snapshot.get("gathered_moonleaf", false) or journey_snapshot.get("phase") == "complete":
		journey_snapshot["moonleaf_method"] = "whole_plant"
	else:
		journey_snapshot["moonleaf_method"] = "unselected"
	_migrate_discovery_snapshot(journey_snapshot)


static func _migrate_discovery_snapshot(journey_snapshot: Dictionary) -> void:
	journey_snapshot["discoveries"] = []
	_migrate_ferryman_snapshot(journey_snapshot)


static func _migrate_ferryman_snapshot(journey_snapshot: Dictionary) -> void:
	journey_snapshot["ferryman_response"] = "unanswered"
	_migrate_basket_snapshot(journey_snapshot)


static func _migrate_basket_snapshot(journey_snapshot: Dictionary) -> void:
	journey_snapshot["basket_response"] = "unanswered"
	_migrate_enemy_intel_snapshot(journey_snapshot)


static func _migrate_enemy_intel_snapshot(journey_snapshot: Dictionary) -> void:
	# Older builds never recorded whether a player studied a spoor. Do not infer
	# knowledge from an encounter or combat round: migration must not invent a
	# choice the player did not make.
	journey_snapshot["enemy_intel"] = []


static func _result(ok: bool, data: Dictionary, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"data": data,
		"reason": reason,
		"source": "none",
		"recovered_from_temporary": false,
		"recovered_from_backup": false,
		"migrated_from_version": 0,
	}


static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_absolute(path))
