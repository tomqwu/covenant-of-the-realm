extends Control

const MapOccluderScript := preload("res://src/ui/map_occluder.gd")
const CompanionTrailScript := preload("res://src/ui/companion_trail.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const LANDMARK_ATLAS := preload("res://assets/pixel/zhaohe_landmarks.png")
const ACTOR_HEIGHT := 56.0
const WORLD_SIZE := Vector2(1536.0, 864.0)
const LANDMARK_FRAME_SIZE := Vector2i(192, 128)
const LANDMARK_PROFILE_COLUMNS := {
	"tree_celadon": 0,
	"ferry_house_rust": 1,
	"ferry_house_ochre": 2,
	"ferry_house_teal": 3,
	"ferry_dock": 4,
	"mountain_rock": 5,
	"spring_cave": 6,
	"spring_gate": 7,
	"ferry_boat_repair": 8,
	"ferry_drying_rack": 9,
	"path_rain_shelter": 10,
}
const INK_ROOT := Color("27312e")
const COOL_SHADOW := Color("355e63")
const RIVER_JADE := Color("4e9da4")
const CLEAR_INDIGO := Color("58738f")
const FRESH_CELADON := Color("8ebb83")
const WARM_RUST := Color("c6764f")
const WARM_PAPER := Color("f2e6cb")
const SPIRIT_GOLD := Color("e4c36e")
const DAWN_PEACH := Color("e7a76f")
const ROCK_SPOOR_POSITION := Vector2(0.65, 0.22)
const MOSS_SPOOR_POSITION := Vector2(0.36, 0.43)
const PUPPET_SPOOR_POSITION := Vector2(0.91, 0.34)
const BOAT_REPAIR_VISUAL_FEET := Vector2(0.38, 0.35)
const DRYING_RACK_VISUAL_FEET := Vector2(0.915, 0.48)
const RAIN_SHELTER_VISUAL_FEET := Vector2(0.575, 0.69)
const FERRY_TREE_POSITIONS: Array[Vector2] = [
	Vector2(0.395, 0.177),
	Vector2(0.849, 0.201),
	Vector2(0.894, 0.525),
	Vector2(0.406, 0.648),
]
const PATH_TREE_POSITIONS: Array[Vector2] = [
	Vector2(0.156, 0.247),
	Vector2(0.347, 0.170),
	Vector2(0.599, 0.224),
	Vector2(0.868, 0.401),
	Vector2(0.816, 0.648),
]
const BATTLE_TREE_POSITIONS: Array[Vector2] = [
	Vector2(0.113, 0.255),
	Vector2(0.293, 0.224),
	Vector2(0.794, 0.177),
	Vector2(0.877, 0.463),
]
const PATH_ROCK_POSITIONS: Array[Vector2] = [
	Vector2(0.226, 0.198),
	Vector2(0.476, 0.179),
	Vector2(0.738, 0.494),
	Vector2(0.313, 0.664),
]
const BATTLE_ROCK_POSITIONS: Array[Vector2] = [
	Vector2(0.217, 0.193),
	Vector2(0.365, 0.139),
	Vector2(0.864, 0.255),
	Vector2(0.898, 0.633),
	Vector2(0.269, 0.664),
]

@onready var player_sprite = %PlayerSprite
@onready var companion_sprite = %CompanionSprite
@onready var ferryman_sprite = %FerrymanSprite
@onready var herbkeeper_sprite = %HerbkeeperSprite
@onready var patrol_sprite = %PatrolSprite
@onready var ferry_ground: TileMapLayer = %FerryGround
@onready var path_ground: TileMapLayer = %PathGround
@onready var map_detail_layer: TileMapLayer = %MapDetailLayer
@onready var battle_enemy_sprite: AnimatedSprite2D = %BattleEnemySprite
@onready var path_rock_enemy_sprite: AnimatedSprite2D = %PathRockEnemySprite
@onready var path_moss_enemy_sprite: AnimatedSprite2D = %PathMossEnemySprite
@onready var path_puppet_enemy_sprite: AnimatedSprite2D = %PathPuppetEnemySprite

var phase_id := "riverbank"
var gathered_moonleaf := false
var moonleaf_method := "unselected"
var talked_to_companion := false
var lamp_turns := 0
var enemy_id := "rock_armor_young"
var player_position := Vector2(0.47, 0.51)
var nearby_action := ""
var player_motion := Vector2.ZERO
var feedback_text := ""
var feedback_remaining := 0.0
var feedback_duration := 0.0
var feedback_motion_enabled := true
var feedback_phase := 0.0
var occluder_nodes: Array[Node] = []
var occluder_signature := ""
var companion_trail = CompanionTrailScript.new()
var companion_position := Vector2(0.53, 0.51)
var companion_motion := Vector2.ZERO
var companion_trail_needs_reset := true
var discoveries: Array[String] = []
var enemy_intel: Array[String] = []
var ferryman_response := "unanswered"
var basket_response := "unanswered"
var patrol_response := "unanswered"
var first_breath_stage := "unstarted"
var patrol_position := Vector2(0.55, 0.66)
var patrol_motion := Vector2.UP
var patrol_moving := false
var patrol_active := false


func set_story_state(
	next_phase: String,
	gathered: bool,
	talked: bool,
	active_lamp_turns: int,
	next_enemy_id: String,
	next_moonleaf_method: String,
	next_discoveries: Array,
	next_ferryman_response: String,
	next_basket_response: String,
	next_patrol_response: String,
	next_enemy_intel: Array = [],
	next_first_breath_stage: String = "unstarted"
) -> void:
	if next_phase != phase_id or talked != talked_to_companion:
		companion_trail_needs_reset = true
	phase_id = next_phase
	gathered_moonleaf = gathered
	moonleaf_method = next_moonleaf_method
	talked_to_companion = talked
	lamp_turns = active_lamp_turns
	enemy_id = next_enemy_id
	discoveries.clear()
	for discovery_id in next_discoveries:
		discoveries.append(str(discovery_id))
	enemy_intel.clear()
	for intel_id in next_enemy_intel:
		enemy_intel.append(str(intel_id))
	ferryman_response = next_ferryman_response
	basket_response = next_basket_response
	patrol_response = next_patrol_response
	first_breath_stage = next_first_breath_stage
	_sync_actor_visuals()
	queue_redraw()


func set_exploration_state(next_position: Vector2, next_nearby_action: String) -> void:
	player_motion = next_position - player_position
	player_position = next_position
	nearby_action = next_nearby_action
	_sync_companion_trail()
	_sync_actor_visuals()
	queue_redraw()


func set_patrol_state(next_position: Vector2, next_motion: Vector2, moving: bool, active: bool) -> void:
	patrol_position = next_position
	patrol_motion = next_motion
	patrol_moving = moving
	patrol_active = active
	_sync_actor_visuals()
	queue_redraw()


func set_nearby_action(next_nearby_action: String) -> void:
	nearby_action = next_nearby_action
	queue_redraw()


func set_player_motion(direction: Vector2) -> void:
	player_motion = direction
	if is_instance_valid(player_sprite):
		player_sprite.set_motion(direction, not direction.is_zero_approx())
	if is_instance_valid(companion_sprite):
		companion_sprite.set_motion(companion_motion, talked_to_companion and not companion_motion.is_zero_approx())


func show_battle_feedback(event_ids: Array, fast_mode: bool, reduced_motion: bool) -> void:
	if is_instance_valid(battle_enemy_sprite):
		battle_enemy_sprite.consume_battle_events(event_ids, fast_mode, reduced_motion)
	var labels := {
		"enemy_hit": "受到冲击",
		"enemy_glanced": "化开冲势",
		"spring_lamp_deployed": "石灯护阵",
		"companion_supported": "砚青凝息",
		"weakness_exposed": "识破弱点",
		"regular_enemy_won": "灵物退开",
		"boss_arrived": "首领现身",
		"battle_won": "道路已开",
	}
	var next_text := ""
	for event_id in [
		"enemy_hit",
		"enemy_glanced",
		"spring_lamp_deployed",
		"companion_supported",
		"weakness_exposed",
		"regular_enemy_won",
		"boss_arrived",
		"battle_won",
	]:
		if event_ids.has(event_id):
			next_text = labels[event_id]
	if next_text.is_empty():
		return
	feedback_text = next_text
	feedback_duration = 0.18 if fast_mode else 0.70
	feedback_remaining = feedback_duration
	feedback_motion_enabled = not reduced_motion
	feedback_phase = 0.0
	queue_redraw()


func feedback_contract() -> Dictionary:
	return {
		"text": feedback_text,
		"duration": feedback_duration,
		"motion_enabled": feedback_motion_enabled,
		"active": feedback_remaining > 0.0,
	}


func actor_height_px() -> float:
	return ACTOR_HEIGHT


func world_visual_contract() -> Dictionary:
	return {
		"world_size": get_rect().size,
		"expected_world_size": WORLD_SIZE,
		"normalized_coordinates": true,
		"pixel_snap": true,
		"collision_authority": false,
		"camera_authority": false,
	}


func presentation_focus_normalized(fallback: Vector2) -> Vector2:
	if not is_node_ready():
		return fallback
	var size := get_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return fallback
	var actor_feet: Array[Vector2] = []
	match phase_id:
		"battle":
			actor_feet.assign([
				player_sprite.position,
				companion_sprite.position,
				battle_enemy_sprite.position,
			])
		"complete":
			actor_feet.assign([
				player_sprite.position,
				companion_sprite.position,
			])
		_:
			return fallback
	var focus := Vector2.ZERO
	for actor_position in actor_feet:
		focus += actor_position
	focus /= float(actor_feet.size())
	return Vector2(focus.x / size.x, focus.y / size.y)


func current_visual_mode() -> String:
	return phase_id


func uses_animated_actor_sprites() -> bool:
	return (
		player_sprite is AnimatedSprite2D
		and companion_sprite is AnimatedSprite2D
		and ferryman_sprite is AnimatedSprite2D
		and herbkeeper_sprite is AnimatedSprite2D
		and patrol_sprite is AnimatedSprite2D
	)


func uses_ferry_tile_layers() -> bool:
	return ferry_ground is TileMapLayer and ferry_ground.tile_set != null


func uses_mountain_path_tile_layers() -> bool:
	return path_ground is TileMapLayer and path_ground.tile_set != null


func uses_map_detail_layer() -> bool:
	return map_detail_layer is TileMapLayer and map_detail_layer.tile_set != null


func landmark_visual_contract() -> Dictionary:
	return {
		"schema_version": 2,
		"atlas_path": LANDMARK_ATLAS.resource_path,
		"atlas_size": LANDMARK_ATLAS.get_size(),
		"frame_size": LANDMARK_FRAME_SIZE,
		"profiles": LANDMARK_PROFILE_COLUMNS.keys(),
		"life_landmarks": {
			"ferry_boat_repair": {
				"phase_id": "riverbank",
				"visual_feet": BOAT_REPAIR_VISUAL_FEET,
				"interaction_anchor": ExplorationStateScript.BOAT_REPAIR_POSITION,
				"action_id": "inspect_boat_repair",
			},
			"ferry_drying_rack": {
				"phase_id": "riverbank",
				"visual_feet": DRYING_RACK_VISUAL_FEET,
				"interaction_anchor": ExplorationStateScript.DRYING_RACK_POSITION,
				"action_id": "inspect_drying_rack",
			},
			"path_rain_shelter": {
				"phase_id": "mountain_path",
				"visual_feet": RAIN_SHELTER_VISUAL_FEET,
				"interaction_anchor": ExplorationStateScript.PATH_RAIN_SHELTER_POSITION,
				"action_id": "inspect_rain_shelter",
			},
		},
		"filter": texture_filter,
		"pixel_snap": true,
		"collision_authority": false,
	}


func uses_animated_enemy_sprites() -> bool:
	return (
		battle_enemy_sprite is AnimatedSprite2D
		and path_rock_enemy_sprite is AnimatedSprite2D
		and path_moss_enemy_sprite is AnimatedSprite2D
		and path_puppet_enemy_sprite is AnimatedSprite2D
	)


func moonleaf_visual_contract() -> Dictionary:
	return {
		"gathered": gathered_moonleaf,
		"method": moonleaf_method,
		"regrowing": gathered_moonleaf and moonleaf_method == "cutting",
	}


func companion_follow_contract() -> Dictionary:
	var contract: Dictionary = companion_trail.visual_contract()
	contract["active"] = talked_to_companion and phase_id in ["riverbank", "mountain_path"]
	contract["normalized_position"] = companion_position
	contract["sprite_position"] = companion_sprite.position
	contract["motion"] = companion_motion
	return contract


func discovery_visual_contract() -> Dictionary:
	return {
		"discovered": discoveries.duplicate(),
		"read_count": discoveries.size(),
		"total": 3,
		"positions": {
			"ferry_watermark": Vector2(0.43, 0.42),
			"spring_seam": Vector2(0.40, 0.30),
			"abandoned_basket": Vector2(0.68, 0.60),
		},
	}


func enemy_intel_visual_contract() -> Dictionary:
	return {
		"studied": enemy_intel.duplicate(),
		"read_count": enemy_intel.size(),
		"total": 3,
		"positions": {
			"rock_armor_young": ROCK_SPOOR_POSITION,
			"spring_moss_shell": MOSS_SPOOR_POSITION,
			"unbalanced_stone_puppet": PUPPET_SPOOR_POSITION,
		},
		"trace_actions": {
			"rock_armor_young": "inspect_rock_spoor",
			"spring_moss_shell": "inspect_moss_spoor",
			"unbalanced_stone_puppet": "inspect_puppet_spoor",
		},
	}


func ferryman_visual_contract() -> Dictionary:
	return {
		"visible": ferryman_sprite.visible,
		"response": ferryman_response,
		"normalized_position": Vector2(0.41, 0.66),
		"sprite_position": ferryman_sprite.position,
		"sprite_depth": ferryman_sprite.z_index,
		"gauge_upright": ferryman_response == "repair",
		"record_tag": ferryman_response == "record",
	}


func basket_visual_contract() -> Dictionary:
	return {
		"response": basket_response,
		"herbkeeper_visible": herbkeeper_sprite.visible,
		"herbkeeper_position": herbkeeper_sprite.position,
		"herbkeeper_depth": herbkeeper_sprite.z_index,
		"returned_to_ferry": basket_response == "return",
		"repaired_on_trail": basket_response == "trail",
	}


func patrol_visual_contract() -> Dictionary:
	return {
		"visible": patrol_sprite.visible,
		"response": patrol_response,
		"normalized_position": patrol_position,
		"sprite_position": patrol_sprite.position,
		"sprite_depth": patrol_sprite.z_index,
		"motion": patrol_motion,
		"moving": patrol_moving,
		"active": patrol_active,
		"collision_authority": false,
		"quest_authority": false,
	}


func first_breath_visual_contract() -> Dictionary:
	var completed := _completed_first_breath_actions()
	return {
		"stage": first_breath_stage,
		"positions": {
			"listen_to_spring": ExplorationStateScript.SPRING_LISTEN_POSITION,
			"warm_meridians": ExplorationStateScript.SPRING_WARM_POSITION,
			"breakthrough": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION,
		},
		"current_action": _current_first_breath_action(),
		"completed": completed,
		"completed_actions": completed.duplicate(),
		"rule_authority": false,
	}


func depth_for_y(feet_y: float) -> int:
	var height := maxf(get_rect().size.y, 1.0)
	return 10 + clampi(int(round(feet_y / height * 50.0)), 0, 50)


func occlusion_contract() -> Dictionary:
	var minimum_depth := 60
	var maximum_depth := 10
	var ids: Array[String] = []
	var depths := {}
	var profiles := {}
	var asset_backed_count := 0
	for occluder in occluder_nodes:
		var contract: Dictionary = occluder.visual_contract()
		minimum_depth = mini(minimum_depth, int(contract["z_index"]))
		maximum_depth = maxi(maximum_depth, int(contract["z_index"]))
		ids.append(str(contract["id"]))
		depths[contract["id"]] = contract["z_index"]
		profiles[contract["id"]] = contract["profile_id"]
		if bool(contract["asset_backed"]):
			asset_backed_count += 1
	return {
		"count": occluder_nodes.size(),
		"ids": ids,
		"depths": depths,
		"profiles": profiles,
		"asset_backed_count": asset_backed_count,
		"minimum_depth": minimum_depth,
		"maximum_depth": maximum_depth,
		"player_depth": player_sprite.z_index,
		"companion_depth": companion_sprite.z_index,
		"ferryman_depth": ferryman_sprite.z_index,
		"herbkeeper_depth": herbkeeper_sprite.z_index,
		"patrol_depth": patrol_sprite.z_index,
		"map_depth_ceiling": 60,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_sync_actor_visuals()


func _process(delta: float) -> void:
	if feedback_remaining <= 0.0:
		return
	feedback_remaining = maxf(0.0, feedback_remaining - delta)
	feedback_phase += delta
	if feedback_remaining <= 0.0:
		feedback_text = ""
	queue_redraw()


func _sync_actor_visuals() -> void:
	if (
		not is_node_ready()
		or not is_instance_valid(player_sprite)
		or not is_instance_valid(companion_sprite)
		or not is_instance_valid(ferryman_sprite)
		or not is_instance_valid(herbkeeper_sprite)
		or not is_instance_valid(patrol_sprite)
		or not is_instance_valid(map_detail_layer)
	):
		return
	var size := get_rect().size
	_sync_occluders(size)
	ferry_ground.visible = phase_id == "riverbank"
	path_ground.visible = phase_id == "mountain_path"
	map_detail_layer.set_context(phase_id)
	battle_enemy_sprite.visible = phase_id == "battle"
	path_rock_enemy_sprite.visible = phase_id == "mountain_path"
	path_moss_enemy_sprite.visible = phase_id == "mountain_path"
	path_puppet_enemy_sprite.visible = phase_id == "mountain_path"
	ferryman_sprite.visible = phase_id == "riverbank"
	herbkeeper_sprite.visible = phase_id == "riverbank"
	patrol_sprite.visible = phase_id == "riverbank" and patrol_active
	battle_enemy_sprite.set_enemy_id(enemy_id)
	battle_enemy_sprite.position = Vector2(size.x * 0.66, size.y * 0.49).round()
	path_rock_enemy_sprite.position = Vector2(size.x * 0.76, size.y * 0.36).round()
	path_moss_enemy_sprite.position = Vector2(size.x * 0.54, size.y * 0.52).round()
	path_puppet_enemy_sprite.position = Vector2(size.x * 0.81, size.y * 0.31).round()
	ferryman_sprite.position = Vector2(size.x * 0.41, size.y * 0.66).round()
	ferryman_sprite.set_motion(Vector2.RIGHT, false)
	herbkeeper_sprite.position = Vector2(size.x * 0.75, size.y * 0.66).round()
	herbkeeper_sprite.set_motion(Vector2.LEFT, false)
	patrol_sprite.position = Vector2(size.x * patrol_position.x, size.y * patrol_position.y).round()
	patrol_sprite.set_motion(patrol_motion, patrol_moving)
	player_sprite.visible = true
	companion_sprite.visible = true
	match phase_id:
		"riverbank":
			var protagonist_feet := Vector2(player_position.x * size.x, player_position.y * size.y).round()
			player_sprite.position = protagonist_feet
			companion_sprite.position = (Vector2(companion_position.x * size.x, companion_position.y * size.y) if talked_to_companion else Vector2(size.x * 0.53, size.y * 0.51)).round()
			set_player_motion(player_motion)
		"mountain_path":
			var path_feet := Vector2(player_position.x * size.x, player_position.y * size.y).round()
			player_sprite.position = path_feet
			companion_sprite.position = Vector2(companion_position.x * size.x, companion_position.y * size.y).round()
			set_player_motion(player_motion)
		"spring":
			player_sprite.position = Vector2(player_position.x * size.x, player_position.y * size.y).round()
			companion_sprite.position = Vector2(size.x * 0.72, size.y * 0.65).round()
			player_sprite.set_motion(player_motion, not player_motion.is_zero_approx())
			companion_sprite.set_motion(Vector2.LEFT, false)
		"battle":
			player_sprite.position = Vector2(size.x * 0.43, size.y * 0.58).round()
			companion_sprite.position = Vector2(size.x * 0.36, size.y * 0.54).round()
			player_sprite.set_motion(Vector2.RIGHT, false)
			companion_sprite.set_motion(Vector2.RIGHT, false)
		_:
			player_sprite.position = Vector2(size.x * 0.47, size.y * 0.66).round()
			companion_sprite.position = Vector2(size.x * 0.69, size.y * 0.65).round()
			player_sprite.set_motion(Vector2.RIGHT, false)
			companion_sprite.set_motion(Vector2.LEFT, false)
	_apply_depth_sort()


func _sync_companion_trail() -> void:
	if not talked_to_companion or phase_id not in ["riverbank", "mountain_path"]:
		companion_motion = Vector2.ZERO
		return
	var previous := companion_position
	var rest_offset := Vector2(0.042, 0.011) if phase_id == "riverbank" else Vector2(-0.040, 0.012)
	if companion_trail_needs_reset:
		companion_position = companion_trail.reset(phase_id, player_position, rest_offset)
		companion_trail_needs_reset = false
	else:
		companion_position = companion_trail.record(phase_id, player_position, rest_offset)
	companion_motion = companion_position - previous


func _apply_depth_sort() -> void:
	player_sprite.z_index = depth_for_y(player_sprite.position.y)
	companion_sprite.z_index = depth_for_y(companion_sprite.position.y)
	battle_enemy_sprite.z_index = depth_for_y(battle_enemy_sprite.position.y)
	path_rock_enemy_sprite.z_index = depth_for_y(path_rock_enemy_sprite.position.y)
	path_moss_enemy_sprite.z_index = depth_for_y(path_moss_enemy_sprite.position.y)
	path_puppet_enemy_sprite.z_index = depth_for_y(path_puppet_enemy_sprite.position.y)
	ferryman_sprite.z_index = depth_for_y(ferryman_sprite.position.y)
	herbkeeper_sprite.z_index = depth_for_y(herbkeeper_sprite.position.y)
	patrol_sprite.z_index = depth_for_y(patrol_sprite.position.y)


func _sync_occluders(size: Vector2) -> void:
	var next_signature := "%s:%d:%d" % [phase_id, int(size.x), int(size.y)]
	if next_signature == occluder_signature:
		return
	occluder_signature = next_signature
	for occluder in occluder_nodes:
		occluder.free()
	occluder_nodes.clear()
	match phase_id:
		"riverbank":
			_add_roof_occluder("ferry_roof_0", Vector2(size.x * 0.51, size.y * 0.20), Vector2(148, 92), "ferry_house_rust")
			_add_roof_occluder("ferry_roof_1", Vector2(size.x * 0.72, size.y * 0.35), Vector2(156, 96), "ferry_house_ochre")
			_add_roof_occluder("ferry_roof_2", Vector2(size.x * 0.82, size.y * 0.58), Vector2(164, 92), "ferry_house_teal")
			for index in range(FERRY_TREE_POSITIONS.size()):
				_add_tree_occluder("ferry_tree_%d" % index, FERRY_TREE_POSITIONS[index] * size)
		"mountain_path":
			for index in range(PATH_TREE_POSITIONS.size()):
				_add_tree_occluder("path_tree_%d" % index, PATH_TREE_POSITIONS[index] * size)
		"battle":
			for index in range(BATTLE_TREE_POSITIONS.size()):
				_add_tree_occluder("battle_tree_%d" % index, BATTLE_TREE_POSITIONS[index] * size)


func _add_tree_occluder(occluder_id: String, center: Vector2) -> void:
	var feet := center + Vector2(0, 46)
	_add_occluder(occluder_id, "tree", "tree_celadon", feet, feet.y)


func _add_roof_occluder(occluder_id: String, top_left: Vector2, dimensions: Vector2, profile_id: String) -> void:
	var feet := top_left + Vector2(dimensions.x * 0.5, dimensions.y)
	_add_occluder(occluder_id, "roof", profile_id, feet, feet.y)


func _add_occluder(
	occluder_id: String,
	kind: String,
	profile_id: String,
	occluder_position: Vector2,
	feet_y: float
) -> void:
	var occluder = MapOccluderScript.new()
	if not occluder.configure(occluder_id, kind, profile_id, occluder_position, feet_y, depth_for_y(feet_y)):
		occluder.free()
		return
	add_child(occluder)
	occluder_nodes.append(occluder)


func _draw() -> void:
	match phase_id:
		"riverbank":
			_draw_riverbank()
		"mountain_path":
			_draw_mountain_path()
		"battle":
			_draw_battle_path()
		"spring":
			_draw_spring_chamber(false)
		_:
			_draw_spring_chamber(true)
	_draw_battle_feedback()
	_draw_vignette()


func _draw_riverbank() -> void:
	var size := get_rect().size
	if not is_instance_valid(ferry_ground) or not ferry_ground.visible:
		draw_rect(Rect2(Vector2.ZERO, size), Color("b7cf9f"))
		_draw_water(Rect2(0, 0, size.x * 0.39, size.y))

		var bank := PackedVector2Array([
			Vector2(size.x * 0.34, 0),
			Vector2(size.x * 0.45, 0),
			Vector2(size.x * 0.39, size.y),
			Vector2(size.x * 0.29, size.y),
		])
		draw_colored_polygon(bank, Color("d7cba5"))

		_draw_path(PackedVector2Array([
			Vector2(size.x * 0.36, size.y * 0.84),
			Vector2(size.x * 0.49, size.y * 0.60),
			Vector2(size.x * 0.61, size.y * 0.48),
			Vector2(size.x * 0.81, size.y * 0.23),
		]), 58.0)
		_draw_path(PackedVector2Array([
			Vector2(size.x * 0.47, size.y * 0.60),
			Vector2(size.x * 0.68, size.y * 0.72),
			Vector2(size.x * 0.93, size.y * 0.67),
		]), 48.0)

	_draw_landmark("ferry_dock", Vector2(size.x * 0.21, size.y * 0.58))
	_draw_landmark("ferry_boat_repair", BOAT_REPAIR_VISUAL_FEET * size)
	_draw_landmark("ferry_drying_rack", DRYING_RACK_VISUAL_FEET * size)

	for index in range(10):
		var plant := Vector2(size.x * 0.63 + float(index % 5) * 28.0, size.y * 0.57 + float(index / 5) * 28.0)
		_draw_plant(plant, not gathered_moonleaf, gathered_moonleaf and moonleaf_method == "cutting")

	_draw_landmark("spring_gate", Vector2(size.x * 0.88, size.y * 0.18 + 25.0))
	_draw_ferry_watermark(Vector2(size.x * 0.43, size.y * 0.42), discoveries.has("ferry_watermark"))
	_draw_ferryman_water_gauge(Vector2(size.x * 0.385, size.y * 0.66), ferryman_response)
	if basket_response == "return":
		_draw_abandoned_basket(Vector2(size.x * 0.79, size.y * 0.68), true, true)
	if not discoveries.has("ferry_watermark"):
		_draw_interaction_marker(Vector2(size.x * 0.43, size.y * 0.42), nearby_action == "inspect_ferry_watermark")
	if not talked_to_companion:
		_draw_interaction_marker(Vector2(size.x * 0.53, size.y * 0.51), nearby_action == "talk_to_companion")
	if ferryman_response == "unanswered":
		_draw_interaction_marker(Vector2(size.x * 0.41, size.y * 0.66), nearby_action == "talk_to_ferryman")
	if discoveries.has("abandoned_basket") and basket_response == "unanswered":
		_draw_interaction_marker(Vector2(size.x * 0.75, size.y * 0.66), nearby_action == "talk_to_herbkeeper")
	if patrol_active and patrol_response == "unanswered":
		_draw_interaction_marker(patrol_position * size, nearby_action == "talk_to_patrol_runner")
	if not gathered_moonleaf:
		_draw_interaction_marker(Vector2(size.x * 0.69, size.y * 0.62), nearby_action == "gather_moonleaf")
	_draw_interaction_marker(ExplorationStateScript.BOAT_REPAIR_POSITION * size, nearby_action == "inspect_boat_repair")
	_draw_interaction_marker(ExplorationStateScript.DRYING_RACK_POSITION * size, nearby_action == "inspect_drying_rack")
	_draw_interaction_marker(Vector2(size.x * 0.88, size.y * 0.18), nearby_action == "enter_spring")

func _draw_battle_path() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("8fb881"))
	draw_rect(Rect2(0, 0, size.x * 0.19, size.y), RIVER_JADE.darkened(0.08))

	for index in range(13):
		var stream_y := 18.0 + float(index) * 42.0
		draw_line(Vector2(0, stream_y), Vector2(size.x * 0.18, stream_y + 12.0), Color("b9ded4"), 2.0)

	_draw_path(PackedVector2Array([
		Vector2(size.x * 0.18, size.y * 0.79),
		Vector2(size.x * 0.42, size.y * 0.67),
		Vector2(size.x * 0.62, size.y * 0.47),
		Vector2(size.x * 0.86, size.y * 0.29),
	]), 118.0)
	_draw_path(PackedVector2Array([
		Vector2(size.x * 0.24, size.y * 0.42),
		Vector2(size.x * 0.40, size.y * 0.20),
	]), 54.0)

	for normalized_position in BATTLE_ROCK_POSITIONS:
		_draw_landmark("mountain_rock", normalized_position * size + Vector2(0, 42))

	_draw_landmark("spring_cave", Vector2(size.x * 0.86 + 63.0, size.y * 0.16 + 88.0))
	if lamp_turns > 0:
		_draw_spring_lamp(Vector2(size.x * 0.48, size.y * 0.62))
	draw_line(Vector2(size.x * 0.40, size.y * 0.49), Vector2(size.x * 0.64, size.y * 0.40), SPIRIT_GOLD, 3.0)
	draw_circle(Vector2(size.x * 0.64, size.y * 0.40), 6.0, SPIRIT_GOLD, false, 2.0)


func _draw_mountain_path() -> void:
	var size := get_rect().size
	for normalized_position in PATH_ROCK_POSITIONS:
		_draw_landmark("mountain_rock", normalized_position * size + Vector2(0, 34))
	_draw_landmark("spring_cave", Vector2(size.x * 0.84 + 64.0, size.y * 0.12 + 90.0))
	_draw_landmark("spring_gate", Vector2(size.x * 0.10, size.y * 0.68 + 25.0))
	_draw_landmark("path_rain_shelter", RAIN_SHELTER_VISUAL_FEET * size)
	_draw_spring_seam(Vector2(size.x * 0.40, size.y * 0.30), discoveries.has("spring_seam"))
	if basket_response != "return":
		_draw_abandoned_basket(Vector2(size.x * 0.68, size.y * 0.60), discoveries.has("abandoned_basket"), basket_response == "trail")
	_draw_enemy_trace(ROCK_SPOOR_POSITION * size, "rock", enemy_intel.has("rock_armor_young"))
	_draw_enemy_trace(MOSS_SPOOR_POSITION * size, "moss", enemy_intel.has("spring_moss_shell"))
	_draw_enemy_trace(PUPPET_SPOOR_POSITION * size, "puppet", enemy_intel.has("unbalanced_stone_puppet"))
	_draw_interaction_marker(Vector2(size.x * 0.10, size.y * 0.68), nearby_action == "return_to_ferry")
	_draw_interaction_marker(Vector2(size.x * 0.43, size.y * 0.57), nearby_action == "inspect_path_marker")
	_draw_interaction_marker(ExplorationStateScript.PATH_RAIN_SHELTER_POSITION * size, nearby_action == "inspect_rain_shelter")
	if not discoveries.has("spring_seam"):
		_draw_interaction_marker(Vector2(size.x * 0.40, size.y * 0.30), nearby_action == "inspect_spring_seam")
	if not discoveries.has("abandoned_basket"):
		_draw_interaction_marker(Vector2(size.x * 0.68, size.y * 0.60), nearby_action == "inspect_abandoned_basket")
	if not enemy_intel.has("rock_armor_young") and nearby_action == "inspect_rock_spoor":
		_draw_interaction_marker(ROCK_SPOOR_POSITION * size, true)
	if not enemy_intel.has("spring_moss_shell") and nearby_action == "inspect_moss_spoor":
		_draw_interaction_marker(MOSS_SPOOR_POSITION * size, true)
	if not enemy_intel.has("unbalanced_stone_puppet") and nearby_action == "inspect_puppet_spoor":
		_draw_interaction_marker(PUPPET_SPOOR_POSITION * size, true)
	_draw_interaction_marker(Vector2(size.x * 0.56, size.y * 0.48), nearby_action == "approach_moss_shell")
	_draw_interaction_marker(Vector2(size.x * 0.73, size.y * 0.34), nearby_action == "approach_enemy")
	_draw_interaction_marker(Vector2(size.x * 0.80, size.y * 0.25), nearby_action == "approach_stone_puppet")
	_draw_interaction_marker(Vector2(size.x * 0.86, size.y * 0.18), nearby_action == "bypass_enemy")
	draw_circle(Vector2(size.x * 0.73, size.y * 0.34), 62.0, Color(0.78, 0.35, 0.24, 0.18), false, 3.0)


func _draw_spring_chamber(completed: bool) -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), COOL_SHADOW.darkened(0.12))

	var opening := PackedVector2Array([
		Vector2(size.x * 0.12, size.y * 0.08),
		Vector2(size.x * 0.88, size.y * 0.08),
		Vector2(size.x * 0.96, size.y * 0.72),
		Vector2(size.x * 0.04, size.y * 0.72),
	])
	draw_colored_polygon(opening, WARM_PAPER if completed else Color("b9d8c7"))
	if completed:
		draw_circle(Vector2(size.x * 0.54, size.y * 0.12), 82.0, Color(1.0, 0.91, 0.65, 0.22))
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x * 0.47, 0),
			Vector2(size.x * 0.61, 0),
			Vector2(size.x * 0.54, size.y * 0.38),
		]), Color(DAWN_PEACH.r, DAWN_PEACH.g, DAWN_PEACH.b, 0.16))

	var layer_colors: Array[Color] = [Color("9abfae"), Color("79a596"), Color("5f887d"), Color("486d68")]
	for index in range(4):
		var baseline := size.y * (0.31 + float(index) * 0.09)
		var points := PackedVector2Array([Vector2(size.x * 0.04, size.y * 0.72)])
		for column in range(8):
			var x := size.x * 0.05 + float(column) * size.x * 0.13
			var peak := baseline - (42.0 + float((column + index) % 3) * 34.0)
			points.append(Vector2(x, baseline))
			points.append(Vector2(x + size.x * 0.065, peak))
		points.append(Vector2(size.x * 0.96, size.y * 0.72))
		draw_colored_polygon(points, layer_colors[index])

	draw_circle(Vector2(size.x * 0.53, size.y * 0.62), 82.0, RIVER_JADE.lightened(0.25))
	draw_circle(Vector2(size.x * 0.53, size.y * 0.62), 68.0, RIVER_JADE)
	var listen_position: Vector2 = ExplorationStateScript.SPRING_LISTEN_POSITION * size
	var warm_position: Vector2 = ExplorationStateScript.SPRING_WARM_POSITION * size
	var breakthrough_position: Vector2 = ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION * size
	var completed_actions := _completed_first_breath_actions()
	_draw_listening_spring(listen_position, completed_actions.has("listen_to_spring"))
	_draw_warming_stone(warm_position, completed_actions.has("warm_meridians"))
	_draw_sitting_vein(breakthrough_position, completed_actions.has("breakthrough"))

	var energy_end := Vector2(size.x * 0.54, size.y * 0.16)
	var energy_start := Vector2(size.x * 0.48, size.y * 0.59)
	if completed_actions.has("listen_to_spring"):
		draw_line(energy_start, breakthrough_position, Color(SPIRIT_GOLD.r, SPIRIT_GOLD.g, SPIRIT_GOLD.b, 0.56), 3.0)
	if completed_actions.has("warm_meridians"):
		draw_line(energy_start, breakthrough_position, SPIRIT_GOLD, 4.0)
		draw_line(breakthrough_position, energy_end, Color(SPIRIT_GOLD.r, SPIRIT_GOLD.g, SPIRIT_GOLD.b, 0.48), 3.0)
	if completed:
		draw_line(breakthrough_position, energy_end, SPIRIT_GOLD, 4.0)
		for index in range(5):
			var point := energy_start.lerp(energy_end, float(index) / 4.0)
			draw_circle(point, 5.0, SPIRIT_GOLD)
	_draw_first_breath_markers(size)


