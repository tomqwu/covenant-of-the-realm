extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const BUDGET_PATH := "res://tests/performance_budget.json"
const PERFORMANCE_SAVE_PATH := "user://performance-save.json"
const PERFORMANCE_SETTINGS_PATH := "user://performance-settings.json"
const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const COMPLETE_BATTLE_ACTIONS := [
	"talk_to_companion",
	"gather_moonleaf",
	"enter_spring",
	"approach_enemy",
	"use_talisman",
	"use_art",
	"use_art",
	"guard",
	"use_art",
	"companion_support",
	"use_art",
	"use_art",
	"breakthrough",
]

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var budget := _load_budget()
	if budget.is_empty():
		_finish({})
		return
	var results := {
		"movement": _benchmark_movement(budget),
		"trail": _benchmark_companion_trail(budget),
		"battle": _benchmark_battle(budget),
	}
	results["scene"] = await _benchmark_scene_lifecycle(budget)
	_finish(results)


func _load_budget() -> Dictionary:
	var file := FileAccess.open(BUDGET_PATH, FileAccess.READ)
	if file == null:
		failures.append("无法读取性能预算")
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		failures.append("性能预算必须是合法 JSON 对象")
		return {}
	var budget: Dictionary = parser.data
	var positive_fields := [
		"movement_iterations",
		"movement_budget_ms",
		"trail_iterations",
		"trail_budget_ms",
		"battle_iterations",
		"battle_budget_ms",
		"scene_cycles",
		"scene_budget_ms",
		"max_main_scene_nodes",
	]
	if int(budget.get("schema_version", 0)) != 1:
		failures.append("性能预算版本必须为 1")
	for field in positive_fields:
		if typeof(budget.get(field)) != TYPE_FLOAT or int(budget[field]) <= 0:
			failures.append("性能预算字段必须为正整数：%s" % field)
	return {} if not failures.is_empty() else budget


func _benchmark_movement(budget: Dictionary) -> Dictionary:
	var exploration = ExplorationStateScript.new()
	var iterations := int(budget["movement_iterations"])
	var started := Time.get_ticks_usec()
	var interaction_checksum := 0
	for index in range(iterations):
		exploration.move(DIRECTIONS[index % DIRECTIONS.size()], 0.016)
		if index % 31 == 0:
			interaction_checksum += exploration.interaction_action(false, false).length()
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if elapsed_ms > float(budget["movement_budget_ms"]):
		failures.append("移动/碰撞预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["movement_budget_ms"])])
	if not exploration.is_walkable(exploration.player_position):
		failures.append("移动性能循环产生了不可行走终点")
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"interaction_checksum": interaction_checksum,
	}


func _benchmark_battle(budget: Dictionary) -> Dictionary:
	var iterations := int(budget["battle_iterations"])
	var started := Time.get_ticks_usec()
	var total_rounds := 0
	for _iteration in range(iterations):
		var journey = JourneyStateScript.new()
		for action_id in COMPLETE_BATTLE_ACTIONS:
			var result: Dictionary = journey.choose(action_id)
			if not result["ok"]:
				failures.append("战斗性能循环拒绝合法行动：%s" % action_id)
				return {"iterations": _iteration, "elapsed_ms": 0.0, "total_rounds": total_rounds}
		if journey.phase_id() != "complete":
			failures.append("战斗性能循环没有到达章节完成态")
			return {"iterations": _iteration, "elapsed_ms": 0.0, "total_rounds": total_rounds}
		total_rounds += journey.round_number
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if elapsed_ms > float(budget["battle_budget_ms"]):
		failures.append("战斗解析预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["battle_budget_ms"])])
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"total_rounds": total_rounds,
	}


func _benchmark_companion_trail(budget: Dictionary) -> Dictionary:
	var trail = CompanionTrailScript.new()
	var position := Vector2(0.50, 0.50)
	trail.reset("performance_map", position, Vector2(0.042, 0.011))
	var iterations := int(budget["trail_iterations"])
	var started := Time.get_ticks_usec()
	for index in range(iterations):
		position += DIRECTIONS[int(index / 250) % DIRECTIONS.size()] * 0.002
		trail.record("performance_map", position, Vector2(0.042, 0.011))
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var contract: Dictionary = trail.visual_contract()
	if elapsed_ms > float(budget["trail_budget_ms"]):
		failures.append("同行脚印预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["trail_budget_ms"])])
	if int(contract["point_count"]) > int(contract["max_points"]):
		failures.append("同行脚印超过固定点数上限")
	if int(contract["reset_count"]) != 1:
		failures.append("连续同行性能循环意外重置轨迹")
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"point_count": contract["point_count"],
		"reset_count": contract["reset_count"],
	}


func _benchmark_scene_lifecycle(budget: Dictionary) -> Dictionary:
	SaveGameScript.remove(PERFORMANCE_SAVE_PATH)
	SettingsStoreScript.remove(PERFORMANCE_SETTINGS_PATH)
	var packed_scene: PackedScene = load("res://src/ui/main.tscn")
	var cycles := int(budget["scene_cycles"])
	var baseline_children := root.get_child_count()
	var maximum_nodes := 0
	var started := Time.get_ticks_usec()
	for _cycle in range(cycles):
		var instance := packed_scene.instantiate()
		instance.configure_save_path(PERFORMANCE_SAVE_PATH)
		instance.configure_settings_path(PERFORMANCE_SETTINGS_PATH)
		root.add_child(instance)
		await process_frame
		maximum_nodes = maxi(maximum_nodes, _count_nodes(instance))
		instance.queue_free()
		await process_frame
		if root.get_child_count() != baseline_children:
			failures.append("主场景销毁后仍残留根节点")
			break
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if elapsed_ms > float(budget["scene_budget_ms"]):
		failures.append("场景生命周期预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["scene_budget_ms"])])
	if maximum_nodes > int(budget["max_main_scene_nodes"]):
		failures.append("主场景节点数超预算：%d > %d" % [maximum_nodes, int(budget["max_main_scene_nodes"])])
	SaveGameScript.remove(PERFORMANCE_SAVE_PATH)
	SettingsStoreScript.remove(PERFORMANCE_SETTINGS_PATH)
	return {
		"cycles": cycles,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"maximum_nodes": maximum_nodes,
		"root_children_after": root.get_child_count(),
	}


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _finish(results: Dictionary) -> void:
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("RPG performance passed: %s" % JSON.stringify(results))
	quit(0)
