class_name PowerUpDrop
extends Area2D

## A falling power-up capsule: a round token like a big ball, with the power-up's icon.
## The paddle catches it (Area2D overlap); if it falls past the bottom it disappears.

signal collected(drop: PowerUpDrop)

const RING_WIDTH: float = 2.5
const NEGATIVE_RING: Color = Color(0.6, 0.05, 0.05)
const POSITIVE_RING: Color = Color(1.0, 1.0, 1.0)
const ICON_COLOR: Color = Color(0.08, 0.08, 0.12)
## Size of the icon relative to the token radius.
const ICON_SCALE: float = 0.72
## Soft highlight in the upper left, so the token reads as a ball.
const SHINE_OFFSET: Vector2 = Vector2(-0.35, -0.4)
const SHINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.35)
## Spin speed (radians per second) and the thinnest the coin gets while turning.
const SPIN_SPEED: float = 2.4
const MIN_SQUASH: float = 0.25

## Must be set before the drop enters the tree.
@export var def: PowerUpDef
@export var radius: float = 20.0
@export var fall_speed: float = 160.0
## Y coordinate below which the capsule is gone.
@export var bottom_limit: float = 720.0

var _collected: bool = false
var _time: float = 0.0

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	assert(def != null, "PowerUpDrop needs a PowerUpDef before entering the tree")
	(_collision.shape as CircleShape2D).radius = radius
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	_time += delta
	queue_redraw()
	if position.y - radius > bottom_limit:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Paddle:
		return
	_collected = true
	collected.emit(self)
	queue_free()


func _draw() -> void:
	# Coin-like spin: only the drawing is squashed, the round collision shape stays.
	var squash := maxf(absf(cos(_time * SPIN_SPEED)), MIN_SQUASH)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash, 1.0))
	draw_circle(Vector2.ZERO, radius, def.color, true, -1.0, true)
	draw_circle(SHINE_OFFSET * radius, radius * 0.35, SHINE_COLOR, true, -1.0, true)
	var ring := NEGATIVE_RING if def.is_negative else POSITIVE_RING
	draw_circle(Vector2.ZERO, radius - RING_WIDTH / 2.0, ring, false, RING_WIDTH, true)
	PowerUpIcons.draw(self, def, Vector2.ZERO, radius * ICON_SCALE, ICON_COLOR)