func _draw_listening_spring(center: Vector2, listened: bool) -> void:
	var ripple_color := SPIRIT_GOLD if listened else Color("b9ded4")
	for index in range(3):
		draw_arc(center + Vector2(13.0, 0.0), 10.0 + float(index) * 8.0, -0.82, 0.82, 16, ripple_color, 2.5)
	if listened:
		draw_circle(center + Vector2(8.0, 0.0), 3.5, SPIRIT_GOLD)


func _draw_warming_stone(center: Vector2, warmed: bool) -> void:
	var stone_color := Color("8aa89d") if warmed else COOL_SHADOW.lightened(0.32)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-31.0, 10.0),
		center + Vector2(-25.0, -8.0),
		center + Vector2(25.0, -8.0),
		center + Vector2(31.0, 10.0),
	]), stone_color)
	draw_line(center + Vector2(-31.0, 10.0), center + Vector2(31.0, 10.0), COOL_SHADOW, 3.0)
	var leaf_color := DAWN_PEACH if warmed else FRESH_CELADON
	draw_arc(center + Vector2(-7.0, -8.0), 9.0, -2.7, 0.15, 14, leaf_color, 3.0)
	draw_arc(center + Vector2(8.0, -8.0), 9.0, PI - 0.15, TAU - 0.45, 14, leaf_color, 3.0)
	draw_line(center + Vector2(0.0, -7.0), center + Vector2(0.0, 2.0), leaf_color, 2.0)


