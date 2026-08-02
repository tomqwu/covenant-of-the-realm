extends Control

const ACTOR_HEIGHT := 56.0
const INK_ROOT := Color("27312e")
const COOL_SHADOW := Color("355e63")
const RIVER_JADE := Color("4e9da4")
const CLEAR_INDIGO := Color("58738f")
const FRESH_CELADON := Color("8ebb83")
const WARM_RUST := Color("c6764f")
const WARM_PAPER := Color("f2e6cb")
const SPIRIT_GOLD := Color("e4c36e")
const DAWN_PEACH := Color("e7a76f")

var phase_id := "riverbank"
var gathered_moonleaf := false


func set_story_state(next_phase: String, gathered: bool) -> void:
	phase_id = next_phase
	gathered_moonleaf = gathered
	queue_redraw()


func actor_height_px() -> float:
	return ACTOR_HEIGHT


func current_visual_mode() -> String:
	return phase_id


func _draw() -> void:
	match phase_id:
		"riverbank":
			_draw_riverbank()
		"battle":
			_draw_battle_path()
		"spring":
			_draw_spring_chamber(false)
		_:
			_draw_spring_chamber(true)
	_draw_vignette()


func _draw_riverbank() -> void:
	var size := get_rect().size
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

	_draw_dock(Vector2(size.x * 0.21, size.y * 0.47))
	_draw_building(Vector2(size.x * 0.51, size.y * 0.20), Vector2(148, 92), WARM_RUST.darkened(0.25))
	_draw_building(Vector2(size.x * 0.72, size.y * 0.35), Vector2(156, 96), Color("9a835d"))
	_draw_building(Vector2(size.x * 0.82, size.y * 0.58), Vector2(164, 92), COOL_SHADOW.lightened(0.2))

	for index in range(10):
		var plant := Vector2(size.x * 0.63 + float(index % 5) * 28.0, size.y * 0.57 + float(index / 5) * 28.0)
		_draw_plant(plant, not gathered_moonleaf)

	for tree_position in [Vector2(455, 115), Vector2(978, 130), Vector2(1030, 340), Vector2(468, 420)]:
		_draw_tree(tree_position)

	_draw_actor(Vector2(size.x * 0.48, size.y * 0.49), CLEAR_INDIGO, true)
	_draw_actor(Vector2(size.x * 0.53, size.y * 0.50), WARM_RUST, false)


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

	for rock_position in [Vector2(250, 125), Vector2(420, 90), Vector2(995, 165), Vector2(1035, 410), Vector2(310, 430)]:
		_draw_rock(rock_position, 42.0)
	for tree_position in [Vector2(130, 165), Vector2(338, 145), Vector2(915, 115), Vector2(1010, 300)]:
		_draw_tree(tree_position)

	_draw_cave(Vector2(size.x * 0.86, size.y * 0.16), Vector2(126, 88))
	_draw_actor(Vector2(size.x * 0.43, size.y * 0.58), CLEAR_INDIGO, true)
	_draw_actor(Vector2(size.x * 0.36, size.y * 0.54), WARM_RUST, false)
	_draw_beast(Vector2(size.x * 0.66, size.y * 0.43))
	draw_line(Vector2(size.x * 0.40, size.y * 0.49), Vector2(size.x * 0.64, size.y * 0.40), SPIRIT_GOLD, 3.0)
	draw_circle(Vector2(size.x * 0.64, size.y * 0.40), 6.0, SPIRIT_GOLD, false, 2.0)


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
	_draw_actor(Vector2(size.x * 0.47, size.y * 0.66), CLEAR_INDIGO, true)
	_draw_actor(Vector2(size.x * 0.69, size.y * 0.65), WARM_RUST, false)

	var energy_end := Vector2(size.x * 0.54, size.y * 0.16)
	var energy_start := Vector2(size.x * 0.48, size.y * 0.59)
	draw_line(energy_start, energy_end, SPIRIT_GOLD, 4.0)
	for index in range(5):
		var point := energy_start.lerp(energy_end, float(index) / 4.0)
		draw_circle(point, 5.0, SPIRIT_GOLD)

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


func _draw_dock(center: Vector2) -> void:
	draw_rect(Rect2(center - Vector2(105, 18), Vector2(155, 36)), Color("836c4c"))
	for index in range(7):
		var x := center.x - 100.0 + float(index) * 23.0
		draw_line(Vector2(x, center.y - 17.0), Vector2(x, center.y + 17.0), Color("b49567"), 2.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-142, 42),
		center + Vector2(-62, 42),
		center + Vector2(-76, 62),
		center + Vector2(-130, 62),
	]), Color("725f47"))


