class_name Shield
extends StaticBody2D

## Glowing barrier under the paddle (shield power-up). The ball bounces off it like a wall;
## every bounce uses up one hit, and the shield disappears when none are left.

const MAX_HITS: int = 3
const THICKNESS: float = 6.0
const COLOR: Color = Color(0.4, 0.85, 1.0)
const GLOW_ALPHA: float = 0.4
const PULSE_SPEED: float = 5.0

## Inner width of the arena the shield spans.
var width: float = 1240.0
var hits: int = 1

var _time: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, THICKNESS)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Another shield power-up while this one is up: one more hit, up to MAX_HITS.
func add_hit() -> void:
	hits = mini(hits + 1, MAX_HITS)


## Called by the ball when it bounces off the shield at `at`.
func absorb(at: Vector2) -> void:
	hits -= 1
	EventBus.shield_hit.emit(Vector2(at.x, global_position.y), hits)
	if hits <= 0:
		# Stop colliding right away (we are inside the physics step), free at the end of the frame.
		collision_layer = 0
		queue_free()


func _draw() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * PULSE_SPEED)
	var glow := COLOR
	glow.a = GLOW_ALPHA * pulse
	var rect := Rect2(-width / 2.0, -THICKNESS / 2.0, width, THICKNESS)
	draw_rect(rect.grow(5.0), glow)
	var line := COLOR
	line.a = 0.5 + 0.5 * pulse
	# One line per remaining hit, so the player can see how strong the shield is.
	for i in hits:
		var y := -THICKNESS / 2.0 + (i + 0.5) * THICKNESS / MAX_HITS
		draw_line(Vector2(-width / 2.0, y), Vector2(width / 2.0, y), line, 3.0)