func _draw_sitting_vein(center: Vector2, awakened: bool) -> void:
	var vein_color := SPIRIT_GOLD if awakened else Color("7ba094")
	draw_line(center + Vector2(0.0, 20.0), center + Vector2(0.0, -22.0), vein_color, 4.0)
	draw_line(center + Vector2(0.0, -7.0), center + Vector2(-24.0, -28.0), vein_color, 3.0)
	draw_line(center + Vector2(0.0, -13.0), center + Vector2(22.0, -34.0), vein_color, 3.0)
	draw_arc(center + Vector2(0.0, 17.0), 22.0, PI, TAU, 18, COOL_SHADOW.lightened(0.18), 4.0)


func _draw_first_breath_markers(size: Vector2) -> void:
	var positions := {
		"listen_to_spring": ExplorationStateScript.SPRING_LISTEN_POSITION,
		"warm_meridians": ExplorationStateScript.SPRING_WARM_POSITION,
		"breakthrough": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION,
	}
	var current_action := _current_first_breath_action()
	var completed_actions := _completed_first_breath_actions()
	for action_id in ["listen_to_spring", "warm_meridians", "breakthrough"]:
		var center: Vector2 = positions[action_id] * size
		if completed_actions.has(action_id):
			_draw_first_breath_completion_mark(center)
		elif action_id == current_action:
			_draw_interaction_marker(center, nearby_action == action_id)
		elif nearby_action == action_id:
			_draw_interaction_marker(center, true)


