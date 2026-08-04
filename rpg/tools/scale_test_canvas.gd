extends Control

const ACTOR_SIZES: Array[float] = [48.0, 56.0, 64.0]
const INK_ROOT := Color("27312e")
const COOL_SHADOW := Color("355e63")
const CLEAR_INDIGO := Color("58738f")
const FRESH_CELADON := Color("8ebb83")
const WARM_PAPER := Color("f2e6cb")
const SPIRIT_GOLD := Color("e4c36e")
const STONE_PATH := Color("d8cca5")


func recommended_actor_height_px() -> float:
	return 56.0


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), WARM_PAPER)
	_draw_text(Vector2(42, 48), "角色比例测试 · 亮草地 / 浅石路 / 冷影", 25, INK_ROOT)
	_draw_text(Vector2(42, 78), "同一功能性轮廓只改变高度；56 px 在身份、地图占比与碰撞余量之间最平衡。", 15, COOL_SHADOW)

	var card_width := 330.0
	var gap := 28.0
	var start_x := (size.x - (card_width * 3.0 + gap * 2.0)) * 0.5
	for column in range(ACTOR_SIZES.size()):
		var x := start_x + float(column) * (card_width + gap)
		var actor_size := ACTOR_SIZES[column]
		_draw_scale_card(Rect2(x, 112, card_width, 482), actor_size, actor_size == recommended_actor_height_px())


func _draw_scale_card(area: Rect2, actor_size: float, recommended: bool) -> void:
	var border_color := SPIRIT_GOLD if recommended else COOL_SHADOW.lightened(0.22)
	draw_rect(area, Color("f8edd3"))
	draw_rect(area, border_color, false, 3.0 if recommended else 1.0)
	_draw_text(area.position + Vector2(18, 34), "%d px%s" % [int(actor_size), " · 推荐" if recommended else ""], 21, INK_ROOT)

	var band_height := 122.0
	var band_colors: Array[Color] = [FRESH_CELADON, STONE_PATH, COOL_SHADOW]
	var band_names: Array[String] = ["亮草地", "浅石路", "冷影"]
	for row in range(3):
		var top := area.position.y + 56.0 + float(row) * (band_height + 10.0)
		var band := Rect2(area.position.x + 16.0, top, area.size.x - 32.0, band_height)
		draw_rect(band, band_colors[row])
		var label_color := WARM_PAPER if row == 2 else INK_ROOT
		_draw_text(band.position + Vector2(12, 22), band_names[row], 13, label_color)
		_draw_actor(Vector2(band.get_center().x, band.end.y - 14.0), actor_size)


func _draw_actor(feet: Vector2, actor_height: float) -> void:
	var scale_factor := actor_height / 56.0
	var top := feet - Vector2(0, actor_height)
	draw_circle(top + Vector2(0, 13) * scale_factor, 10.0 * scale_factor, Color("d9b895"))
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(-13, 22) * scale_factor,
		top + Vector2(13, 22) * scale_factor,
		feet + Vector2(16, -5) * scale_factor,
		feet + Vector2(-16, -5) * scale_factor,
	]), CLEAR_INDIGO)
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(-19, 23) * scale_factor,
		top + Vector2(0, 17) * scale_factor,
		feet + Vector2(-3, -7) * scale_factor,
	]), Color("b89b63"))
	draw_line(feet + Vector2(-7, -5) * scale_factor, feet + Vector2(-9, 4) * scale_factor, INK_ROOT, 5.0 * scale_factor)
	draw_line(feet + Vector2(7, -5) * scale_factor, feet + Vector2(9, 4) * scale_factor, INK_ROOT, 5.0 * scale_factor)
	draw_circle(top + Vector2(0, 2) * scale_factor, 6.0 * scale_factor, INK_ROOT)


func _draw_text(position: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
