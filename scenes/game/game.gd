extends Node2D

## Main game scene. For now it only launches the ball and relaunches it when it falls out;
## lives and launching from the paddle come in a later step.

@export var ball_start_position: Vector2 = Vector2(640, 400)
@export var ball_start_angle_deg: float = -60.0

@onready var _ball: Ball = $Ball


func _ready() -> void:
	_ball.exited_bottom.connect(_on_ball_exited_bottom)
	_reset_ball()


func _reset_ball() -> void:
	_ball.position = ball_start_position
	# Teleport: skip interpolating from the old position to the new one.
	_ball.reset_physics_interpolation()
	_ball.launch(Vector2.from_angle(deg_to_rad(ball_start_angle_deg)))


func _on_ball_exited_bottom(_lost_ball: Ball) -> void:
	_reset_ball()