func _draw_first_breath_completion_mark(center: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -31.0),
		center + Vector2(6.0, -25.0),
		center + Vector2(0.0, -19.0),
		center + Vector2(-6.0, -25.0),
	]), SPIRIT_GOLD)
	draw_circle(center + Vector2(0.0, -25.0), 11.0, Color(SPIRIT_GOLD.r, SPIRIT_GOLD.g, SPIRIT_GOLD.b, 0.24), false, 2.0)


func _current_first_breath_action() -> String:
	return {
		"unstarted": "listen_to_spring",
		"listened": "warm_meridians",
		"warmed": "breakthrough",
	}.get(first_breath_stage, "")


func _completed_first_breath_actions() -> Array[String]:
	var result: Array[String] = []
	if first_breath_stage in ["listened", "warmed", "completed"]:
		result.append("listen_to_spring")
	if first_breath_stage in ["warmed", "completed"]:
		result.append("warm_meridians")
	if first_breath_stage == "completed":
		result.append("breakthrough")
	return result

func _draw_water(area: Rect2) -> void:
	draw_rect(area, RIVER_JADE)
	for index in range(16):
		var y := area.position.y + 18.0 + float(index) * 34.0
		var inset := 16.0 + float(index % 3) * 12.0
		draw_line(Vector2(area.position.x + inset, y), Vector2(area.end.x - inset, y + 8.0), Color("a7d7cc"), 3.0)
	for glint in [Vector2(110, 92), Vector2(250, 165), Vector2(150, 310), Vector2(315, 388), Vector2(88, 475)]:
		draw_line(glint - Vector2(10, 0), glint + Vector2(10, 0), WARM_PAPER, 2.0)


