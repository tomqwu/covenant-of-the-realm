extends Control
class_name IntentTelegraph

const PANEL_SIZE := Vector2(532.0, 90.0)
const STANDARD_CUE_DURATION := 0.70
const FAST_CUE_DURATION := 0.18
const STANDARD_PRIMARY_FONT_SIZE := 18
const STANDARD_SECONDARY_FONT_SIZE := 14
const LARGE_PRIMARY_FONT_SIZE := 23
const LARGE_SECONDARY_FONT_SIZE := 18
const MAX_DISPLAY_ID_LENGTH := 64
const MAX_DISPLAY_TEXT_LENGTH := 24
const MAX_DISPLAY_DAMAGE := 999

const INK_ROOT := Color("27312e")
const WARM_PAPER := Color("f2e6cb")
const HIGH_CONTRAST_INK := Color("131a17")
const HIGH_CONTRAST_PAPER := Color("fdfaf1")
const NEUTRAL_ACCENT := Color("58738f")

const PROFILE_STYLES := {
	"rock_armor_young": {
		"accent": Color("8f4a32"),
		"edge": "cracked",
	},
	"spring_moss_shell": {
		"accent": Color("34737a"),
		"edge": "droplets",
	},
	"unbalanced_stone_puppet": {
		"accent": Color("355e63"),
		"edge": "stepped",
	},
	"rock_armor_warden": {
		"accent": Color("8a6b24"),
		"edge": "armored",
	},
}

const INTENT_STYLES := {
	"rock_probing_charge": {
		"enemy_id": "rock_armor_young",
		"shape": "probing_charge",
	},
	"rock_rending_charge": {
		"enemy_id": "rock_armor_young",
		"shape": "rending_charge",
	},
	"moss_absorb_tide": {
		"enemy_id": "spring_moss_shell",
		"shape": "absorb_tide",
	},
	"moss_spore_spray": {
		"enemy_id": "spring_moss_shell",
		"shape": "spore_spray",
	},
	"puppet_unbalanced_swing": {
		"enemy_id": "unbalanced_stone_puppet",
		"shape": "unbalanced_swing",
	},
	"puppet_rebalance_step": {
		"enemy_id": "unbalanced_stone_puppet",
		"shape": "rebalance_step",
	},
	"warden_pressing_charge": {
		"enemy_id": "rock_armor_warden",
		"shape": "pressing_charge",
	},
	"warden_stonebreaking_blow": {
		"enemy_id": "rock_armor_warden",
		"shape": "stonebreaking_blow",
	},
	"warden_nest_guard": {
		"enemy_id": "rock_armor_warden",
		"shape": "nest_guard",
	},
}

var presentation := {"active": false}
var enemy_id := ""
var recognized_intent := false
var shape_id := "neutral"
var profile_edge := "neutral"
var accent_color := NEUTRAL_ACCENT
var high_contrast := false
var large_text := false
var reduced_motion := false
var fast_mode := false
var cue_key := ""
var cue_duration := 0.0
var cue_remaining := 0.0


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = false
	set_process(false)
	if not bool(presentation.get("active", false)):
		hide()


func set_battle_intent_presentation(
	next_presentation: Dictionary,
	next_enemy_id: String,
	next_high_contrast: bool = false,
	next_large_text: bool = false,
	next_reduced_motion: bool = false,
	next_fast_mode: bool = false
) -> bool:
	var normalized := _normalize_presentation(next_presentation)
	if normalized.is_empty():
		clear_battle_intent_presentation()
		return false
	if not bool(normalized["active"]):
		clear_battle_intent_presentation()
		return true

	var next_intent_id := str(normalized["current_id"])
	var next_style: Dictionary = INTENT_STYLES.get(next_intent_id, {})
	var next_recognized := (
		not next_style.is_empty()
		and str(next_style.get("enemy_id", "")) == next_enemy_id
		and PROFILE_STYLES.has(next_enemy_id)
	)
	var next_key := "%s:%s" % [next_enemy_id, next_intent_id]
	var intent_changed := next_key != cue_key

	presentation = normalized
	enemy_id = next_enemy_id
	recognized_intent = next_recognized
	shape_id = str(next_style.get("shape", "neutral")) if next_recognized else "neutral"
	var style: Dictionary = PROFILE_STYLES.get(next_enemy_id, {}) if next_recognized else {}
	profile_edge = str(style.get("edge", "neutral"))
	accent_color = style.get("accent", NEUTRAL_ACCENT)
	high_contrast = next_high_contrast
	large_text = next_large_text
	reduced_motion = next_reduced_motion
	fast_mode = next_fast_mode
	show()

	if intent_changed:
		cue_key = next_key
		cue_duration = FAST_CUE_DURATION if fast_mode else STANDARD_CUE_DURATION
		cue_remaining = 0.0 if reduced_motion else cue_duration
		set_process(cue_remaining > 0.0)
	elif reduced_motion and cue_remaining > 0.0:
		cue_remaining = 0.0
		set_process(false)
	queue_redraw()
	return true


