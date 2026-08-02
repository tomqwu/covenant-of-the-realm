extends SceneTree

const OUTPUT_DIR := "res://assets/pixel"
const FRAME_SIZE := Vector2i(32, 56)
const ATLAS_SIZE := Vector2i(128, 224)
const TRANSPARENT := Color(0, 0, 0, 0)
const INK := Color("27312e")
const SKIN := Color("d9b895")
const PAPER := Color("f2e6cb")
const GOLD := Color("e4c36e")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_generate_actor("protagonist.png", Color("58738f"), Color("b89b63"), true)
	_generate_actor("yanqing.png", Color("c6764f"), Color("73533d"), false)
	_generate_ferry_tiles()
	print("Generated original pixel atlases in %s." % OUTPUT_DIR)
	quit(0)


func _generate_actor(file_name: String, robe: Color, accent: Color, protagonist: bool) -> void:
	var image := Image.create(ATLAS_SIZE.x, ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	for row in range(4):
		for column in range(4):
			_draw_frame(image, Vector2i(column * FRAME_SIZE.x, row * FRAME_SIZE.y), row, column, robe, accent, protagonist)
	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _generate_ferry_tiles() -> void:
	var image := Image.create(256, 32, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	_draw_tile_base(image, 0, Color("b7cf9f"), Color("9fbd89"), "grass")
	_draw_tile_base(image, 1, Color("4e9da4"), Color("a7d7cc"), "water")
	_draw_tile_base(image, 2, Color("d7cba5"), Color("b9aa80"), "bank")
	_draw_tile_base(image, 3, Color("d8cca5"), Color("b6aa84"), "path")
	_draw_tile_base(image, 4, Color("a9c98f"), Color("e4c36e"), "moonleaf")
	_draw_tile_base(image, 5, Color("829a8f"), Color("355e63"), "stone")
	_draw_tile_base(image, 6, Color("8ebb83"), Color("739b70"), "grass")
	_draw_tile_base(image, 7, Color("4e9da4"), Color("f2e6cb"), "water")
	var output_path := "%s/ferry_tiles.png" % OUTPUT_DIR
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _draw_tile_base(image: Image, column: int, base: Color, detail: Color, pattern: String) -> void:
	var origin_x := column * 32
	_fill(image, Rect2i(origin_x, 0, 32, 32), base)
	match pattern:
		"water":
			_fill(image, Rect2i(origin_x + 3, 8, 17, 2), detail)
			_fill(image, Rect2i(origin_x + 12, 22, 16, 2), detail)
		"bank":
			_fill(image, Rect2i(origin_x + 5, 6, 3, 2), detail)
			_fill(image, Rect2i(origin_x + 20, 18, 5, 2), detail)
			_fill(image, Rect2i(origin_x + 10, 28, 7, 2), detail)
		"path":
			_fill(image, Rect2i(origin_x, 3, 32, 2), detail)
			_fill(image, Rect2i(origin_x + 4, 25, 28, 2), detail)
			_fill(image, Rect2i(origin_x + 9, 13, 4, 2), detail.lightened(0.12))
		"moonleaf":
			for plant_x in [8, 23]:
				_fill(image, Rect2i(origin_x + plant_x, 11, 2, 13), detail.darkened(0.30))
				_fill(image, Rect2i(origin_x + plant_x - 4, 10, 5, 5), detail.lightened(0.16))
				_fill(image, Rect2i(origin_x + plant_x + 1, 15, 5, 5), detail)
		"stone":
			_fill(image, Rect2i(origin_x + 4, 5, 25, 23), detail.lightened(0.30))
			_fill(image, Rect2i(origin_x + 6, 7, 20, 3), detail.lightened(0.47))
		_:
			_fill(image, Rect2i(origin_x + 6, 8, 2, 5), detail)
			_fill(image, Rect2i(origin_x + 22, 20, 2, 6), detail)


func _draw_frame(image: Image, origin: Vector2i, direction: int, column: int, robe: Color, accent: Color, protagonist: bool) -> void:
	var step := -1 if column == 2 else (1 if column == 3 else 0)
	var bob := 1 if column == 3 else 0
	var center_x := origin.x + 16
	var feet_y := origin.y + 52

	# Soft one-pixel shadow keeps the fixed 16x20 collision footprint visually legible.
	_fill(image, Rect2i(center_x - 9, feet_y - 2, 18, 3), Color(0.15, 0.19, 0.18, 0.38))
	# Legs alternate only inside the frame; the foot anchor itself never changes.
	_fill(image, Rect2i(center_x - 7 + step, feet_y - 9, 5, 9), INK)
	_fill(image, Rect2i(center_x + 2 - step, feet_y - 9, 5, 9), INK)
	_fill(image, Rect2i(center_x - 8 + step, feet_y - 1, 7, 2), PAPER.darkened(0.48))
	_fill(image, Rect2i(center_x + 1 - step, feet_y - 1, 7, 2), PAPER.darkened(0.48))

	var body_y := origin.y + 20 + bob
	_fill(image, Rect2i(center_x - 10, body_y, 20, 25), robe.darkened(0.12))
	_fill(image, Rect2i(center_x - 12, body_y + 8, 24, 16), robe)
	_fill(image, Rect2i(center_x - 10, body_y + 24, 20, 5), robe.darkened(0.22))
	_fill(image, Rect2i(center_x - 1, body_y + 5, 2, 20), GOLD.darkened(0.08))

	if protagonist:
		_fill(image, Rect2i(center_x - 12, body_y + 6, 5, 21), accent)
		_fill(image, Rect2i(center_x - 14, body_y + 8, 3, 17), accent.darkened(0.18))
	else:
		_fill(image, Rect2i(center_x + 10, body_y + 8, 4, 20), accent)
		_fill(image, Rect2i(center_x + 14, body_y + 12, 2, 16), accent.darkened(0.22))

	var head_y := origin.y + 7 + bob
	_fill(image, Rect2i(center_x - 7, head_y, 14, 14), SKIN)
	_fill(image, Rect2i(center_x - 7, head_y, 14, 4), INK)
	_fill(image, Rect2i(center_x - 4, head_y - 3, 8, 4), INK)
	if direction == 0:
		_fill(image, Rect2i(center_x - 4, head_y + 8, 2, 2), INK)
		_fill(image, Rect2i(center_x + 2, head_y + 8, 2, 2), INK)
	elif direction == 1:
		_fill(image, Rect2i(center_x - 6, head_y + 8, 2, 2), INK)
	elif direction == 2:
		_fill(image, Rect2i(center_x + 4, head_y + 8, 2, 2), INK)
	else:
		_fill(image, Rect2i(center_x - 5, head_y + 5, 10, 3), INK.lightened(0.05))


func _fill(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)
