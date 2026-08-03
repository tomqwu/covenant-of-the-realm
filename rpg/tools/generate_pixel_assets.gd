extends SceneTree

const OUTPUT_DIR := "res://assets/pixel"
const FRAME_SIZE := Vector2i(32, 56)
const ATLAS_SIZE := Vector2i(128, 224)
const ENEMY_FRAME_SIZE := Vector2i(64, 64)
const ENEMY_ATLAS_SIZE := Vector2i(128, 256)
const LANDMARK_FRAME_SIZE := Vector2i(192, 128)
const LANDMARK_ATLAS_SIZE := Vector2i(2112, 128)
const LANDMARK_PROFILES := [
	"tree_celadon",
	"ferry_house_rust",
	"ferry_house_ochre",
	"ferry_house_teal",
	"ferry_dock",
	"mountain_rock",
	"spring_cave",
	"spring_gate",
	"ferry_boat_repair",
	"ferry_drying_rack",
	"path_rain_shelter",
]
const TRANSPARENT := Color(0, 0, 0, 0)
const INK := Color("27312e")
const SKIN := Color("d9b895")
const PAPER := Color("f2e6cb")
const GOLD := Color("e4c36e")


func _initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 1:
		push_error("pixel asset generator accepts at most one output directory")
		quit(1)
		return
	var output_dir := OUTPUT_DIR if user_args.is_empty() else str(user_args[0])
	DirAccess.make_dir_recursive_absolute(_globalize_output_path(output_dir))
	_generate_actor("protagonist.png", Color("58738f"), Color("b89b63"), "protagonist")
	_generate_actor("yanqing.png", Color("c6764f"), Color("73533d"), "yanqing")
	_generate_actor("liangshu.png", Color("526963"), Color("a88b57"), "liangshu")
	_generate_actor("huishen.png", Color("82966a"), Color("a9784f"), "huishen")
	_generate_enemy_atlas()
	_generate_ferry_tiles()
	_generate_landmark_atlas()
	print("Generated original pixel atlases in %s." % output_dir)
	quit(0)


