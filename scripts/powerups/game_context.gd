class_name GameContext
extends RefCounted

## What power-up effects are allowed to touch. Effects never reach into Game directly, so
## Game can change without breaking them, and tests can hand effects a fake context.
## Game implements the methods below (see game.gd, "GameContext API").

var paddle: Paddle = null
## Paddle width before any effect changed it.
var paddle_base_width: float = 0.0

var _game: Node = null


func _init(game: Node, game_paddle: Paddle) -> void:
	_game = game
	paddle = game_paddle
	paddle_base_width = game_paddle.width


## Balls currently flying (not lost).
func balls() -> Array[Ball]:
	return _game.ctx_balls()


## Adds a ball at `position` moving in `direction`. Returns null if the ball limit is reached.
func spawn_ball(position: Vector2, direction: Vector2) -> Ball:
	return _game.ctx_spawn_ball(position, direction)


func add_life() -> void:
	_game.ctx_add_life()


## Multiplier on top of the level's ball speed (1.0 = normal).
func set_ball_speed_factor(factor: float) -> void:
	_game.ctx_set_ball_speed_factor(factor)


## Sticky paddle: balls that hit the paddle stay on it until `launch`.
func set_sticky(enabled: bool) -> void:
	_game.ctx_set_sticky(enabled)


## Fire ball: balls pass through bricks and destroy them, steel included.
func set_fire(enabled: bool) -> void:
	_game.ctx_set_fire(enabled)


## Ball size multiplier (1.0 = normal).
func set_ball_radius_factor(factor: float) -> void:
	_game.ctx_set_ball_radius_factor(factor)


## Multiplies the score multiplier (call again with 1 / factor to undo).
func multiply_score(factor: float) -> void:
	_game.ctx_multiply_score(factor)


## While on, hitting the paddle does not reset the combo.
func set_combo_lock(enabled: bool) -> void:
	_game.ctx_set_combo_lock(enabled)


## Bricks still in the level.
func bricks() -> Array[Brick]:
	return _game.ctx_bricks()


func lose_life() -> void:
	_game.ctx_lose_life()


func complete_level() -> void:
	_game.ctx_complete_level()


## Slows down (or speeds up) the whole game; 1.0 = normal.
func set_time_scale(scale: float) -> void:
	_game.ctx_set_time_scale(scale)


## Explosive ball: every brick hit also damages the bricks around it.
func set_explosive(enabled: bool) -> void:
	_game.ctx_set_explosive(enabled)


## Paddle weapon: &"laser", &"missile" or &"" for none. `ammo` -1 = unlimited.
func set_weapon(kind: StringName, ammo: int = -1) -> void:
	_game.ctx_set_weapon(kind, ammo)


## Shots left for the current weapon (-1 = unlimited).
func weapon_ammo() -> int:
	return _game.ctx_weapon_ammo()


## Adds a shield under the paddle, or one more hit to the existing shield.
func add_shield() -> void:
	_game.ctx_add_shield()


## Falling capsules drift toward the paddle.
func set_magnet(enabled: bool) -> void:
	_game.ctx_set_magnet(enabled)


## A second, one-way paddle above the main one.
func set_twin_paddle(enabled: bool) -> void:
	_game.ctx_set_twin_paddle(enabled)
