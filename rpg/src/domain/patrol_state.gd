extends RefCounted
class_name PatrolState

const TALK_TO_PATROL_RUNNER := "talk_to_patrol_runner"
const WORKSITE_BOAT := "boat"
const WORKSITE_HERBS := "herbs"
const TALK_AT_BOAT_WORKSITE := "talk_at_boat_worksite"
const TALK_AT_HERBS_WORKSITE := "talk_at_herbs_worksite"
const RESPONSE_UNANSWERED := "unanswered"
const RESPONSE_BOAT_FIRST := "boat_first"
const RESPONSE_HERBS_FIRST := "herbs_first"
const RESPONSES := [RESPONSE_UNANSWERED, RESPONSE_BOAT_FIRST, RESPONSE_HERBS_FIRST]

# The route is authored in normalized ferry-map coordinates. Every segment stays
# inside ExplorationState's public walkable space, so the NPC follows the same
# visible roads as the player instead of crossing scenery for presentation only.
# The endpoints stop beside (but outside the interaction radius of) the boat
# frame and drying rack. Fixed landmark actions therefore keep priority without
# making a yielding patrol runner impossible to address.
const WAYPOINTS: Array[Vector2] = [
	Vector2(0.43, 0.37),
	Vector2(0.43, 0.66),
	Vector2(0.68, 0.66),
	Vector2(0.68, 0.27),
	Vector2(0.90, 0.27),
	Vector2(0.90, 0.50),
]
const BOAT_WAYPOINT := 0
const HERBS_WAYPOINT := 5
const START_POSITION := Vector2(0.55, 0.66)
const START_TARGET_INDEX := 2
const MOVE_SPEED := 0.09
const MAX_STEP_SECONDS := 0.10
const ENDPOINT_DWELL_SECONDS := 2.0
const WAYPOINT_DWELL_SECONDS := 0.25
const START_DWELL_SECONDS := 1.0
const INTERACTION_RADIUS := 0.065
const YIELD_ENTER_RADIUS := 0.080
const YIELD_EXIT_RADIUS := 0.100
const POSITION_EPSILON := 0.00001

var position := START_POSITION
var target_index := START_TARGET_INDEX
var route_step := 1
var dwell_remaining := START_DWELL_SECONDS
var yielding_to_player := false


func advance(
	delta: float,
	player_position := Vector2(-1.0, -1.0),
	response_id: String = RESPONSE_UNANSWERED
) -> Vector2:
	if delta <= 0.0:
		return position
	var remaining := delta
	while remaining > 0.0:
		var step_seconds := minf(remaining, MAX_STEP_SECONDS)
		_update_yielding(player_position, response_id)
		if yielding_to_player:
			break
		_advance_step(step_seconds)
		remaining -= step_seconds
		_update_yielding(player_position, response_id)
		if yielding_to_player:
			break
	return position


func apply_priority(response_id: String) -> bool:
	if response_id not in [RESPONSE_BOAT_FIRST, RESPONSE_HERBS_FIRST]:
		return false
	var waypoint_index := _waypoint_index(position)
	var segment_index := _segment_for_position(position)
	if waypoint_index < 0 and segment_index < 0:
		return false
	if response_id == RESPONSE_BOAT_FIRST:
		if waypoint_index == BOAT_WAYPOINT:
			target_index = BOAT_WAYPOINT + 1
			route_step = 1
			dwell_remaining = ENDPOINT_DWELL_SECONDS
		else:
			target_index = waypoint_index - 1 if waypoint_index >= 0 else segment_index
			route_step = -1
			dwell_remaining = 0.0
	else:
		if waypoint_index == HERBS_WAYPOINT:
			target_index = HERBS_WAYPOINT - 1
			route_step = -1
			dwell_remaining = ENDPOINT_DWELL_SECONDS
		else:
			target_index = waypoint_index + 1 if waypoint_index >= 0 else segment_index + 1
			route_step = 1
			dwell_remaining = 0.0
	return true


func interaction_action(player_position: Vector2, response_id: String, active: bool = true) -> String:
	var distance := player_position.distance_to(position)
	if not active or not is_finite(distance) or distance > INTERACTION_RADIUS:
		return ""
	if response_id == RESPONSE_UNANSWERED:
		return TALK_TO_PATROL_RUNNER
	return String(worksite_context(response_id).get("action_id", ""))


