extends Control
class_name DialoguePortrait

const PROTAGONIST := "protagonist"
const YANQING := "yanqing"
const LIANGSHU := "liangshu"
const HUISHEN := "huishen"
const TAO_XIAOMAN := "tao_xiaoman"
const JOURNAL := "journal"
const PORTRAIT_IDS := [PROTAGONIST, YANQING, LIANGSHU, HUISHEN, TAO_XIAOMAN, JOURNAL]
const STYLE_REVISION := 2

const INK_ROOT := Color("27312e")
const COOL_SHADOW := Color("355e63")
const RIVER_JADE := Color("4e9da4")
const CLEAR_INDIGO := Color("58738f")
const FRESH_CELADON := Color("8ebb83")
const WARM_OCHRE := Color("c6764f")
const WARM_PAPER := Color("f2e6cb")
const SPIRIT_GOLD := Color("e4c36e")
const MORNING_PEACH := Color("e7a76f")

const PORTRAIT_PROFILES := {
	PROTAGONIST: {"expression": "curious", "silhouette": "high_tie_straw_cape", "accent": "indigo_ribbon"},
	YANQING: {"expression": "warm", "silhouette": "low_wrap_herb_pin", "accent": "medicine_case"},
	LIANGSHU: {"expression": "steady", "silhouette": "reed_hat_short_beard", "accent": "water_gauge"},
	HUISHEN: {"expression": "kind", "silhouette": "head_wrap_low_bun", "accent": "woven_apron"},
	TAO_XIAOMAN: {"expression": "bright", "silhouette": "cropped_scarf_satchel", "accent": "wooden_wedges"},
	JOURNAL: {"expression": "none", "silhouette": "open_journal", "accent": "morning_seal"},
}

var portrait_id := YANQING


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_portrait(portrait_id)


func set_portrait(next_id: String) -> bool:
	if next_id not in PORTRAIT_IDS:
		portrait_id = JOURNAL
		tooltip_text = "行旅札记纸绘图"
		queue_redraw()
		return false
	portrait_id = next_id
	tooltip_text = {
		PROTAGONIST: "行旅者纸绘头像",
		YANQING: "砚青纸绘头像",
		LIANGSHU: "梁叔纸绘头像",
		HUISHEN: "蕙婶纸绘头像",
		TAO_XIAOMAN: "陶小满纸绘头像",
		JOURNAL: "行旅札记纸绘图",
	}[portrait_id]
	queue_redraw()
	return true


func visual_contract() -> Dictionary:
	return {
		"portrait_id": portrait_id,
		"supported_ids": PORTRAIT_IDS.duplicate(),
		"medium": "painted_paper",
		"style_revision": STYLE_REVISION,
		"rendering": "deterministic_runtime_primitives",
		"deterministic": true,
		"external_assets": false,
		"asset_dependencies": [],
		"profile": PORTRAIT_PROFILES[portrait_id].duplicate(true),
		"palette": {
			"ink_root": INK_ROOT,
			"warm_paper": WARM_PAPER,
			"protagonist": CLEAR_INDIGO,
			"yanqing": WARM_OCHRE,
			"liangshu": COOL_SHADOW,
			"huishen": FRESH_CELADON.darkened(0.12),
			"tao_xiaoman": SPIRIT_GOLD.darkened(0.08),
			"journal": FRESH_CELADON,
			"morning_peach": MORNING_PEACH,
		},
		"motion_free": true,
		"rule_authority": false,
		"save_authority": false,
	}


func _draw() -> void:
	var size := get_rect().size
	if size.x < 8.0 or size.y < 8.0:
		return
	_draw_paper_ground(size)
	match portrait_id:
		PROTAGONIST:
			_draw_protagonist(size)
		YANQING:
			_draw_yanqing(size)
		LIANGSHU:
			_draw_liangshu(size)
		HUISHEN:
			_draw_huishen(size)
		TAO_XIAOMAN:
			_draw_tao_xiaoman(size)
		_:
			_draw_journal(size)
	_draw_frame(size)


