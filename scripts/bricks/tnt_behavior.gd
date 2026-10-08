class_name TntBehavior
extends BrickBehavior

## Explosive brick: when destroyed, destroys the 8 bricks around it regardless of their hp
## (indestructible bricks survive). Neighboring TNT explodes in turn, a short moment later,
## so a chain reaction spreads visibly and never recurses deeply.

## Delay before neighbors are destroyed, in seconds.
const CHAIN_DELAY: float = 0.05


func on_destroyed(brick: Brick, grid: BrickGrid) -> void:
	EventBus.explosion.emit(brick.global_position)
	if grid == null:
		return
	var targets := grid.neighbors(brick.cell)
	if targets.is_empty():
		return
	# The timer belongs to the SceneTree, not to the brick that is being freed. If a target
	# is freed before the timer fires, Godot drops that connection on its own.
	var timer := brick.get_tree().create_timer(CHAIN_DELAY)
	for target in targets:
		timer.timeout.connect(target.destroy)
