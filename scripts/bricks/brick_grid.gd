class_name BrickGrid
extends RefCounted

## Which brick sits in which level cell, so bricks can find their neighbors (TNT and others).
## Cells are Vector2i(column, row).

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

var _cells: Dictionary[Vector2i, Brick] = {}


func add(cell: Vector2i, brick: Brick) -> void:
	_cells[cell] = brick


## Removes the brick only if it still owns the cell.
func remove(cell: Vector2i, brick: Brick) -> void:
	if _cells.get(cell) == brick:
		_cells.erase(cell)


func at(cell: Vector2i) -> Brick:
	return _cells.get(cell)


## The bricks in the 8 cells around `cell`.
func neighbors(cell: Vector2i) -> Array[Brick]:
	var result: Array[Brick] = []
	for offset in NEIGHBOR_OFFSETS:
		var brick: Brick = _cells.get(cell + offset)
		if brick != null:
			result.append(brick)
	return result


func size() -> int:
	return _cells.size()


func clear() -> void:
	_cells.clear()