func _draw_paper_ground(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WARM_PAPER.lightened(0.015))
	# A restrained dawn wash lifts the paper without bloom or time-dependent light.
	draw_circle(Vector2(size.x * 0.82, size.y * 0.14), size.x * 0.28, _with_alpha(MORNING_PEACH, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.48, 0), Vector2(size.x, 0),
		Vector2(size.x, size.y * 0.40), Vector2(size.x * 0.68, size.y * 0.28),
	]), _with_alpha(WARM_PAPER.lightened(0.08), 0.48))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.67),
		Vector2(size.x, size.y * 0.48),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]), RIVER_JADE.lightened(0.40))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.78),
		Vector2(size.x * 0.48, size.y * 0.61),
		Vector2(size.x, size.y * 0.70),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]), FRESH_CELADON.lightened(0.34))
	for index in range(8):
		var y := 11.0 + float(index) * 17.0
		var start_x := 7.0 + float((index * 11) % 23)
		var fiber_length := 17.0 + float((index * 7) % 15)
		var fiber_rise := float((index % 3) - 1) * 2.0
		draw_line(
			Vector2(start_x, y),
			Vector2(minf(size.x - 8.0, start_x + fiber_length), y + fiber_rise),
			Color(0.39, 0.46, 0.40, 0.12),
			1.0
		)


func _draw_protagonist(size: Vector2) -> void:
	var center := _portrait_center(size)
	_draw_profile_wash(center, CLEAR_INDIGO)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, CLEAR_INDIGO, COOL_SHADOW)
	_draw_straw_cape(center, size)
	_draw_neck_and_face(center, Color("d9ad87"), Color("bc8064"))
	# High tied hair and a practical indigo ribbon keep the map silhouette recognizable.
	draw_circle(center + Vector2(0, -42), 12.0, INK_ROOT)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-25, -20), center + Vector2(-19, -49),
		center + Vector2(-4, -61), center + Vector2(18, -48),
		center + Vector2(27, -15), center + Vector2(12, -25),
		center + Vector2(-10, -27),
	]), INK_ROOT)
	draw_line(center + Vector2(-8, -54), center + Vector2(15, -54), CLEAR_INDIGO.lightened(0.18), 4.0)
	draw_line(center + Vector2(9, -52), center + Vector2(22, -44), CLEAR_INDIGO, 3.0)
	_draw_face(center, COOL_SHADOW, Vector2(1, 0), "curious")
	draw_line(center + Vector2(-24, 18), center + Vector2(-6, 39), SPIRIT_GOLD.darkened(0.12), 3.0)
	draw_circle(center + Vector2(-25, 18), 4.0, SPIRIT_GOLD)


func _draw_yanqing(size: Vector2) -> void:
	var center := _portrait_center(size)
	_draw_profile_wash(center, WARM_OCHRE)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, WARM_OCHRE, Color("8f553f"))
	draw_line(center + Vector2(-15, 19), center + Vector2(2, 40), WARM_PAPER.darkened(0.06), 3.0)
	draw_line(center + Vector2(15, 19), center + Vector2(-2, 40), MORNING_PEACH.darkened(0.12), 2.0)
	_draw_neck_and_face(center, Color("deb18b"), Color("bd8164"))
	# Low wrapped hair, herb pin and loose side strand distinguish the travelling apothecary.
	draw_circle(center + Vector2(18, -34), 13.0, INK_ROOT.lightened(0.05))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-27, -13), center + Vector2(-22, -46),
		center + Vector2(-5, -58), center + Vector2(20, -46),
		center + Vector2(27, -14), center + Vector2(10, -27),
		center + Vector2(-11, -28),
	]), INK_ROOT.lightened(0.05))
	draw_line(center + Vector2(19, -42), center + Vector2(31, -53), FRESH_CELADON.darkened(0.18), 3.0)
	draw_circle(center + Vector2(32, -54), 4.0, FRESH_CELADON)
	draw_line(center + Vector2(-23, -8), center + Vector2(-29, 16), INK_ROOT.lightened(0.05), 4.0)
	_draw_face(center, Color("704c42"), Vector2(-1, 0), "warm")
	draw_line(center + Vector2(9, 29), center + Vector2(31, 11), WARM_PAPER.darkened(0.12), 4.0)
	draw_circle(center + Vector2(30, 10), 4.0, FRESH_CELADON)
	var medicine_case := Rect2(center + Vector2(24, 31), Vector2(18, 27))
	draw_rect(medicine_case, WARM_OCHRE.darkened(0.18))
	draw_rect(medicine_case, INK_ROOT.lightened(0.16), false, 2.0)
	draw_line(medicine_case.position + Vector2(4, 9), medicine_case.end - Vector2(4, 9), SPIRIT_GOLD.darkened(0.18), 2.0)


