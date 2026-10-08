class_name Ball
extends CharacterBody2D

## Ball with hand-rolled physics: constant speed, move_and_collide() and bounce off the
## collision normal. Long moves are split into substeps so the ball cannot tunnel through
## thin bricks at high speed.

signal exited_bottom(ball: Ball)
signal paddle_hit(ball: Ball)

## Max collisions resolved inside one substep (corners can cause two or three).
const MAX_BOUNCES_PER_STEP: int = 4
## Trail behind the ball, in physics frames; the fire ball's trail is longer.
const TRAIL_LENGTH: int = 6
const FIRE_TRAIL_LENGTH: int = 12
const TRAIL_ALPHA: float = 0.45

@export var speed: float = 540.0
@export var radius: float = 8.0:
	set(value):
		radius = value
		if is_node_ready():
			_apply_size()
@export var color: Color = Color(1.0, 0.95, 0.8)
@export var fire_color: Color = Color(1.0, 0.45, 0.1)
@export var explosive_color: Color = Color(1.0, 0.85, 0.2)
## Minimum angle between the ball direction and the horizontal, in degrees.
@export var min_angle_deg: float = 20.0
## Bounce angle from vertical when the ball hits the very edge of the paddle.
@export var max_paddle_angle_deg: float = 65.0
## Longest distance moved in one substep; keep it below the thinnest brick height.
@export var max_step_distance: float = 8.0
## Y coordinate below which the ball counts as lost.
@export var bottom_limit: float = 720.0

## Fire ball: passes through bricks and destroys them (steel included) without bouncing.
var fire: bool = false:
	set(value):
		fire = value
		queue_redraw()

## Explosive ball: every brick hit also damages the bricks around it.
var explosive: bool = false:
	set(value):
		explosive = value
		queue_redraw()

var _moving: bool = false
## Recent global positions, newest last (the trail behind the ball).
var _trail: PackedVector2Array = []

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func launch(direction: Vector2) -> void:
	velocity = BallMath.enforce_min_angle(direction, min_angle_deg) * speed
	_moving = true


## Changes the speed, keeping the current direction if the ball is moving.
func change_speed(value: float) -> void:
	speed = value
	if _moving:
		velocity = velocity.normalized() * speed


func stop() -> void:
	velocity = Vector2.ZERO
	_moving = false
	_trail.clear()
	queue_redraw()


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
	_trail.append(global_position)
	var max_points := FIRE_TRAIL_LENGTH if fire else TRAIL_LENGTH
	while _trail.size() > max_points:
		_trail.remove_at(0)
	queue_redraw()
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
		paddle_hit.emit(self)
		EventBus.ball_bounced.emit(&"paddle")
		return
	if collider is Brick:
		var brick := collider as Brick
		if fire and not brick.behavior() is PortalBehavior:
			# Burn through: the brick stops colliding at once, so the ball keeps its course.
			brick.destroy(true)
			return
		if brick.hit(self):
			return  # the brick let the ball through (portal)
		if explosive:
			_explode_around(brick)
	else:
		EventBus.ball_bounced.emit(&"wall")
		if collider is Shield:
			(collider as Shield).absorb(global_position)
	var bounced := velocity.bounce(collision.get_normal())
	velocity = BallMath.enforce_min_angle(bounced, min_angle_deg) * speed


## Explosive ball: one damage to every brick next to the one that was hit.
func _explode_around(brick: Brick) -> void:
	EventBus.ball_exploded.emit(brick.global_position)
	if brick.grid == null:
		return
	for other in brick.grid.neighbors(brick.cell):
		other.damage(1)


func _draw() -> void:
	var main_color := color
	if fire:
		main_color = fire_color
	elif explosive:
		main_color = explosive_color
	var count := _trail.size()
	for i in count:
		var t := float(i + 1) / float(count + 1)
		var trail_color := main_color
		trail_color.a = t * TRAIL_ALPHA
		draw_circle(_trail[i] - global_position, radius * (0.35 + 0.55 * t), trail_color, true,
				-1.0, true)
	draw_circle(Vector2.ZERO, radius, main_color, true, -1.0, true)


func _apply_size() -> void:
	(_collision.shape as CircleShape2D).radius = radius
	queue_redraw()