func _draw_building(position: Vector2, building_size: Vector2, roof_color: Color) -> void:
	draw_rect(Rect2(position, building_size), Color("d7c9a7"))
	draw_rect(Rect2(position + Vector2(0, building_size.y * 0.63), Vector2(building_size.x, building_size.y * 0.37)), Color("b99d70"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-12, 12),
		position + Vector2(building_size.x * 0.5, -18),
		position + Vector2(building_size.x + 12, 12),
		position + Vector2(building_size.x, 34),
		position + Vector2(0, 34),
	]), roof_color)
	draw_rect(Rect2(position + Vector2(building_size.x * 0.43, building_size.y * 0.58), Vector2(24, building_size.y * 0.42)), INK_ROOT.lightened(0.12))


func _draw_tree(position: Vector2) -> void:
	draw_rect(Rect2(position + Vector2(-5, 14), Vector2(10, 32)), Color("6f654b"))
	draw_circle(position, 30.0, FRESH_CELADON.darkened(0.18))
	draw_circle(position + Vector2(-18, 8), 22.0, FRESH_CELADON)
	draw_circle(position + Vector2(19, 9), 21.0, Color("a1c98c"))


func _draw_plant(position: Vector2, available: bool) -> void:
	var color := Color("a9cd84") if available else Color("72836b")
	draw_line(position + Vector2(0, 12), position - Vector2(0, 12), color.darkened(0.2), 3.0)
	draw_circle(position + Vector2(-6, -6), 6.0, color)
	draw_circle(position + Vector2(7, -2), 6.0, color)


func _draw_rock(position: Vector2, radius: float) -> void:
	draw_circle(position, radius, COOL_SHADOW)
	draw_circle(position - Vector2(radius * 0.2, radius * 0.25), radius * 0.72, Color("6d837c"))


func _draw_cave(position: Vector2, cave_size: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		position,
		position + Vector2(cave_size.x * 0.5, -cave_size.y * 0.36),
		position + Vector2(cave_size.x, 0),
		position + cave_size,
	]), COOL_SHADOW.darkened(0.28))
	draw_rect(Rect2(position + Vector2(cave_size.x * 0.32, cave_size.y * 0.24), Vector2(cave_size.x * 0.36, cave_size.y * 0.76)), INK_ROOT.darkened(0.2))
	draw_circle(position + Vector2(cave_size.x * 0.5, cave_size.y * 0.56), 7.0, SPIRIT_GOLD)


func _draw_actor(feet: Vector2, robe_color: Color, is_protagonist: bool) -> void:
	var top := feet - Vector2(0, ACTOR_HEIGHT)
	_draw_oval(top + Vector2(0, 13), Vector2(10, 12), Color("d9b895"))
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(-13, 22),
		top + Vector2(13, 22),
		feet + Vector2(16, -5),
		feet + Vector2(-16, -5),
	]), robe_color)
	draw_line(feet + Vector2(-7, -5), feet + Vector2(-9, 4), INK_ROOT, 5.0)
	draw_line(feet + Vector2(7, -5), feet + Vector2(9, 4), INK_ROOT, 5.0)
	if is_protagonist:
		draw_colored_polygon(PackedVector2Array([
			top + Vector2(-19, 23),
			top + Vector2(0, 17),
			feet + Vector2(-3, -7),
		]), Color("b89b63"))
	else:
		draw_rect(Rect2(top + Vector2(11, 27), Vector2(13, 24)), Color("73533d"))
	draw_circle(top + Vector2(0, 2), 6.0, INK_ROOT)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_beast(center: Vector2) -> void:
	for offset_and_radius in [
		[Vector2(-22, -8), 25.0],
		[Vector2(4, -18), 31.0],
		[Vector2(28, -4), 24.0],
		[Vector2(-16, 21), 20.0],
		[Vector2(24, 22), 21.0],
	]:
		draw_circle(center + offset_and_radius[0], offset_and_radius[1], INK_ROOT.lightened(0.20))
	draw_line(center + Vector2(-8, -35), center + Vector2(8, 10), SPIRIT_GOLD, 3.0)
	draw_circle(center + Vector2(-13, -15), 3.0, SPIRIT_GOLD)
	draw_circle(center + Vector2(8, -17), 3.0, SPIRIT_GOLD)


func _draw_vignette() -> void:
	var size := get_rect().size
	var edge := Color(0.08, 0.12, 0.11, 0.17)
	draw_rect(Rect2(0, 0, size.x, 14), edge)
	draw_rect(Rect2(0, size.y - 14, size.x, 14), edge)
	draw_rect(Rect2(0, 0, 14, size.y), edge)
	draw_rect(Rect2(size.x - 14, 0, 14, size.y), edge)