func _draw_liangshu(size: Vector2) -> void:
	var center := _portrait_center(size)
	_draw_profile_wash(center, COOL_SHADOW.lightened(0.16))
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, COOL_SHADOW.lightened(0.16), Color("596d65"))
	_draw_neck_and_face(center, Color("c99673"), Color("a46d58"))
	# A broad reed hat, rain-dark coat and short grey beard read as a working levee keeper.
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-43, -42), center + Vector2(-19, -59),
		center + Vector2(18, -59), center + Vector2(43, -42),
	]), Color("a88b57"))
	draw_line(center + Vector2(-43, -42), center + Vector2(43, -42), INK_ROOT, 3.0)
	draw_line(center + Vector2(-25, -50), center + Vector2(27, -50), SPIRIT_GOLD.darkened(0.28), 2.0)
	for rib_x in [-26.0, -10.0, 10.0, 26.0]:
		draw_line(center + Vector2(rib_x * 0.55, -58), center + Vector2(rib_x, -43), Color("806b48"), 1.5)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-17, -41), center + Vector2(18, -41),
		center + Vector2(15, -20), center + Vector2(-15, -20),
	]), INK_ROOT.lightened(0.12))
	_draw_face(center, COOL_SHADOW.darkened(0.18), Vector2(-1, 0), "steady")
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-10, 5), center + Vector2(10, 5), center + Vector2(5, 22), center + Vector2(-4, 25),
	]), Color("b8b3a1"))
	draw_line(center + Vector2(-27, 32), center + Vector2(-27, 69), Color("927a52"), 5.0)
	draw_line(center + Vector2(-32, 68), center + Vector2(-22, 68), INK_ROOT, 2.0)
	draw_line(center + Vector2(18, 26), center + Vector2(30, 66), _with_alpha(WARM_PAPER, 0.42), 2.0)


func _draw_huishen(size: Vector2) -> void:
	var center := _portrait_center(size)
	var herb_green := FRESH_CELADON.darkened(0.12)
	_draw_profile_wash(center, herb_green)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, herb_green, Color("6b7358"))
	_draw_neck_and_face(center, Color("d5a47d"), Color("b8795f"))
	# A practical head wrap, low bun, leaf pin and woven apron identify the herb-garden keeper.
	draw_circle(center + Vector2(22, -34), 14.0, INK_ROOT.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-27, -12), center + Vector2(-21, -47),
		center + Vector2(-4, -58), center + Vector2(22, -46),
		center + Vector2(27, -13), center + Vector2(10, -28),
		center + Vector2(-12, -27),
	]), INK_ROOT.lightened(0.08))
	draw_line(center + Vector2(-20, -42), center + Vector2(22, -42), WARM_PAPER.darkened(0.16), 5.0)
	draw_line(center + Vector2(-17, -47), center + Vector2(16, -47), _with_alpha(WARM_PAPER, 0.72), 2.0)
	draw_line(center + Vector2(21, -42), center + Vector2(33, -52), herb_green, 3.0)
	draw_circle(center + Vector2(34, -53), 4.0, FRESH_CELADON.lightened(0.08))
	_draw_face(center, Color("5d5140"), Vector2(-1, 0), "kind")
	var apron := Rect2(center + Vector2(-24, 27), Vector2(48, 59))
	draw_rect(apron, Color("af8d59"))
	for offset in [8.0, 20.0, 32.0, 44.0]:
		draw_line(apron.position + Vector2(offset, 0), apron.position + Vector2(offset - 6.0, apron.size.y), Color("dbc083"), 1.5)
	for offset in [13.0, 28.0, 43.0]:
		draw_line(apron.position + Vector2(0, offset), apron.position + Vector2(apron.size.x, offset), Color("826946"), 1.5)
	draw_arc(center + Vector2(0, 29), 23.0, PI, TAU, 16, Color("826946"), 3.0)
	draw_line(apron.position + Vector2(4, 5), apron.position + Vector2(4, apron.size.y - 5), _with_alpha(WARM_PAPER, 0.55), 2.0)


func _draw_tao_xiaoman(size: Vector2) -> void:
	var center := _portrait_center(size)
	var sunny_jacket := SPIRIT_GOLD.darkened(0.08)
	_draw_profile_wash(center, sunny_jacket)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, sunny_jacket, Color("a46f3e"))
	_draw_neck_and_face(center, Color("deb18b"), Color("bd8164"))
	# A cropped river-blue scarf and wedge satchel keep the young runner distinct.
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-25, -14), center + Vector2(-18, -48),
		center + Vector2(0, -58), center + Vector2(22, -43),
		center + Vector2(27, -13), center + Vector2(9, -26),
		center + Vector2(-11, -27),
	]), INK_ROOT.lightened(0.03))
	draw_line(center + Vector2(-20, -43), center + Vector2(22, -43), RIVER_JADE, 5.0)
	draw_line(center + Vector2(-18, -40), center + Vector2(-30, -24), RIVER_JADE.darkened(0.14), 4.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(20, -40), center + Vector2(34, -31), center + Vector2(26, -18),
	]), RIVER_JADE.lightened(0.12))
	_draw_face(center, COOL_SHADOW, Vector2(1, 0), "bright")
	draw_line(center + Vector2(-23, 23), center + Vector2(20, 45), RIVER_JADE.darkened(0.12), 5.0)
	draw_rect(Rect2(center + Vector2(13, 36), Vector2(31, 35)), RIVER_JADE.darkened(0.18))
	for offset in [0.0, 9.0, 18.0]:
		draw_rect(Rect2(center + Vector2(19 + offset, 44), Vector2(5, 18)), WARM_PAPER.darkened(0.20))


