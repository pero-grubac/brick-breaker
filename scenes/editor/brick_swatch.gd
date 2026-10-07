class_name BrickSwatch
extends Button

## Palette button that shows a brick. Toggle button in the editor's brick palette.

const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const PREVIEW_INSET: Vector2 = Vector2(8, 8)
const TNT_FONT_SIZE: int = 8

var brick_type: BrickType = null


func setup(type: BrickType) -> void:
	brick_type = type
	toggle_mode = true
	custom_minimum_size = Vector2(64, 38)
	tooltip_text = "BRICK_" + type.id.to_upper()
	queue_redraw()


func _draw() -> void:
	if brick_type == null:
		return
	var rect := Rect2(PREVIEW_INSET, size - PREVIEW_INSET * 2.0)
	RetroDraw.bevel_rect(self, rect, brick_type.color, 3.0, 0.45, 0.45, OUTLINE_COLOR)
	if brick_type.id == "tnt":
		var font := RetroDraw.font()
		var text_size := font.get_string_size("TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, TNT_FONT_SIZE)
		var baseline := rect.get_center() + Vector2(-text_size.x / 2.0,
				font.get_ascent(TNT_FONT_SIZE) - text_size.y / 2.0)
		draw_string(font, baseline, "TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, TNT_FONT_SIZE,
				Color(1.0, 0.85, 0.2))
