extends Node2D

## Main game scene: owns the game state, the lives count and the bricks.
## Loads a level through LevelLoader and builds its bricks. The ball sits on the paddle until
## `launch`; losing the last ball costs a life; breaking every clearable brick clears the level.

enum State { SERVING, PLAYING, GAME_OVER, LEVEL_CLEARED, LOAD_ERROR }

const BRICK_SCENE: PackedScene = preload("res://scenes/game/brick.tscn")
const MSG_SERVE := "Press Space or click to launch"
const MSG_GAME_OVER := "Game over\nPress Space or click to restart"
const MSG_LEVEL_CLEARED := "Level cleared!\nPress Space or click to play again"
const MSG_LOAD_ERROR := "Cannot load level"
## How many load errors to show on screen (the full list goes to the Output panel).
const MAX_ERRORS_SHOWN: int = 3

@export var starting_lives: int = 3
## Launch direction, in degrees from vertical (positive = to the right).
@export var launch_angle_deg: float = 20.0
## Gap between the paddle top and the ball while serving.
@export var serve_gap: float = 1.0

@export_group("Play area")
## Inner edges of the side walls.
@export var play_left: float = 20.0
@export var play_right: float = 1260.0

@export_group("Level")
@export_dir var level_set_dir: String = "res://levels/classic"
## Index of the level to play (0 = first level of the set).
@export var start_level: int = 0

@export_group("Bricks")
@export var brick_height: float = 20.0
@export var brick_gap: float = 4.0
## Y of the top edge of the first brick row.
@export var bricks_top: float = 70.0

var _state: State = State.SERVING
var _lives: int = 0
var _balls_in_play: Array[Ball] = []
var _bricks_remaining: int = 0
## Ball speed from the scene, before the level's ball_speed multiplier.
var _base_ball_speed: float = 0.0

@onready var _paddle: Paddle = $Paddle
@onready var _ball: Ball = $Ball
@onready var _hud: Hud = $HUD
@onready var _bricks: Node2D = $Bricks


func _ready() -> void:
	# Run after the paddle each physics tick, so a served ball follows the paddle's new position.
	process_physics_priority = 1
	_ball.exited_bottom.connect(_on_ball_exited_bottom)
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	_base_ball_speed = _ball.speed
	_lives = starting_lives
	EventBus.lives_changed.emit(_lives)
	var level := _load_level()
	if level == null:
		return
	_build_level(level)
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
		State.GAME_OVER, State.LEVEL_CLEARED:
			get_tree().reload_current_scene()


## Returns the level, or null after showing why it could not be loaded.
func _load_level() -> LevelData:
	var set_result := LevelLoader.load_set(level_set_dir)
	if not set_result.is_ok():
		_show_load_error(set_result.errors)
		return null
	var level_set := set_result.level_set
	var index := clampi(start_level, 0, level_set.level_count() - 1)
	var level_result := LevelLoader.load_level(level_set, index)
	if not level_result.is_ok():
		_show_load_error(level_result.errors)
		return null
	return level_result.level


func _show_load_error(errors: PackedStringArray) -> void:
	_state = State.LOAD_ERROR
	_ball.stop()
	_ball.hide()
	for error in errors:
		push_error(error)
	var shown := errors.slice(0, MAX_ERRORS_SHOWN)
	_hud.show_message(MSG_LOAD_ERROR + "\n\n" + "\n".join(shown))


func _build_level(level: LevelData) -> void:
	_ball.speed = _base_ball_speed * level.ball_speed
	var columns := LevelData.COLUMNS
	var width := play_right - play_left
	var brick_width := (width - brick_gap * (columns + 1)) / columns
	for row in level.row_count():
		var y := bricks_top + brick_height / 2.0 + row * (brick_height + brick_gap)
		for col in columns:
			var id := level.cell(row, col)
			if id.is_empty():
				continue
			var brick: Brick = BRICK_SCENE.instantiate()
			brick.brick_type = LevelLoader.get_brick_type(id)
			brick.size = Vector2(brick_width, brick_height)
			var x := play_left + brick_gap + brick_width / 2.0 + col * (brick_width + brick_gap)
			brick.position = Vector2(x, y)
			_bricks.add_child(brick)
			if brick.counts_for_clear():
				_bricks_remaining += 1


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


func _on_brick_destroyed(brick: Brick) -> void:
	if not brick.counts_for_clear():
		return
	_bricks_remaining -= 1
	if _bricks_remaining > 0 or _state != State.PLAYING:
		return
	_state = State.LEVEL_CLEARED
	for ball in _balls_in_play:
		ball.stop()
	_balls_in_play.clear()
	EventBus.level_cleared.emit()
	_hud.show_message(MSG_LEVEL_CLEARED)
