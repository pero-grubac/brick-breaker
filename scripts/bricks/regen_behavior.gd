class_name RegenBehavior
extends BrickBehavior

## A damaged regenerating brick heals back to full hp if it is not finished off in time.

const REGEN_TIME: float = 4.0

var _timer: float = 0.0


func wants_tick() -> bool:
	return true


func on_damaged(_brick: Brick) -> void:
	_timer = 0.0


func tick(brick: Brick, delta: float) -> void:
	if brick.hp >= brick.brick_type.hp:
		return
	_timer += delta
	if _timer >= REGEN_TIME:
		_timer = 0.0
		brick.heal(brick.brick_type.hp)
