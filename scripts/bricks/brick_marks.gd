class_name BrickMarks
extends RefCounted

## Marks drawn on top of special bricks so every type is recognizable at a glance, in the
## game, in the editor grid and on the editor palette. Drawn in code, like everything else.

const MARK_COLOR: Color = Color(1.0, 0.85, 0.2)
const DARK: Color = Color(0.02, 0.02, 0.06)
const LIGHT: Color = Color(1, 1, 1, 0.85)


## Draws the mark of brick type `id` inside `rect` on `ci` (nothing for plain bricks).
## `in_editor` adds marks that would give away hidden bricks in the game (ghost).
static func draw(ci: CanvasItem, rect: Rect2, id: String, in_editor: bool = false) -> void:
	var c := rect.get_center()
	var h := rect.size.y
	match id:
		"tnt":
			_label(ci, c, "TNT", 16 if h >= 18.0 else 8)
		"moving":
			var s := h * 0.28
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 3.2, 0), c + Vector2(-s * 1.6, -s),
					c + Vector2(-s * 1.6, s)]), LIGHT)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 3.2, 0), c + Vector2(s * 1.6, -s),
					c + Vector2(s * 1.6, s)]), LIGHT)
		"regen":
			var s := h * 0.3
			ci.draw_rect(Rect2(c - Vector2(s, s * 0.3), Vector2(s * 2, s * 0.6)), LIGHT)
			ci.draw_rect(Rect2(c - Vector2(s * 0.3, s), Vector2(s * 0.6, s * 2)), LIGHT)
		"portal":
			ci.draw_circle(c, h * 0.36, DARK, true, -1.0, true)
			ci.draw_circle(c, h * 0.36, LIGHT, false, 2.0, true)
			ci.draw_circle(c, h * 0.16, MARK_COLOR, true, -1.0, true)
		"spawner":
			var s := h * 0.16
			for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				ci.draw_rect(Rect2(c + offset * s * 1.6 - Vector2(s, s), Vector2(s * 2, s * 2)), DARK)
		"bonus":
			_label(ci, c, "?", 16 if h >= 18.0 else 8)
		"ghost":
			if in_editor:
				_label(ci, c, "...", 8)


static func _label(ci: CanvasItem, c: Vector2, text: String, font_size: int) -> void:
	var font := RetroDraw.font()
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := c + Vector2(-size.x / 2.0, font.get_ascent(font_size) - size.y / 2.0)
	ci.draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3,
			Color(0.25, 0.0, 0.0))
	ci.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, MARK_COLOR)
