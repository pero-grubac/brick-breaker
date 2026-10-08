class_name BrickBehavior
extends RefCounted

## Base class for special brick behaviors. A BrickType points to a subclass script in its
## `behavior` field; every brick of that type gets its own instance. Override what you need;
## the defaults do nothing.


## Called once when the brick enters the game (its grid and cell are set).
func setup(_brick: Brick) -> void:
	pass


## True if tick() must run every physics frame (moving, regenerating, spawning bricks).
func wants_tick() -> bool:
	return false


func tick(_brick: Brick, _delta: float) -> void:
	pass


## Called when the ball hits the brick, before any damage. Return true if the behavior handled
## the hit completely: no damage and no bounce, the ball keeps going (portals).
func on_hit(_brick: Brick, _ball: Ball) -> bool:
	return false


## Called whenever the brick takes damage but survives.
func on_damaged(_brick: Brick) -> void:
	pass


## Called once when the brick is destroyed, after it left the grid.
func on_destroyed(_brick: Brick, _grid: BrickGrid) -> void:
	pass


## False hides the brick's normal drawing (ghost bricks before their first hit).
func is_visible(_brick: Brick) -> bool:
	return true


## Called at the end of the brick's _draw(); draw extra marks with the brick's draw_* methods.
func draw(_brick: Brick) -> void:
	pass
