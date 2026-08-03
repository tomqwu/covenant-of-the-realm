extends Node2D
class_name WorldCamera

const WORLD_SIZE := Vector2(1536.0, 864.0)
const FOCUS_ANCHOR := Vector2(0.5, 0.47)
const SAFE_FRAME_LEFT := 32.0
const SAFE_FRAME_RIGHT := 32.0
const SAFE_FRAME_TOP := 96.0
const SAFE_FRAME_BOTTOM := 192.0

var viewport_size := Vector2.ZERO
var normalized_focus := Vector2.ZERO
var world_focus := Vector2.ZERO
var origin := Vector2.ZERO
var clamped_sides := {
	"left": true,
	"right": false,
	"top": true,
	"bottom": false,
}


func update_focus(next_normalized_focus: Vector2, next_viewport_size: Vector2) -> Vector2:
	if not _valid_normalized_focus(next_normalized_focus) or not _valid_viewport_size(next_viewport_size):
		return origin

	var next_world_focus := Vector2(
		next_normalized_focus.x * WORLD_SIZE.x,
		next_normalized_focus.y * WORLD_SIZE.y
	).round()
	var snapped_anchor := Vector2(
		next_viewport_size.x * FOCUS_ANCHOR.x,
		next_viewport_size.y * FOCUS_ANCHOR.y
	).round()
	var maximum_origin := Vector2(
		maxf(0.0, WORLD_SIZE.x - next_viewport_size.x),
		maxf(0.0, WORLD_SIZE.y - next_viewport_size.y)
	)
	var snapped_maximum := Vector2(floorf(maximum_origin.x), floorf(maximum_origin.y))
	var desired_origin := next_world_focus - snapped_anchor
	var next_origin := Vector2(
		clampf(desired_origin.x, 0.0, snapped_maximum.x),
		clampf(desired_origin.y, 0.0, snapped_maximum.y)
	)
	if next_viewport_size.x >= WORLD_SIZE.x:
		next_origin.x = 0.0
	if next_viewport_size.y >= WORLD_SIZE.y:
		next_origin.y = 0.0

	viewport_size = next_viewport_size
	normalized_focus = next_normalized_focus
	world_focus = next_world_focus
	origin = next_origin.round()
	position = -origin
	clamped_sides = {
		"left": is_zero_approx(origin.x),
		"right": is_equal_approx(origin.x, snapped_maximum.x),
		"top": is_zero_approx(origin.y),
		"bottom": is_equal_approx(origin.y, snapped_maximum.y),
	}
	return origin


func camera_contract() -> Dictionary:
	return {
		"world_size": WORLD_SIZE,
		"viewport_size": viewport_size,
		"normalized_focus": normalized_focus,
		"world_focus": world_focus,
		"focus_anchor": FOCUS_ANCHOR,
		"origin": origin,
		"world_offset": position,
		"safe_frame": {
			"left": SAFE_FRAME_LEFT,
			"right": SAFE_FRAME_RIGHT,
			"top": SAFE_FRAME_TOP,
			"bottom": SAFE_FRAME_BOTTOM,
			"rect": _safe_frame_rect(),
		},
		"pixel_snap": origin == origin.round() and position == position.round(),
		"clamped_sides": clamped_sides.duplicate(),
	}


func _safe_frame_rect() -> Rect2:
	return Rect2(
		Vector2(SAFE_FRAME_LEFT, SAFE_FRAME_TOP),
		Vector2(
			maxf(0.0, viewport_size.x - SAFE_FRAME_LEFT - SAFE_FRAME_RIGHT),
			maxf(0.0, viewport_size.y - SAFE_FRAME_TOP - SAFE_FRAME_BOTTOM)
		)
	)


func _valid_normalized_focus(candidate: Vector2) -> bool:
	return (
		is_finite(candidate.x)
		and is_finite(candidate.y)
		and candidate.x >= 0.0
		and candidate.x <= 1.0
		and candidate.y >= 0.0
		and candidate.y <= 1.0
	)


func _valid_viewport_size(candidate: Vector2) -> bool:
	return is_finite(candidate.x) and is_finite(candidate.y) and candidate.x > 0.0 and candidate.y > 0.0
