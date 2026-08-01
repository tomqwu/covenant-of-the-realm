extends Control

var phase_id := "riverbank"
var gathered_moonleaf := false


func set_story_state(next_phase: String, gathered: bool) -> void:
	phase_id = next_phase
	gathered_moonleaf = gathered
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("162329"))
	draw_rect(Rect2(0, 0, size.x * 0.32, size.y), Color("294e59"))
	for index in range(9):
		var y := 30.0 + index * 58.0
		draw_line(Vector2(0, y), Vector2(size.x * 0.31, y + 18), Color("5f8790"), 2.0)

	var bank := PackedVector2Array([
		Vector2(size.x * 0.28, 0),
		Vector2(size.x * 0.38, 0),
		Vector2(size.x * 0.42, size.y),
		Vector2(size.x * 0.30, size.y),
	])
	draw_colored_polygon(bank, Color("9b8b63"))
	draw_rect(Rect2(size.x * 0.42, 0, size.x * 0.58, size.y), Color("324b35"))
	draw_line(Vector2(size.x * 0.36, size.y * 0.72), Vector2(size.x * 0.78, size.y * 0.24), Color("a99369"), 22.0)

	for row in range(3):
		for column in range(5):
			var plant := Vector2(size.x * 0.53 + column * 38, size.y * 0.60 + row * 34)
			draw_circle(plant, 8.0, Color("aac8a1" if not gathered_moonleaf else "63745f"))

	for column in range(4):
		var mountain := Vector2(size.x * 0.72 + column * 52, size.y * 0.20 - column * 12)
		draw_colored_polygon(PackedVector2Array([
			mountain + Vector2(-34, 34),
			mountain + Vector2(0, -28),
			mountain + Vector2(34, 34),
		]), Color("45564c"))

	var marker := Vector2(size.x * 0.37, size.y * 0.73)
	if phase_id == "battle":
		marker = Vector2(size.x * 0.70, size.y * 0.33)
	elif phase_id in ["spring", "complete"]:
		marker = Vector2(size.x * 0.82, size.y * 0.20)
	draw_circle(marker, 14.0, Color("e4c77e"))
	draw_circle(marker, 6.0, Color("3d2f24"))
