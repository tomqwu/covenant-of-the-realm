extends AnimatedSprite2D

const FRAME_SIZE := Vector2(64, 64)
const FOOT_ANCHOR := Vector2(32, 56)
const STANDARD_CUE_DURATION := 0.70
const FAST_CUE_DURATION := 0.18
const PROFILE_ROWS := {
	"rock_armor_young": 0,
	"spring_moss_shell": 1,
	"unbalanced_stone_puppet": 2,
	"rock_armor_warden": 3,
}
const STATE_COLUMNS := {
	"idle": [0, 1],
	"attack": [2, 3],
	"react": [4, 5],
	"defeat": [6, 7],
}
const STATE_FPS := {
	"idle": 2.5,
	"attack": 8.0,
	"react": 7.0,
	"defeat": 6.0,
}
const REGULAR_PROFILES := [
	"rock_armor_young",
	"spring_moss_shell",
	"unbalanced_stone_puppet",
]
const REACTION_EVENTS := ["weakness_exposed", "art_hit", "talisman_hit"]
const ATTACK_EVENTS := ["enemy_hit", "enemy_glanced"]
const SEMANTIC_EVENT_PRIORITY := [
	"weakness_exposed",
	"art_hit",
	"talisman_hit",
	"enemy_hit",
	"enemy_glanced",
]
const TERMINAL_EVENTS := [
	"regular_enemy_won",
	"boss_arrived",
	"battle_won",
	"retreated",
	"companion_rescue",
]

@export var atlas_texture: Texture2D
@export_enum("rock_armor_young", "spring_moss_shell", "unbalanced_stone_puppet", "rock_armor_warden") var initial_enemy_id := "rock_armor_young"
@export_enum("current", "outgoing") var presentation_role := "current"

var enemy_id := "rock_armor_young"
var semantic_state := "idle"
var semantic_event_id := ""
var cue_duration := 0.0
var cue_remaining := 0.0
var cue_motion_enabled := true
var cue_anchor := Vector2.ZERO
var cue_offset := Vector2.ZERO


func _ready() -> void:
	centered = true
	offset = Vector2(0, -24)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = _build_sprite_frames()
	if presentation_role == "outgoing":
		clear_outgoing_defeat()
	else:
		set_enemy_id(initial_enemy_id)


func set_enemy_id(next_enemy_id: String) -> bool:
	if presentation_role != "current" or not PROFILE_ROWS.has(next_enemy_id):
		return false
	var needs_reset := enemy_id != next_enemy_id or semantic_state != "idle"
	enemy_id = next_enemy_id
	if needs_reset or animation != _animation_name("idle"):
		reset_presentation()
	position = position.round()
	return true


func set_outgoing_anchor(next_anchor: Vector2) -> bool:
	if (
		presentation_role != "outgoing"
		or not is_finite(next_anchor.x)
		or not is_finite(next_anchor.y)
	):
		return false
	cue_anchor = next_anchor.round()
	if cue_remaining <= 0.0:
		position = cue_anchor
	return true


func start_outgoing_defeat(
	profile_id: String,
	fast_mode: bool,
	reduced_motion: bool,
	anchor: Vector2 = Vector2.ZERO
) -> bool:
	if (
		presentation_role != "outgoing"
		or profile_id not in REGULAR_PROFILES
		or not is_finite(anchor.x)
		or not is_finite(anchor.y)
	):
		return false
	clear_outgoing_defeat()
	enemy_id = profile_id
	semantic_state = "defeat"
	semantic_event_id = "regular_enemy_won"
	cue_duration = FAST_CUE_DURATION if fast_mode else STANDARD_CUE_DURATION
	cue_remaining = cue_duration
	cue_motion_enabled = not reduced_motion
	cue_anchor = anchor.round()
	cue_offset = Vector2.ZERO
	position = cue_anchor
	modulate = Color.WHITE
	visible = true
	_play_animation(_animation_name("defeat"), cue_motion_enabled)
	return true


func consume_battle_events(event_ids: Array, fast_mode: bool, reduced_motion: bool) -> bool:
	if presentation_role != "current":
		return false
	for terminal_event in TERMINAL_EVENTS:
		if event_ids.has(terminal_event):
			reset_presentation()
			return false
	var selected_event := ""
	for event_id in SEMANTIC_EVENT_PRIORITY:
		if event_ids.has(event_id):
			selected_event = event_id
			break
	if selected_event.is_empty():
		return false
	if selected_event in REACTION_EVENTS:
		semantic_state = "react"
	elif selected_event in ATTACK_EVENTS:
		semantic_state = "attack"
	else:
		return false
	semantic_event_id = selected_event
	cue_duration = FAST_CUE_DURATION if fast_mode else STANDARD_CUE_DURATION
	cue_remaining = cue_duration
	cue_motion_enabled = not reduced_motion
	_play_animation(_animation_name(semantic_state), cue_motion_enabled)
	return true


