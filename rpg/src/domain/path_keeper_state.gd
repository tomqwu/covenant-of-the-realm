extends RefCounted
class_name PathKeeperState

const TALK_TO_PATH_KEEPER := "talk_to_path_keeper"

# Cen Wei walks a short, authored mountain-path route. Every segment is kept in
# normalized world coordinates so the domain remains independent from viewport
# size, scene nodes, and presentation frame rate.
const WAYPOINTS: Array[Vector2] = [
	Vector2(0.17, 0.61),
	Vector2(0.29, 0.57),
	Vector2(0.38, 0.64),
	Vector2(0.45, 0.64),
]
const START_POSITION := Vector2(0.17, 0.61)
const START_TARGET_INDEX := 1
const START_ROUTE_STEP := 1
const MOVE_SPEED := 0.075
const MAX_STEP_SECONDS := 0.10
const ENDPOINT_DWELL_SECONDS := 1.5
const WAYPOINT_DWELL_SECONDS := 0.25
const START_DWELL_SECONDS := ENDPOINT_DWELL_SECONDS
const INTERACTION_RADIUS := 0.065
const YIELD_ENTER_RADIUS := 0.080
const YIELD_EXIT_RADIUS := 0.100
const POSITION_EPSILON := 0.00001

var position := START_POSITION
var target_index := START_TARGET_INDEX
var route_step := START_ROUTE_STEP
var dwell_remaining := START_DWELL_SECONDS
var yielding_to_player := false


func advance(delta: float, player_position := Vector2(-1.0, -1.0)) -> Vector2:
	if not is_finite(delta) or delta <= 0.0:
		return position
	var remaining := delta
	while remaining > 0.0:
		var step_seconds := minf(remaining, MAX_STEP_SECONDS)
		_update_yielding(player_position)
		if yielding_to_player:
			break
		if _advance_step(step_seconds, player_position):
			break
		remaining -= step_seconds
	return position


func interaction_action(player_position: Vector2, active: bool = true) -> String:
	var distance := player_position.distance_to(position)
	if not active or not is_finite(distance) or distance > INTERACTION_RADIUS:
		return ""
	return TALK_TO_PATH_KEEPER


func motion_direction() -> Vector2:
	if dwell_remaining > 0.0:
		return Vector2.ZERO
	var offset := WAYPOINTS[target_index] - position
	return Vector2.ZERO if offset.length() <= POSITION_EPSILON else offset.normalized()


func is_moving() -> bool:
	return (
		not yielding_to_player
		and dwell_remaining <= 0.0
		and position.distance_to(WAYPOINTS[target_index]) > POSITION_EPSILON
	)


func snapshot() -> Dictionary:
	return {
		"position_x": position.x,
		"position_y": position.y,
		"target_index": target_index,
		"route_step": route_step,
		"dwell_remaining": dwell_remaining,
		"yielding_to_player": yielding_to_player,
	}


func restore(snapshot_data: Dictionary) -> bool:
	for key in ["position_x", "position_y", "target_index", "route_step", "dwell_remaining", "yielding_to_player"]:
		if not snapshot_data.has(key):
			return false
	if not _finite_number(snapshot_data["position_x"]) or not _finite_number(snapshot_data["position_y"]):
		return false
	if not _integer_in_range(snapshot_data["target_index"], 0, WAYPOINTS.size() - 1):
		return false
	if not _integer_in_range(snapshot_data["route_step"], -1, 1) or int(snapshot_data["route_step"]) == 0:
		return false
	if not _finite_number(snapshot_data["dwell_remaining"]):
		return false
	if typeof(snapshot_data["yielding_to_player"]) != TYPE_BOOL:
		return false
	var next_dwell := float(snapshot_data["dwell_remaining"])
	if next_dwell < 0.0:
		return false
	var next_position := Vector2(float(snapshot_data["position_x"]), float(snapshot_data["position_y"]))
	var next_target := int(snapshot_data["target_index"])
	var next_route_step := int(snapshot_data["route_step"])
	if not _valid_runtime_state(next_position, next_target, next_route_step, next_dwell):
		return false
	position = next_position
	target_index = next_target
	route_step = next_route_step
	dwell_remaining = next_dwell
	yielding_to_player = snapshot_data["yielding_to_player"]
	return true


static func default_snapshot() -> Dictionary:
	return PathKeeperState.new().snapshot()


func reset() -> void:
	position = START_POSITION
	target_index = START_TARGET_INDEX
	route_step = START_ROUTE_STEP
	dwell_remaining = START_DWELL_SECONDS
	yielding_to_player = false


func runtime_contract() -> Dictionary:
	return {
		"position": position,
		"target_index": target_index,
		"route_step": route_step,
		"motion": motion_direction(),
		"moving": is_moving(),
		"yielding": yielding_to_player,
		"route_points": WAYPOINTS.duplicate(),
		"collision_authority": false,
		"quest_authority": false,
		"battle_authority": false,
		"reward_authority": false,
		"persistent": true,
	}