func set_presentation(
	next_presentation: Dictionary,
	next_enemy_id: String,
	next_high_contrast: bool = false,
	next_large_text: bool = false,
	next_reduced_motion: bool = false,
	next_fast_mode: bool = false
) -> bool:
	return set_battle_intent_presentation(
		next_presentation,
		next_enemy_id,
		next_high_contrast,
		next_large_text,
		next_reduced_motion,
		next_fast_mode
	)


func clear_battle_intent_presentation() -> void:
	presentation = {"active": false}
	enemy_id = ""
	recognized_intent = false
	shape_id = "neutral"
	profile_edge = "neutral"
	accent_color = NEUTRAL_ACCENT
	cue_key = ""
	cue_duration = 0.0
	cue_remaining = 0.0
	set_process(false)
	hide()
	queue_redraw()


func battle_intent_presentation_contract() -> Dictionary:
	var panel_colors := _resolved_colors()
	var stable_shape_ids: Array[String] = []
	var unique_shapes := {}
	for stable_intent_id in INTENT_STYLES:
		var stable_shape_id := str(INTENT_STYLES[stable_intent_id]["shape"])
		stable_shape_ids.append(stable_shape_id)
		unique_shapes[stable_shape_id] = true
	var first_line := _first_line()
	var second_line := _second_line()
	return {
		"active": visible and bool(presentation.get("active", false)),
		"enemy_id": enemy_id,
		"intent_id": str(presentation.get("current_id", "")),
		"current_name": str(presentation.get("current_name", "")),
		"current_damage": int(presentation.get("current_damage", 0)),
		"recognized_intent": recognized_intent,
		"shape_id": shape_id,
		"profile_edge": profile_edge,
		"supported_intent_ids": INTENT_STYLES.keys(),
		"supported_shape_ids": stable_shape_ids,
		"stable_shape_count": INTENT_STYLES.size(),
		"unique_shape_count": unique_shapes.size(),
		"nine_shape_complete": INTENT_STYLES.size() == 9 and unique_shapes.size() == 9,
		"first_line": first_line,
		"second_line": second_line,
		"text_equivalent": "%s\n%s" % [first_line, second_line] if not first_line.is_empty() else "",
		"intel_known": bool(presentation.get("intel_known", false)),
		"next_intent_visible": bool(presentation.get("intel_known", false)),
		"next_intent_id": str(presentation.get("next_id", "")),
		"next_name": str(presentation.get("next_name", "")),
		"next_damage": int(presentation.get("next_damage", 0)),
		"counter_text": str(presentation.get("counter_text", "")),
		"panel_size": PANEL_SIZE,
		"primary_font_size": _primary_font_size(),
		"secondary_font_size": _secondary_font_size(),
		"paper_color": panel_colors["paper"],
		"ink_color": panel_colors["ink"],
		"accent_color": panel_colors["accent"],
		"high_contrast": high_contrast,
		"large_text": large_text,
		"reduced_motion": reduced_motion,
		"fast_mode": fast_mode,
		"cue_duration": cue_duration,
		"cue_remaining": cue_remaining,
		"cue_active": cue_remaining > 0.0,
		"motion_enabled": cue_remaining > 0.0 and not reduced_motion,
		"fixed_screen_space": true,
		"screen_space_parent_required": true,
		"mouse_filter": mouse_filter,
		"focus_mode": focus_mode,
		"external_context_only": true,
		"unknown_shape_fallback": "neutral",
		"rule_authority": false,
		"damage_authority": false,
		"intent_authority": false,
		"profile_authority": false,
		"intel_authority": false,
		"round_authority": false,
		"counter_authority": false,
		"timing_authority": false,
		"gameplay_timing_authority": false,
		"save_authority": false,
		"input_authority": false,
		"blocks_input": false,
	}