func worksite_context(response_id: String) -> Dictionary:
	if dwell_remaining <= 0.0 or response_id not in [RESPONSE_BOAT_FIRST, RESPONSE_HERBS_FIRST]:
		return {}
	var waypoint_index := _waypoint_index(position)
	var worksite_id := ""
	var action_id := ""
	if waypoint_index == BOAT_WAYPOINT:
		worksite_id = WORKSITE_BOAT
		action_id = TALK_AT_BOAT_WORKSITE
	elif waypoint_index == HERBS_WAYPOINT:
		worksite_id = WORKSITE_HERBS
		action_id = TALK_AT_HERBS_WORKSITE
	else:
		return {}
	var priority_worksite := WORKSITE_BOAT if response_id == RESPONSE_BOAT_FIRST else WORKSITE_HERBS
	return {
		"worksite_id": worksite_id,
		"action_id": action_id,
		"route_role": "priority" if worksite_id == priority_worksite else "followup",
	}


func finish_worksite(worksite_id: String) -> bool:
	if dwell_remaining <= 0.0:
		return false
	var expected_worksite := ""
	match _waypoint_index(position):
		BOAT_WAYPOINT:
			expected_worksite = WORKSITE_BOAT
		HERBS_WAYPOINT:
			expected_worksite = WORKSITE_HERBS
	if expected_worksite.is_empty() or worksite_id != expected_worksite:
		return false
	dwell_remaining = 0.0
	return true


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
	return PatrolState.new().snapshot()


func reset() -> void:
	position = START_POSITION
	target_index = START_TARGET_INDEX
	route_step = 1
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
		"persistent": true,
	}


func _advance_step(delta: float) -> void:
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
		if travel_time > remaining:
			position += position.direction_to(target) * MOVE_SPEED * remaining
			return
		position = target
		remaining -= travel_time
		_arrive_at_waypoint()


func _arrive_at_waypoint() -> void:
	if target_index in [BOAT_WAYPOINT, HERBS_WAYPOINT]:
		dwell_remaining = ENDPOINT_DWELL_SECONDS
		route_step = 1 if target_index == BOAT_WAYPOINT else -1
	else:
		dwell_remaining = WAYPOINT_DWELL_SECONDS
	target_index += route_step


func _position_is_on_route(candidate: Vector2) -> bool:
	for index in range(WAYPOINTS.size() - 1):
		var start := WAYPOINTS[index]
		var finish := WAYPOINTS[index + 1]
		var segment := finish - start
		var length_squared := segment.length_squared()
		var amount := 0.0 if length_squared <= 0.0 else clampf((candidate - start).dot(segment) / length_squared, 0.0, 1.0)
		if candidate.distance_to(start + segment * amount) <= POSITION_EPSILON:
			return true
	return false


func _segment_for_position(candidate: Vector2) -> int:
	for index in range(WAYPOINTS.size() - 1):
		if _point_on_segment(candidate, WAYPOINTS[index], WAYPOINTS[index + 1]):
			return index
	return -1


func _update_yielding(player_position: Vector2, response_id: String) -> void:
	if player_position.x < 0.0 or player_position.y < 0.0:
		yielding_to_player = false
		return
	if _player_waits_at_target_endpoint(player_position, response_id):
		yielding_to_player = false
		return
	var distance := position.distance_to(player_position)
	if yielding_to_player:
		yielding_to_player = distance <= YIELD_EXIT_RADIUS
	else:
		yielding_to_player = distance <= YIELD_ENTER_RADIUS


func _player_waits_at_target_endpoint(player_position: Vector2, response_id: String) -> bool:
	if response_id not in [RESPONSE_BOAT_FIRST, RESPONSE_HERBS_FIRST]:
		return false
	if dwell_remaining > 0.0 or target_index not in [BOAT_WAYPOINT, HERBS_WAYPOINT]:
		return false
	var target := WAYPOINTS[target_index]
	if position.distance_to(target) <= POSITION_EPSILON:
		return false
	return player_position.distance_to(target) <= INTERACTION_RADIUS


func _valid_runtime_state(candidate: Vector2, next_target: int, next_route_step: int, next_dwell: float) -> bool:
	if not _position_is_on_route(candidate):
		return false
	var waypoint_index := _waypoint_index(candidate)
	if next_dwell > 0.0:
		if candidate.distance_to(START_POSITION) <= POSITION_EPSILON:
			return (
				next_target == START_TARGET_INDEX
				and next_route_step == 1
				and next_dwell <= START_DWELL_SECONDS
			)
		if waypoint_index < 0:
			return false
		var dwell_limit := ENDPOINT_DWELL_SECONDS if waypoint_index in [BOAT_WAYPOINT, HERBS_WAYPOINT] else WAYPOINT_DWELL_SECONDS
		if next_dwell > dwell_limit:
			return false
		return next_target == waypoint_index + next_route_step
	if waypoint_index >= 0:
		return next_target == waypoint_index + next_route_step
	var segment_index := _segment_for_position(candidate)
	if next_route_step == 1:
		return next_target == segment_index + 1
	return next_target == segment_index


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
