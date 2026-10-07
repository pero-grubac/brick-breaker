class_name PowerUpIcons
extends RefCounted

## Vector icons for power-ups, drawn in code on any CanvasItem (capsules now, HUD later).
## Every icon fits in a circle of radius `r` around `c`. Power-ups without an icon here fall
## back to their short_label text.

const LINE_WIDTH_FACTOR: float = 0.16
const LABEL_FONT_FACTOR: float = 0.9


static func has_icon(id: String) -> bool:
	return id in ["multiball", "long_paddle", "short_paddle", "slow_ball", "fast_ball",
			"extra_life", "sticky_paddle", "fire_ball"]


## Draws the icon of `def` centered at `c`, fitting in radius `r`.
static func draw(ci: CanvasItem, def: PowerUpDef, c: Vector2, r: float, color: Color) -> void:
	var w := maxf(r * LINE_WIDTH_FACTOR, 1.5)
	match def.id:
		"multiball":
			for offset in [Vector2(-0.45, 0.3), Vector2(0.45, 0.3), Vector2(0.0, -0.4)]:
				ci.draw_circle(c + offset * r, r * 0.28, color, true, -1.0, true)
		"long_paddle":
			_bar(ci, c, r * 0.32, r * 0.2, color)
			_arrow(ci, c + Vector2(-r * 0.95, 0), Vector2.LEFT, r * 0.45, color)
			_arrow(ci, c + Vector2(r * 0.95, 0), Vector2.RIGHT, r * 0.45, color)
		"short_paddle":
			_bar(ci, c, r * 0.22, r * 0.2, color)
			_arrow(ci, c + Vector2(-r * 0.32, 0), Vector2.RIGHT, r * 0.45, color)
			_arrow(ci, c + Vector2(r * 0.32, 0), Vector2.LEFT, r * 0.45, color)
		"slow_ball":
			_hourglass(ci, c, r * 0.75, color, w)
		"fast_ball":
			ci.draw_circle(c + Vector2(r * 0.35, 0), r * 0.3, color, true, -1.0, true)
			_chevron(ci, c + Vector2(-r * 0.15, 0), Vector2.RIGHT, r * 0.28, color, w)
			_chevron(ci, c + Vector2(-r * 0.55, 0), Vector2.RIGHT, r * 0.28, color, w)
		"extra_life":
			_heart(ci, c, r * 0.7, color)
		"sticky_paddle":
			_bar(ci, c + Vector2(0, r * 0.35), r * 0.6, r * 0.18, color)
			ci.draw_circle(c + Vector2(0, -r * 0.05), r * 0.3, color, true, -1.0, true)
			for x in [-0.35, 0.0, 0.35]:
				ci.draw_line(c + Vector2(x * r, r * 0.2), c + Vector2(x * r, r * 0.55), color, w, true)
		"fire_ball":
			_flame(ci, c, r * 0.75, color)
		_:
			_label(ci, def.short_label, c, r, color)


static func _bar(ci: CanvasItem, c: Vector2, half_w: float, half_h: float, color: Color) -> void:
	ci.draw_rect(Rect2(c - Vector2(half_w, half_h), Vector2(half_w, half_h) * 2.0), color)


## Arrow whose tip is at `tip`, pointing in `dir`.
static func _arrow(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, color: Color) -> void:
	var back := tip - dir * size
	var side := dir.orthogonal() * size * 0.6
	ci.draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), color)


static func _chevron(ci: CanvasItem, c: Vector2, dir: Vector2, size: float, color: Color,
		w: float) -> void:
	var tip := c + dir * size * 0.5
	var side := dir.orthogonal() * size
	var back := c - dir * size * 0.5
	ci.draw_polyline(PackedVector2Array([back + side, tip, back - side]), color, w, true)


static func _hourglass(ci: CanvasItem, c: Vector2, s: float, color: Color, w: float) -> void:
	var hw := s * 0.6
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-hw, -s), c + Vector2(hw, -s), c + Vector2(0.0, -s * 0.05),
	]), color)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.0, s * 0.05), c + Vector2(hw, s), c + Vector2(-hw, s),
	]), color)
	ci.draw_line(c + Vector2(-hw * 1.2, -s), c + Vector2(hw * 1.2, -s), color, w, true)
	ci.draw_line(c + Vector2(-hw * 1.2, s), c + Vector2(hw * 1.2, s), color, w, true)


static func _heart(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.45, -s * 0.2), s * 0.5, color, true, -1.0, true)
	ci.draw_circle(c + Vector2(s * 0.45, -s * 0.2), s * 0.5, color, true, -1.0, true)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.92, 0.0), c + Vector2(s * 0.92, 0.0), c + Vector2(0.0, s * 0.95),
	]), color)


static func _flame(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.0, -s), c + Vector2(s * 0.35, -s * 0.35), c + Vector2(s * 0.6, s * 0.1),
		c + Vector2(s * 0.45, s * 0.65), c + Vector2(0.0, s * 0.85), c + Vector2(-s * 0.45, s * 0.65),
		c + Vector2(-s * 0.6, s * 0.1), c + Vector2(-s * 0.2, -s * 0.3),
	]), color)


static func _label(ci: CanvasItem, text: String, c: Vector2, r: float, color: Color) -> void:
	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := maxi(int(r * LABEL_FONT_FACTOR), 8)
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := c + Vector2(-size.x / 2.0, font.get_ascent(font_size) - size.y / 2.0)
	ci.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