func _draw_path(points: PackedVector2Array, width: float) -> void:
	draw_polyline(points, Color("d8cca5"), width, false)
	draw_polyline(points, Color("b6aa84"), 3.0, false)


func _draw_landmark(profile_id: String, feet_position: Vector2) -> bool:
	if not LANDMARK_PROFILE_COLUMNS.has(profile_id):
		return false
	var frame_column := int(LANDMARK_PROFILE_COLUMNS[profile_id])
	var destination := Rect2(
		(feet_position - Vector2(float(LANDMARK_FRAME_SIZE.x) * 0.5, float(LANDMARK_FRAME_SIZE.y))).round(),
		Vector2(LANDMARK_FRAME_SIZE)
	)
	var source := Rect2(
		Vector2(float(frame_column * LANDMARK_FRAME_SIZE.x), 0.0),
		Vector2(LANDMARK_FRAME_SIZE)
	)
	draw_texture_rect_region(LANDMARK_ATLAS, destination, source, Color.WHITE, false, true)
	return true


func _draw_plant(position: Vector2, available: bool, regrowing: bool) -> void:
	if regrowing:
		draw_line(position + Vector2(0, 12), position + Vector2(0, 1), Color("739b70"), 3.0)
		draw_circle(position + Vector2(-4, 3), 4.0, Color("a9cd84"))
		draw_circle(position + Vector2(5, 6), 3.0, Color("8ebb83"))
		return
	var color := Color("a9cd84") if available else Color("72836b")
	draw_line(position + Vector2(0, 12), position - Vector2(0, 12), color.darkened(0.2), 3.0)
	draw_circle(position + Vector2(-6, -6), 6.0, color)
	draw_circle(position + Vector2(7, -2), 6.0, color)


