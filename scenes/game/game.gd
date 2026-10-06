extends Node2D

## Main game scene: owns the game state (serving, playing, game over) and the lives count.
## The ball sits on the paddle until `launch`; losing the last ball costs a life.

enum State { SERVING, PLAYING, GAME_OVER }

const MSG_SERVE := "Press Space or click to launch"
const MSG_GAME_OVER := "Game over\nPress Space or click to restart"

@export var starting_lives: int = 3
## Launch direction, in degrees from vertical (positive = to the right).
@export var launch_angle_deg: float = 20.0
## Gap between the paddle top and the ball while serving.
@export var serve_gap: float = 1.0

var _state: State = State.SERVING
var _lives: int = 0
var _balls_in_play: Array[Ball] = []

@onready var _paddle: Paddle = $Paddle
@onready var _ball: Ball = $Ball
@onready var _hud: Hud = $HUD


func _ready() -> void:
	# Run after the paddle each physics tick, so a served ball follows the paddle's new position.
	process_physics_priority = 1
	_ball.exited_bottom.connect(_on_ball_exited_bottom)
	_lives = starting_lives
	EventBus.lives_changed.emit(_lives)
	_serve()


func _physics_process(_delta: float) -> void:
	if _state == State.SERVING:
		_place_ball_on_paddle()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("launch"):
		return
	match _state:
		State.SERVING:
			_launch()
		State.GAME_OVER:
			get_tree().reload_current_scene()


func _serve() -> void:
	_state = State.SERVING
	_ball.stop()
	_place_ball_on_paddle()
	_ball.reset_physics_interpolation()
	_hud.show_message(MSG_SERVE)


func _launch() -> void:
	_state = State.PLAYING
	_hud.hide_message()
	_balls_in_play = [_ball]
	_ball.launch(Vector2.UP.rotated(deg_to_rad(launch_angle_deg)))


func _place_ball_on_paddle() -> void:
	var y_offset := _paddle.height / 2.0 + _ball.radius + serve_gap
	_ball.position = _paddle.position - Vector2(0.0, y_offset)


func _on_ball_exited_bottom(ball: Ball) -> void:
	_balls_in_play.erase(ball)
	if not _balls_in_play.is_empty():
		return
	EventBus.ball_lost.emit()
	_lives -= 1
	EventBus.lives_changed.emit(_lives)
	if _lives > 0:
		_serve()
	else:
		_state = State.GAME_OVER
		EventBus.game_over.emit()
		_hud.show_message(MSG_GAME_OVER)
