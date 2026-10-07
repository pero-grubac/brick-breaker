class_name FloatingText
extends Node2D

## Text that pops up, floats upward and fades out, then frees itself ("+75", "x2.5!").

const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const OUTLINE_SIZE: int = 6

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 16
var rise: float = 40.0
var duration: float = 0.7
## Start larger and shrink to normal size ("pop").
var pop: float = 1.6


func _ready() -> void:
	scale = Vector2(pop, pop)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, duration * 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - rise, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := RetroDraw.font()
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-size.x / 2.0, font.get_ascent(font_size) - size.y / 2.0)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			OUTLINE_SIZE, OUTLINE_COLOR)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
