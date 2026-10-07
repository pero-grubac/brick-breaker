extends Node2D

## Main game scene: owns the game state, lives, score, balls and bricks.
## Plays a level set from LevelLoader level by level; lives and score carry over between levels.
## The ball sits on the paddle until `launch`; losing the last ball costs a life; breaking
## every clearable brick clears the level. Broken levels are skipped with a message.
## Power-up effects change the game through GameContext, which calls the ctx_* methods below.

enum State { SERVING, PLAYING, GAME_OVER, LEVEL_CLEARED, SET_COMPLETE, LOAD_ERROR }

const BRICK_SCENE: PackedScene = preload("res://scenes/game/brick.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/game/ball.tscn")
# Message lines are translation keys (i18n/strings.csv); see _message().
## How many load errors to show on screen (the full list goes to the Output panel).
const MAX_ERRORS_SHOWN: int = 3

@export var starting_lives: int = 3
@export var max_lives: int = 9
## Most balls in play at once (multiball).
@export var max_balls: int = 30
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
## Index of the first level to play (0 = first level of the set). Handy for testing a level.
@export var start_level: int = 0

@export_group("Bricks")
@export var brick_height: float = 20.0
@export var brick_gap: float = 4.0
## Y of the top edge of the first brick row.
@export var bricks_top: float = 70.0

var _state: State = State.SERVING
var _lives: int = 0
## Balls in play, the main ball included; extra balls are freed when they are lost.
var _balls_in_play: Array[Ball] = []
var _bricks_remaining: int = 0
var _grid: BrickGrid = BrickGrid.new()
var _score: ScoreTracker = ScoreTracker.new()
var _level_set: LevelSetData = null
var _level_index: int = 0
var _level: LevelData = null
## Error of the last skipped level, shown with the next serve message.
var _skip_note: String = ""
## The final score of this run was already reported (EventBus.run_ended).
var _run_ended: bool = false
## Playing one level from the editor ("Test"); progress and scores are not recorded.
var _testing: bool = false

# Ball speed = base (from the scene) x level ball_speed x power-up factor.
var _base_ball_speed: float = 0.0
var _level_speed: float = 1.0
var _speed_factor: float = 1.0

var _sticky: bool = false
## Balls stuck to the sticky paddle, with their x offset from the paddle center.
var _stuck_balls: Dictionary[Ball, float] = {}
var _fire: bool = false

@onready var _paddle: Paddle = $Paddle
@onready var _ball: Ball = $Ball
@onready var _hud: Hud = $HUD
@onready var _bricks: Node2D = $Bricks
@onready var _power_ups: PowerUpManager = $PowerUpManager
@onready var _pause: PauseController = $PauseController


func _ready() -> void:
	# Run after the paddle and balls each physics tick, so balls on the paddle follow it.
	process_physics_priority = 1
	_connect_ball(_ball)
	_power_ups.setup(GameContext.new(self, _paddle))
	EventBus.brick_destroyed.connect(_on_brick_destroyed)
	_hud.resume_requested.connect(_pause.set_paused.bind(false))
	_hud.restart_requested.connect(_on_restart_requested)
	_hud.main_menu_requested.connect(_on_main_menu_requested)
	_base_ball_speed = _ball.speed
	_lives = starting_lives
	EventBus.lives_changed.emit(_lives)
	EventBus.score_changed.emit(_score.score)
	EventBus.combo_changed.emit(_score.combo)

	if GameSession.test_level != null:
		# "Test" from the level editor: one level from memory, Escape goes back to the editor.
		_start_test(GameSession.test_level)
		return
	if GameSession.level_set != null:
		# Started from the menu.
		_level_set = GameSession.level_set
		start_level = GameSession.start_level
	else:
		# Started directly (F6 on this scene): use the exported set and level.
		var set_result := LevelLoader.load_set(level_set_dir)
		if not set_result.is_ok():
			_show_load_error(set_result.errors)
			return
		_level_set = set_result.level_set
	_start_level(clampi(start_level, 0, _level_set.level_count() - 1))


func _physics_process(_delta: float) -> void:
	if _state == State.SERVING:
		_place_ball_on_paddle()
	elif _state == State.PLAYING:
		_place_stuck_balls()


func _unhandled_input(event: InputEvent) -> void:
	if _testing and event.is_action_pressed("pause"):
		GameSession.back_to_level_editor()
		return
	if not event.is_action_pressed("launch"):
		return
	if _testing and _state in [State.GAME_OVER, State.SET_COMPLETE]:
		GameSession.back_to_level_editor()
		return
	match _state:
		State.SERVING:
			_launch()
		State.PLAYING:
			_release_stuck_balls()
		State.LEVEL_CLEARED:
			_start_level(_level_index + 1)
		State.GAME_OVER:
			# Try again from where this run started.
			GameSession.play(_level_set, start_level)
		State.SET_COMPLETE:
			GameSession.go_to_set_select()


