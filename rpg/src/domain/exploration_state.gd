extends RefCounted
class_name ExplorationState

const GATHER_MOONLEAF := "gather_moonleaf"
const ENTER_SPRING := "enter_spring"
const TALK_TO_COMPANION := "talk_to_companion"
const TALK_TO_FERRYMAN := "talk_to_ferryman"
const TALK_TO_HERBKEEPER := "talk_to_herbkeeper"
const INSPECT_PATH_MARKER := "inspect_path_marker"
const INSPECT_FERRY_WATERMARK := "inspect_ferry_watermark"
const INSPECT_SPRING_SEAM := "inspect_spring_seam"
const INSPECT_ABANDONED_BASKET := "inspect_abandoned_basket"
const INSPECT_ROCK_SPOOR := "inspect_rock_spoor"
const INSPECT_MOSS_SPOOR := "inspect_moss_spoor"
const INSPECT_PUPPET_SPOOR := "inspect_puppet_spoor"
const APPROACH_ENEMY := "approach_enemy"
const APPROACH_MOSS_SHELL := "approach_moss_shell"
const APPROACH_STONE_PUPPET := "approach_stone_puppet"
const BYPASS_ENEMY := "bypass_enemy"
const RETURN_TO_FERRY := "return_to_ferry"
const LISTEN_TO_SPRING := "listen_to_spring"
const WARM_MERIDIANS := "warm_meridians"
const BREAKTHROUGH := "breakthrough"
const DEFAULT_MAP_ID := "zhaohe_ferry"
const MOUNTAIN_PATH_MAP_ID := "cangquan_path"
const CANGQUAN_SPRING_MAP_ID := "cangquan_spring"

# Positions are normalized world coordinates. Rendering resolution never changes
# traversal, collision, or interaction outcomes.
const START_POSITION := Vector2(0.47, 0.51)
const MOONLEAF_POSITION := Vector2(0.69, 0.62)
const SPRING_GATE_POSITION := Vector2(0.88, 0.18)
const COMPANION_POSITION := Vector2(0.53, 0.51)
const FERRY_WATERMARK_POSITION := Vector2(0.43, 0.42)
const FERRYMAN_POSITION := Vector2(0.41, 0.66)
const HERBKEEPER_POSITION := Vector2(0.75, 0.66)
const PATH_START_POSITION := Vector2(0.16, 0.68)
const PATH_RETURN_POSITION := Vector2(0.10, 0.68)
const PATH_MARKER_POSITION := Vector2(0.43, 0.57)
const PATH_SPRING_SEAM_POSITION := Vector2(0.40, 0.30)
const PATH_ABANDONED_BASKET_POSITION := Vector2(0.68, 0.60)
const PATH_ROCK_SPOOR_POSITION := Vector2(0.65, 0.22)
const PATH_MOSS_SPOOR_POSITION := Vector2(0.36, 0.43)
const PATH_PUPPET_SPOOR_POSITION := Vector2(0.91, 0.34)
const PATH_ENEMY_POSITION := Vector2(0.73, 0.34)
const PATH_MOSS_POSITION := Vector2(0.56, 0.48)
const PATH_PUPPET_POSITION := Vector2(0.80, 0.25)
const PATH_BYPASS_POSITION := Vector2(0.86, 0.18)
const PATH_RETREAT_POSITION := Vector2(0.64, 0.44)
const SPRING_START_POSITION := Vector2(0.7917, 0.625)
const SPRING_LISTEN_POSITION := Vector2(0.4306, 0.625)
const SPRING_WARM_POSITION := Vector2(0.7083, 0.525)
const SPRING_BREAKTHROUGH_POSITION := Vector2(0.5417, 0.325)
const MOVE_SPEED := 0.30
const MAX_STEP_SECONDS := 0.10
const INTERACTION_RADIUS := 0.065
const PLAYER_EXTENTS := Vector2(0.016, 0.030)
const WALK_BOUNDS := Rect2(0.36, 0.12, 0.61, 0.59)