func _draw_journal(size: Vector2) -> void:
	var center := size * Vector2(0.50, 0.47)
	_draw_profile_wash(center + Vector2(0, 3), FRESH_CELADON)
	var page := Rect2(center + Vector2(-43, -51), Vector2(86, 100))
	draw_rect(page, WARM_PAPER.lightened(0.03))
	draw_rect(Rect2(page.position + Vector2(7, 5), page.size - Vector2(14, 10)), Color(0.38, 0.34, 0.24, 0.10), false, 2.0)
	draw_line(center + Vector2(-31, -31), center + Vector2(28, -31), COOL_SHADOW, 3.0)
	draw_polyline(PackedVector2Array([
		center + Vector2(-31, -39), center + Vector2(-20, -47), center + Vector2(-8, -40),
		center + Vector2(4, -50), center + Vector2(18, -40), center + Vector2(31, -44),
	]), _with_alpha(COOL_SHADOW, 0.62), 2.0)
	draw_line(center + Vector2(-31, -14), center + Vector2(18, -14), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(-31, 2), center + Vector2(27, 2), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(-31, 18), center + Vector2(9, 18), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(28, 10), center + Vector2(43, -13), WARM_OCHRE.darkened(0.10), 4.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(42, -13), center + Vector2(48, -24), center + Vector2(38, -17),
	]), INK_ROOT)
	draw_circle(center + Vector2(-35, 34), 7.0, FRESH_CELADON)
	draw_line(center + Vector2(-35, 34), center + Vector2(-21, 42), FRESH_CELADON.darkened(0.18), 2.0)
	draw_circle(center + Vector2(30, 35), 8.0, _with_alpha(MORNING_PEACH, 0.78))
	draw_line(center + Vector2(25, 35), center + Vector2(35, 35), WARM_PAPER, 2.0)


func _draw_person_shadow(center: Vector2, size: Vector2) -> void:
	_draw_flat_ellipse(center + Vector2(0, size.y * 0.30), Vector2(size.x * 0.38, 9), Color(0.13, 0.21, 0.20, 0.20))


func _draw_shoulders(center: Vector2, size: Vector2, cloth: Color, shadow: Color) -> void:
	var bottom := minf(size.y - 5.0, center.y + size.y * 0.46)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-19, 18), Vector2(size.x * 0.13, bottom - 22),
		Vector2(size.x * 0.06, bottom), Vector2(size.x * 0.94, bottom),
		Vector2(size.x * 0.87, bottom - 22), center + Vector2(19, 18),
	]), shadow)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-16, 18), Vector2(size.x * 0.28, bottom - 15),
		Vector2(size.x * 0.23, bottom), Vector2(size.x * 0.77, bottom),
		Vector2(size.x * 0.72, bottom - 15), center + Vector2(16, 18),
	]), cloth)
	draw_line(center + Vector2(0, 26), Vector2(center.x, bottom), WARM_PAPER.darkened(0.18), 2.0)
	draw_line(center + Vector2(-15, 24), Vector2(size.x * 0.30, bottom - 8), _with_alpha(WARM_PAPER, 0.34), 2.0)


func _draw_neck_and_face(center: Vector2, skin: Color, skin_shadow: Color) -> void:
	draw_rect(Rect2(center + Vector2(-8, 7), Vector2(16, 22)), skin_shadow)
	draw_circle(center + Vector2(0, -9), 26.0, skin_shadow)
	draw_circle(center + Vector2(-1, -11), 24.0, skin)
	draw_circle(center + Vector2(-25, -8), 4.0, skin_shadow)
	draw_circle(center + Vector2(23, -8), 4.0, skin_shadow)
	draw_circle(center + Vector2(-8, -21), 7.0, _with_alpha(WARM_PAPER.lightened(0.06), 0.13))