## Joins translated message lines.
func _message(keys: Array[String]) -> String:
	var lines := PackedStringArray()
	for key in keys:
		lines.append(tr(key))
	return "\n".join(lines)


func _on_restart_requested() -> void:
	GameSession.play(_level_set, _level_index)


func _on_main_menu_requested() -> void:
	_end_run()
	GameSession.go_to_main_menu()


## Reports the final score once per run. Returns true if it is a new best for the set.
## Test runs from the editor never count.
func _end_run() -> bool:
	if _level_set == null or _run_ended or _testing:
		return false
	_run_ended = true
	var is_best := _score.score > 0 and _score.score > SaveManager.data.best_score(_level_set.id)
	EventBus.run_ended.emit(_level_set.id, _score.score)
	return is_best


# --- levels ---

## Plays one level handed over by the editor. The pause menu is off: Escape returns to the
## editor, and so does Space after the level ends.
func _start_test(level: LevelData) -> void:
	_testing = true
	_pause.process_mode = Node.PROCESS_MODE_DISABLED
	_level_set = LevelSetData.new()
	_level_set.id = "editor.test"
	_level_set.name = level.name
	_level_set.level_files = PackedStringArray(["test.json"])
	_level_index = 0
	_level = level
	_power_ups.set_level(_level)
	_build_level(_level)
	EventBus.level_started.emit(1, 1, _level.name)
	_reset_paddle()
	_serve()


## Starts the level at `index`, skipping broken levels. Past the last level, the set is done.
func _start_level(index: int) -> void:
	_power_ups.clear_all()
	_clear_bricks()
	_skip_note = ""
	while index < _level_set.level_count():
		var result := LevelLoader.load_level(_level_set, index)
		if result.is_ok():
			_level_index = index
			_level = result.level
			_power_ups.set_level(_level)
			_build_level(_level)
			EventBus.level_started.emit(index + 1, _level_set.level_count(), _level.name)
			_reset_paddle()
			_serve()
			return
		for error in result.errors:
			push_error(error)
		_skip_note = result.errors[0]
		index += 1
	_finish_set()


func _finish_set() -> void:
	_state = State.SET_COMPLETE
	_stop_all_balls()
	var keys: Array[String] = ["MSG_SET_COMPLETE"]
	if _end_run():
		keys.append("MSG_NEW_BEST")
	keys.append("MSG_BACK_TO_MENU")
	var message := _message(keys)
	if not _skip_note.is_empty():
		# The last level(s) were broken; still say why.
		message += "\n\n%s\n%s" % [tr("MSG_SKIPPED"), _skip_note]
	_hud.show_message(message)


func _show_load_error(errors: PackedStringArray) -> void:
	_state = State.LOAD_ERROR
	_ball.stop()
	_ball.hide()
	for error in errors:
		push_error(error)
	var shown := errors.slice(0, MAX_ERRORS_SHOWN)
	_hud.show_message(tr("MSG_LOAD_ERROR") + "\n\n" + "\n".join(shown))


func _clear_bricks() -> void:
	for brick in _bricks.get_children():
		_bricks.remove_child(brick)
		brick.queue_free()
	_grid.clear()
	_bricks_remaining = 0


func _build_level(level: LevelData) -> void:
	_level_speed = level.ball_speed
	_apply_ball_speed()
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
			brick.cell = Vector2i(col, row)
			brick.grid = _grid
			_grid.add(brick.cell, brick)
			_bricks.add_child(brick)
			if brick.counts_for_clear():
				_bricks_remaining += 1


# --- serving and balls ---

func _reset_paddle() -> void:
	_paddle.position.x = (play_left + play_right) / 2.0
	_paddle.reset_physics_interpolation()


func _serve() -> void:
	_state = State.SERVING
	_remove_extra_balls()
	_stuck_balls.clear()
	_ball.stop()
	_ball.show()
	_place_ball_on_paddle()
	_ball.reset_physics_interpolation()
	var message := _message(["MSG_SERVE", "TEST_RETURN" if _testing else "MSG_PAUSE_HINT"])
	if not _skip_note.is_empty():
		message += "\n\n%s\n%s" % [tr("MSG_SKIPPED"), _skip_note]
	_hud.show_message(message)


func _launch() -> void:
	_state = State.PLAYING
	_skip_note = ""
	_hud.hide_message()
	_balls_in_play = [_ball]
	_ball.launch(Vector2.UP.rotated(deg_to_rad(launch_angle_deg)))


func _place_ball_on_paddle() -> void:
	_ball.position = _paddle.position - Vector2(0.0, _ball_rest_height(_ball))


func _ball_rest_height(ball: Ball) -> float:
	return _paddle.height / 2.0 + ball.radius + serve_gap


func _connect_ball(ball: Ball) -> void:
	ball.exited_bottom.connect(_on_ball_exited_bottom)
	ball.paddle_hit.connect(_on_ball_paddle_hit)


