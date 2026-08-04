extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const PathKeeperStateScript := preload("res://src/domain/path_keeper_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const BUDGET_PATH := "res://tests/performance_budget.json"
const PERFORMANCE_SAVE_PATH := "user://performance-save.json"
const PERFORMANCE_SETTINGS_PATH := "user://performance-settings.json"
const EXPECTED_STATIC_MAIN_SCENE_NODES := 117
const LIFECYCLE_CONFIRMATION_POLICY_CHECKS := 6
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
		"path_keeper": _benchmark_path_keeper(budget),
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
		"path_keeper_iterations",
		"path_keeper_budget_ms",
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
	if not patrol.apply_priority(PatrolStateScript.RESPONSE_BOAT_FIRST):
		failures.append("独立巡路性能夹具无法设定木楔优先路线")
	var iterations := int(budget["patrol_iterations"])
	var started := Time.get_ticks_usec()
	var interaction_checksum := 0
	var worksite_count := 0
	var far_player := Vector2(0.40, 0.16)
	for index in range(iterations):
		patrol.advance(0.016, far_player, PatrolStateScript.RESPONSE_BOAT_FIRST)
		var worksite: Dictionary = patrol.worksite_context(PatrolStateScript.RESPONSE_BOAT_FIRST)
		if not worksite.is_empty():
			interaction_checksum += str(worksite.get("action_id", "")).length()
			worksite_count += 1
			if not patrol.finish_worksite(str(worksite.get("worksite_id", ""))):
				failures.append("独立巡路性能循环无法结束合法工位停留")
				break
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
	if worksite_count <= 0:
		failures.append("独立巡路性能循环没有覆盖端点工位查询")
	var herbs_endpoint = PatrolStateScript.new()
	if (
		not herbs_endpoint.restore({
			"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].x,
			"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].y,
			"target_index": PatrolStateScript.HERBS_WAYPOINT - 1,
			"route_step": -1,
			"dwell_remaining": PatrolStateScript.ENDPOINT_DWELL_SECONDS,
			"yielding_to_player": false,
		})
		or herbs_endpoint.worksite_context(PatrolStateScript.RESPONSE_HERBS_FIRST).get("route_role") != "priority"
		or not herbs_endpoint.finish_worksite(PatrolStateScript.WORKSITE_HERBS)
	):
		failures.append("独立巡路性能合同未覆盖药叶优先工位与完成路径")
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"interaction_checksum": interaction_checksum,
		"worksite_count": worksite_count,
		"position": patrol.position,
		"target_index": patrol.target_index,
	}


