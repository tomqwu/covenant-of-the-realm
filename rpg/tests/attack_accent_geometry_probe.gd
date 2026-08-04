extends "res://src/ui/map_canvas.gd"

var geometry_commands := PackedStringArray()


func fingerprint(shape_id: String) -> String:
	geometry_commands.clear()
	_draw_attack_shape(
		shape_id,
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.DOWN,
		Color.WHITE,
		1.0,
		Vector2.ZERO
	)
	return ";".join(geometry_commands)


func _draw_attack_polyline(
	coordinates: Array,
	origin: Vector2,
	forward: Vector2,
	side: Vector2,
	_accent: Color,
	_alpha: float,
	shift: Vector2 = Vector2.ZERO,
	closed: bool = false
) -> void:
	var points := _attack_points(coordinates, origin, forward, side, shift, closed)
	var encoded_points := PackedStringArray()
	for point in points:
		encoded_points.append(_encode_point(point))
	geometry_commands.append("line[%s]" % ",".join(encoded_points))


func _draw_attack_dot(
	coordinate: Vector2,
	radius: float,
	origin: Vector2,
	forward: Vector2,
	side: Vector2,
	_accent: Color,
	_alpha: float,
	shift: Vector2 = Vector2.ZERO
) -> void:
	var center := _attack_point(origin, forward, side, coordinate, shift)
	geometry_commands.append("dot[%s;r=%s]" % [_encode_point(center), _encode_number(radius)])


func _draw_attack_square(
	coordinate: Vector2,
	half_size: float,
	origin: Vector2,
	forward: Vector2,
	side: Vector2,
	_accent: Color,
	_alpha: float,
	shift: Vector2 = Vector2.ZERO
) -> void:
	var center := _attack_point(origin, forward, side, coordinate, shift)
	geometry_commands.append("square[%s;h=%s]" % [_encode_point(center), _encode_number(half_size)])


func _encode_point(point: Vector2) -> String:
	return "%s:%s" % [_encode_number(point.x), _encode_number(point.y)]


func _encode_number(value: float) -> String:
	return "%.2f" % value