const OBSTACLES: Array[Rect2] = [
	Rect2(0.50, 0.20, 0.15, 0.17),
	Rect2(0.71, 0.32, 0.16, 0.21),
	Rect2(0.81, 0.55, 0.17, 0.18),
]

const PATH_WALK_BOUNDS := Rect2(0.06, 0.10, 0.89, 0.65)
const PATH_OBSTACLES: Array[Rect2] = [
	Rect2(0.20, 0.12, 0.15, 0.20),
	Rect2(0.47, 0.18, 0.13, 0.20),
	Rect2(0.77, 0.48, 0.17, 0.20),
	Rect2(0.28, 0.68, 0.16, 0.17),
]
const SPRING_WALK_BOUNDS := Rect2(0.16, 0.18, 0.68, 0.50)
const SPRING_OBSTACLES: Array[Rect2] = [Rect2(0.46, 0.50, 0.14, 0.19)]

var player_position := START_POSITION
var map_id := DEFAULT_MAP_ID


func move(direction: Vector2, delta: float) -> Vector2:
	if direction.is_zero_approx() or delta <= 0.0:
		return player_position
	var normalized_direction := direction.normalized()
	var remaining := delta
	while remaining > 0.0:
		var step_seconds: float = minf(remaining, MAX_STEP_SECONDS)
		_move_axis(Vector2(normalized_direction.x * MOVE_SPEED * step_seconds, 0.0))
		_move_axis(Vector2(0.0, normalized_direction.y * MOVE_SPEED * step_seconds))
		remaining -= step_seconds
	return player_position