func _draw_face(center: Vector2, eye_color: Color, gaze: Vector2, expression: String) -> void:
	var gaze_offset := gaze * 1.2
	var left_brow := [Vector2(-15, -18), Vector2(-5, -19)]
	var right_brow := [Vector2(6, -19), Vector2(16, -17)]
	match expression:
		"curious":
			left_brow = [Vector2(-15, -18), Vector2(-5, -21)]
			right_brow = [Vector2(6, -20), Vector2(16, -17)]
		"steady":
			left_brow = [Vector2(-15, -18), Vector2(-5, -18)]
			right_brow = [Vector2(6, -18), Vector2(16, -18)]
		"kind":
			left_brow = [Vector2(-15, -17), Vector2(-5, -19)]
			right_brow = [Vector2(6, -19), Vector2(16, -17)]
		"bright":
			left_brow = [Vector2(-15, -16), Vector2(-5, -19)]
			right_brow = [Vector2(6, -19), Vector2(16, -16)]
	draw_line(center + left_brow[0], center + left_brow[1], eye_color, 2.0)
	draw_line(center + right_brow[0], center + right_brow[1], eye_color, 2.0)
	var left_eye := center + Vector2(-9, -13) + gaze_offset
	var right_eye := center + Vector2(11, -12) + gaze_offset
	draw_circle(left_eye, 2.2, eye_color)
	draw_circle(right_eye, 2.2, eye_color)
	draw_circle(left_eye + Vector2(-0.6, -0.7), 0.7, WARM_PAPER.lightened(0.08))
	draw_circle(right_eye + Vector2(-0.6, -0.7), 0.7, WARM_PAPER.lightened(0.08))
	draw_line(center + Vector2(0, -10), center + Vector2(-2, 0), Color(0.49, 0.31, 0.27, 0.65), 1.5)
	draw_circle(center + Vector2(-18, 0), 4.0, _with_alpha(MORNING_PEACH, 0.18))
	draw_circle(center + Vector2(17, 1), 4.0, _with_alpha(MORNING_PEACH, 0.18))
	var mouth_color := Color("945746")
	match expression:
		"steady":
			draw_line(center + Vector2(-7, 7), center + Vector2(7, 7), mouth_color, 2.0)
		"warm":
			draw_arc(center + Vector2(0, 4), 7.0, 0.28, 2.86, 10, mouth_color, 2.0)
		"kind":
			draw_arc(center + Vector2(-1, 4), 7.5, 0.24, 2.90, 10, mouth_color, 2.0)
		"bright":
			draw_arc(center + Vector2(0, 3), 8.0, 0.22, 2.92, 10, mouth_color, 2.0)
		_:
			draw_arc(center + Vector2(0, 5), 6.5, 0.35, 2.74, 9, mouth_color, 2.0)


func _portrait_center(size: Vector2) -> Vector2:
	return Vector2(roundf(size.x * 0.50), roundf(size.y * 0.45))


func _draw_profile_wash(center: Vector2, accent: Color) -> void:
	draw_circle(center + Vector2(-7, -11), 43.0, _with_alpha(accent.lightened(0.24), 0.16))
	draw_arc(center + Vector2(-7, -11), 44.0, 3.45, 5.92, 18, _with_alpha(accent, 0.34), 2.0)
	draw_circle(center + Vector2(30, -47), 3.0, _with_alpha(MORNING_PEACH, 0.48))


func _draw_straw_cape(center: Vector2, size: Vector2) -> void:
	var bottom := minf(size.y - 5.0, center.y + size.y * 0.46)
	var straw := SPIRIT_GOLD.lightened(0.12)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-20, 18), Vector2(size.x * 0.10, bottom - 19),
		Vector2(size.x * 0.18, bottom), center + Vector2(-2, 38),
	]), straw)
	for offset in [0.0, 8.0, 16.0]:
		draw_line(
			center + Vector2(-18 + offset * 0.25, 23 + offset),
			Vector2(size.x * 0.14 + offset * 0.30, bottom - 5),
			WARM_OCHRE.darkened(0.12),
			1.5
		)


func _with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result


func _draw_flat_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_frame(size: Vector2) -> void:
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(0.31, 0.35, 0.29, 0.55), false, 2.0)
	draw_line(Vector2(9, 7), Vector2(29, 7), SPIRIT_GOLD.darkened(0.15), 2.0)
	draw_line(Vector2(size.x - 28, 7), Vector2(size.x - 10, 7), MORNING_PEACH.darkened(0.08), 2.0)
	draw_line(Vector2(size.x - 29, size.y - 7), Vector2(size.x - 9, size.y - 7), SPIRIT_GOLD.darkened(0.15), 2.0)
