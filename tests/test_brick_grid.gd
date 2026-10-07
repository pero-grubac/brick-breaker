extends GutTest

## Unit tests for BrickGrid: registration, removal and the 8-cell neighborhood.

var _grid: BrickGrid


func before_each() -> void:
	_grid = BrickGrid.new()


func _brick() -> Brick:
	# A bare Brick object is enough here: the grid never touches its nodes.
	return autofree(Brick.new())


func test_at_returns_registered_brick() -> void:
	var b := _brick()
	_grid.add(Vector2i(3, 2), b)
	assert_eq(_grid.at(Vector2i(3, 2)), b)
	assert_null(_grid.at(Vector2i(0, 0)))


func test_neighbors_are_the_8_surrounding_cells() -> void:
	var center := Vector2i(5, 5)
	_grid.add(center, _brick())
	for offset in BrickGrid.NEIGHBOR_OFFSETS:
		_grid.add(center + offset, _brick())
	_grid.add(Vector2i(7, 5), _brick())  # two cells away: not a neighbor
	assert_eq(_grid.neighbors(center).size(), 8)


func test_neighbors_do_not_include_the_cell_itself() -> void:
	var b := _brick()
	_grid.add(Vector2i(1, 1), b)
	assert_eq(_grid.neighbors(Vector2i(1, 1)).size(), 0)


func test_neighbors_at_the_edge_skip_missing_cells() -> void:
	_grid.add(Vector2i(0, 0), _brick())
	_grid.add(Vector2i(1, 0), _brick())
	_grid.add(Vector2i(0, 1), _brick())
	assert_eq(_grid.neighbors(Vector2i(0, 0)).size(), 2)


func test_remove_only_removes_the_owner() -> void:
	var a := _brick()
	var b := _brick()
	_grid.add(Vector2i(2, 2), a)
	_grid.remove(Vector2i(2, 2), b)
	assert_eq(_grid.at(Vector2i(2, 2)), a, "another brick cannot remove it")
	_grid.remove(Vector2i(2, 2), a)
	assert_null(_grid.at(Vector2i(2, 2)))


func test_clear() -> void:
	_grid.add(Vector2i(0, 0), _brick())
	_grid.clear()
	assert_eq(_grid.size(), 0)
