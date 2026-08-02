extends RefCounted
class_name ExplorationState

const GATHER_MOONLEAF := "gather_moonleaf"
const ENTER_SPRING := "enter_spring"
const TALK_TO_COMPANION := "talk_to_companion"
const DEFAULT_MAP_ID := "zhaohe_ferry"

# Positions are normalized world coordinates. Rendering resolution never changes
# traversal, collision, or interaction outcomes.
const START_POSITION := Vector2(0.47, 0.51)
const MOONLEAF_POSITION := Vector2(0.69, 0.62)
const SPRING_GATE_POSITION := Vector2(0.88, 0.18)
const COMPANION_POSITION := Vector2(0.53, 0.51)
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


func interaction_action(gathered_moonleaf: bool, talked_to_companion: bool = false) -> String:
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
	if not _is_walkable(candidate):
		return false
	map_id = str(snapshot_data["map_id"])
	player_position = candidate
	return true


static func supports_map_id(candidate: Variant) -> bool:
	return typeof(candidate) == TYPE_STRING and candidate == DEFAULT_MAP_ID


func is_walkable(position: Vector2) -> bool:
	return _is_walkable(position)


func _move_axis(offset: Vector2) -> void:
	if offset.is_zero_approx():
		return
	var candidate := player_position + offset
	if _is_walkable(candidate):
		player_position = candidate


func _is_walkable(position: Vector2) -> bool:
	var safe_bounds := WALK_BOUNDS.grow_individual(
		-PLAYER_EXTENTS.x,
		-PLAYER_EXTENTS.y,
		-PLAYER_EXTENTS.x,
		-PLAYER_EXTENTS.y
	)
	if not safe_bounds.has_point(position):
		return false
	for obstacle in OBSTACLES:
		if obstacle.grow_individual(
			PLAYER_EXTENTS.x,
			PLAYER_EXTENTS.y,
			PLAYER_EXTENTS.x,
			PLAYER_EXTENTS.y
		).has_point(position):
			return false
	return true
