extends RefCounted

const FOLLOW_DISTANCE := 0.058
const TELEPORT_DISTANCE := 0.14
const MAX_POINTS := 96

var context_id := ""
var points: Array[Vector2] = []
var follower_position := Vector2.ZERO
var reset_count := 0


func reset(next_context_id: String, player_position: Vector2, rest_offset: Vector2) -> Vector2:
	context_id = next_context_id
	points.clear()
	var rest_position := player_position + rest_offset
	points.append(rest_position)
	points.append(player_position)
	follower_position = rest_position
	reset_count += 1
	return follower_position


func record(next_context_id: String, player_position: Vector2, rest_offset: Vector2) -> Vector2:
	if points.is_empty() or next_context_id != context_id:
		return reset(next_context_id, player_position, rest_offset)
	if points[-1].distance_to(player_position) > TELEPORT_DISTANCE:
		return reset(next_context_id, player_position, rest_offset)
	if not points[-1].is_equal_approx(player_position):
		points.append(player_position)
	while points.size() > MAX_POINTS:
		points.pop_front()
	follower_position = _point_behind(player_position)
	return follower_position


func visual_contract() -> Dictionary:
	return {
		"context_id": context_id,
		"point_count": points.size(),
		"position": follower_position,
		"follow_distance": FOLLOW_DISTANCE,
		"teleport_distance": TELEPORT_DISTANCE,
		"max_points": MAX_POINTS,
		"reset_count": reset_count,
	}


func _point_behind(player_position: Vector2) -> Vector2:
	var remaining := FOLLOW_DISTANCE
	var cursor := player_position
	for index in range(points.size() - 2, -1, -1):
		var previous := points[index]
		var segment_length := cursor.distance_to(previous)
		if segment_length >= remaining and segment_length > 0.0:
			return cursor.lerp(previous, remaining / segment_length)
		remaining -= segment_length
		cursor = previous
	return points[0]