func _advance_step(delta: float, player_position: Vector2) -> bool:
	var remaining := delta
	while remaining > POSITION_EPSILON:
		if dwell_remaining > 0.0:
			var dwell_used := minf(remaining, dwell_remaining)
			dwell_remaining = maxf(0.0, dwell_remaining - dwell_used)
			remaining -= dwell_used
			continue
		var target := WAYPOINTS[target_index]
		var distance := position.distance_to(target)
		if distance <= POSITION_EPSILON:
			position = target
			_arrive_at_waypoint()
			continue
		var travel_time := distance / MOVE_SPEED
		var movement_time := minf(travel_time, remaining)
		var direction := position.direction_to(target)
		var yield_time := _yield_entry_time(player_position, direction, movement_time)
		if yield_time >= 0.0:
			position += direction * MOVE_SPEED * yield_time
			yielding_to_player = true
			return true
		if travel_time > remaining:
			position += direction * MOVE_SPEED * remaining
			return false
		position = target
		remaining -= travel_time
		_arrive_at_waypoint()
	return false


func _yield_entry_time(player_position: Vector2, direction: Vector2, duration: float) -> float:
	if (
		duration <= 0.0
		or not is_finite(player_position.x)
		or not is_finite(player_position.y)
		or player_position.x < 0.0
		or player_position.y < 0.0
	):
		return -1.0
	var velocity := direction * MOVE_SPEED
	var offset := position - player_position
	var a := velocity.length_squared()
	var b := 2.0 * offset.dot(velocity)
	var c := offset.length_squared() - YIELD_ENTER_RADIUS * YIELD_ENTER_RADIUS
	var discriminant := b * b - 4.0 * a * c
	if a <= 0.0 or discriminant < 0.0:
		return -1.0
	var first_entry := (-b - sqrt(discriminant)) / (2.0 * a)
	if first_entry < -POSITION_EPSILON or first_entry > duration + POSITION_EPSILON:
		return -1.0
	return clampf(first_entry, 0.0, duration)


func _arrive_at_waypoint() -> void:
	if target_index == 0:
		dwell_remaining = ENDPOINT_DWELL_SECONDS
		route_step = 1
	elif target_index == WAYPOINTS.size() - 1:
		dwell_remaining = ENDPOINT_DWELL_SECONDS
		route_step = -1
	else:
		dwell_remaining = WAYPOINT_DWELL_SECONDS
	target_index += route_step


func _update_yielding(player_position: Vector2) -> void:
	if (
		not is_finite(player_position.x)
		or not is_finite(player_position.y)
		or player_position.x < 0.0
		or player_position.y < 0.0
	):
		yielding_to_player = false
		return
	var distance := position.distance_to(player_position)
	if yielding_to_player:
		yielding_to_player = distance <= YIELD_EXIT_RADIUS
	else:
		yielding_to_player = distance <= YIELD_ENTER_RADIUS


func _valid_runtime_state(candidate: Vector2, next_target: int, next_route_step: int, next_dwell: float) -> bool:
	if not _position_is_on_route(candidate):
		return false
	var waypoint_index := _waypoint_index(candidate)
	if next_dwell > 0.0:
		if waypoint_index < 0:
			return false
		var dwell_limit := (
			ENDPOINT_DWELL_SECONDS
			if waypoint_index in [0, WAYPOINTS.size() - 1]
			else WAYPOINT_DWELL_SECONDS
		)
		if next_dwell > dwell_limit:
			return false
		return next_target == waypoint_index + next_route_step
	if waypoint_index >= 0:
		return next_target == waypoint_index + next_route_step
	var segment_index := _segment_for_position(candidate)
	if next_route_step == 1:
		return next_target == segment_index + 1
	return next_target == segment_index


func _position_is_on_route(candidate: Vector2) -> bool:
	for index in range(WAYPOINTS.size() - 1):
		if _point_on_segment(candidate, WAYPOINTS[index], WAYPOINTS[index + 1]):
			return true
	return false


func _segment_for_position(candidate: Vector2) -> int:
	for index in range(WAYPOINTS.size() - 1):
		if _point_on_segment(candidate, WAYPOINTS[index], WAYPOINTS[index + 1]):
			return index
	return -1


func _waypoint_index(candidate: Vector2) -> int:
	for index in range(WAYPOINTS.size()):
		if candidate.distance_to(WAYPOINTS[index]) <= POSITION_EPSILON:
			return index
	return -1


func _point_on_segment(candidate: Vector2, start: Vector2, finish: Vector2) -> bool:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0:
		return candidate.distance_to(start) <= POSITION_EPSILON
	var amount := (candidate - start).dot(segment) / length_squared
	return amount >= 0.0 and amount <= 1.0 and candidate.distance_to(start + segment * amount) <= POSITION_EPSILON


func _finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	if not _finite_number(value):
		return false
	var numeric := float(value)
	return numeric == floorf(numeric) and numeric >= minimum and numeric <= maximum
