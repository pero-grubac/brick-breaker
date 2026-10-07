class_name Brick
extends StaticBody2D

## A brick the ball can break. All data comes from its BrickType; the brick only tracks
## remaining hp, draws itself and announces its destruction on the EventBus. A type with a
## `behavior` script (e.g. TNT) gets an instance of it for special effects.

## Outline width of the placeholder graphics.
const OUTLINE_WIDTH: float = 2.0
## How much darker the outline is than the fill.
const OUTLINE_DARKEN: float = 0.4
const CRACK_COLOR: Color = Color(0.1, 0.1, 0.12, 0.85)

## Must be set before the brick enters the tree.
@export var brick_type: BrickType
@export var size: Vector2 = Vector2(64.0, 20.0):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()

## Level cell (column, row) and the grid this brick is registered in; set by Game.
var cell: Vector2i = Vector2i.ZERO
var grid: BrickGrid = null
var hp: int = 0
var _destroyed: bool = false
var _behavior: BrickBehavior = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	assert(brick_type != null, "Brick needs a BrickType before entering the tree")
	hp = brick_type.hp
	if brick_type.behavior != null:
		_behavior = brick_type.behavior.new() as BrickBehavior
	_apply_size()


func counts_for_clear() -> bool:
	return brick_type.counts_for_clear


## Called by the ball on collision: costs one hp.
func hit(_ball: Ball) -> void:
	if _destroyed or brick_type.is_indestructible():
		return
	hp -= 1
	if hp > 0:
		queue_redraw()
		return
	destroy()


## Destroys the brick at once, whatever its hp (explosions). Indestructible bricks ignore it.
func destroy() -> void:
	if _destroyed or brick_type.is_indestructible():
		return
	_destroyed = true
	# Stop colliding right away; queue_free() only removes the node at the end of the frame.
	collision_layer = 0
	if grid != null:
		grid.remove(cell, self)
	EventBus.brick_destroyed.emit(self)
	if _behavior != null:
		_behavior.on_destroyed(self, grid)
	queue_free()


func is_destroyed() -> bool:
	return _destroyed


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, brick_type.color)
	draw_rect(rect.grow(-OUTLINE_WIDTH / 2.0), brick_type.color.darkened(OUTLINE_DARKEN),
			false, OUTLINE_WIDTH)
	var damage := brick_type.hp - hp
	if not brick_type.is_indestructible() and damage > 0:
		_draw_cracks(damage)
	if _behavior != null:
		_behavior.draw(self)


## One crack per hit taken: a zigzag line across the brick, each one in a different spot.
func _draw_cracks(damage: int) -> void:
	var half := size / 2.0
	for i in damage:
		var x := lerpf(-half.x, half.x, 0.3 + 0.4 * i)
		var points := PackedVector2Array([
			Vector2(x - 6.0, -half.y),
			Vector2(x + 3.0, -half.y * 0.3),
			Vector2(x - 3.0, half.y * 0.3),
			Vector2(x + 5.0, half.y),
		])
		draw_polyline(points, CRACK_COLOR, 1.5, true)


func _apply_size() -> void:
	(_collision.shape as RectangleShape2D).size = size
	queue_redraw()
