class_name PowerUpDrop
extends Area2D

## A falling power-up capsule. The paddle catches it (Area2D overlap); if it falls past the
## bottom it disappears. Looks are placeholders until real icons arrive (phase 5).

signal collected(drop: PowerUpDrop)

const OUTLINE_WIDTH: float = 2.0
const NEGATIVE_OUTLINE: Color = Color(0.55, 0.05, 0.05)
const POSITIVE_OUTLINE: Color = Color(0.95, 0.95, 0.95)
const LABEL_COLOR: Color = Color(0.08, 0.08, 0.1)
const LABEL_FONT_SIZE: int = 14

## Must be set before the drop enters the tree.
@export var def: PowerUpDef
@export var size: Vector2 = Vector2(44.0, 18.0)
@export var fall_speed: float = 160.0
## Y coordinate below which the capsule is gone.
@export var bottom_limit: float = 720.0

var _collected: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	assert(def != null, "PowerUpDrop needs a PowerUpDef before entering the tree")
	(_collision.shape as RectangleShape2D).size = size
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y - size.y / 2.0 > bottom_limit:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Paddle:
		return
	_collected = true
	collected.emit(self)
	queue_free()


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, def.color)
	var outline := NEGATIVE_OUTLINE if def.is_negative else POSITIVE_OUTLINE
	draw_rect(rect.grow(-OUTLINE_WIDTH / 2.0), outline, false, OUTLINE_WIDTH)
	if def.short_label.is_empty():
		return
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(def.short_label, HORIZONTAL_ALIGNMENT_LEFT, -1,
			LABEL_FONT_SIZE)
	var baseline := Vector2(-text_size.x / 2.0, font.get_ascent(LABEL_FONT_SIZE) - text_size.y / 2.0)
	draw_string(font, baseline, def.short_label, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE,
			LABEL_COLOR)
