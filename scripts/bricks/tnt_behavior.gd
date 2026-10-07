class_name TntBehavior
extends BrickBehavior

## Explosive brick: when destroyed, destroys the 8 bricks around it regardless of their hp
## (indestructible bricks survive). Neighboring TNT explodes in turn, a short moment later,
## so a chain reaction spreads visibly and never recurses deeply.

## Delay before neighbors are destroyed, in seconds.
const CHAIN_DELAY: float = 0.05
const MARK_COLOR: Color = Color(1.0, 0.85, 0.2)
const MARK_WIDTH: float = 2.0
## Inset of the X mark from the brick edges.
const MARK_INSET: Vector2 = Vector2(6.0, 4.0)


func on_destroyed(brick: Brick, grid: BrickGrid) -> void:
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


func draw(brick: Brick) -> void:
	var half := brick.size / 2.0 - MARK_INSET
	brick.draw_line(-half, half, MARK_COLOR, MARK_WIDTH, true)
	brick.draw_line(Vector2(-half.x, half.y), Vector2(half.x, -half.y), MARK_COLOR, MARK_WIDTH, true)