func interaction_action(
	gathered_moonleaf: bool,
	talked_to_companion: bool = false,
	discoveries: Array = [],
	ferryman_response: String = "unanswered",
	basket_response: String = "unanswered",
	enemy_intel: Array = []
) -> String:
	if map_id == CANGQUAN_SPRING_MAP_ID:
		if player_position.distance_to(SPRING_LISTEN_POSITION) <= INTERACTION_RADIUS:
			return LISTEN_TO_SPRING
		if player_position.distance_to(SPRING_WARM_POSITION) <= INTERACTION_RADIUS:
			return WARM_MERIDIANS
		if player_position.distance_to(SPRING_BREAKTHROUGH_POSITION) <= INTERACTION_RADIUS:
			return BREAKTHROUGH
		return ""
	if map_id == MOUNTAIN_PATH_MAP_ID:
		if player_position.distance_to(PATH_RETURN_POSITION) <= INTERACTION_RADIUS:
			return RETURN_TO_FERRY
		if player_position.distance_to(PATH_MARKER_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_PATH_MARKER
		if not discoveries.has("spring_seam") and player_position.distance_to(PATH_SPRING_SEAM_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_SPRING_SEAM
		if not discoveries.has("abandoned_basket") and player_position.distance_to(PATH_ABANDONED_BASKET_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_ABANDONED_BASKET
		if not enemy_intel.has("rock_armor_young") and player_position.distance_to(PATH_ROCK_SPOOR_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_ROCK_SPOOR
		if not enemy_intel.has("spring_moss_shell") and player_position.distance_to(PATH_MOSS_SPOOR_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_MOSS_SPOOR
		if not enemy_intel.has("unbalanced_stone_puppet") and player_position.distance_to(PATH_PUPPET_SPOOR_POSITION) <= INTERACTION_RADIUS:
			return INSPECT_PUPPET_SPOOR
		if player_position.distance_to(PATH_MOSS_POSITION) <= INTERACTION_RADIUS:
			return APPROACH_MOSS_SHELL
		if player_position.distance_to(PATH_ENEMY_POSITION) <= INTERACTION_RADIUS:
			return APPROACH_ENEMY
		if player_position.distance_to(PATH_PUPPET_POSITION) <= INTERACTION_RADIUS:
			return APPROACH_STONE_PUPPET
		if player_position.distance_to(PATH_BYPASS_POSITION) <= INTERACTION_RADIUS:
			return BYPASS_ENEMY
		return ""
	if not discoveries.has("ferry_watermark") and player_position.distance_to(FERRY_WATERMARK_POSITION) <= INTERACTION_RADIUS:
		return INSPECT_FERRY_WATERMARK
	if ferryman_response == "unanswered" and player_position.distance_to(FERRYMAN_POSITION) <= INTERACTION_RADIUS:
		return TALK_TO_FERRYMAN
	if discoveries.has("abandoned_basket") and basket_response == "unanswered" and player_position.distance_to(HERBKEEPER_POSITION) <= INTERACTION_RADIUS:
		return TALK_TO_HERBKEEPER
	if not talked_to_companion and player_position.distance_to(COMPANION_POSITION) <= INTERACTION_RADIUS:
		return TALK_TO_COMPANION
	if not gathered_moonleaf and player_position.distance_to(MOONLEAF_POSITION) <= INTERACTION_RADIUS:
		return GATHER_MOONLEAF
	if player_position.distance_to(SPRING_GATE_POSITION) <= INTERACTION_RADIUS:
		return ENTER_SPRING
	return ""


func snapshot() -> Dictionary:
	return {
		"map_id": map_id,
		"player_x": player_position.x,
		"player_y": player_position.y,
	}


func restore(snapshot_data: Dictionary) -> bool:
	if not snapshot_data.has("map_id") or not snapshot_data.has("player_x") or not snapshot_data.has("player_y"):
		return false
	if not supports_map_id(snapshot_data["map_id"]):
		return false
	var candidate := Vector2(float(snapshot_data["player_x"]), float(snapshot_data["player_y"]))
	var next_map_id := str(snapshot_data["map_id"])
	if not _is_walkable_on_map(candidate, next_map_id):
		return false
	map_id = next_map_id
	player_position = candidate
	return true


static func supports_map_id(candidate: Variant) -> bool:
	return typeof(candidate) == TYPE_STRING and candidate in [DEFAULT_MAP_ID, MOUNTAIN_PATH_MAP_ID, CANGQUAN_SPRING_MAP_ID]


func transition_to(next_map_id: String, spawn_position := Vector2(-1, -1)) -> bool:
	if not supports_map_id(next_map_id):
		return false
	var next_position: Vector2 = spawn_position
	if next_position.x < 0.0 or next_position.y < 0.0:
		match next_map_id:
			DEFAULT_MAP_ID:
				next_position = START_POSITION
			MOUNTAIN_PATH_MAP_ID:
				next_position = PATH_START_POSITION
			CANGQUAN_SPRING_MAP_ID:
				next_position = SPRING_START_POSITION
	if not _is_walkable_on_map(next_position, next_map_id):
		return false
	map_id = next_map_id
	player_position = next_position
	return true


func is_walkable(position: Vector2) -> bool:
	return _is_walkable(position)


func _move_axis(offset: Vector2) -> void:
	if offset.is_zero_approx():
		return
	var candidate := player_position + offset
	if _is_walkable(candidate):
		player_position = candidate


func _is_walkable(position: Vector2) -> bool:
	return _is_walkable_on_map(position, map_id)


func _is_walkable_on_map(position: Vector2, target_map_id: String) -> bool:
	var bounds := WALK_BOUNDS
	var obstacles := OBSTACLES
	match target_map_id:
		MOUNTAIN_PATH_MAP_ID:
			bounds = PATH_WALK_BOUNDS
			obstacles = PATH_OBSTACLES
		CANGQUAN_SPRING_MAP_ID:
			bounds = SPRING_WALK_BOUNDS
			obstacles = SPRING_OBSTACLES
	var safe_bounds := bounds.grow_individual(
		-PLAYER_EXTENTS.x,
		-PLAYER_EXTENTS.y,
		-PLAYER_EXTENTS.x,
		-PLAYER_EXTENTS.y
	)
	if not safe_bounds.has_point(position):
		return false
	for obstacle in obstacles:
		if obstacle.grow_individual(
			PLAYER_EXTENTS.x,
			PLAYER_EXTENTS.y,
			PLAYER_EXTENTS.x,
			PLAYER_EXTENTS.y
		).has_point(position):
			return false
	return true
