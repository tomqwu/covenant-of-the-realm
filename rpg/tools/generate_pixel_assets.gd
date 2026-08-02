extends SceneTree

const OUTPUT_DIR := "res://assets/pixel"
const FRAME_SIZE := Vector2i(32, 56)
const ATLAS_SIZE := Vector2i(128, 224)
const ENEMY_FRAME_SIZE := Vector2i(64, 64)
const ENEMY_ATLAS_SIZE := Vector2i(128, 256)
const TRANSPARENT := Color(0, 0, 0, 0)
const INK := Color("27312e")
const SKIN := Color("d9b895")
const PAPER := Color("f2e6cb")
const GOLD := Color("e4c36e")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_generate_actor("protagonist.png", Color("58738f"), Color("b89b63"), true)
	_generate_actor("yanqing.png", Color("c6764f"), Color("73533d"), false)
	_generate_enemy_atlas()
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


func _generate_enemy_atlas() -> void:
	var image := Image.create(ENEMY_ATLAS_SIZE.x, ENEMY_ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	for row in range(4):
		for column in range(2):
			var origin := Vector2i(column * ENEMY_FRAME_SIZE.x, row * ENEMY_FRAME_SIZE.y)
			match row:
				0:
					_draw_rock_armor_young(image, origin, column)
				1:
					_draw_spring_moss_shell(image, origin, column)
				2:
					_draw_stone_puppet(image, origin, column)
				_:
					_draw_rock_armor_warden(image, origin, column)
	var output_path := "%s/enemy_profiles.png" % OUTPUT_DIR
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _draw_enemy_shadow(image: Image, origin: Vector2i, width: int) -> void:
	var center_x := origin.x + 32
	_fill(image, Rect2i(center_x - width / 2, origin.y + 54, width, 4), Color(0.15, 0.19, 0.18, 0.42))
	_fill(image, Rect2i(center_x - width / 2 + 5, origin.y + 58, width - 10, 2), Color(0.15, 0.19, 0.18, 0.22))


func _draw_rock_armor_young(image: Image, origin: Vector2i, frame: int) -> void:
	var lift := -1 if frame == 1 else 0
	var stone := Color("60766f")
	var stone_light := Color("829a8f")
	_draw_enemy_shadow(image, origin, 48)
	_fill(image, Rect2i(origin.x + 9, origin.y + 31 + lift, 45, 20), INK)
	_fill(image, Rect2i(origin.x + 12, origin.y + 27 + lift, 38, 21), stone)
	_fill(image, Rect2i(origin.x + 18, origin.y + 22 + lift, 26, 21), stone_light)
	_fill(image, Rect2i(origin.x + 7, origin.y + 34 + lift, 12, 13), stone.darkened(0.12))
	_fill(image, Rect2i(origin.x + 46, origin.y + 31 + lift, 11, 15), stone.darkened(0.18))
	var front_step := 2 if frame == 1 else 0
	_fill(image, Rect2i(origin.x + 15 + front_step, origin.y + 46, 9, 10), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 40 - front_step, origin.y + 45, 9, 11), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 21, origin.y + 25 + lift, 3, 18), GOLD)
	_fill(image, Rect2i(origin.x + 24, origin.y + 38 + lift, 11, 3), GOLD.darkened(0.10))
	_fill(image, Rect2i(origin.x + 13, origin.y + 35 + lift, 4, 4), GOLD)
	_fill(image, Rect2i(origin.x + 49, origin.y + 36 + lift, 4, 4), GOLD)