func _remove_extra_balls() -> void:
	for ball in _balls_in_play:
		if ball != _ball:
			ball.queue_free()
	_balls_in_play.clear()


func _stop_all_balls() -> void:
	for ball in _balls_in_play:
		ball.stop()
	_stuck_balls.clear()


func _apply_ball_speed() -> void:
	var speed := _base_ball_speed * _level_speed * _speed_factor
	_ball.change_speed(speed)
	for ball in _balls_in_play:
		ball.change_speed(speed)


func _place_stuck_balls() -> void:
	for ball in _stuck_balls:
		var offset := _stuck_balls[ball]
		ball.position = _paddle.position + Vector2(offset, -_ball_rest_height(ball))


func _release_stuck_balls() -> void:
	for ball in _stuck_balls:
		var direction := BallMath.paddle_bounce_direction(_stuck_balls[ball],
				_paddle.width / 2.0, ball.max_paddle_angle_deg)
		ball.launch(direction)
	_stuck_balls.clear()


func _on_ball_exited_bottom(ball: Ball) -> void:
	_balls_in_play.erase(ball)
	_stuck_balls.erase(ball)
	if ball != _ball:
		ball.queue_free()
	if not _balls_in_play.is_empty():
		return
	EventBus.ball_lost.emit()
	_power_ups.clear_all()
	_reset_combo()
	_lives -= 1
	EventBus.lives_changed.emit(_lives)
	if _lives > 0:
		_serve()
	else:
		_state = State.GAME_OVER
		_power_ups.clear_all()
		EventBus.game_over.emit()
		var keys: Array[String] = ["MSG_GAME_OVER"]
		if _end_run():
			keys.append("MSG_NEW_BEST")
		keys.append("TEST_DONE" if _testing else "MSG_TRY_AGAIN")
		_hud.show_message(_message(keys))


func _on_ball_paddle_hit(ball: Ball) -> void:
	_reset_combo()
	if _sticky and _state == State.PLAYING:
		ball.stop()
		var max_offset := _paddle.width / 2.0
		_stuck_balls[ball] = clampf(ball.position.x - _paddle.position.x, -max_offset, max_offset)


# --- score ---

func _reset_combo() -> void:
	_score.reset_combo()
	EventBus.combo_changed.emit(_score.combo)


func _on_brick_destroyed(brick: Brick) -> void:
	_add_score(brick.brick_type.points)
	if not brick.counts_for_clear():
		return
	_bricks_remaining -= 1
	if _bricks_remaining > 0 or _state != State.PLAYING:
		return
	_stop_all_balls()
	_remove_extra_balls()
	_power_ups.clear_all()
	EventBus.level_cleared.emit()
	if _testing:
		_state = State.SET_COMPLETE
		_hud.show_message(_message(["MSG_LEVEL_CLEARED", "TEST_DONE"]))
		return
	EventBus.level_completed.emit(_level_set.id, _level_index)
	if _level_index + 1 < _level_set.level_count():
		_state = State.LEVEL_CLEARED
		_hud.show_message(_message(["MSG_LEVEL_CLEARED", "MSG_NEXT_LEVEL"]))
	else:
		_finish_set()


func _add_score(points: int) -> void:
	var lives_earned := _score.add_brick(points)
	EventBus.score_changed.emit(_score.score)
	EventBus.combo_changed.emit(_score.combo)
	if lives_earned > 0:
		_change_lives(lives_earned)


func _change_lives(amount: int) -> void:
	var lives := clampi(_lives + amount, 0, max_lives)
	if lives != _lives:
		_lives = lives
		EventBus.lives_changed.emit(_lives)


# --- GameContext API (called by power-up effects through GameContext) ---

func ctx_balls() -> Array[Ball]:
	var moving: Array[Ball] = []
	for ball in _balls_in_play:
		if ball.is_moving():
			moving.append(ball)
	return moving


func ctx_spawn_ball(position_: Vector2, direction: Vector2) -> Ball:
	if _state != State.PLAYING or _balls_in_play.size() >= max_balls:
		return null
	var ball: Ball = BALL_SCENE.instantiate()
	add_child(ball)
	_connect_ball(ball)
	ball.position = position_
	ball.reset_physics_interpolation()
	ball.fire = _fire
	ball.change_speed(_base_ball_speed * _level_speed * _speed_factor)
	ball.launch(direction)
	_balls_in_play.append(ball)
	return ball


func ctx_add_life() -> void:
	_change_lives(1)


func ctx_set_ball_speed_factor(factor: float) -> void:
	_speed_factor = factor
	_apply_ball_speed()


func ctx_set_sticky(enabled: bool) -> void:
	_sticky = enabled
	if not enabled:
		_release_stuck_balls()


func ctx_set_fire(enabled: bool) -> void:
	_fire = enabled
	_ball.fire = enabled
	for ball in _balls_in_play:
		ball.fire = enabled
