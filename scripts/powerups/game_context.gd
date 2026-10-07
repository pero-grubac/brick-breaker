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