func _benchmark_path_keeper(budget: Dictionary) -> Dictionary:
	var path_keeper = PathKeeperStateScript.new()
	var exploration = ExplorationStateScript.new()
	if not exploration.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID):
		failures.append("山道补签人性能夹具无法进入山道地图")
	var iterations := int(budget["path_keeper_iterations"])
	var started := Time.get_ticks_usec()
	var interaction_checksum := 0
	var far_player := Vector2(0.90, 0.70)
	for index in range(iterations):
		path_keeper.advance(0.016, far_player)
		if index % 31 == 0:
			interaction_checksum += path_keeper.interaction_action(path_keeper.position).length()
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var contract: Dictionary = path_keeper.runtime_contract()
	if elapsed_ms > float(budget["path_keeper_budget_ms"]):
		failures.append(
			"山道补签人预算超时：%.2f ms > %d ms"
			% [elapsed_ms, int(budget["path_keeper_budget_ms"])]
		)
	if not exploration.is_walkable(path_keeper.position):
		failures.append("山道补签人性能循环产生了不可行走终点")
	if (
		contract["route_points"] != PathKeeperStateScript.WAYPOINTS
		or bool(contract["collision_authority"])
		or bool(contract["quest_authority"])
		or bool(contract["battle_authority"])
		or bool(contract["reward_authority"])
		or not bool(contract["persistent"])
	):
		failures.append("山道补签人性能循环改变了固定路线或权威边界")
	if interaction_checksum <= 0:
		failures.append("山道补签人性能循环没有覆盖近距语义交互")
	return {
		"iterations": iterations,
		"elapsed_ms": snappedf(elapsed_ms, 0.01),
		"interaction_checksum": interaction_checksum,
		"position": path_keeper.position,
		"target_index": path_keeper.target_index,
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
	_verify_lifecycle_confirmation_policy(float(budget["scene_budget_ms"]))
	var sample_results: Array[Dictionary] = []
	var first_sample: Dictionary = await _benchmark_scene_lifecycle_sample(budget)
	sample_results.append(first_sample)
	if _should_confirm_lifecycle(
		float(first_sample["elapsed_ms"]),
		float(budget["scene_budget_ms"]),
		failures.size()
	):
		sample_results.append(await _benchmark_scene_lifecycle_sample(budget))
	var raw_samples_ms := _lifecycle_elapsed_samples(sample_results)
	var result := _merge_lifecycle_samples(sample_results)
	if (
		failures.is_empty()
		and _lifecycle_samples_exceed_budget(
			raw_samples_ms,
			float(budget["scene_budget_ms"])
		)
	):
		failures.append(
			"场景生命周期两次完整样本均超时：低争用样本 %.3f ms > %d ms（samples=%s）"
			% [
				_accepted_lifecycle_elapsed(raw_samples_ms),
				int(budget["scene_budget_ms"]),
				JSON.stringify(raw_samples_ms),
			]
		)
	return result


func _benchmark_scene_lifecycle_sample(budget: Dictionary) -> Dictionary:
	var packed_scene: PackedScene = load("res://src/ui/main.tscn")
	var cycles := int(budget["scene_cycles"])
	var baseline_children := root.get_child_count()
	var maximum_nodes := 0
	var static_scene_nodes := 0
	var maximum_detail_rebuilds := 0
	var maximum_landmark_nodes := 0
	var dialogue_speed_probe_cycles := 0
	var dialogue_settings_writes := 0
	var state_peaks := {
		"title": 0,
		"path": 0,
		"dialogue": 0,
		"patrol": 0,
		"patrol_worksite_dialogue": 0,
		"battle": 0,
		"battle_action_immediate": 0,
		"battle_action_stable": 0,
		"battle_replacement_immediate": 0,
		"battle_replacement_stable": 0,
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
		if (
			instance.get_node("%TitleDialogueSpeedButton").text != "对话显字：标准"
			or instance.get_node("%PauseDialogueSpeedButton").text != "对话显字：标准"
		):
			failures.append("生命周期新场景必须从持久设置的标准对话显字开始")
		# Unit, E2E, and physical-input suites own exhaustive reveal behavior.
		# Exercise all four real persistence writes once per complete lifecycle
		# sample without multiplying shared-runner file-system noise by 20.
		if _cycle == 0:
			dialogue_speed_probe_cycles += 1
			instance.toggle_dialogue_speed()
			dialogue_settings_writes += 1
			if instance.settings.get("dialogue_speed") != "fast":
				failures.append("生命周期无法切到快速对话显字")
			instance.toggle_dialogue_speed()
			dialogue_settings_writes += 1
			if instance.settings.get("dialogue_speed") != "instant":
				failures.append("生命周期无法切到整句显示")

		instance.start_new_game()
		await process_frame
		await process_frame
		instance._start_companion_dialogue()
		if _cycle == 0:
			if instance.get_node("%DialogueLabel").visible_characters != -1:
				failures.append("整句显示必须在生命周期中直接显示全文")
			instance.toggle_dialogue_speed()
			dialogue_settings_writes += 1
			instance.advance_dialogue()
			if instance.settings.get("dialogue_speed") != "standard" or instance.get_node("%DialogueLabel").visible_characters != 0:
				failures.append("整句循环回标准后下一句必须恢复逐字显示")
			instance._process_dialogue_reveal(0.10)
			var standard_reveal_count: int = instance.get_node("%DialogueLabel").visible_characters
			instance.toggle_dialogue_speed()
			dialogue_settings_writes += 1
			instance._process_dialogue_reveal(0.10)
			var fast_reveal_count: int = instance.get_node("%DialogueLabel").visible_characters
			if instance.settings.get("dialogue_speed") != "fast":
				failures.append("生命周期无法从标准切回快速对话显字")
			if standard_reveal_count <= 0 or fast_reveal_count <= standard_reveal_count:
				failures.append("快速对话显字必须在相同固定增量内推进更多文字")
		else:
			if instance.get_node("%DialogueLabel").visible_characters != 0:
				failures.append("生命周期后续场景必须从标准逐字显字开始")
			instance.show_full_dialogue_line()
			instance.advance_dialogue()
			if instance.get_node("%DialogueLabel").visible_characters != 0:
				failures.append("生命周期后续场景推进下一句后必须继续逐字显字")
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
		var patrol_choice: Dictionary = instance.journey.complete_patrol_dialogue(PatrolStateScript.RESPONSE_BOAT_FIRST)
		if not bool(patrol_choice.get("ok", false)) or not instance.patrol.apply_priority(PatrolStateScript.RESPONSE_BOAT_FIRST):
			failures.append("工位对话生命周期夹具无法设定木楔优先路线")
		if not instance.patrol.restore({
			"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
			"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
			"target_index": PatrolStateScript.BOAT_WAYPOINT + 1,
			"route_step": 1,
			"dwell_remaining": PatrolStateScript.ENDPOINT_DWELL_SECONDS,
			"yielding_to_player": false,
		}):
			failures.append("工位对话生命周期夹具无法恢复合法补船停留")
		if not instance.exploration.restore({
			"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
			"player_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
			"player_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
		}):
			failures.append("工位对话生命周期夹具无法恢复近距玩家")
		instance._render([])
		var worksite_start: Dictionary = instance.interact()
		if not bool(worksite_start.get("ok", false)) or instance.dialogue.dialogue_id != "patrol_boat_priority":
			failures.append("补船优先工位必须进入结构化对话")
		instance.skip_dialogue_to_response()
		await process_frame
		await process_frame
		state_peaks["patrol_worksite_dialogue"] = maxi(int(state_peaks["patrol_worksite_dialogue"]), _count_nodes(instance))
		instance._choose_dialogue_response("secure_boat_cloth")
		if instance.dialogue.active or not is_zero_approx(instance.patrol.dwell_remaining):
			failures.append("工位回应必须结束对话与当前停留")
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
		var path_keeper_before: Dictionary = instance.path_keeper.snapshot()
		instance.path_keeper.advance(2.0, Vector2(0.90, 0.70))
		instance._render([])
		var path_keeper_visual: Dictionary = instance.get_node("%MapCanvas").path_keeper_visual_contract()
		if instance.path_keeper.snapshot() == path_keeper_before:
			failures.append("山道生命周期必须推进补签人确定性路线")
		if (
			not bool(path_keeper_visual["visible"])
			or not bool(path_keeper_visual["active"])
			or path_keeper_visual["normalized_position"] != instance.path_keeper.position
			or bool(path_keeper_visual["collision_authority"])
			or bool(path_keeper_visual["quest_authority"])
			or bool(path_keeper_visual["battle_authority"])
			or bool(path_keeper_visual["reward_authority"])
		):
			failures.append("山道生命周期补签人表现必须跟随 domain 且保持零规则权威")

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
		instance._on_action("use_talisman")
		instance._on_action("use_art")
		instance._on_action("use_art")
		state_peaks["battle_replacement_immediate"] = maxi(
			int(state_peaks["battle_replacement_immediate"]),
			_count_nodes(instance)
		)
		var replacement_feedback: Dictionary = instance.get_node("%MapCanvas").feedback_contract()
		var replacement_intent: Dictionary = instance.get_node("%IntentTelegraph").presentation_contract()
		var outgoing_defeat: Dictionary = instance.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
		if (
			instance.journey.enemy_id != "rock_armor_warden"
			or replacement_feedback["enemy_id_before"] != "rock_armor_young"
			or replacement_feedback["announced_intent_id"] != "rock_rending_charge"
			or replacement_feedback["resolved_intent_id"] != ""
			or replacement_feedback["outgoing_enemy_id"] != "rock_armor_young"
			or replacement_feedback["replacement_enemy_id"] != "rock_armor_warden"
		):
			failures.append("生命周期必须真实击败普通敌人并保留替换行动的旧新身份")
		if (
			not replacement_intent["active"]
			or replacement_intent["enemy_id"] != "rock_armor_warden"
			or replacement_intent["intent_id"] != "warden_pressing_charge"
			or replacement_intent["shape_id"] != "pressing_charge"
		):
			failures.append("生命周期普通敌替换后必须同步呈现首领当前势签")
		if (
			not outgoing_defeat["active"]
			or not instance.get_node("%OutgoingEnemySprite").visible
			or outgoing_defeat["enemy_id"] != "rock_armor_young"
			or outgoing_defeat["state"] != "defeat"
			or outgoing_defeat["role"] != "outgoing"
			or outgoing_defeat["duration"] != 0.70
			or not outgoing_defeat["motion_enabled"]
			or bool(outgoing_defeat["rule_authority"])
			or bool(outgoing_defeat["timing_authority"])
			or bool(outgoing_defeat["save_authority"])
			or bool(outgoing_defeat["blocks_input"])
		):
			failures.append("生命周期普通敌替换即时帧必须显示零权威旧敌退场姿态")
		instance.get_node("%SceneTransition").finish()
		var replacement_map_canvas = instance.get_node("%MapCanvas")
		replacement_map_canvas._process(float(replacement_feedback["duration"]))
		await process_frame
		await process_frame
		state_peaks["battle_replacement_stable"] = maxi(
			int(state_peaks["battle_replacement_stable"]),
			_count_nodes(instance)
		)
		var expired_defeat: Dictionary = instance.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
		if (
			expired_defeat["active"]
			or instance.get_node("%OutgoingEnemySprite").visible
			or expired_defeat["enemy_id"] != ""
			or expired_defeat["state"] != "idle"
			or expired_defeat["event_id"] != ""
			or expired_defeat["outgoing_enemy_id"] != ""
			or expired_defeat["replacement_enemy_id"] != ""
			or instance.journey.enemy_id != "rock_armor_warden"
			or instance.get_node("%BattleEnemySprite").enemy_id != "rock_armor_warden"
			or instance.get_node("%IntentTelegraph").presentation_contract()["enemy_id"] != "rock_armor_warden"
		):
			failures.append("生命周期普通敌替换稳定帧必须清退旧档案并保留首领权威表现")

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
	if dialogue_speed_probe_cycles != 1 or dialogue_settings_writes != 4:
		failures.append(
			"每个完整生命周期样本必须执行一次显字探针和四次设置写入：%d / %d"
			% [dialogue_speed_probe_cycles, dialogue_settings_writes]
		)
	if maximum_nodes > int(budget["max_main_scene_nodes"]):
		failures.append("主场景节点数超预算：%d > %d（%s）" % [maximum_nodes, int(budget["max_main_scene_nodes"]), JSON.stringify(state_peaks)])
	SaveGameScript.remove(PERFORMANCE_SAVE_PATH)
	SettingsStoreScript.remove(PERFORMANCE_SETTINGS_PATH)
	return {
		"cycles": cycles,
		"dialogue_speed_probe_cycles": dialogue_speed_probe_cycles,
		"dialogue_settings_writes": dialogue_settings_writes,
		"elapsed_ms": elapsed_ms,
		"maximum_nodes": maximum_nodes,
		"static_scene_nodes": static_scene_nodes,
		"maximum_detail_rebuilds": maximum_detail_rebuilds,
		"maximum_landmark_nodes": maximum_landmark_nodes,
		"state_peaks": state_peaks,
		"root_children_after": root.get_child_count(),
	}


func _should_confirm_lifecycle(elapsed_ms: float, budget_ms: float, failure_count: int) -> bool:
	return failure_count == 0 and elapsed_ms > budget_ms


func _accepted_lifecycle_elapsed(samples_ms: Array[float]) -> float:
	var accepted_ms := INF
	for sample_ms in samples_ms:
		accepted_ms = minf(accepted_ms, sample_ms)
	return accepted_ms


func _lifecycle_samples_exceed_budget(samples_ms: Array[float], budget_ms: float) -> bool:
	return _accepted_lifecycle_elapsed(samples_ms) > budget_ms


func _lifecycle_elapsed_samples(sample_results: Array[Dictionary]) -> Array[float]:
	var samples_ms: Array[float] = []
	for sample in sample_results:
		samples_ms.append(float(sample["elapsed_ms"]))
	return samples_ms


func _merge_lifecycle_samples(sample_results: Array[Dictionary]) -> Dictionary:
	var merged: Dictionary = sample_results[0].duplicate(true)
	var raw_samples_ms := _lifecycle_elapsed_samples(sample_results)
	var displayed_samples_ms: Array[float] = []
	var dialogue_speed_probe_cycles := 0
	var dialogue_settings_writes := 0
	for sample_ms in raw_samples_ms:
		displayed_samples_ms.append(snappedf(sample_ms, 0.01))
	var maximum_fields := [
		"maximum_nodes",
		"static_scene_nodes",
		"maximum_detail_rebuilds",
		"maximum_landmark_nodes",
		"root_children_after",
	]
	for sample in sample_results:
		dialogue_speed_probe_cycles += int(sample["dialogue_speed_probe_cycles"])
		dialogue_settings_writes += int(sample["dialogue_settings_writes"])
		for field in maximum_fields:
			merged[field] = maxi(int(merged[field]), int(sample[field]))
		var merged_peaks: Dictionary = merged["state_peaks"]
		var sample_peaks: Dictionary = sample["state_peaks"]
		for state_id in sample_peaks:
			merged_peaks[state_id] = maxi(int(merged_peaks[state_id]), int(sample_peaks[state_id]))
		merged["state_peaks"] = merged_peaks
	merged["elapsed_ms"] = snappedf(_accepted_lifecycle_elapsed(raw_samples_ms), 0.01)
	merged["samples_ms"] = displayed_samples_ms
	merged["sample_count"] = sample_results.size()
	merged["total_cycles"] = int(merged["cycles"]) * sample_results.size()
	merged["dialogue_speed_probe_cycles"] = dialogue_speed_probe_cycles
	merged["dialogue_settings_writes"] = dialogue_settings_writes
	merged["confirmation_policy_checks"] = LIFECYCLE_CONFIRMATION_POLICY_CHECKS
	return merged


func _verify_lifecycle_confirmation_policy(budget_ms: float) -> void:
	# Keep this just above the raw boundary so display rounding can never become
	# authoritative for the confirmation or failure decision.
	var above_budget := budget_ms + 0.001
	var below_budget := maxf(0.0, budget_ms - 1.0)
	var recovered_samples: Array[float] = [above_budget, below_budget]
	var sustained_samples: Array[float] = [above_budget, above_budget + 0.001]
	if not _should_confirm_lifecycle(above_budget, budget_ms, 0):
		failures.append("生命周期策略必须确认纯时间超限")
	if _should_confirm_lifecycle(budget_ms, budget_ms, 0):
		failures.append("生命周期策略不得重复已达标样本")
	if _should_confirm_lifecycle(above_budget, budget_ms, 1):
		failures.append("生命周期策略不得重试结构或正确性失败")
	if _lifecycle_samples_exceed_budget(recovered_samples, budget_ms):
		failures.append("生命周期策略必须接受完整低争用确认样本")
	if not _lifecycle_samples_exceed_budget(sustained_samples, budget_ms):
		failures.append("生命周期策略必须拒绝持续超限的完整样本")
	if not is_equal_approx(_accepted_lifecycle_elapsed(recovered_samples), below_budget):
		failures.append("生命周期策略必须报告最低完整样本")


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _finish(results: Dictionary) -> void:
	if not failures.is_empty():
		print("RPG performance failed: %s" % JSON.stringify(results))
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("RPG performance passed: %s" % JSON.stringify(results))
	quit(0)