func presentation_contract() -> Dictionary:
	return battle_intent_presentation_contract()


func _process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or cue_remaining <= 0.0:
		return
	cue_remaining = maxf(0.0, cue_remaining - delta)
	if cue_remaining <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if not bool(presentation.get("active", false)):
		return
	var panel_rect := Rect2(Vector2.ZERO, PANEL_SIZE)
	var colors := _resolved_colors()
	_draw_paper_panel(panel_rect, colors["paper"], colors["ink"], colors["accent"])
	_draw_profile_edge(panel_rect, profile_edge, colors["accent"])
	_draw_intent_icon(Vector2(47.0, 45.0), shape_id, colors["accent"], _cue_progress())
	_draw_copy(panel_rect, colors["ink"])


func _normalize_presentation(candidate: Dictionary) -> Dictionary:
	if typeof(candidate.get("active")) != TYPE_BOOL:
		return {}
	if not bool(candidate["active"]):
		return {"active": false}
	if (
		typeof(candidate.get("current_id")) != TYPE_STRING
		or typeof(candidate.get("current_name")) != TYPE_STRING
		or typeof(candidate.get("current_damage")) != TYPE_INT
		or typeof(candidate.get("intel_known")) != TYPE_BOOL
	):
		return {}
	var current_id := str(candidate["current_id"]).strip_edges()
	var current_name := str(candidate["current_name"]).strip_edges()
	var current_damage := int(candidate["current_damage"])
	if (
		current_id.is_empty()
		or current_name.is_empty()
		or current_id.length() > MAX_DISPLAY_ID_LENGTH
		or current_name.length() > MAX_DISPLAY_TEXT_LENGTH
		or current_damage < 0
		or current_damage > MAX_DISPLAY_DAMAGE
	):
		return {}

	var normalized := {
		"active": true,
		"current_id": current_id,
		"current_name": current_name,
		"current_damage": current_damage,
		"intel_known": bool(candidate["intel_known"]),
		"next_id": "",
		"next_name": "",
		"next_damage": 0,
		"counter_text": "",
	}
	if not bool(normalized["intel_known"]):
		return normalized
	if (
		typeof(candidate.get("next_id")) != TYPE_STRING
		or typeof(candidate.get("next_name")) != TYPE_STRING
		or typeof(candidate.get("next_damage")) != TYPE_INT
		or typeof(candidate.get("counter_text", "")) != TYPE_STRING
	):
		return {}
	var next_id := str(candidate["next_id"]).strip_edges()
	var next_name := str(candidate["next_name"]).strip_edges()
	var next_damage := int(candidate["next_damage"])
	var counter_text := str(candidate.get("counter_text", "")).strip_edges()
	if (
		next_id.is_empty()
		or next_name.is_empty()
		or next_id.length() > MAX_DISPLAY_ID_LENGTH
		or next_name.length() > MAX_DISPLAY_TEXT_LENGTH
		or counter_text.length() > MAX_DISPLAY_TEXT_LENGTH
		or next_damage < 0
		or next_damage > MAX_DISPLAY_DAMAGE
	):
		return {}
	normalized["next_id"] = next_id
	normalized["next_name"] = next_name
	normalized["next_damage"] = next_damage
	normalized["counter_text"] = counter_text
	return normalized


func _resolved_colors() -> Dictionary:
	if high_contrast:
		return {
			"paper": HIGH_CONTRAST_PAPER,
			"ink": HIGH_CONTRAST_INK,
			"accent": HIGH_CONTRAST_INK,
		}
	return {
		"paper": WARM_PAPER,
		"ink": INK_ROOT,
		"accent": accent_color,
	}