func _draw_spring_lamp(feet: Vector2) -> void:
	draw_rect(Rect2(feet + Vector2(-8, -28), Vector2(16, 26)), COOL_SHADOW.lightened(0.18))
	draw_colored_polygon(PackedVector2Array([
		feet + Vector2(-13, -29),
		feet + Vector2(0, -39),
		feet + Vector2(13, -29),
	]), SPIRIT_GOLD.darkened(0.16))
	draw_circle(feet + Vector2(0, -17), 7.0, Color(0.70, 0.94, 0.86, 0.82))
	draw_circle(feet + Vector2(0, -17), 19.0, Color(0.70, 0.94, 0.86, 0.18), false, 3.0)


func _draw_ferry_watermark(center: Vector2, discovered: bool) -> void:
	var stone_color := Color("849088") if discovered else Color("9da49a")
	draw_rect(Rect2(center + Vector2(-12, -21), Vector2(24, 34)), stone_color)
	for index in range(3):
		var width := 7.0 + float(index) * 3.0
		var y := center.y - 12.0 + float(index) * 8.0
		draw_line(Vector2(center.x - width, y), Vector2(center.x + width, y), RIVER_JADE.darkened(0.18), 2.0)
	if discovered:
		draw_circle(center + Vector2(0, -25), 4.0, FRESH_CELADON)


