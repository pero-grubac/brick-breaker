class_name MovingBehavior
extends BrickBehavior

## Slides left and right through the free cells of its row (the cells that were empty when the
## level started), bouncing at the ends. With no free cell next to it, it stays put.

const SPEED: float = 70.0

var _min_x: float = 0.0
var _max_x: float = 0.0
var _direction: float = 1.0


func setup(brick: Brick) -> void:
	if brick.grid == null:
		return
	var span := free_span(brick.grid, brick.cell)
	_min_x = brick.position.x + (span.x - brick.cell.x) * brick.grid.cell_step.x
	_max_x = brick.position.x + (span.y - brick.cell.x) * brick.grid.cell_step.x


func wants_tick() -> bool:
	return true


func tick(brick: Brick, delta: float) -> void:
	if _max_x <= _min_x:
		return
	brick.position.x += _direction * SPEED * delta
	if brick.position.x >= _max_x:
		brick.position.x = _max_x
		_direction = -1.0
	elif brick.position.x <= _min_x:
		brick.position.x = _min_x
		_direction = 1.0


## Columns (first, last) the brick may occupy: its own cell plus the free cells beside it.
static func free_span(grid: BrickGrid, cell: Vector2i) -> Vector2i:
	var first := cell.x
	while grid.is_free(Vector2i(first - 1, cell.y)):
		first -= 1
	var last := cell.x
	while grid.is_free(Vector2i(last + 1, cell.y)):
		last += 1
	return Vector2i(first, last)