func _first_line() -> String:
	if not bool(presentation.get("active", false)):
		return ""
	return "本势　%s　｜　伤害 %d" % [
		presentation["current_name"],
		int(presentation["current_damage"]),
	]


func _second_line() -> String:
	if not bool(presentation.get("active", false)):
		return ""
	if not bool(presentation.get("intel_known", false)):
		return "敌迹未辨　｜　后一势与破绽暂不显示"
	var ending := "本势无特定破绽"
	var counter_text := str(presentation.get("counter_text", ""))
	if not counter_text.is_empty():
		ending = "破绽　%s" % counter_text
	return "后一势　%s（%d 伤害）　｜　%s" % [
		presentation["next_name"],
		int(presentation["next_damage"]),
		ending,
	]


func _primary_font_size() -> int:
	return LARGE_PRIMARY_FONT_SIZE if large_text else STANDARD_PRIMARY_FONT_SIZE


func _secondary_font_size() -> int:
	return LARGE_SECONDARY_FONT_SIZE if large_text else STANDARD_SECONDARY_FONT_SIZE


func _cue_progress() -> float:
	if reduced_motion or cue_duration <= 0.0 or cue_remaining <= 0.0:
		return 1.0
	var linear := clampf(1.0 - cue_remaining / cue_duration, 0.0, 1.0)
	return 1.0 - pow(1.0 - linear, 2.0)


func _draw_paper_panel(panel_rect: Rect2, paper: Color, ink: Color, accent: Color) -> void:
	var width := panel_rect.size.x
	var height := panel_rect.size.y
	var paper_shape := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(width - 12.0, 0.0),
		Vector2(width, 12.0),
		Vector2(width, height),
		Vector2(0.0, height),
	])
	draw_colored_polygon(paper_shape, paper)
	var outline := PackedVector2Array(paper_shape)
	outline.append(Vector2.ZERO)
	draw_polyline(outline, ink, 2.0, false)
	draw_line(Vector2(width - 12.0, 1.0), Vector2(width - 12.0, 12.0), accent, 2.0)
	draw_line(Vector2(width - 12.0, 12.0), Vector2(width - 1.0, 12.0), accent, 2.0)


func _draw_profile_edge(panel_rect: Rect2, edge_id: String, color: Color) -> void:
	var bottom := panel_rect.size.y - 8.0
	match edge_id:
		"cracked":
			draw_line(Vector2(8.0, 8.0), Vector2(8.0, 34.0), color, 4.0)
			draw_line(Vector2(8.0, 42.0), Vector2(8.0, bottom), color, 4.0)
			draw_line(Vector2(8.0, 34.0), Vector2(13.0, 39.0), color, 3.0)
			draw_line(Vector2(13.0, 39.0), Vector2(8.0, 42.0), color, 3.0)
		"droplets":
			draw_line(Vector2(8.0, 8.0), Vector2(8.0, bottom - 18.0), color, 4.0)
			for offset in [0.0, 9.0, 18.0]:
				draw_circle(Vector2(8.0, bottom - 18.0 + offset), 2.5, color)
		"stepped":
			draw_polyline(PackedVector2Array([
				Vector2(7.0, 8.0),
				Vector2(7.0, 30.0),
				Vector2(12.0, 30.0),
				Vector2(12.0, 52.0),
				Vector2(7.0, 52.0),
				Vector2(7.0, bottom),
			]), color, 4.0, false)
		"armored":
			draw_line(Vector2(6.0, 8.0), Vector2(6.0, bottom), color, 2.0)
			draw_line(Vector2(11.0, 8.0), Vector2(11.0, bottom), color, 2.0)
			draw_line(Vector2(6.0, 28.0), Vector2(11.0, 33.0), color, 2.0)
			draw_line(Vector2(11.0, 55.0), Vector2(6.0, 60.0), color, 2.0)
		_:
			draw_line(Vector2(8.0, 8.0), Vector2(8.0, bottom), color, 3.0)