func _generate_actor(file_name: String, robe: Color, accent: Color, role: String) -> void:
	var image := Image.create(ATLAS_SIZE.x, ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	for row in range(4):
		for column in range(4):
			_draw_frame(image, Vector2i(column * FRAME_SIZE.x, row * FRAME_SIZE.y), row, column, robe, accent, role)
	var output_path := _asset_output_path(file_name)
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _generate_ferry_tiles() -> void:
	var image := Image.create(256, 64, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	_draw_tile_base(image, 0, Color("b7cf9f"), Color("9fbd89"), "grass")
	_draw_tile_base(image, 1, Color("4e9da4"), Color("a7d7cc"), "water")
	_draw_tile_base(image, 2, Color("d7cba5"), Color("b9aa80"), "bank")
	_draw_tile_base(image, 3, Color("d8cca5"), Color("b6aa84"), "path")
	_draw_tile_base(image, 4, Color("a9c98f"), Color("e4c36e"), "moonleaf")
	_draw_tile_base(image, 5, Color("829a8f"), Color("355e63"), "stone")
	_draw_tile_base(image, 6, Color("8ebb83"), Color("739b70"), "grass")
	_draw_tile_base(image, 7, Color("4e9da4"), Color("f2e6cb"), "water")
	_draw_detail_tile(image, 0, "reeds")
	_draw_detail_tile(image, 1, "bank_grass")
	_draw_detail_tile(image, 2, "path_pebbles")
	_draw_detail_tile(image, 3, "wildflowers")
	_draw_detail_tile(image, 4, "stone_cracks")
	_draw_detail_tile(image, 5, "moss")
	_draw_detail_tile(image, 6, "fallen_leaves")
	_draw_detail_tile(image, 7, "water_foam")
	var output_path := _asset_output_path("ferry_tiles.png")
	var error := image.save_png(output_path)
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
	var output_path := _asset_output_path("enemy_profiles.png")
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _generate_landmark_atlas() -> void:
	var image := Image.create(LANDMARK_ATLAS_SIZE.x, LANDMARK_ATLAS_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	for column in range(LANDMARK_PROFILES.size()):
		var origin := Vector2i(column * LANDMARK_FRAME_SIZE.x, 0)
		match LANDMARK_PROFILES[column]:
			"tree_celadon":
				_draw_landmark_tree(image, origin)
			"ferry_house_rust":
				_draw_landmark_house(image, origin, Color("9a513d"), Color("c6764f"), Color("e4c36e"))
			"ferry_house_ochre":
				_draw_landmark_house(image, origin, Color("806e50"), Color("a88b57"), Color("8ebb83"))
			"ferry_house_teal":
				_draw_landmark_house(image, origin, Color("466a68"), Color("668c83"), Color("e7a76f"))
			"ferry_dock":
				_draw_landmark_dock(image, origin)
			"mountain_rock":
				_draw_landmark_rock(image, origin)
			"spring_cave":
				_draw_landmark_cave(image, origin)
			"spring_gate":
				_draw_landmark_gate(image, origin)
			"ferry_boat_repair":
				_draw_landmark_boat_repair(image, origin)
			"ferry_drying_rack":
				_draw_landmark_drying_rack(image, origin)
			"path_rain_shelter":
				_draw_landmark_rain_shelter(image, origin)
	var output_path := _asset_output_path("zhaohe_landmarks.png")
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Unable to save %s: %s" % [output_path, error])
		quit(1)


func _draw_landmark_tree(image: Image, origin: Vector2i) -> void:
	_fill(image, Rect2i(origin.x + 60, origin.y + 122, 72, 4), Color(0.15, 0.19, 0.18, 0.28))
	_fill(image, Rect2i(origin.x + 90, origin.y + 69, 13, 55), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 82, origin.y + 79, 12, 8), Color("6f654b"))
	_fill(image, Rect2i(origin.x + 101, origin.y + 73, 14, 8), Color("6f654b"))
	_fill(image, Rect2i(origin.x + 59, origin.y + 39, 75, 50), Color("739b70"))
	_fill(image, Rect2i(origin.x + 72, origin.y + 24, 50, 65), Color("8ebb83"))
	_fill(image, Rect2i(origin.x + 48, origin.y + 52, 44, 42), Color("82ad78"))
	_fill(image, Rect2i(origin.x + 111, origin.y + 49, 39, 43), Color("a1c98c"))
	_fill(image, Rect2i(origin.x + 82, origin.y + 30, 15, 9), Color("b7d79d"))
	_fill(image, Rect2i(origin.x + 58, origin.y + 62, 11, 8), Color("a9cf91"))
	_fill(image, Rect2i(origin.x + 126, origin.y + 58, 10, 8), Color("c0dca4"))
	_fill(image, Rect2i(origin.x + 68, origin.y + 86, 18, 6), Color("587f62"))
	_fill(image, Rect2i(origin.x + 112, origin.y + 84, 17, 6), Color("698e68"))


func _draw_landmark_house(image: Image, origin: Vector2i, roof: Color, roof_light: Color, banner: Color) -> void:
	_fill(image, Rect2i(origin.x + 14, origin.y + 123, 164, 4), Color(0.15, 0.19, 0.18, 0.30))
	_fill(image, Rect2i(origin.x + 24, origin.y + 49, 144, 74), Color("d7c9a7"))
	_fill(image, Rect2i(origin.x + 24, origin.y + 93, 144, 30), Color("b99d70"))
	for band in range(10):
		var width := 32 + band * 16
		var x := origin.x + 96 - (width >> 1)
		_fill(image, Rect2i(x, origin.y + 10 + band * 4, width, 4), roof if band > 3 else roof_light)
	_fill(image, Rect2i(origin.x + 8, origin.y + 50, 176, 7), roof.darkened(0.12))
	_fill(image, Rect2i(origin.x + 31, origin.y + 57, 7, 66), Color("735b43"))
	_fill(image, Rect2i(origin.x + 154, origin.y + 57, 7, 66), Color("735b43"))
	_fill(image, Rect2i(origin.x + 82, origin.y + 83, 29, 40), INK.lightened(0.10))
	_fill(image, Rect2i(origin.x + 88, origin.y + 91, 17, 32), Color("6f654b"))
	_fill(image, Rect2i(origin.x + 47, origin.y + 72, 23, 18), Color("58738f"))
	_fill(image, Rect2i(origin.x + 51, origin.y + 76, 15, 10), PAPER)
	_fill(image, Rect2i(origin.x + 123, origin.y + 72, 23, 18), Color("58738f"))
	_fill(image, Rect2i(origin.x + 127, origin.y + 76, 15, 10), PAPER)
	_fill(image, Rect2i(origin.x + 115, origin.y + 58, 8, 25), banner)
	_fill(image, Rect2i(origin.x + 116, origin.y + 61, 6, 3), PAPER)


func _draw_landmark_dock(image: Image, origin: Vector2i) -> void:
	_fill(image, Rect2i(origin.x + 8, origin.y + 122, 176, 4), Color(0.15, 0.19, 0.18, 0.24))
	_fill(image, Rect2i(origin.x + 18, origin.y + 68, 154, 34), Color("725f47"))
	for plank in range(7):
		_fill(image, Rect2i(origin.x + 22 + plank * 21, origin.y + 71, 3, 28), Color("b49567"))
	_fill(image, Rect2i(origin.x + 26, origin.y + 102, 8, 21), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 154, origin.y + 102, 8, 21), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 29, origin.y + 108, 72, 12), Color("836c4c"))
	_fill(image, Rect2i(origin.x + 39, origin.y + 120, 51, 5), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 107, origin.y + 57, 47, 6), Color("e4c36e"))
	_fill(image, Rect2i(origin.x + 128, origin.y + 43, 5, 21), Color("735b43"))