func _draw_ferryman_water_gauge(feet: Vector2, response: String) -> void:
	var lean := Vector2.ZERO if response == "repair" else Vector2(9, 0)
	var base := feet + Vector2(-8, 0)
	draw_line(base, base + Vector2(lean.x, -52), Color("7a6545"), 6.0)
	for index in range(4):
		var ratio := float(index + 1) / 5.0
		var mark := base.lerp(base + Vector2(lean.x, -52), ratio)
		draw_line(mark + Vector2(-5, 0), mark + Vector2(5, 0), WARM_PAPER.darkened(0.48), 2.0)
	if response == "repair":
		draw_circle(base + Vector2(0, -56), 4.0, FRESH_CELADON)
	elif response == "record":
		var tag := base + Vector2(lean.x + 8, -35)
		draw_rect(Rect2(tag, Vector2(17, 13)), WARM_PAPER)
		draw_line(tag + Vector2(4, 4), tag + Vector2(13, 4), COOL_SHADOW, 1.0)
		draw_line(tag + Vector2(4, 8), tag + Vector2(11, 8), COOL_SHADOW, 1.0)


func _draw_spring_seam(center: Vector2, discovered: bool) -> void:
	var vein_color := Color("b9ded4") if discovered else Color("d9f0dc")
	draw_line(center + Vector2(-24, 12), center + Vector2(0, -10), vein_color, 4.0)
	draw_line(center + Vector2(0, -10), center + Vector2(23, -20), vein_color, 3.0)
	draw_line(center + Vector2(0, -10), center + Vector2(18, 14), vein_color.darkened(0.08), 2.0)


