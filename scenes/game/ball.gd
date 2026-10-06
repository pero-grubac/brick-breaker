class_name Ball
extends CharacterBody2D

## Ball with hand-rolled physics: constant speed, move_and_collide() and bounce off the
## collision normal. Long moves are split into substeps so the ball cannot tunnel through
## thin bricks at high speed.

signal exited_bottom(ball: Ball)

## Max collisions resolved inside one substep (corners can cause two or three).
const MAX_BOUNCES_PER_STEP: int = 4

@export var speed: float = 450.0
@export var radius: float = 8.0:
	set(value):
		radius = value
		if is_node_ready():
			_apply_size()
@export var color: Color = Color(1.0, 0.95, 0.8)
## Minimum angle between the ball direction and the horizontal, in degrees.
@export var min_angle_deg: float = 20.0
## Bounce angle from vertical when the ball hits the very edge of the paddle.
@export var max_paddle_angle_deg: float = 65.0
## Longest distance moved in one substep; keep it below the thinnest brick height.
@export var max_step_distance: float = 8.0
## Y coordinate below which the ball counts as lost.
@export var bottom_limit: float = 720.0

var _moving: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func launch(direction: Vector2) -> void:
	velocity = BallMath.enforce_min_angle(direction, min_angle_deg) * speed
	_moving = true


func stop() -> void:
	velocity = Vector2.ZERO
	_moving = false


func is_moving() -> bool:
	return _moving


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	var travel := speed * delta
	var steps := maxi(1, ceili(travel / max_step_distance))
	var step_length := travel / steps
	for i in steps:
		_move_step(step_length)
	if global_position.y - radius > bottom_limit:
		stop()
		exited_bottom.emit(self)


func _move_step(distance: float) -> void:
	var motion := velocity.normalized() * distance
	for i in MAX_BOUNCES_PER_STEP:
		var collision := move_and_collide(motion)
		if collision == null:
			return
		_on_collision(collision)
		var remainder := collision.get_remainder().length()
		if is_zero_approx(remainder):
			return
		motion = velocity.normalized() * remainder


func _on_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Paddle:
		var paddle := collider as Paddle
		var offset := global_position.x - paddle.global_position.x
		velocity = BallMath.paddle_bounce_direction(offset, paddle.width / 2.0,
				max_paddle_angle_deg) * speed
		return
	var bounced := velocity.bounce(collision.get_normal())
	velocity = BallMath.enforce_min_angle(bounced, min_angle_deg) * speed
	if collider != null and collider.has_method("hit"):
		collider.hit(self)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)


func _apply_size() -> void:
	(_collision.shape as CircleShape2D).radius = radius
	queue_redraw()
