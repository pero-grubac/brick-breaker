class_name PowerUpIcons
extends RefCounted

## Vector icons for power-ups, drawn in code on any CanvasItem (capsules now, HUD later).
## Every icon fits in a circle of radius `r` around `c`. Power-ups without an icon here fall
## back to their short_label text.

const LINE_WIDTH_FACTOR: float = 0.16
const LABEL_FONT_FACTOR: float = 0.9


static func has_icon(id: String) -> bool:
	return id in ["multiball", "long_paddle", "short_paddle", "slow_ball", "fast_ball",
			"extra_life", "sticky_paddle", "fire_ball", "big_ball", "small_ball", "slow_motion",
			"points_x2", "combo_lock", "weaken", "fortify", "death", "skip_level", "mega_ball",
			"lightning", "laser", "missile", "explosive_ball", "shield", "magnet", "twin_paddle"]


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
		"big_ball":
			ci.draw_circle(c, r * 0.62, color, true, -1.0, true)
		"small_ball":
			ci.draw_circle(c, r * 0.2, color, true, -1.0, true)
			ci.draw_arc(c, r * 0.62, 0.0, TAU, 24, color, w * 0.6, true)
		"slow_motion":
			ci.draw_arc(c, r * 0.68, 0.0, TAU, 24, color, w, true)
			ci.draw_line(c, c + Vector2(0, -r * 0.45), color, w, true)
			ci.draw_line(c, c + Vector2(r * 0.32, 0), color, w, true)
		"points_x2":
			_label(ci, "x2", c, r, color)
		"combo_lock":
			_lock(ci, c, r * 0.7, color, w)
		"weaken":
			_bar(ci, c + Vector2(0, -r * 0.3), r * 0.6, r * 0.22, color)
			_arrow(ci, c + Vector2(0, r * 0.75), Vector2.DOWN, r * 0.5, color)
		"fortify":
			_bar(ci, c + Vector2(0, r * 0.3), r * 0.6, r * 0.22, color)
			_arrow(ci, c + Vector2(0, -r * 0.75), Vector2.UP, r * 0.5, color)
		"death":
			_skull(ci, c, r * 0.7, color, def.color)
		"skip_level":
			_arrow(ci, c + Vector2(r * 0.05, 0), Vector2.RIGHT, r * 0.55, color)
			_arrow(ci, c + Vector2(r * 0.6, 0), Vector2.RIGHT, r * 0.55, color)
			ci.draw_line(c + Vector2(r * 0.68, -r * 0.4), c + Vector2(r * 0.68, r * 0.4), color, w, true)
		"mega_ball":
			for i in 8:
				var offset := Vector2.from_angle(TAU * i / 8.0) * r * 0.55
				ci.draw_circle(c + offset, r * 0.15, color, true, -1.0, true)
			ci.draw_circle(c, r * 0.2, color, true, -1.0, true)
		"lightning":
			_bolt(ci, c, r * 0.8, color)
		"laser":
			_bar(ci, c + Vector2(0, r * 0.5), r * 0.62, r * 0.16, color)
			for x in [-0.45, 0.45]:
				ci.draw_line(c + Vector2(x * r, r * 0.25), c + Vector2(x * r, -r * 0.7), color, w, true)
		"missile":
			_rocket(ci, c, r * 0.8, color)
		"explosive_ball":
			_star(ci, c, r * 0.75, r * 0.38, 8, color)
		"shield":
			_bar(ci, c + Vector2(0, r * 0.15), r * 0.75, r * 0.12, color)
			ci.draw_circle(c + Vector2(0, -r * 0.4), r * 0.22, color, true, -1.0, true)
			_arrow(ci, c + Vector2(0, -r * 0.05), Vector2.UP, r * 0.3, color)
			_bar(ci, c + Vector2(0, r * 0.6), r * 0.45, r * 0.1, color)
		"magnet":
			_magnet(ci, c, r * 0.65, color, w)
		"twin_paddle":
			_bar(ci, c + Vector2(0, -r * 0.3), r * 0.6, r * 0.15, color)
			_bar(ci, c + Vector2(0, r * 0.35), r * 0.6, r * 0.15, color)
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


static func _lock(ci: CanvasItem, c: Vector2, s: float, color: Color, w: float) -> void:
	ci.draw_arc(c + Vector2(0, -s * 0.2), s * 0.45, PI, TAU, 12, color, w, true)
	_bar(ci, c + Vector2(0, s * 0.35), s * 0.65, s * 0.5, color)


## `eye_color` is the background (capsule) color, so the eyes look like holes.
static func _skull(ci: CanvasItem, c: Vector2, s: float, color: Color, eye_color: Color) -> void:
	ci.draw_circle(c + Vector2(0, -s * 0.15), s * 0.7, color, true, -1.0, true)
	_bar(ci, c + Vector2(0, s * 0.6), s * 0.4, s * 0.25, color)
	ci.draw_circle(c + Vector2(-s * 0.28, -s * 0.1), s * 0.18, eye_color, true, -1.0, true)
	ci.draw_circle(c + Vector2(s * 0.28, -s * 0.1), s * 0.18, eye_color, true, -1.0, true)


static func _bolt(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(s * 0.15, -s), c + Vector2(-s * 0.5, s * 0.1), c + Vector2(-s * 0.05, s * 0.1),
		c + Vector2(-s * 0.2, s), c + Vector2(s * 0.5, -s * 0.15), c + Vector2(s * 0.05, -s * 0.15),
	]), color)


static func _rocket(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var half := s * 0.3
	_bar(ci, c + Vector2(0, s * 0.1), half, s * 0.5, color)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-half, -s * 0.4), c + Vector2(half, -s * 0.4), c + Vector2(0, -s),
	]), color)
	for side: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([
			c + Vector2(side * half, s * 0.1), c + Vector2(side * s * 0.75, s * 0.75),
			c + Vector2(side * half, s * 0.6),
		]), color)


## Star with `points` spikes between radii `outer` and `inner`.
static func _star(ci: CanvasItem, c: Vector2, outer: float, inner: float, points: int,
		color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in points * 2:
		var radius := outer if i % 2 == 0 else inner
		polygon.append(c + Vector2.from_angle(PI * i / points - PI / 2.0) * radius)
	ci.draw_colored_polygon(polygon, color)


## Horseshoe magnet, open side up.
static func _magnet(ci: CanvasItem, c: Vector2, s: float, color: Color, w: float) -> void:
	var thick := w * 2.2
	ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.7, 0.0, PI, 16, color, thick, true)
	for side: float in [-1.0, 1.0]:
		var x := side * s * 0.7
		ci.draw_line(c + Vector2(x, s * 0.1), c + Vector2(x, -s * 0.75), color, thick, true)


static func _label(ci: CanvasItem, text: String, c: Vector2, r: float, color: Color) -> void:
	if text.is_empty():
		return
	var font := RetroDraw.font()
	var font_size := maxi(int(r * LABEL_FONT_FACTOR), 8)
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := c + Vector2(-size.x / 2.0, font.get_ascent(font_size) - size.y / 2.0)
	ci.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
