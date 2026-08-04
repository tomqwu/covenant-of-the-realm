extends AnimatedSprite2D

const FRAME_SIZE := Vector2(32, 56)
const DIRECTIONS := ["down", "left", "right", "up"]

@export var atlas_texture: Texture2D
@export_enum("down", "left", "right", "up") var initial_facing := "down"

var facing := "down"


func _ready() -> void:
	facing = initial_facing
	centered = true
	offset = Vector2(0, -28)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = _build_sprite_frames()
	play("idle_%s" % facing)


func set_motion(direction: Vector2, moving: bool) -> void:
	if not direction.is_zero_approx():
		facing = _direction_name(direction)
	var next_animation := "%s_%s" % ["walk" if moving else "idle", facing]
	if animation != next_animation:
		play(next_animation)
	position = position.round()


func animation_contract() -> Dictionary:
	return {
		"frame_size": FRAME_SIZE,
		"foot_anchor": Vector2(16, 52),
		"collision_box": Vector2(16, 20),
		"directions": DIRECTIONS.duplicate(),
		"filter": texture_filter,
	}


func _direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0 else "left"
	return "down" if direction.y > 0 else "up"


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(DIRECTIONS.size()):
		var direction: String = DIRECTIONS[row]
		_add_animation(frames, "idle_%s" % direction, row, [0, 1], 2.0)
		_add_animation(frames, "walk_%s" % direction, row, [2, 3], 6.0)
	return frames


func _add_animation(frames: SpriteFrames, animation_name: String, row: int, columns: Array, fps: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, fps)
	for column in columns:
		var frame := AtlasTexture.new()
		frame.atlas = atlas_texture
		frame.region = Rect2(float(column) * FRAME_SIZE.x, float(row) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, frame)
