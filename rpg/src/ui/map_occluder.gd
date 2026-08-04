extends Sprite2D

const LANDMARK_ATLAS := preload("res://assets/pixel/zhaohe_landmarks.png")
const FRAME_SIZE := Vector2i(192, 128)
const PROFILE_COLUMNS := {
	"tree_celadon": 0,
	"ferry_house_rust": 1,
	"ferry_house_ochre": 2,
	"ferry_house_teal": 3,
}

var occluder_id := ""
var kind := ""
var profile_id := ""
var feet_y := 0.0


func configure(
	next_id: String,
	next_kind: String,
	next_profile_id: String,
	next_position: Vector2,
	next_feet_y: float,
	next_z_index: int
) -> bool:
	if not PROFILE_COLUMNS.has(next_profile_id):
		return false
	occluder_id = next_id
	name = "Occluder_%s" % next_id
	kind = next_kind
	profile_id = next_profile_id
	feet_y = next_feet_y
	texture = LANDMARK_ATLAS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region_enabled = true
	region_filter_clip_enabled = true
	region_rect = Rect2(
		Vector2(float(int(PROFILE_COLUMNS[profile_id]) * FRAME_SIZE.x), 0.0),
		Vector2(FRAME_SIZE)
	)
	centered = true
	offset = Vector2(0.0, -float(FRAME_SIZE.y) * 0.5)
	position = next_position.round()
	z_index = next_z_index
	return true


func visual_contract() -> Dictionary:
	return {
		"id": occluder_id,
		"kind": kind,
		"profile_id": profile_id,
		"feet_y": feet_y,
		"z_index": z_index,
		"position": position,
		"frame_size": FRAME_SIZE,
		"frame_column": int(PROFILE_COLUMNS.get(profile_id, -1)),
		"filter": texture_filter,
		"atlas_path": texture.resource_path if texture != null else "",
		"asset_backed": texture == LANDMARK_ATLAS and region_enabled,
		"pixel_snapped": position == position.round(),
		"collision_authority": false,
	}