func _draw_copy(panel_rect: Rect2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_left := 79.0
	var text_width := panel_rect.size.x - text_left - 16.0
	draw_string(
		font,
		Vector2(text_left, 35.0),
		_first_line(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		_primary_font_size(),
		color
	)
	draw_string(
		font,
		Vector2(text_left, 68.0),
		_second_line(),
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		_secondary_font_size(),
		color
	)


func _draw_intent_icon(center: Vector2, next_shape_id: String, color: Color, progress: float) -> void:
	match next_shape_id:
		"probing_charge":
			_draw_probing_charge(center, color, progress)
		"rending_charge":
			_draw_rending_charge(center, color, progress)
		"absorb_tide":
			_draw_absorb_tide(center, color, progress)
		"spore_spray":
			_draw_spore_spray(center, color, progress)
		"unbalanced_swing":
			_draw_unbalanced_swing(center, color, progress)
		"rebalance_step":
			_draw_rebalance_step(center, color, progress)
		"pressing_charge":
			_draw_pressing_charge(center, color, progress)
		"stonebreaking_blow":
			_draw_stonebreaking_blow(center, color, progress)
		"nest_guard":
			_draw_nest_guard(center, color, progress)
		_:
			_draw_neutral_intent(center, color)


func _draw_probing_charge(center: Vector2, color: Color, progress: float) -> void:
	draw_line(center + Vector2(-18.0, -10.0), center + Vector2(-5.0, -10.0), color, 3.0)
	draw_line(center + Vector2(-18.0, 10.0), center + Vector2(-5.0, 10.0), color, 3.0)
	var offset := Vector2(-2.0 * (1.0 - progress), 0.0)
	draw_polyline(PackedVector2Array([
		center + Vector2(-3.0, -15.0) + offset,
		center + Vector2(15.0, 0.0) + offset,
		center + Vector2(-3.0, 15.0) + offset,
	]), color, 3.0, false)


func _draw_rending_charge(center: Vector2, color: Color, progress: float) -> void:
	var settle := Vector2(0.0, -2.0 * (1.0 - progress))
	var wedge := PackedVector2Array([
		center + Vector2(-18.0, 12.0) + settle,
		center + Vector2(-9.0, -10.0) + settle,
		center + Vector2(15.0, -4.0) + settle,
		center + Vector2(18.0, 12.0) + settle,
		center + Vector2(-18.0, 12.0) + settle,
	])
	draw_polyline(wedge, color, 3.0, false)
	var crack_mid := center + Vector2(-1.0, 1.0) * progress
	draw_line(center + Vector2(-5.0, -7.0), crack_mid, color, 2.0)
	draw_line(crack_mid, center + Vector2(4.0, 9.0) * progress, color, 2.0)


func _draw_absorb_tide(center: Vector2, color: Color, progress: float) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(-17.0, 0.0),
		center + Vector2(-12.0, 11.0),
		center + Vector2(0.0, 16.0),
		center + Vector2(12.0, 11.0),
		center + Vector2(17.0, 0.0),
	]), color, 3.0, false)
	var drop_offset := -3.0 * (1.0 - progress)
	for drop_x in [-10.0, 0.0, 10.0]:
		var drop := center + Vector2(drop_x, -11.0 + drop_offset)
		draw_line(drop + Vector2(0.0, -5.0), drop + Vector2(0.0, 2.0), color, 2.0)
		draw_circle(drop + Vector2(0.0, 3.0), 2.0, color)


func _draw_spore_spray(center: Vector2, color: Color, progress: float) -> void:
	draw_arc(center + Vector2(-7.0, 4.0), 13.0, -1.25, 1.25, 16, color, 3.0, false)
	draw_line(center + Vector2(-6.0, -9.0), center + Vector2(-15.0, 12.0), color, 3.0)
	var spread := 0.55 + 0.45 * progress
	for point in [Vector2(8.0, -13.0), Vector2(17.0, -2.0), Vector2(11.0, 12.0)]:
		draw_circle(center + point * spread, 2.5, color)


