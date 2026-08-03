extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const BUDGET_PATH := "res://tests/performance_budget.json"
const PERFORMANCE_SAVE_PATH := "user://performance-save.json"
const PERFORMANCE_SETTINGS_PATH := "user://performance-settings.json"
const EXPECTED_STATIC_MAIN_SCENE_NODES := 112
const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const COMPLETE_BATTLE_ACTIONS := [
	"talk_to_companion",
	"gather_moonleaf",
	"enter_spring",
	"approach_enemy",
	"guard",
	"use_talisman",
	"use_art",
	"use_art",
	"use_art",
	"guard",
	"companion_support",
	"use_art",
	"use_art",
	"listen_to_spring",
	"warm_meridians",
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
		"patrol": _benchmark_patrol(budget),
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
		"patrol_iterations",
		"patrol_budget_ms",
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


func _benchmark_patrol(budget: Dictionary) -> Dictionary:
	var patrol = PatrolStateScript.new()
	var exploration = ExplorationStateScript.new()
	var iterations := int(budget["patrol_iterations"])
	var started := Time.get_ticks_usec()
	var interaction_checksum := 0
	var far_player := Vector2(0.40, 0.16)
	for index in range(iterations):
		patrol.advance(0.016, far_player)
		if index % 31 == 0:
			interaction_checksum += patrol.interaction_action(
				patrol.position,
				PatrolStateScript.RESPONSE_UNANSWERED
			).length()
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var contract: Dictionary = patrol.runtime_contract()
	if elapsed_ms > float(budget["patrol_budget_ms"]):
		failures.append("独立巡路预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["patrol_budget_ms"])])
	if not exploration.is_walkable(patrol.position):
		failures.append("独立巡路性能循环产生了不可行走终点")
	if contract["route_points"] != PatrolStateScript.WAYPOINTS or bool(contract["collision_authority"]) or bool(contract["quest_authority"]):
		failures.append("独立巡路性能循环改变了固定路线或权威边界")
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"interaction_checksum": interaction_checksum,
		"position": patrol.position,
		"target_index": patrol.target_index,
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
	var packed_scene: PackedScene = load("res://src/ui/main.tscn")
	var cycles := int(budget["scene_cycles"])
	var baseline_children := root.get_child_count()
	var maximum_nodes := 0
	var static_scene_nodes := 0
	var maximum_detail_rebuilds := 0
	var maximum_landmark_nodes := 0
	var state_peaks := {
		"title": 0,
		"path": 0,
		"dialogue": 0,
		"patrol": 0,
		"battle": 0,
		"battle_action_immediate": 0,
		"battle_action_stable": 0,
		"journal": 0,
		"spring_unstarted": 0,
		"spring_listened": 0,
		"spring_warmed": 0,
		"complete": 0,
	}
	var started := Time.get_ticks_usec()
	for _cycle in range(cycles):
		SaveGameScript.remove(PERFORMANCE_SAVE_PATH)
		SettingsStoreScript.remove(PERFORMANCE_SETTINGS_PATH)
		var instance := packed_scene.instantiate()
		var cycle_static_nodes := _count_nodes(instance)
		static_scene_nodes = maxi(static_scene_nodes, cycle_static_nodes)
		if cycle_static_nodes != EXPECTED_STATIC_MAIN_SCENE_NODES and _cycle == 0:
			failures.append("主场景静态节点数改变：%d != %d" % [cycle_static_nodes, EXPECTED_STATIC_MAIN_SCENE_NODES])
		instance.configure_save_path(PERFORMANCE_SAVE_PATH)
		instance.configure_settings_path(PERFORMANCE_SETTINGS_PATH)
		root.add_child(instance)
		await process_frame
		await process_frame
		state_peaks["title"] = maxi(int(state_peaks["title"]), _count_nodes(instance))
		var detail_layer: TileMapLayer = instance.get_node("%MapDetailLayer")
		var title_detail_contract: Dictionary = detail_layer.map_contract()
		maximum_detail_rebuilds = maxi(maximum_detail_rebuilds, int(title_detail_contract["rebuild_count"]))
		if int(title_detail_contract["rebuild_count"]) != 1 or not bool(title_detail_contract["visible"]):
			failures.append("标题底图细节必须恰好构建一次并保持可见")
		var title_landmarks: Dictionary = instance.get_node("%MapCanvas").occlusion_contract()
		maximum_landmark_nodes = maxi(maximum_landmark_nodes, int(title_landmarks["count"]))
		if _cycle == 0 and (int(title_landmarks["count"]) != 7 or int(title_landmarks["asset_backed_count"]) != 7):
			failures.append("渡口必须复用七个资产化房屋/树木前景节点")
		var title_camera: Dictionary = instance.world_camera_contract()
		if _cycle == 0 and (title_camera["world_size"] != Vector2(1536, 864) or not bool(title_camera["pixel_snap"])):
			failures.append("标题底图必须使用固定整数像素滚动世界")
		if instance.get_node("%WorldRoot").is_ancestor_of(instance.get_node("%ChapterLabel")):
			failures.append("HUD 不得进入滚动世界节点树")

		instance.start_new_game()
		await process_frame
		await process_frame
		instance._start_companion_dialogue()
		instance.skip_dialogue_to_response()
		await process_frame
		await process_frame
		state_peaks["dialogue"] = maxi(int(state_peaks["dialogue"]), _count_nodes(instance))
		if int(detail_layer.map_contract()["rebuild_count"]) != 1:
			failures.append("同一渡口上下文的对话流程意外重建地图细节")

		instance._choose_dialogue_response("careful")
		state_peaks["patrol"] = maxi(int(state_peaks["patrol"]), _count_nodes(instance))
		var patrol_visual: Dictionary = instance.get_node("%MapCanvas").patrol_visual_contract()
		if not bool(patrol_visual["visible"]) or not bool(patrol_visual["active"]):
			failures.append("完成同行简报后独立巡路角色必须进入渡口场景")
		instance._on_action("gather_moonleaf")
		instance._on_action("enter_spring")
		instance.get_node("%SceneTransition").finish()
		# An explicit transition finish is synchronous; one frame drains queued
		# action children before the stable tree and detail contracts are sampled.
		await process_frame
		state_peaks["path"] = maxi(int(state_peaks["path"]), _count_nodes(instance))
		var path_detail_contract: Dictionary = detail_layer.map_contract()
		maximum_detail_rebuilds = maxi(maximum_detail_rebuilds, int(path_detail_contract["rebuild_count"]))
		if int(path_detail_contract["rebuild_count"]) != 2 or not bool(path_detail_contract["visible"]):
			failures.append("首次山道切换必须只追加一次可见细节重建")
		var path_landmarks: Dictionary = instance.get_node("%MapCanvas").occlusion_contract()
		maximum_landmark_nodes = maxi(maximum_landmark_nodes, int(path_landmarks["count"]))
		if _cycle == 0 and (int(path_landmarks["count"]) != 5 or int(path_landmarks["asset_backed_count"]) != 5):
			failures.append("山道必须复用五个资产化树木前景节点")
		var path_camera: Dictionary = instance.world_camera_contract()
		if path_camera["normalized_focus"] != instance.exploration.player_position or not bool(path_camera["pixel_snap"]):
			failures.append("山道切换必须同步确定性坐标与整数像素镜头")

		instance._on_action("approach_enemy")
		instance.get_node("%SceneTransition").finish()
		await process_frame
		state_peaks["battle"] = maxi(int(state_peaks["battle"]), _count_nodes(instance))
		var battle_detail_contract: Dictionary = detail_layer.map_contract()
		maximum_detail_rebuilds = maxi(maximum_detail_rebuilds, int(battle_detail_contract["rebuild_count"]))
		if int(battle_detail_contract["rebuild_count"]) != 2 or bool(battle_detail_contract["visible"]):
			failures.append("战斗必须隐藏细节且不得重复构建缓存的山道布局")
		var battle_landmarks: Dictionary = instance.get_node("%MapCanvas").occlusion_contract()
		maximum_landmark_nodes = maxi(maximum_landmark_nodes, int(battle_landmarks["count"]))
		if _cycle == 0 and (int(battle_landmarks["count"]) != 4 or int(battle_landmarks["asset_backed_count"]) != 4):
			failures.append("战斗镜头必须复用四个资产化树木前景节点")
		instance._on_action("guard")
		state_peaks["battle_action_immediate"] = maxi(int(state_peaks["battle_action_immediate"]), _count_nodes(instance))
		await process_frame
		await process_frame
		state_peaks["battle_action_stable"] = maxi(int(state_peaks["battle_action_stable"]), _count_nodes(instance))

		instance.open_journal()
		await process_frame
		await process_frame
		state_peaks["journal"] = maxi(int(state_peaks["journal"]), _count_nodes(instance))
		instance.close_journal()
		# Closing restores focus on the next frame. Keep that boundary, then sample
		# phase transitions one frame after their explicit synchronous `finish()`.
		await process_frame
		instance._on_action("retreat")
		instance._on_action("bypass_enemy")
		instance.get_node("%SceneTransition").finish()
		await process_frame
		state_peaks["spring_unstarted"] = maxi(int(state_peaks["spring_unstarted"]), _count_nodes(instance))
		var spring_detail_contract: Dictionary = detail_layer.map_contract()
		maximum_detail_rebuilds = maxi(maximum_detail_rebuilds, int(spring_detail_contract["rebuild_count"]))
		if int(spring_detail_contract["rebuild_count"]) != 2 or bool(spring_detail_contract["visible"]):
			failures.append("藏泉石室必须隐藏山道细节且不得重建细节缓存")
		if _cycle == 0 and int(instance.get_node("%MapCanvas").occlusion_contract()["count"]) != 0:
			failures.append("藏泉石室不得残留照禾地标前景节点")

		# These actions have no transition or deferred node creation: `_render()`
		# replaces the single nearby-action child synchronously. Sample immediately
		# so the lifecycle budget measures work rather than four fixed-clock waits
		# that add no coverage across every cycle.
		instance._on_action("listen_to_spring")
		state_peaks["spring_listened"] = maxi(int(state_peaks["spring_listened"]), _count_nodes(instance))
		instance._on_action("warm_meridians")
		state_peaks["spring_warmed"] = maxi(int(state_peaks["spring_warmed"]), _count_nodes(instance))
		instance._on_action("breakthrough")
		instance.get_node("%SceneTransition").finish()
		await process_frame
		state_peaks["complete"] = maxi(int(state_peaks["complete"]), _count_nodes(instance))
		var complete_detail_contract: Dictionary = detail_layer.map_contract()
		maximum_detail_rebuilds = maxi(maximum_detail_rebuilds, int(complete_detail_contract["rebuild_count"]))
		if int(complete_detail_contract["rebuild_count"]) != 2 or bool(complete_detail_contract["visible"]):
			failures.append("三步引息与完成态不得重建或重新显示地图细节")
		for state_peak in state_peaks.values():
			maximum_nodes = maxi(maximum_nodes, int(state_peak))
		instance.queue_free()
		await process_frame
		if root.get_child_count() != baseline_children:
			failures.append("主场景销毁后仍残留根节点")
			break
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if elapsed_ms > float(budget["scene_budget_ms"]):
		failures.append("场景生命周期预算超时：%.2f ms > %d ms" % [elapsed_ms, int(budget["scene_budget_ms"])])
	if maximum_nodes > int(budget["max_main_scene_nodes"]):
		failures.append("主场景节点数超预算：%d > %d（%s）" % [maximum_nodes, int(budget["max_main_scene_nodes"]), JSON.stringify(state_peaks)])
	SaveGameScript.remove(PERFORMANCE_SAVE_PATH)
	SettingsStoreScript.remove(PERFORMANCE_SETTINGS_PATH)
	return {
		"cycles": cycles,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"maximum_nodes": maximum_nodes,
		"static_scene_nodes": static_scene_nodes,
		"maximum_detail_rebuilds": maximum_detail_rebuilds,
		"maximum_landmark_nodes": maximum_landmark_nodes,
		"state_peaks": state_peaks,
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
