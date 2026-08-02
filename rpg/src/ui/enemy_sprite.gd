extends AnimatedSprite2D

const FRAME_SIZE := Vector2(64, 64)
const FOOT_ANCHOR := Vector2(32, 56)
const PROFILE_ROWS := {
	"rock_armor_young": 0,
	"spring_moss_shell": 1,
	"unbalanced_stone_puppet": 2,
	"rock_armor_warden": 3,
}

@export var atlas_texture: Texture2D
@export_enum("rock_armor_young", "spring_moss_shell", "unbalanced_stone_puppet", "rock_armor_warden") var initial_enemy_id := "rock_armor_young"

var enemy_id := "rock_armor_young"


func _ready() -> void:
	centered = true
	offset = Vector2(0, -24)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = _build_sprite_frames()
	set_enemy_id(initial_enemy_id)


func set_enemy_id(next_enemy_id: String) -> bool:
	if not PROFILE_ROWS.has(next_enemy_id):
		return false
	enemy_id = next_enemy_id
	var next_animation := "idle_%s" % enemy_id
	if animation != next_animation:
		play(next_animation)
	position = position.round()
	return true


func animation_contract() -> Dictionary:
	return {
		"frame_size": FRAME_SIZE,
		"foot_anchor": FOOT_ANCHOR,
		"profiles": PROFILE_ROWS.keys(),
		"frames_per_profile": 2,
		"fps": 2.5,
		"filter": texture_filter,
	}


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for profile_id in PROFILE_ROWS:
		var animation_name := "idle_%s" % profile_id
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, 2.5)
		for column in range(2):
			var frame := AtlasTexture.new()
			frame.atlas = atlas_texture
			frame.region = Rect2(float(column) * FRAME_SIZE.x, float(PROFILE_ROWS[profile_id]) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
			frames.add_frame(animation_name, frame)
	return frames
