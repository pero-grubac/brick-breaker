class_name Brick
extends StaticBody2D

## A brick the ball can break. Announces its destruction on the EventBus and disappears.
## Brick types (BrickType resources) replace the exported values in phase 2.

@export var hp: int = 1
@export var size: Vector2 = Vector2(90.0, 28.0):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()
@export var color: Color = Color(0.9, 0.4, 0.4)

var _destroyed: bool = false

@onready var _visual: ColorRect = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


## Called by the ball on collision.
func hit(_ball: Ball) -> void:
	if _destroyed:
		return
	hp -= 1
	if hp > 0:
		return
	_destroyed = true
	# Stop colliding right away; queue_free() only removes the node at the end of the frame.
	collision_layer = 0
	EventBus.brick_destroyed.emit(self)
	queue_free()


func _apply_size() -> void:
	(_collision.shape as RectangleShape2D).size = size
	_visual.size = size
	_visual.position = -size / 2.0
	_visual.color = color