func _draw_spring_moss_shell(image: Image, origin: Vector2i, frame: int) -> void:
	var breathe := 1 if frame == 1 else 0
	var shell := Color("6d837c")
	var moss := Color("8ebb83")
	_draw_enemy_shadow(image, origin, 46)
	_fill(image, Rect2i(origin.x + 10, origin.y + 30 - breathe, 44, 23 + breathe), INK)
	_fill(image, Rect2i(origin.x + 13, origin.y + 26 - breathe, 38, 25 + breathe), shell)
	_fill(image, Rect2i(origin.x + 18, origin.y + 22 - breathe, 29, 21), moss.darkened(0.12))
	_fill(image, Rect2i(origin.x + 13, origin.y + 23 - breathe, 13, 11), moss)
	_fill(image, Rect2i(origin.x + 27, origin.y + 17 - breathe, 12, 12), moss.lightened(0.10))
	_fill(image, Rect2i(origin.x + 41, origin.y + 24 - breathe, 11, 10), moss)
	_fill(image, Rect2i(origin.x + 16, origin.y + 49, 9, 7), INK.lightened(0.08))
	_fill(image, Rect2i(origin.x + 40, origin.y + 49, 9, 7), INK.lightened(0.08))
	_fill(image, Rect2i(origin.x + 17, origin.y + 37 - breathe, 4, 4), GOLD)
	_fill(image, Rect2i(origin.x + 24, origin.y + 43 - breathe, 18, 2), Color("4e9da4").lightened(0.18))
	if frame == 1:
		_fill(image, Rect2i(origin.x + 5, origin.y + 28, 3, 3), Color("a7d7cc"))
		_fill(image, Rect2i(origin.x + 56, origin.y + 22, 3, 3), Color("a7d7cc"))


func _draw_stone_puppet(image: Image, origin: Vector2i, frame: int) -> void:
	var sway := 2 if frame == 1 else 0
	var stone := Color("6d837c")
	var crack := Color("c6764f")
	_draw_enemy_shadow(image, origin, 40)
	_fill(image, Rect2i(origin.x + 20 + sway, origin.y + 18, 27, 34), INK)
	_fill(image, Rect2i(origin.x + 22 + sway, origin.y + 16, 23, 34), stone)
	_fill(image, Rect2i(origin.x + 18 + sway, origin.y + 4, 24, 18), stone.lightened(0.12))
	_fill(image, Rect2i(origin.x + 20 + sway, origin.y + 8, 5, 5), GOLD)
	_fill(image, Rect2i(origin.x + 16 + sway, origin.y + 25, 8, 27), stone.darkened(0.20))
	_fill(image, Rect2i(origin.x + 43 + sway, origin.y + 24, 8, 25), stone.darkened(0.20))
	_fill(image, Rect2i(origin.x + 20 + sway, origin.y + 48, 9, 9), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 39 + sway, origin.y + 47, 10, 10), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 33 + sway, origin.y + 20, 3, 20), crack)
	_fill(image, Rect2i(origin.x + 35 + sway, origin.y + 37, 9, 3), crack.darkened(0.12))
	_fill(image, Rect2i(origin.x + 7, origin.y + 28 + sway, 13, 7), stone.darkened(0.08))
	_fill(image, Rect2i(origin.x + 49, origin.y + 18 - sway, 10, 8), stone.darkened(0.08))


func _draw_rock_armor_warden(image: Image, origin: Vector2i, frame: int) -> void:
	var heave := -2 if frame == 1 else 0
	var dark_stone := Color("526963")
	var stone := Color("829a8f")
	_draw_enemy_shadow(image, origin, 58)
	_fill(image, Rect2i(origin.x + 3, origin.y + 25 + heave, 58, 28), INK)
	_fill(image, Rect2i(origin.x + 6, origin.y + 22 + heave, 52, 28), dark_stone)
	_fill(image, Rect2i(origin.x + 13, origin.y + 14 + heave, 38, 27), stone)
	_fill(image, Rect2i(origin.x + 4, origin.y + 17 + heave, 14, 20), dark_stone.darkened(0.12))
	_fill(image, Rect2i(origin.x + 47, origin.y + 17 + heave, 14, 20), dark_stone.darkened(0.12))
	_fill(image, Rect2i(origin.x + 15, origin.y + 6 + heave, 9, 13), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 28, origin.y + 3 + heave, 9, 14), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 42, origin.y + 7 + heave, 9, 13), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 11, origin.y + 47, 12, 10), INK.lightened(0.08))
	_fill(image, Rect2i(origin.x + 42, origin.y + 47, 12, 10), INK.lightened(0.08))
	_fill(image, Rect2i(origin.x + 17, origin.y + 31 + heave, 31, 7), Color("c6764f").darkened(0.10))
	_fill(image, Rect2i(origin.x + 31, origin.y + 14 + heave, 4, 25), GOLD)
	_fill(image, Rect2i(origin.x + 13, origin.y + 27 + heave, 5, 5), GOLD)
	_fill(image, Rect2i(origin.x + 47, origin.y + 27 + heave, 5, 5), GOLD)


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
