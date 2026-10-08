class_name Paddle
extends CharacterBody2D

## Player paddle. Moves only on the X axis, driven by move_left/move_right actions
## (keyboard, gamepad) or by the absolute mouse position.

const OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.06)
const BEVEL: float = 3.0
## Width of the red end caps.
const CAP_WIDTH: float = 16.0

@export var speed: float = 900.0
@export var width: float = 120.0:
	set(value):
		width = value
		if is_node_ready():
			_apply_size()
@export var height: float = 20.0
@export var color: Color = Color(0.7, 0.74, 0.84)
## Color of the end caps (retro DX-Ball style paddle).
@export var cap_color: Color = Color(0.86, 0.2, 0.25)
## Horizontal limits of the play area (inner edges of the side walls).
@export var min_x: float = 0.0
@export var max_x: float = 1280.0
## Ice paddle: acceleration (px/s²) toward the wanted speed, and how strongly it chases the mouse.
@export var ice_acceleration: float = 1500.0
@export var ice_mouse_gain: float = 6.0

## Reverse controls power-up: left and right swap (the mouse is mirrored around the arena center).
var reversed: bool = false
## Ice paddle power-up: the paddle speeds up and slides instead of stopping at once.
var ice: bool = false:
	set(value):
		ice = value
		_ice_velocity = 0.0

var _mouse_active: bool = false
var _ice_velocity: float = 0.0

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_active = true


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if reversed:
		axis = -axis
	if axis != 0.0:
		_mouse_active = false
	if ice:
		_ice_move(axis, delta)
	elif axis != 0.0:
		position.x += axis * speed * delta
	elif _mouse_active:
		position.x = _mouse_x()
	var half := width / 2.0
	var clamped := clampf(position.x, min_x + half, max_x - half)
	if clamped != position.x:
		_ice_velocity = 0.0  # hit the wall
	position.x = clamped


## Where the mouse wants the paddle (mirrored with reverse controls).
func _mouse_x() -> float:
	var x := get_global_mouse_position().x
	return min_x + max_x - x if reversed else x


## Ice: the input only sets the wanted speed; the paddle accelerates toward it and slides.
func _ice_move(axis: float, delta: float) -> void:
	var wanted := axis * speed
	if axis == 0.0 and _mouse_active:
		wanted = clampf((_mouse_x() - position.x) * ice_mouse_gain, -speed, speed)
	_ice_velocity = move_toward(_ice_velocity, wanted, ice_acceleration * delta)
	position.x += _ice_velocity * delta


func _apply_size() -> void:
	var rect := _collision.shape as RectangleShape2D
	rect.size = Vector2(width, height)
	queue_redraw()


func _draw() -> void:
	var size := Vector2(width, height)
	var body := Rect2(-size / 2.0, size)
	var cap := minf(CAP_WIDTH, width * 0.25)
	RetroDraw.bevel_rect(self, body, color, BEVEL, 0.5, 0.5, OUTLINE_COLOR)
	RetroDraw.bevel_rect(self, Rect2(body.position, Vector2(cap, height)), cap_color, BEVEL,
			0.45, 0.5, OUTLINE_COLOR)
	RetroDraw.bevel_rect(self, Rect2(body.end.x - cap, body.position.y, cap, height), cap_color,
			BEVEL, 0.45, 0.5, OUTLINE_COLOR)