func _draw_abandoned_basket(center: Vector2, discovered: bool, repaired: bool = false) -> void:
	var basket_color := Color("927a52") if discovered else Color("b28c55")
	draw_rect(Rect2(center + Vector2(-18, -10), Vector2(36, 22)), basket_color)
	for offset in [-10.0, 0.0, 10.0]:
		draw_line(center + Vector2(offset, -9), center + Vector2(offset, 11), Color("d0b477"), 2.0)
	draw_arc(center + Vector2(0, -10), 15.0, PI, TAU, 12, basket_color.darkened(0.2), 3.0)
	if discovered:
		draw_line(center + Vector2(10, -18), center + Vector2(21, -27), FRESH_CELADON.darkened(0.15), 3.0)
	if repaired:
		draw_line(center + Vector2(-16, -5), center + Vector2(16, 7), SPIRIT_GOLD.darkened(0.18), 2.0)
		draw_circle(center + Vector2(0, -27), 4.0, FRESH_CELADON)


func _draw_enemy_trace(center: Vector2, trace_kind: String, studied: bool) -> void:
	var trace_color := COOL_SHADOW.lightened(0.18) if studied else WARM_RUST.darkened(0.14)
	match trace_kind:
		"rock":
			for offset in [-10.0, 0.0, 10.0]:
				draw_line(center + Vector2(offset - 7.0, 10.0), center + Vector2(offset + 5.0, -10.0), trace_color, 3.0)
		"moss":
			draw_arc(center, 13.0, 0.25, PI + 0.45, 16, trace_color, 3.0)
			draw_circle(center + Vector2(-13.0, 9.0), 3.0, trace_color)
			draw_circle(center + Vector2(14.0, -7.0), 2.5, trace_color)
		"puppet":
			draw_rect(Rect2(center + Vector2(-17.0, -8.0), Vector2(14.0, 16.0)), trace_color, false, 3.0)
			draw_rect(Rect2(center + Vector2(4.0, -8.0), Vector2(14.0, 16.0)), trace_color, false, 3.0)
	if studied:
		draw_circle(center + Vector2(0.0, -19.0), 4.0, SPIRIT_GOLD)


func _draw_interaction_marker(center: Vector2, active: bool) -> void:
	var color := SPIRIT_GOLD if active else Color(0.95, 0.90, 0.70, 0.64)
	draw_circle(center, 24.0 if active else 18.0, color, false, 3.0 if active else 2.0)
	if active:
		draw_circle(center, 31.0, Color(color.r, color.g, color.b, 0.28), false, 2.0)


func _draw_vignette() -> void:
	var size := get_rect().size
	var edge := Color(0.08, 0.12, 0.11, 0.17)
	draw_rect(Rect2(0, 0, size.x, 14), edge)
	draw_rect(Rect2(0, size.y - 14, size.x, 14), edge)
	draw_rect(Rect2(0, 0, 14, size.y), edge)
	draw_rect(Rect2(size.x - 14, 0, 14, size.y), edge)


func _draw_battle_feedback() -> void:
	if feedback_text.is_empty() or feedback_duration <= 0.0:
		return
	var size := get_rect().size
	var progress := feedback_remaining / feedback_duration
	var pulse := 1.0
	if feedback_motion_enabled:
		pulse = 0.88 + sin(feedback_phase * 18.0) * 0.12
	var center := Vector2(size.x * 0.54, size.y * 0.20)
	var panel_size := Vector2(210, 54) * pulse
	var panel := Rect2(center - panel_size * 0.5, panel_size)
	draw_rect(panel, Color(0.15, 0.19, 0.18, 0.72 * progress), true)
	draw_rect(panel, Color(0.89, 0.76, 0.43, 0.88 * progress), false, 3.0)
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
	draw_string(
		font,
		center + Vector2(-text_width * 0.5, 8),
		feedback_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		23,
		Color(0.95, 0.90, 0.80, progress)
	)