func advance_presentation(delta: float) -> bool:
	if not is_finite(delta) or delta <= 0.0 or cue_remaining <= 0.0:
		return false
	cue_remaining = maxf(0.0, cue_remaining - delta)
	if cue_remaining <= 0.0:
		if presentation_role == "outgoing":
			clear_outgoing_defeat()
		else:
			reset_presentation()
	elif presentation_role == "outgoing" and cue_motion_enabled:
		var progress := clampf(1.0 - cue_remaining / cue_duration, 0.0, 1.0)
		var travel_progress := clampf((progress - 0.18) / 0.82, 0.0, 1.0)
		cue_offset = Vector2(-roundf(14.0 * travel_progress), roundf(4.0 * travel_progress))
		position = cue_anchor + cue_offset
		modulate.a = 1.0 - 0.72 * clampf((progress - 0.55) / 0.45, 0.0, 1.0)
	return true


func reset_presentation() -> void:
	if presentation_role == "outgoing":
		clear_outgoing_defeat()
		return
	semantic_state = "idle"
	semantic_event_id = ""
	cue_duration = 0.0
	cue_remaining = 0.0
	cue_motion_enabled = true
	_play_animation(_animation_name("idle"), true)


func clear_outgoing_defeat() -> void:
	if presentation_role != "outgoing":
		return
	stop()
	enemy_id = ""
	semantic_state = "idle"
	semantic_event_id = ""
	cue_duration = 0.0
	cue_remaining = 0.0
	cue_motion_enabled = true
	cue_offset = Vector2.ZERO
	position = cue_anchor
	modulate = Color.WHITE
	visible = false


func animation_contract() -> Dictionary:
	return {
		"frame_size": FRAME_SIZE,
		"foot_anchor": FOOT_ANCHOR,
		"profiles": PROFILE_ROWS.keys(),
		"states": ["idle", "attack", "react", "defeat"],
		"frames_per_state": 2,
		"animations_per_profile": 4,
		"state_fps": STATE_FPS.duplicate(true),
		"semantic_event_priority": SEMANTIC_EVENT_PRIORITY.duplicate(),
		"terminal_events": TERMINAL_EVENTS.duplicate(),
		"standard_cue_duration": STANDARD_CUE_DURATION,
		"fast_cue_duration": FAST_CUE_DURATION,
		"filter": texture_filter,
		"damage_authority": false,
		"intent_authority": false,
		"gameplay_timing_authority": false,
		"save_authority": false,
		"outgoing_profiles": REGULAR_PROFILES.duplicate(),
	}


func presentation_contract() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"state": semantic_state,
		"event_id": semantic_event_id,
		"duration": cue_duration,
		"remaining": cue_remaining,
		"active": cue_remaining > 0.0,
		"motion_enabled": cue_motion_enabled,
		"motion_skipped": cue_remaining > 0.0 and not cue_motion_enabled,
		"animation": str(animation),
		"role": presentation_role,
		"anchor": cue_anchor,
		"offset": cue_offset,
		"alpha": modulate.a,
		"visible": visible,
		"rule_authority": false,
		"timing_authority": false,
		"save_authority": false,
		"blocks_input": false,
	}


func _process(delta: float) -> void:
	advance_presentation(delta)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for profile_id in PROFILE_ROWS:
		for state_id in STATE_COLUMNS:
			var animation_name := "%s_%s" % [state_id, profile_id]
			frames.add_animation(animation_name)
			frames.set_animation_loop(animation_name, state_id == "idle")
			frames.set_animation_speed(animation_name, float(STATE_FPS[state_id]))
			for column in STATE_COLUMNS[state_id]:
				var frame := AtlasTexture.new()
				frame.atlas = atlas_texture
				frame.region = Rect2(float(column) * FRAME_SIZE.x, float(PROFILE_ROWS[profile_id]) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
				frames.add_frame(animation_name, frame)
	return frames


func _animation_name(state_id: String) -> String:
	return "%s_%s" % [state_id, enemy_id]


func _play_animation(animation_name: String, motion_enabled: bool) -> void:
	stop()
	play(animation_name)
	if not motion_enabled:
		pause()
		frame = 0
		frame_progress = 0.0
