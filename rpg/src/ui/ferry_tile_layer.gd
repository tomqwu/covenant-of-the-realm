extends TileMapLayer

const MAP_SIZE := Vector2i(36, 20)
const TILE_SIZE := Vector2i(32, 32)
const SOURCE_ID := 0
const TILE_GRASS := Vector2i(0, 0)
const TILE_WATER := Vector2i(1, 0)
const TILE_BANK := Vector2i(2, 0)
const TILE_PATH := Vector2i(3, 0)
const TILE_MOONLEAF := Vector2i(4, 0)
const TILE_STONE := Vector2i(5, 0)
const TILE_DEEP_GRASS := Vector2i(6, 0)
const TILE_WATER_GLINT := Vector2i(7, 0)
const MOUNTAIN_GATE_BRIDGE := Rect2i(2, 12, 5, 5)

@export var atlas_texture: Texture2D
@export_enum("ferry", "mountain_path") var map_kind := "ferry"

var tile_counts: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile_set = _build_tile_set()
	_build_ground()


func map_contract() -> Dictionary:
	return {
		"map_kind": map_kind,
		"map_size": MAP_SIZE,
		"tile_size": TILE_SIZE,
		"used_rect": get_used_rect(),
		"tile_counts": tile_counts.duplicate(true),
		"mountain_gate_bridge": MOUNTAIN_GATE_BRIDGE if map_kind == "mountain_path" else Rect2i(),
		"filter": texture_filter,
	}


func tile_kind_at_normalized(normalized_position: Vector2) -> String:
	if (
		normalized_position.x < 0.0
		or normalized_position.y < 0.0
		or normalized_position.x >= 1.0
		or normalized_position.y >= 1.0
	):
		return "outside"
	var cell := Vector2i(
		int(floor(normalized_position.x * float(MAP_SIZE.x))),
		int(floor(normalized_position.y * float(MAP_SIZE.y)))
	)
	return _tile_kind(get_cell_atlas_coords(cell))


func _build_tile_set() -> TileSet:
	var result := TileSet.new()
	result.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = TILE_SIZE
	for column in range(8):
		source.create_tile(Vector2i(column, 0))
	result.add_source(source, SOURCE_ID)
	return result


func _build_ground() -> void:
	clear()
	tile_counts = {
		"grass": 0,
		"water": 0,
		"bank": 0,
		"path": 0,
		"moonleaf": 0,
		"stone": 0,
	}
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var tile := _tile_for_cell(Vector2i(x, y))
			set_cell(Vector2i(x, y), SOURCE_ID, tile)
			_count_tile(tile)


func _tile_for_cell(cell: Vector2i) -> Vector2i:
	if map_kind == "mountain_path":
		return _mountain_tile_for_cell(cell)
	if cell.x <= 11:
		return TILE_WATER_GLINT if (cell.x + cell.y) % 5 == 0 else TILE_WATER
	if cell.x <= 14:
		return TILE_BANK
	if Rect2i(22, 11, 6, 3).has_point(cell):
		return TILE_MOONLEAF
	if Rect2i(30, 2, 3, 3).has_point(cell):
		return TILE_STONE
	var point := Vector2(cell) + Vector2(0.5, 0.5)
	var main_path := _distance_to_polyline(point, [Vector2(13, 18), Vector2(17, 12), Vector2(22, 9), Vector2(31, 3)])
	var field_path := _distance_to_polyline(point, [Vector2(17, 12), Vector2(24, 14), Vector2(34, 13)])
	if minf(main_path, field_path) <= 1.35:
		return TILE_PATH
	return TILE_DEEP_GRASS if (cell.x + cell.y) % 7 == 0 else TILE_GRASS


func _mountain_tile_for_cell(cell: Vector2i) -> Vector2i:
	if MOUNTAIN_GATE_BRIDGE.has_point(cell):
		return TILE_STONE if cell.x <= 4 else TILE_PATH
	if cell.x <= 4:
		return TILE_WATER_GLINT if (cell.x + cell.y) % 4 == 0 else TILE_WATER
	var point := Vector2(cell) + Vector2(0.5, 0.5)
	var path_distance := _distance_to_polyline(point, [
		Vector2(3, 14),
		Vector2(9, 15),
		Vector2(14, 12),
		Vector2(20, 9),
		Vector2(27, 6),
		Vector2(32, 3),
	])
	if path_distance <= 1.25:
		return TILE_PATH
	if Rect2i(24, 5, 5, 4).has_point(cell) or Rect2i(14, 10, 3, 3).has_point(cell):
		return TILE_STONE
	return TILE_DEEP_GRASS if (cell.x * 3 + cell.y) % 5 == 0 else TILE_GRASS


func _distance_to_polyline(point: Vector2, points: Array) -> float:
	var nearest := INF
	for index in range(points.size() - 1):
		nearest = minf(nearest, _distance_to_segment(point, points[index], points[index + 1]))
	return nearest


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.is_zero_approx():
		return point.distance_to(start)
	var amount := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * amount)


func _count_tile(tile: Vector2i) -> void:
	var key := _tile_kind(tile)
	tile_counts[key] += 1


func _tile_kind(tile: Vector2i) -> String:
	match tile:
		TILE_WATER, TILE_WATER_GLINT:
			return "water"
		TILE_BANK:
			return "bank"
		TILE_PATH:
			return "path"
		TILE_MOONLEAF:
			return "moonleaf"
		TILE_STONE:
			return "stone"
	return "grass"