func _draw_landmark_rock(image: Image, origin: Vector2i) -> void:
	_fill(image, Rect2i(origin.x + 50, origin.y + 122, 92, 4), Color(0.15, 0.19, 0.18, 0.30))
	_fill(image, Rect2i(origin.x + 61, origin.y + 83, 71, 39), INK)
	_fill(image, Rect2i(origin.x + 67, origin.y + 72, 58, 48), Color("60766f"))
	_fill(image, Rect2i(origin.x + 78, origin.y + 63, 35, 38), Color("829a8f"))
	_fill(image, Rect2i(origin.x + 84, origin.y + 69, 19, 7), Color("9bada2"))
	_fill(image, Rect2i(origin.x + 69, origin.y + 97, 18, 5), Color("8ebb83"))
	_fill(image, Rect2i(origin.x + 105, origin.y + 103, 15, 4), Color("739b70"))


func _draw_landmark_cave(image: Image, origin: Vector2i) -> void:
	_fill(image, Rect2i(origin.x + 15, origin.y + 123, 162, 4), Color(0.15, 0.19, 0.18, 0.34))
	for band in range(9):
		var width := 72 + band * 12
		var x := origin.x + 96 - (width >> 1)
		_fill(image, Rect2i(x, origin.y + 30 + band * 8, width, 8), Color("486d68") if band < 4 else Color("355e63"))
	_fill(image, Rect2i(origin.x + 68, origin.y + 70, 56, 53), INK.darkened(0.18))
	_fill(image, Rect2i(origin.x + 76, origin.y + 61, 40, 17), INK.darkened(0.18))
	_fill(image, Rect2i(origin.x + 92, origin.y + 88, 8, 8), GOLD)
	_fill(image, Rect2i(origin.x + 88, origin.y + 84, 16, 16), Color(0.89, 0.76, 0.43, 0.18))
	_fill(image, Rect2i(origin.x + 43, origin.y + 99, 18, 5), Color("8ebb83"))
	_fill(image, Rect2i(origin.x + 132, origin.y + 106, 15, 4), Color("739b70"))


func _draw_landmark_gate(image: Image, origin: Vector2i) -> void:
	_fill(image, Rect2i(origin.x + 49, origin.y + 123, 94, 4), Color(0.15, 0.19, 0.18, 0.24))
	_fill(image, Rect2i(origin.x + 64, origin.y + 64, 10, 59), Color("755f43"))
	_fill(image, Rect2i(origin.x + 118, origin.y + 64, 10, 59), Color("755f43"))
	_fill(image, Rect2i(origin.x + 55, origin.y + 56, 82, 11), Color("9a513d"))
	_fill(image, Rect2i(origin.x + 62, origin.y + 49, 68, 8), Color("c6764f"))
	_fill(image, Rect2i(origin.x + 91, origin.y + 50, 10, 10), GOLD)
	_fill(image, Rect2i(origin.x + 83, origin.y + 72, 26, 15), Color("d7c9a7"))
	_fill(image, Rect2i(origin.x + 87, origin.y + 76, 18, 3), INK.lightened(0.15))


