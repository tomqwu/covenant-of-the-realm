extends Control
class_name DialoguePortrait

const PROTAGONIST := "protagonist"
const YANQING := "yanqing"
const LIANGSHU := "liangshu"
const JOURNAL := "journal"
const PORTRAIT_IDS := [PROTAGONIST, YANQING, LIANGSHU, JOURNAL]

const INK_ROOT := Color("27312e")
const COOL_SHADOW := Color("355e63")
const RIVER_JADE := Color("4e9da4")
const CLEAR_INDIGO := Color("58738f")
const FRESH_CELADON := Color("8ebb83")
const WARM_OCHRE := Color("c6764f")
const WARM_PAPER := Color("f2e6cb")
const SPIRIT_GOLD := Color("e4c36e")

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
		JOURNAL: "行旅札记纸绘图",
	}[portrait_id]
	queue_redraw()
	return true


func visual_contract() -> Dictionary:
	return {
		"portrait_id": portrait_id,
		"supported_ids": PORTRAIT_IDS.duplicate(),
		"medium": "painted_paper",
		"palette": {
			"ink_root": INK_ROOT,
			"warm_paper": WARM_PAPER,
			"protagonist": CLEAR_INDIGO,
			"yanqing": WARM_OCHRE,
			"liangshu": COOL_SHADOW,
			"journal": FRESH_CELADON,
		},
		"motion_free": true,
		"rule_authority": false,
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
		_:
			_draw_journal(size)
	_draw_frame(size)


func _draw_paper_ground(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WARM_PAPER.darkened(0.025))
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
		var y := 12.0 + float(index) * 17.0
		var start_x := 8.0 + float((index * 11) % 19)
		draw_line(Vector2(start_x, y), Vector2(minf(size.x - 8.0, start_x + 24.0), y - 3.0), Color(0.39, 0.46, 0.40, 0.12), 1.0)


func _draw_protagonist(size: Vector2) -> void:
	var center := Vector2(size.x * 0.50, size.y * 0.45)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, CLEAR_INDIGO, COOL_SHADOW)
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
	_draw_face(center, COOL_SHADOW, Vector2(1, 0))
	draw_line(center + Vector2(-24, 18), center + Vector2(-6, 39), SPIRIT_GOLD.darkened(0.12), 3.0)
	draw_circle(center + Vector2(-25, 18), 4.0, SPIRIT_GOLD)


func _draw_yanqing(size: Vector2) -> void:
	var center := Vector2(size.x * 0.50, size.y * 0.45)
	_draw_person_shadow(center, size)
	_draw_shoulders(center, size, WARM_OCHRE, Color("8f553f"))
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
	_draw_face(center, Color("704c42"), Vector2(-1, 0))
	draw_arc(center + Vector2(0, 7), 6.0, 0.45, 2.20, 8, Color("945746"), 1.5)
	draw_line(center + Vector2(9, 29), center + Vector2(31, 11), WARM_PAPER.darkened(0.12), 4.0)
	draw_circle(center + Vector2(30, 10), 4.0, FRESH_CELADON)


func _draw_liangshu(size: Vector2) -> void:
	var center := Vector2(size.x * 0.50, size.y * 0.45)
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
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-17, -41), center + Vector2(18, -41),
		center + Vector2(15, -20), center + Vector2(-15, -20),
	]), INK_ROOT.lightened(0.12))
	_draw_face(center, COOL_SHADOW.darkened(0.18), Vector2(-1, 0))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-10, 5), center + Vector2(10, 5), center + Vector2(5, 22), center + Vector2(-4, 25),
	]), Color("b8b3a1"))
	draw_line(center + Vector2(-27, 32), center + Vector2(-27, 69), Color("927a52"), 5.0)
	draw_line(center + Vector2(-32, 68), center + Vector2(-22, 68), INK_ROOT, 2.0)


func _draw_journal(size: Vector2) -> void:
	var center := size * Vector2(0.50, 0.47)
	var page := Rect2(center + Vector2(-43, -51), Vector2(86, 100))
	draw_rect(page, WARM_PAPER.lightened(0.03))
	draw_rect(Rect2(page.position + Vector2(7, 5), page.size - Vector2(14, 10)), Color(0.38, 0.34, 0.24, 0.10), false, 2.0)
	draw_line(center + Vector2(-31, -31), center + Vector2(28, -31), COOL_SHADOW, 3.0)
	draw_line(center + Vector2(-31, -14), center + Vector2(18, -14), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(-31, 2), center + Vector2(27, 2), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(-31, 18), center + Vector2(9, 18), RIVER_JADE.darkened(0.08), 2.0)
	draw_line(center + Vector2(28, 10), center + Vector2(43, -13), WARM_OCHRE.darkened(0.10), 4.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(42, -13), center + Vector2(48, -24), center + Vector2(38, -17),
	]), INK_ROOT)
	draw_circle(center + Vector2(-35, 34), 7.0, FRESH_CELADON)
	draw_line(center + Vector2(-35, 34), center + Vector2(-21, 42), FRESH_CELADON.darkened(0.18), 2.0)


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


func _draw_neck_and_face(center: Vector2, skin: Color, skin_shadow: Color) -> void:
	draw_rect(Rect2(center + Vector2(-8, 7), Vector2(16, 22)), skin_shadow)
	draw_circle(center + Vector2(0, -9), 26.0, skin_shadow)
	draw_circle(center + Vector2(-1, -11), 24.0, skin)
	draw_circle(center + Vector2(-25, -8), 4.0, skin_shadow)
	draw_circle(center + Vector2(23, -8), 4.0, skin_shadow)


func _draw_face(center: Vector2, eye_color: Color, gaze: Vector2) -> void:
	var gaze_offset := gaze * 1.2
	draw_line(center + Vector2(-15, -17), center + Vector2(-5, -18), eye_color, 2.0)
	draw_line(center + Vector2(6, -18), center + Vector2(16, -16), eye_color, 2.0)
	draw_circle(center + Vector2(-9, -13) + gaze_offset, 1.7, eye_color)
	draw_circle(center + Vector2(11, -12) + gaze_offset, 1.7, eye_color)
	draw_line(center + Vector2(0, -10), center + Vector2(-2, 0), Color(0.49, 0.31, 0.27, 0.65), 1.5)
	draw_line(center + Vector2(-7, 8), center + Vector2(7, 7), Color("945746"), 1.5)


func _draw_flat_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_frame(size: Vector2) -> void:
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(0.31, 0.35, 0.29, 0.55), false, 2.0)
	draw_line(Vector2(9, 7), Vector2(29, 7), SPIRIT_GOLD.darkened(0.15), 2.0)
	draw_line(Vector2(size.x - 29, size.y - 7), Vector2(size.x - 9, size.y - 7), SPIRIT_GOLD.darkened(0.15), 2.0)
