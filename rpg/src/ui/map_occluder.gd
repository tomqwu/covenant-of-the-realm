extends Node2D

const INK_ROOT := Color("27312e")
const FRESH_CELADON := Color("8ebb83")

var occluder_id := ""
var kind := "tree"
var dimensions := Vector2.ZERO
var accent := Color("c6764f")
var feet_y := 0.0


func configure(
	next_id: String,
	next_kind: String,
	next_position: Vector2,
	next_dimensions: Vector2,
	next_accent: Color,
	next_feet_y: float,
	next_z_index: int
) -> void:
	occluder_id = next_id
	name = "Occluder_%s" % next_id
	kind = next_kind
	position = next_position.round()
	dimensions = next_dimensions
	accent = next_accent
	feet_y = next_feet_y
	z_index = next_z_index
	queue_redraw()


func visual_contract() -> Dictionary:
	return {
		"id": occluder_id,
		"kind": kind,
		"feet_y": feet_y,
		"z_index": z_index,
		"position": position,
	}


func _draw() -> void:
	match kind:
		"tree":
			draw_circle(Vector2.ZERO, 30.0, FRESH_CELADON.darkened(0.18))
			draw_circle(Vector2(-18, 8), 22.0, FRESH_CELADON)
			draw_circle(Vector2(19, 9), 21.0, Color("a1c98c"))
		"roof":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, 12),
				Vector2(dimensions.x * 0.5, -18),
				Vector2(dimensions.x + 12, 12),
				Vector2(dimensions.x, 34),
				Vector2(0, 34),
			]), accent)
			draw_line(Vector2(0, 34), Vector2(dimensions.x, 34), INK_ROOT.lightened(0.22), 2.0)