func _draw_landmark_boat_repair(image: Image, origin: Vector2i) -> void:
	# A low, open repair cradle keeps the riverbank silhouette readable without
	# pretending to own collision. Fresh paulownia, old planks, rope and one tool
	# establish ordinary ferry work in the bright morning palette.
	_fill(image, Rect2i(origin.x + 23, origin.y + 122, 146, 4), Color(0.15, 0.19, 0.18, 0.25))
	_fill(image, Rect2i(origin.x + 47, origin.y + 91, 8, 32), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 137, origin.y + 91, 8, 32), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 39, origin.y + 91, 24, 6), Color("a9784f"))
	_fill(image, Rect2i(origin.x + 129, origin.y + 91, 24, 6), Color("a9784f"))
	_fill(image, Rect2i(origin.x + 27, origin.y + 72, 138, 8), INK.lightened(0.08))
	_fill(image, Rect2i(origin.x + 34, origin.y + 67, 124, 20), Color("a9784f"))
	_fill(image, Rect2i(origin.x + 43, origin.y + 76, 106, 16), Color("c28a58"))
	_fill(image, Rect2i(origin.x + 53, origin.y + 82, 86, 12), Color("d9b895"))
	_fill(image, Rect2i(origin.x + 48, origin.y + 62, 96, 6), Color("e7a76f"))
	for rib_x in [55, 75, 96, 117, 137]:
		_fill(image, Rect2i(origin.x + rib_x, origin.y + 55, 4, 31), Color("735b43"))
	_fill(image, Rect2i(origin.x + 149, origin.y + 92, 5, 25), Color("e4c36e"))
	_fill(image, Rect2i(origin.x + 145, origin.y + 90, 13, 5), Color("735b43"))
	_fill(image, Rect2i(origin.x + 29, origin.y + 101, 15, 12), Color("58738f"))
	_fill(image, Rect2i(origin.x + 32, origin.y + 98, 9, 4), Color("f2e6cb"))


func _draw_landmark_drying_rack(image: Image, origin: Vector2i) -> void:
	# The narrow footprint fits beside the eastern house: herbs, washed cloth and
	# a time tablet hang in distinct material blocks instead of noisy decoration.
	_fill(image, Rect2i(origin.x + 39, origin.y + 122, 114, 4), Color(0.15, 0.19, 0.18, 0.24))
	_fill(image, Rect2i(origin.x + 47, origin.y + 50, 7, 73), Color("735b43"))
	_fill(image, Rect2i(origin.x + 139, origin.y + 50, 7, 73), Color("735b43"))
	_fill(image, Rect2i(origin.x + 41, origin.y + 47, 111, 7), Color("a9784f"))
	_fill(image, Rect2i(origin.x + 58, origin.y + 56, 23, 29), Color("f2e6cb"))
	_fill(image, Rect2i(origin.x + 61, origin.y + 61, 17, 4), Color("58738f"))
	_fill(image, Rect2i(origin.x + 87, origin.y + 56, 19, 34), Color("8ebb83"))
	_fill(image, Rect2i(origin.x + 91, origin.y + 61, 11, 20), Color("739b70"))
	_fill(image, Rect2i(origin.x + 113, origin.y + 56, 17, 27), Color("c6764f"))
	_fill(image, Rect2i(origin.x + 116, origin.y + 61, 11, 5), Color("e7a76f"))
	for bundle_x in [62, 74, 91, 103, 118, 128]:
		_fill(image, Rect2i(origin.x + bundle_x, origin.y + 93, 3, 18), Color("526963"))
		_fill(image, Rect2i(origin.x + bundle_x - 2, origin.y + 101, 7, 8), Color("8ebb83"))
	_fill(image, Rect2i(origin.x + 134, origin.y + 69, 12, 17), Color("d7c9a7"))
	_fill(image, Rect2i(origin.x + 136, origin.y + 73, 8, 2), INK.lightened(0.15))
	_fill(image, Rect2i(origin.x + 136, origin.y + 78, 7, 2), INK.lightened(0.15))


