extends TileMapLayer

const MAP_SIZE := Vector2i(36, 20)
const TILE_SIZE := Vector2i(32, 32)
const MAP_BOUNDS := Rect2i(Vector2i.ZERO, MAP_SIZE)
const SOURCE_ID := 0
const DETAIL_TILE_NAMES := [
	"reeds",
	"bank_grass",
	"path_pebbles",
	"wildflowers",
	"stone_cracks",
	"moss",
	"fallen_leaves",
	"water_foam",
]
const DETAIL_TILES := {
	"reeds": Vector2i(0, 1),
	"bank_grass": Vector2i(1, 1),
	"path_pebbles": Vector2i(2, 1),
	"wildflowers": Vector2i(3, 1),
	"stone_cracks": Vector2i(4, 1),
	"moss": Vector2i(5, 1),
	"fallen_leaves": Vector2i(6, 1),
	"water_foam": Vector2i(7, 1),
}
const FERRY_DETAIL_CELLS := {
	"reeds": [Vector2i(8, 2), Vector2i(10, 5), Vector2i(9, 9), Vector2i(11, 13), Vector2i(8, 17), Vector2i(12, 18)],
	"bank_grass": [Vector2i(14, 1), Vector2i(14, 6), Vector2i(14, 10), Vector2i(14, 15), Vector2i(15, 18)],
	"path_pebbles": [Vector2i(15, 17), Vector2i(17, 13), Vector2i(19, 11), Vector2i(21, 10), Vector2i(24, 8), Vector2i(27, 6), Vector2i(30, 4), Vector2i(21, 13), Vector2i(25, 14), Vector2i(29, 14), Vector2i(33, 13)],
	"wildflowers": [Vector2i(18, 3), Vector2i(21, 5), Vector2i(27, 2), Vector2i(33, 7), Vector2i(17, 16), Vector2i(29, 18), Vector2i(34, 16)],
	"stone_cracks": [Vector2i(30, 2), Vector2i(32, 3), Vector2i(31, 4)],
	"moss": [Vector2i(16, 2), Vector2i(18, 7), Vector2i(33, 4), Vector2i(31, 17)],
	"fallen_leaves": [Vector2i(14, 3), Vector2i(31, 5), Vector2i(33, 10), Vector2i(15, 14), Vector2i(29, 16)],
	"water_foam": [Vector2i(2, 3), Vector2i(6, 7), Vector2i(4, 12), Vector2i(9, 15), Vector2i(1, 18)],
}
const MOUNTAIN_DETAIL_CELLS := {
	"reeds": [Vector2i(4, 2), Vector2i(3, 7), Vector2i(4, 12), Vector2i(3, 17)],
	"bank_grass": [Vector2i(5, 1), Vector2i(5, 5), Vector2i(5, 10), Vector2i(5, 15), Vector2i(6, 18)],
	"path_pebbles": [Vector2i(4, 14), Vector2i(7, 15), Vector2i(10, 14), Vector2i(13, 13), Vector2i(16, 11), Vector2i(20, 9), Vector2i(24, 7), Vector2i(28, 5), Vector2i(31, 3)],
	"wildflowers": [Vector2i(8, 3), Vector2i(12, 6), Vector2i(18, 4), Vector2i(22, 14), Vector2i(30, 11), Vector2i(33, 16)],
	"stone_cracks": [Vector2i(25, 6), Vector2i(27, 7), Vector2i(15, 11), Vector2i(16, 12)],
	"moss": [Vector2i(6, 7), Vector2i(11, 9), Vector2i(18, 14), Vector2i(25, 15), Vector2i(32, 8)],
	"fallen_leaves": [Vector2i(6, 4), Vector2i(12, 2), Vector2i(20, 3), Vector2i(29, 10), Vector2i(33, 13), Vector2i(15, 17)],
	"water_foam": [Vector2i(1, 4), Vector2i(2, 9), Vector2i(1, 14), Vector2i(3, 18)],
}

@export var atlas_texture: Texture2D

var context_id := "riverbank"
var map_kind := "ferry"
var rebuild_count := 0
var tile_counts: Dictionary = {}
var tile_cells: Dictionary = {}
var used_cells: Array[Vector2i] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile_set = _build_tile_set()
	_rebuild_details()


func set_context(next_context_id: String) -> bool:
	var next_map_kind := _map_kind_for_context(next_context_id)
	context_id = next_context_id
	visible = not next_map_kind.is_empty()
	if next_map_kind.is_empty() or next_map_kind == map_kind:
		return false
	map_kind = next_map_kind
	_rebuild_details()
	return true


func map_contract() -> Dictionary:
	return {
		"schema_version": 1,
		"context_id": context_id,
		"map_kind": map_kind,
		"map_size": MAP_SIZE,
		"tile_size": TILE_SIZE,
		"used_rect": get_used_rect(),
		"used_cell_count": used_cells.size(),
		"used_cells": used_cells.duplicate(),
		"tile_counts": tile_counts.duplicate(true),
		"tile_cells": tile_cells.duplicate(true),
		"layout_signature": _layout_signature(),
		"filter": texture_filter,
		"visible": visible,
		"collision_authority": false,
		"physics_layer_count": tile_set.get_physics_layers_count(),
		"navigation_layer_count": tile_set.get_navigation_layers_count(),
		"rebuild_count": rebuild_count,
	}


func _build_tile_set() -> TileSet:
	var result := TileSet.new()
	result.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = TILE_SIZE
	for column in range(DETAIL_TILE_NAMES.size()):
		source.create_tile(Vector2i(column, 1))
	result.add_source(source, SOURCE_ID)
	return result


func _rebuild_details() -> void:
	clear()
	rebuild_count += 1
	tile_counts.clear()
	tile_cells.clear()
	used_cells.clear()
	var cells_by_tile: Dictionary = FERRY_DETAIL_CELLS if map_kind == "ferry" else MOUNTAIN_DETAIL_CELLS
	for tile_name in DETAIL_TILE_NAMES:
		tile_counts[tile_name] = 0
		tile_cells[tile_name] = []
		for cell_value in cells_by_tile[tile_name]:
			var cell := Vector2i(cell_value)
			if not MAP_BOUNDS.has_point(cell) or get_cell_source_id(cell) != -1:
				push_error("Invalid or duplicate map-detail cell %s for %s" % [cell, tile_name])
				continue
			set_cell(cell, SOURCE_ID, DETAIL_TILES[tile_name])
			tile_counts[tile_name] += 1
			tile_cells[tile_name].append(cell)
			used_cells.append(cell)
	used_cells.sort_custom(_cell_before)


func _map_kind_for_context(next_context_id: String) -> String:
	match next_context_id:
		"riverbank":
			return "ferry"
		"mountain_path":
			return "mountain_path"
		_:
			return ""


func _layout_signature() -> String:
	var entries := PackedStringArray()
	for tile_name in DETAIL_TILE_NAMES:
		for cell in tile_cells.get(tile_name, []):
			entries.append("%s:%d,%d" % [tile_name, cell.x, cell.y])
	return "|".join(entries).sha256_text()


func _cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)
