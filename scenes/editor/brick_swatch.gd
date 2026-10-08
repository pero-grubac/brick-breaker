class_name BrickSwatch
extends Button

## Palette button that shows a brick. Toggle button in the editor's brick palette.

const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const PREVIEW_INSET: Vector2 = Vector2(8, 8)

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
	BrickMarks.draw(self, rect, brick_type.id, true)