func _draw_unbalanced_swing(center: Vector2, color: Color, progress: float) -> void:
	var angle := -0.14 * (1.0 - progress)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_line(Vector2(-8.0, -17.0), Vector2(-8.0, 15.0), color, 3.0)
	draw_circle(Vector2(-8.0, -4.0), 3.0, color)
	draw_line(Vector2(-8.0, -4.0), Vector2(13.0, 9.0), color, 3.0)
	draw_rect(Rect2(Vector2(10.0, 5.0), Vector2(10.0, 9.0)), color, false, 3.0)
	draw_arc(Vector2(-8.0, -4.0), 24.0, -0.35, 0.75, 14, color, 2.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rebalance_step(center: Vector2, color: Color, progress: float) -> void:
	var angle := -0.12 * (1.0 - progress)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_line(Vector2(0.0, -18.0), Vector2(0.0, 8.0), color, 3.0)
	draw_circle(Vector2(0.0, -18.0), 3.0, color)
	draw_rect(Rect2(Vector2(-11.0, 8.0), Vector2(22.0, 9.0)), color, false, 3.0)
	draw_line(Vector2(-18.0, 20.0), Vector2(18.0, 20.0), color, 3.0)
	draw_line(Vector2(-13.0, 24.0), Vector2(13.0, 24.0), color, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pressing_charge(center: Vector2, color: Color, progress: float) -> void:
	var press_offset := -3.0 * (1.0 - progress)
	draw_rect(Rect2(center + Vector2(-18.0 + press_offset, -14.0), Vector2(21.0, 10.0)), color, false, 3.0)
	draw_rect(Rect2(center + Vector2(-14.0 + press_offset, 4.0), Vector2(21.0, 10.0)), color, false, 3.0)
	for vertical_offset in [-9.0, 9.0]:
		draw_polyline(PackedVector2Array([
			center + Vector2(5.0 + press_offset, vertical_offset - 6.0),
			center + Vector2(17.0 + press_offset, vertical_offset),
			center + Vector2(5.0 + press_offset, vertical_offset + 6.0),
		]), color, 2.0, false)


func _draw_stonebreaking_blow(center: Vector2, color: Color, progress: float) -> void:
	var hammer_offset := Vector2(0.0, -3.0 * (1.0 - progress))
	draw_line(center + Vector2(0.0, -20.0) + hammer_offset, center + Vector2(0.0, -3.0) + hammer_offset, color, 3.0)
	draw_rect(Rect2(center + Vector2(-12.0, -22.0) + hammer_offset, Vector2(24.0, 8.0)), color, false, 3.0)
	draw_polyline(PackedVector2Array([
		center + Vector2(-16.0, 14.0),
		center + Vector2(0.0, 3.0),
		center + Vector2(16.0, 14.0),
	]), color, 3.0, false)
	var crack_tip := center + Vector2(0.0, 20.0) * progress
	draw_line(center + Vector2(0.0, 4.0), crack_tip, color, 2.0)
	draw_line(center + Vector2(0.0, 12.0) * progress, center + Vector2(-7.0, 17.0) * progress, color, 2.0)


func _draw_nest_guard(center: Vector2, color: Color, progress: float) -> void:
	draw_circle(center, 6.0, color, false, 3.0)
	var start_angle := -1.9
	var end_angle := start_angle + 3.8 * progress
	draw_arc(center, 18.0, start_angle, end_angle, 24, color, 3.0, false)
	if progress >= 0.92:
		var arrow_tip := center + Vector2(cos(end_angle), sin(end_angle)) * 18.0
		draw_polyline(PackedVector2Array([
			arrow_tip + Vector2(-5.0, -1.0),
			arrow_tip,
			arrow_tip + Vector2(-1.0, 5.0),
		]), color, 2.0, false)


func _draw_neutral_intent(center: Vector2, color: Color) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(0.0, -17.0),
		center + Vector2(17.0, 0.0),
		center + Vector2(0.0, 17.0),
		center + Vector2(-17.0, 0.0),
		center + Vector2(0.0, -17.0),
	]), color, 3.0, false)
	draw_line(center + Vector2(-7.0, -7.0), center + Vector2(7.0, 7.0), color, 2.0)
	draw_line(center + Vector2(7.0, -7.0), center + Vector2(-7.0, 7.0), color, 2.0)