func _draw_landmark_rain_shelter(image: Image, origin: Vector2i) -> void:
	# Open sides communicate that the shelter is non-blocking presentation. A dry
	# wood bundle, water dipper and stone bench make the travellers' compact real.
	_fill(image, Rect2i(origin.x + 35, origin.y + 122, 122, 4), Color(0.15, 0.19, 0.18, 0.28))
	_fill(image, Rect2i(origin.x + 48, origin.y + 68, 8, 55), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 137, origin.y + 68, 8, 55), Color("5d513c"))
	_fill(image, Rect2i(origin.x + 34, origin.y + 55, 124, 10), Color("806e50"))
	_fill(image, Rect2i(origin.x + 41, origin.y + 48, 110, 9), Color("a88b57"))
	_fill(image, Rect2i(origin.x + 52, origin.y + 41, 88, 8), Color("d9b895"))
	_fill(image, Rect2i(origin.x + 61, origin.y + 91, 71, 22), Color("60766f"))
	_fill(image, Rect2i(origin.x + 67, origin.y + 86, 59, 9), Color("829a8f"))
	_fill(image, Rect2i(origin.x + 72, origin.y + 89, 25, 4), Color("9bada2"))
	_fill(image, Rect2i(origin.x + 55, origin.y + 104, 14, 14), Color("735b43"))
	_fill(image, Rect2i(origin.x + 58, origin.y + 100, 8, 5), Color("e7a76f"))
	_fill(image, Rect2i(origin.x + 121, origin.y + 101, 8, 15), Color("58738f"))
	_fill(image, Rect2i(origin.x + 117, origin.y + 99, 15, 4), Color("f2e6cb"))
	_fill(image, Rect2i(origin.x + 82, origin.y + 68, 30, 13), Color("f2e6cb"))
	_fill(image, Rect2i(origin.x + 87, origin.y + 72, 20, 3), INK.lightened(0.15))
	_fill(image, Rect2i(origin.x + 88, origin.y + 77, 16, 2), INK.lightened(0.15))


func _asset_output_path(file_name: String) -> String:
	var user_args := OS.get_cmdline_user_args()
	var output_dir := OUTPUT_DIR if user_args.is_empty() else str(user_args[0])
	return _globalize_output_path(output_dir.path_join(file_name))


func _globalize_output_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


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


func _draw_detail_tile(image: Image, column: int, pattern: String) -> void:
	var origin := Vector2i(column * 32, 32)
	match pattern:
		"reeds":
			for offset_x in [7, 15, 24]:
				_fill(image, Rect2i(origin.x + offset_x, origin.y + 10, 2, 18), Color("526963"))
				_fill(image, Rect2i(origin.x + offset_x - 1, origin.y + 8, 4, 5), Color("a9784f"))
			_fill(image, Rect2i(origin.x + 4, origin.y + 17, 5, 2), Color("8ebb83"))
			_fill(image, Rect2i(origin.x + 16, origin.y + 20, 6, 2), Color("8ebb83"))
		"bank_grass":
			for offset_x in [5, 13, 22, 28]:
				_fill(image, Rect2i(origin.x + offset_x, origin.y + 17, 2, 11), Color("739b70"))
				_fill(image, Rect2i(origin.x + offset_x - 3, origin.y + 20, 4, 2), Color("9fbd89"))
				_fill(image, Rect2i(origin.x + offset_x + 1, origin.y + 14, 3, 2), Color("8ebb83"))
		"path_pebbles":
			_fill(image, Rect2i(origin.x + 4, origin.y + 10, 7, 4), Color("9a835d"))
			_fill(image, Rect2i(origin.x + 18, origin.y + 7, 5, 3), Color("829a8f"))
			_fill(image, Rect2i(origin.x + 23, origin.y + 21, 6, 4), Color("b6aa84"))
			_fill(image, Rect2i(origin.x + 9, origin.y + 25, 4, 3), Color("829a8f"))
		"wildflowers":
			for offset_x in [7, 17, 26]:
				_fill(image, Rect2i(origin.x + offset_x, origin.y + 13, 2, 15), Color("739b70"))
				_fill(image, Rect2i(origin.x + offset_x - 2, origin.y + 10, 6, 5), Color("f2e6cb"))
				_fill(image, Rect2i(origin.x + offset_x, origin.y + 11, 2, 2), Color("e4c36e"))
		"stone_cracks":
			_fill(image, Rect2i(origin.x + 15, origin.y + 5, 3, 9), Color("355e63"))
			_fill(image, Rect2i(origin.x + 17, origin.y + 12, 7, 3), Color("355e63"))
			_fill(image, Rect2i(origin.x + 22, origin.y + 14, 3, 7), Color("355e63"))
			_fill(image, Rect2i(origin.x + 8, origin.y + 21, 9, 3), Color("526963"))
			_fill(image, Rect2i(origin.x + 7, origin.y + 23, 3, 5), Color("526963"))
		"moss":
			_fill(image, Rect2i(origin.x + 3, origin.y + 19, 11, 7), Color("739b70"))
			_fill(image, Rect2i(origin.x + 8, origin.y + 14, 12, 10), Color("8ebb83"))
			_fill(image, Rect2i(origin.x + 18, origin.y + 18, 10, 8), Color("9fbd89"))
			_fill(image, Rect2i(origin.x + 12, origin.y + 11, 4, 4), Color("b7cf9f"))
		"fallen_leaves":
			_fill(image, Rect2i(origin.x + 5, origin.y + 8, 7, 4), Color("c6764f"))
			_fill(image, Rect2i(origin.x + 18, origin.y + 14, 5, 7), Color("a9784f"))
			_fill(image, Rect2i(origin.x + 8, origin.y + 24, 6, 4), Color("e7a76f"))
			_fill(image, Rect2i(origin.x + 25, origin.y + 6, 4, 6), Color("c6764f"))
		"water_foam":
			_fill(image, Rect2i(origin.x + 2, origin.y + 8, 13, 3), Color("f2e6cb"))
			_fill(image, Rect2i(origin.x + 10, origin.y + 11, 10, 2), Color("a7d7cc"))
			_fill(image, Rect2i(origin.x + 17, origin.y + 21, 13, 3), Color("f2e6cb"))
			_fill(image, Rect2i(origin.x + 5, origin.y + 25, 10, 2), Color("a7d7cc"))


