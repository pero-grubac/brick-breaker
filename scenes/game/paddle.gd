class_name Paddle
extends CharacterBody2D

## Player paddle. Moves only on the X axis, driven by move_left/move_right actions
## (keyboard, gamepad) or by the absolute mouse position.

@export var speed: float = 900.0
@export var width: float = 120.0:
	set(value):
		width = value
		if is_node_ready():
			_apply_size()
@export var height: float = 20.0
@export var color: Color = Color(0.3, 0.75, 1.0)
## Horizontal limits of the play area (inner edges of the side walls).
@export var min_x: float = 0.0
@export var max_x: float = 1280.0

var _mouse_active: bool = false

@onready var _visual: ColorRect = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_active = true


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		_mouse_active = false
		position.x += axis * speed * delta
	elif _mouse_active:
		position.x = get_global_mouse_position().x
	var half := width / 2.0
	position.x = clampf(position.x, min_x + half, max_x - half)


func _apply_size() -> void:
	var rect := _collision.shape as RectangleShape2D
	rect.size = Vector2(width, height)
	_visual.size = Vector2(width, height)
	_visual.position = -_visual.size / 2.0
	_visual.color = color
