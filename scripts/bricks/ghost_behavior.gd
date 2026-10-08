class_name GhostBehavior
extends BrickBehavior

## Invisible until the ball hits it for the first time; the first hit also does damage.

var revealed: bool = false


func on_hit(brick: Brick, _ball: Ball) -> bool:
	if not revealed:
		revealed = true
		brick.queue_redraw()
	return false


func is_visible(_brick: Brick) -> bool:
	return revealed