func _draw_frame(image: Image, origin: Vector2i, direction: int, column: int, robe: Color, accent: Color, role: String) -> void:
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

	if role == "protagonist":
		_fill(image, Rect2i(center_x - 12, body_y + 6, 5, 21), accent)
		_fill(image, Rect2i(center_x - 14, body_y + 8, 3, 17), accent.darkened(0.18))
	elif role == "yanqing":
		_fill(image, Rect2i(center_x + 10, body_y + 8, 4, 20), accent)
		_fill(image, Rect2i(center_x + 14, body_y + 12, 2, 16), accent.darkened(0.22))
	elif role == "liangshu":
		# The levee keeper carries a measuring staff and a rain-dark shoulder cape.
		_fill(image, Rect2i(center_x - 13, body_y + 5, 26, 8), accent.darkened(0.22))
		_fill(image, Rect2i(center_x + 12, body_y + 1, 3, 35), accent.darkened(0.30))
	else:
		# The herb keeper wears a woven apron and keeps a seed basket at her hip.
		_fill(image, Rect2i(center_x - 9, body_y + 11, 18, 16), PAPER.darkened(0.18))
		_fill(image, Rect2i(center_x + 9, body_y + 15, 7, 12), accent.darkened(0.12))
		_fill(image, Rect2i(center_x + 8, body_y + 12, 9, 3), accent.lightened(0.10))

	var head_y := origin.y + 7 + bob
	_fill(image, Rect2i(center_x - 7, head_y, 14, 14), SKIN)
	if role == "liangshu":
		# Broad reed hat and silver beard distinguish Liangshu at map scale in every direction.
		_fill(image, Rect2i(center_x - 13, head_y - 3, 26, 4), accent)
		_fill(image, Rect2i(center_x - 9, head_y - 7, 18, 5), accent.lightened(0.12))
		_fill(image, Rect2i(center_x - 7, head_y, 14, 3), INK.lightened(0.10))
		_fill(image, Rect2i(center_x - 5, head_y + 11, 10, 7), Color("b8b3a1"))
	elif role == "huishen":
		# A low cloth wrap, small bun and green pin keep Huishen distinct from Yanqing.
		_fill(image, Rect2i(center_x - 8, head_y - 1, 16, 6), accent.lightened(0.12))
		_fill(image, Rect2i(center_x - 7, head_y - 5, 14, 5), INK.lightened(0.06))
		_fill(image, Rect2i(center_x + 5, head_y - 8, 7, 6), INK)
		_fill(image, Rect2i(center_x - 10, head_y + 1, 3, 10), Color("8ebb83"))
	else:
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
